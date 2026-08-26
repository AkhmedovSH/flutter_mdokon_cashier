import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/features/cashier/domain/subscription_payment.dart';

/// Абонплата картой через сервис `paysystems` — порт `src/api/apiMulticard.js`.
///
/// Поток: `/points` → `/invoice` → открыть `shortLink` в браузере →
/// опрос `/status/{invoiceId}`. Оплата идёт вне кассы (3-D Secure), поэтому
/// единственный источник правды об оплате — статус на сервере.
const _base = '/services/paysystems/api/multicard';

class SubscriptionPaymentRepository {
  const SubscriptionPaymentRepository();

  /// Точки, доступные пользователю. Любая ошибка — пустой список: модалка
  /// покажет «нет доступных точек», а не пустой экран с крутилкой.
  Future<List<SubscriptionPoint>> points() async {
    try {
      final response = await get('$_base/points');
      if (!httpOk(response)) return const [];
      return parseSubscriptionPoints(response);
    } catch (_) {
      return const [];
    }
  }

  /// Создать счёт. `amount` — в сумах, целое.
  Future<SubscriptionInvoice> createInvoice({
    required int posId,
    required int amount,
    String? phone,
  }) async {
    final payload = <String, dynamic>{'posId': posId, 'amount': amount};
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty) payload['phone'] = digits;

    try {
      final response = await post('$_base/invoice', payload);
      if (!httpOk(response)) return const SubscriptionInvoice(success: false);
      return SubscriptionInvoice.fromJson(response, amount: amount);
    } catch (_) {
      return const SubscriptionInvoice(success: false);
    }
  }

  /// Статус счёта. `null` — спросить не удалось; для опроса это не «не оплачен»,
  /// а «попробуем на следующем тике».
  Future<InvoiceStatus?> status(String invoiceId) async {
    try {
      final response = await get('$_base/status/$invoiceId');
      if (!httpOk(response)) return null;
      return parseInvoiceStatus(response);
    } catch (_) {
      return null;
    }
  }
}
