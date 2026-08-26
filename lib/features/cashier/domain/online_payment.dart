import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Онлайн-оплата с телефона покупателя: Click Pass, Payme, Uzum (Apelsin).
///
/// Порт `Tab.js:3082-3220` + `apiClick.js` / `apiPayme.js` / `apiUzum.js` +
/// `generate-sha1` из `public/electron.js:177`. Фискальный накопитель здесь не
/// участвует ни в одном шаге — нужен только `merchant_secret_key` точки,
/// поэтому провайдеры и переносятся на мобилку (в отличие от UzQR).
///
/// Файл чистый: ни сети, ни Flutter. Сеть — в `data/online_payment_repository.dart`.
enum OnlineProvider { click, payme, uzum }

/// `paymentTypeId` из справочника типов оплаты кассы.
int onlineProviderPaymentTypeId(OnlineProvider provider) => switch (provider) {
      OnlineProvider.click => 5,
      OnlineProvider.payme => 6,
      OnlineProvider.uzum => 7,
    };

OnlineProvider? onlineProviderFromPaymentTypeId(dynamic id) {
  final value = id is num ? id.toInt() : int.tryParse('${id ?? ''}');
  return switch (value) {
    5 => OnlineProvider.click,
    6 => OnlineProvider.payme,
    7 => OnlineProvider.uzum,
    _ => null,
  };
}

/// Ключ настроек кассы, где лежат merchant-данные провайдера.
String onlineProviderCashboxKey(OnlineProvider provider) => switch (provider) {
      OnlineProvider.click => 'clickPay',
      OnlineProvider.payme => 'paymePay',
      OnlineProvider.uzum => 'uzumPay',
    };

/// Название провайдера для сообщения кассиру.
String onlineProviderName(OnlineProvider provider) => switch (provider) {
      OnlineProvider.click => 'Click',
      OnlineProvider.payme => 'Payme',
      OnlineProvider.uzum => 'Uzum',
    };

double _amount(dynamic value) {
  if (value is num) return value.toDouble();
  final text = '${value ?? ''}'.replaceAll(' ', '').replaceAll(',', '.');
  return double.tryParse(text) ?? 0;
}

/// Выбранный кассиром онлайн-способ оплаты и его сумма.
class OnlinePaymentSelection {
  const OnlinePaymentSelection({
    required this.provider,
    required this.amount,
    this.customPaymentTypeId,
  });

  final OnlineProvider provider;

  /// Сумма в сумах (не в тийинах): перевод — забота payload'а провайдера.
  final double amount;
  final dynamic customPaymentTypeId;
}

/// Есть ли в чеке онлайн-оплата и на какую сумму.
///
/// Как на десктопе (`Tab.js:1937-1959`): побеждает последний непустой онлайн-способ,
/// сумма складывается по всем онлайн-способам. Смешивать Click с Payme в одном
/// чеке нельзя — но справочник это и не позволяет, у точки подключён один провайдер.
OnlinePaymentSelection? detectOnlinePayment(List<dynamic>? paymentTypes) {
  OnlineProvider? provider;
  dynamic customPaymentTypeId;
  double amount = 0;

  for (final raw in paymentTypes ?? const []) {
    if (raw is! Map) continue;
    final sum = _amount(raw['amount']);
    if (sum <= 0) continue;
    final current = onlineProviderFromPaymentTypeId(raw['paymentTypeId']);
    if (current == null) continue;
    provider = current;
    customPaymentTypeId = raw['customPaymentTypeId'];
    amount += sum;
  }

  if (provider == null) return null;
  return OnlinePaymentSelection(
    provider: provider,
    amount: amount,
    customPaymentTypeId: customPaymentTypeId,
  );
}

/// Идентификатор кассы в формате провайдера (`Tab.js:3093`).
String onlineCashboxCode({dynamic posId, dynamic cashboxId, dynamic shiftId}) =>
    'posId${posId}cashboxId${cashboxId}shiftId$shiftId';

/// Подпись запроса: `id:sha1(timestamp + secret):timestamp`.
///
/// `timestampMs` — миллисекунды: на десктопе это `getTime()` из date-fns
/// (`electron.js:178`), а не unix-секунды.
String onlineAuthToken({
  required String userId,
  required String secret,
  required int timestampMs,
}) {
  final hash = sha1.convert(utf8.encode('$timestampMs$secret')).toString();
  return '$userId:$hash:$timestampMs';
}

/// Тот же токен, но с разбором merchant-данных кассы.
///
/// Click подписывается `merchant_service_user_id`, Uzum — `merchant_id`
/// (`electron.js:184-189`). Payme подписи не использует вовсе: там пара
/// `merchant_id:merchant_secret_key`.
String? onlineAuthFromCashbox(
  OnlineProvider provider,
  Map<String, dynamic>? merchant,
  int timestampMs,
) {
  final secret = '${merchant?['merchant_secret_key'] ?? ''}';
  if (secret.isEmpty) return null;

  if (provider == OnlineProvider.payme) {
    final id = '${merchant?['merchant_id'] ?? ''}';
    if (id.isEmpty) return null;
    return '$id:$secret';
  }

  final userId = provider == OnlineProvider.click
      ? '${merchant?['merchant_service_user_id'] ?? ''}'
      : '${merchant?['merchant_id'] ?? ''}';
  if (userId.isEmpty) return null;

  return onlineAuthToken(userId: userId, secret: secret, timestampMs: timestampMs);
}

