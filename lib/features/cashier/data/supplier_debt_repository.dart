import 'package:flutter_mdokon/core/network/api.dart';

/// Взаиморасчёт с поставщиками — порт `getOrganizationDebtList` /
/// `createOrganizationPayment` из `src/containers/Titlebar.js`.
///
/// Долг только гасится: касса выдаёт деньги поставщику (`amountOut`), увеличить
/// долг отсюда нельзя. Долг закрывается и деньги списываются из ящика одной
/// операцией — иначе выдачу пришлось бы проводить обычным расходом, и долг
/// поставщику остался бы висеть.
class SupplierDebtRepository {
  const SupplierDebtRepository();

  /// Долги по поставщикам и валютам на точке.
  Future<List> list(dynamic posId) async {
    final response = await get('/services/desktop/api/organization-debt-list/$posId');
    return response is List ? response : const [];
  }

  /// Выдача денег поставщику.
  ///
  /// Отказ приходит с кодом 200 и `success: false`, поэтому одного [httpOk]
  /// мало: сообщение сервера возвращаем наверх, чтобы кассир видел причину.
  Future<SupplierPaymentResult> pay(Map payload) async {
    final response = await post('/services/desktop/api/organization-payment', payload);
    if (!httpOk(response)) return const SupplierPaymentResult(ok: false);
    if (response is Map && response['success'] != true) {
      return SupplierPaymentResult(ok: false, message: '${response['message'] ?? ''}');
    }
    return const SupplierPaymentResult(ok: true);
  }
}

/// Результат выдачи: прошла ли операция и что ответил сервер.
class SupplierPaymentResult {
  const SupplierPaymentResult({required this.ok, this.message = ''});

  final bool ok;
  final String message;
}
