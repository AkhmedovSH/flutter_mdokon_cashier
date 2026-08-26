/// Абонплата картой из кассы (Multicard / Rahmat).
///
/// Порт `src/api/apiMulticard.js` + `SubscriptionPaymentModal.js`.
/// Накопитель не участвует: касса только создаёт счёт и опрашивает его статус,
/// баланс точки пополняет callback Multicard на стороне сервера.
///
/// Файл чистый: разбор ответов и правила шага «выбор точки и суммы».
library;

/// Статус счёта. `NOT_FOUND` от сервера — тоже «ещё не оплачен»: счёт мог
/// не успеть дойти до Multicard.
enum InvoiceStatus { pending, paid, canceled, failed }

InvoiceStatus parseInvoiceStatus(dynamic raw) {
  if (raw is! Map) return InvoiceStatus.pending;
  if (raw['paid'] == true) return InvoiceStatus.paid;

  return switch ('${raw['status'] ?? ''}'.trim().toUpperCase()) {
    'PAID' => InvoiceStatus.paid,
    'CANCELED' => InvoiceStatus.canceled,
    'FAILED' => InvoiceStatus.failed,
    _ => InvoiceStatus.pending,
  };
}

/// Ключ перевода для неуспешного статуса; `null` — говорить нечего.
String? invoiceStatusMessageKey(InvoiceStatus status) => switch (status) {
      InvoiceStatus.canceled => 'subscription_pay_canceled',
      InvoiceStatus.failed => 'subscription_pay_failed',
      _ => null,
    };

/// Точка продаж в списке к оплате.
class SubscriptionPoint {
  const SubscriptionPoint({
    required this.posId,
    required this.name,
    required this.balance,
    required this.suggestedAmount,
    required this.activated,
  });

  final int posId;
  final String name;

  /// Баланс точки: минус — долг.
  final double balance;

  /// Сумма, которую сервер предлагает внести.
  final double suggestedAmount;
  final bool activated;

  static double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('${value ?? ''}'.replaceAll(' ', '')) ?? 0;
  }

  static SubscriptionPoint? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final posId = raw['posId'] is num
        ? (raw['posId'] as num).toInt()
        : int.tryParse('${raw['posId'] ?? ''}');
    if (posId == null) return null;

    return SubscriptionPoint(
      posId: posId,
      name: '${raw['name'] ?? raw['posName'] ?? ''}',
      balance: _number(raw['balance']),
      suggestedAmount: _number(raw['suggestedAmount']),
      activated: raw['activated'] != false,
    );
  }

  /// Сумма, подставляемая в поле при выборе точки (`SubscriptionPaymentModal.js:73`).
  int get defaultAmount => suggestedAmount <= 0 ? 0 : suggestedAmount.round();
}

List<SubscriptionPoint> parseSubscriptionPoints(dynamic raw) {
  final list = raw is List ? raw : const [];
  return list.map(SubscriptionPoint.fromJson).whereType<SubscriptionPoint>().toList();
}

/// Созданный счёт.
class SubscriptionInvoice {
  const SubscriptionInvoice({
    required this.success,
    this.invoiceId,
    this.shortLink,
    this.message,
    this.amount = 0,
  });

  final bool success;
  final String? invoiceId;

  /// Ссылка на страницу банка: открывается во внешнем браузере (3-D Secure).
  final String? shortLink;

  /// Текст ошибки сервиса — показывается кассиру как есть.
  final String? message;
  final int amount;

  /// Счёт годен, только если есть куда отправить плательщика.
  bool get usable => success && (shortLink ?? '').isNotEmpty;

  static SubscriptionInvoice fromJson(dynamic raw, {int amount = 0}) {
    if (raw is! Map) return const SubscriptionInvoice(success: false);
    final id = raw['invoiceId'];
    return SubscriptionInvoice(
      success: raw['success'] == true,
      invoiceId: id == null ? null : '$id',
      shortLink: '${raw['shortLink'] ?? ''}'.isEmpty ? null : '${raw['shortLink']}',
      message: '${raw['message'] ?? ''}'.isEmpty ? null : '${raw['message']}',
      amount: amount,
    );
  }
}

/// Ключ ошибки шага «выбор точки и суммы»; `null` — можно создавать счёт.
String? subscriptionFormError({int? posId, required int amount}) {
  if (posId == null) return 'subscription_pay_no_point_selected';
  if (amount <= 0) return 'subscription_pay_amount_invalid';
  return null;
}

/// Опрашивать статус дольше 15 минут бессмысленно — счёт всё равно протухнет.
const subscriptionPollInterval = Duration(seconds: 5);
const subscriptionPollLimit = Duration(minutes: 15);