/// Payload Click Pass. Сумма идёт в сумах, без умножения (`Tab.js:3180-3188`).
Map<String, dynamic> clickPayload({
  required double amount,
  required String cashboxCode,
  required String otpCode,
  required dynamic transactionId,
  required dynamic serviceId,
}) =>
    {
      'amount': amount,
      'cashbox_code': cashboxCode,
      'otp_data': otpCode,
      'transaction_id': transactionId,
      'service_id': serviceId,
      'items': const [],
    };

/// Payload Uzum (Apelsin). Сумма в тийинах.
Map<String, dynamic> uzumPayload({
  required double amount,
  required String cashboxCode,
  required String otpCode,
  required dynamic transactionId,
  required dynamic serviceId,
}) =>
    {
      'amount': (amount * 100).round(),
      'cashbox_code': cashboxCode,
      'otp_data': otpCode,
      'transaction_id': transactionId,
      'service_id': serviceId,
    };

/// Payme, шаг 1: `receipts.create`. Сумма в тийинах, состав чека — позициями.
Map<String, dynamic> paymeCreatePayload({
  required dynamic chequeNumber,
  required double amount,
  required List<dynamic> itemsList,
}) {
  final items = <Map<String, dynamic>>[];
  for (final raw in itemsList) {
    if (raw is! Map) continue;
    items.add({
      'title': raw['productName'],
      'price': (_amount(raw['salePrice']) * 100).round(),
      'count': raw['quantity'],
      'code': raw['gtin'],
      'vat_percent': raw['vat'],
      'package_code': raw['packageCode'],
    });
  }

  return {
    'id': chequeNumber,
    'method': 'receipts.create',
    'params': {
      'amount': (amount * 100).round(),
      'account': {'order_id': chequeNumber},
      'detail': {'receipt_type': 0, 'items': items},
    },
  };
}

/// Payme, шаг 2: `receipts.pay` по чеку, созданному на шаге 1.
Map<String, dynamic> paymePayPayload({
  required dynamic requestId,
  required dynamic receiptId,
  required String otpCode,
}) =>
    {
      'id': requestId,
      'method': 'receipts.pay',
      'params': {'id': receiptId, 'token': otpCode},
    };

/// `_id` чека Payme из ответа `receipts.create`; `null` — ответ не разобран.
String? paymeReceiptId(dynamic response) {
  final result = response is Map ? response['result'] : null;
  final receipt = result is Map ? result['receipt'] : null;
  final id = receipt is Map ? receipt['_id'] : null;
  return id == null ? null : '$id';
}

/// Результат оплаты у провайдера.
class OnlinePaymentResult {
  const OnlinePaymentResult({
    required this.ok,
    this.error,
    this.paymentId,
    this.clientPhone,
  });

  final bool ok;

  /// Готовое сообщение провайдера — показывается кассиру как есть.
  final String? error;
  final String? paymentId;
  final String? clientPhone;
}

String? _text(dynamic value) {
  final text = '${value ?? ''}'.trim();
  return text.isEmpty ? null : text;
}

bool _hasError(dynamic code) {
  if (code == null) return false;
  final value = code is num ? code.toDouble() : double.tryParse('$code');
  return value == null ? '$code'.trim().isNotEmpty : value != 0;
}

/// Ответ Click Pass. Ошибка — непустой `error_code` (`Tab.js:3214`).
OnlinePaymentResult parseClickResponse(dynamic response) {
  if (response is! Map) return const OnlinePaymentResult(ok: false);
  if (_hasError(response['error_code'])) {
    return OnlinePaymentResult(
      ok: false,
      error: _text(response['error_note']) ?? _text(response['error_message']),
    );
  }
  return OnlinePaymentResult(
    ok: true,
    paymentId: _text(response['payment_id']),
    clientPhone: _text(response['phone_number']),
  );
}

/// Ответ Uzum. Ошибка — `error_code > 0` (`Tab.js:3104`).
OnlinePaymentResult parseUzumResponse(dynamic response) {
  if (response is! Map) return const OnlinePaymentResult(ok: false);
  final code = response['error_code'];
  final value = code is num ? code.toDouble() : double.tryParse('${code ?? ''}');
  if (value != null && value > 0) {
    return OnlinePaymentResult(ok: false, error: _text(response['error_message']));
  }
  return OnlinePaymentResult(
    ok: true,
    paymentId: _text(response['payment_id']),
    clientPhone: _text(response['client_phone_number']),
  );
}

/// Ответ Payme на `receipts.pay`. Ошибка — объект `error` (`Tab.js:3157`).
OnlinePaymentResult parsePaymeResponse(dynamic response) {
  if (response is! Map) return const OnlinePaymentResult(ok: false);
  final error = response['error'];
  if (error is Map && error['code'] != null) {
    final message = _text(error['message']) ?? '';
    final detail = _text(error['data']) ?? '';
    return OnlinePaymentResult(ok: false, error: _text('$message $detail'.trim()));
  }

  final result = response['result'];
  final receipt = result is Map ? result['receipt'] : null;
  final payer = receipt is Map ? receipt['payer'] : null;
  return OnlinePaymentResult(
    ok: true,
    paymentId: receipt is Map ? _text(receipt['_id']) : null,
    clientPhone: payer is Map ? _text(payer['phone']) : null,
  );
}
