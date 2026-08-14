import 'dart:convert';

import 'package:flutter_mdokon/core/network/api.dart';

/// Доступ к API экрана продажи.
///
/// Слой данных ничего не знает о виджетах: только сеть и разбор ответа.
class SaleRepository {
  const SaleRepository();

  /// Отправка чека агентом на кассу (`create` или `update`).
  Future<bool> sendToCashbox({
    required dynamic posId,
    required Map cheque,
    dynamic id,
  }) async {
    final payload = {
      'posId': posId,
      'cheque': jsonEncode(cheque),
      'id': ?id,
    };

    final response = id != null
        ? await put('/services/desktop/api/cheque-online', payload)
        : await post('/services/desktop/api/cheque-online', payload);

    return httpOk(response) && response['success'] == true;
  }

  /// Клиенты с долгом по точке — для модалки погашения.
  Future<List> debtClients(dynamic posId) async {
    final response = await get('/services/desktop/api/client-debt-list/$posId');
    return response is List ? response : const [];
  }

  /// Справочник статей расхода.
  Future<List> expenses() async {
    final response = await get('/services/desktop/api/expense-helper');
    return response is List ? response : const [];
  }

  /// Расход из кассы.
  Future<bool> createExpense(Map payload) async {
    final response = await post('/services/desktop/api/expense-out', payload);
    return httpOk(response) && response['success'] == true;
  }

  /// Погашение долга клиента.
  Future<bool> repayDebt(Map payload) async {
    final response = await post('/services/desktop/api/client-debt-in', payload);
    return httpOk(response);
  }

  /// Список клиентов агента (с поиском).
  Future<List> clients({String search = ''}) async {
    final url = search.isEmpty
        ? '/services/desktop/api/clients-helper'
        : '/services/desktop/api/clients-helper?search=$search';
    final response = await get(url);
    return response is List ? response : const [];
  }

  /// Создание клиента.
  Future<bool> createClient(Map payload) async {
    final response = await post('/services/desktop/api/clients', payload);
    return httpOk(response) && response['success'] == true;
  }
}
