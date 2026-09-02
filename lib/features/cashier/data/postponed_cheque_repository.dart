import 'dart:convert';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/features/cashier/domain/postponed_cheque.dart';

/// Доступ к API отложенных чеков.
///
/// Два разных эндпоинта, которые легко перепутать:
/// `cheque-online-list-cashbox/{posId}` — чеки, отложенные самой кассой,
/// `cheque-online-list/{posId}` — чеки, присланные агентами (облако).
/// Удаляются оба через `cheque-online-cashbox/{id}`.
class PostponedChequeRepository {
  const PostponedChequeRepository();

  /// Отложить чек на сервер. Реквизиты покупателя дублируются рядом с чеком —
  /// по ним сервер отдаёт список, не разбирая JSON.
  Future<bool> save({required dynamic posId, required Map cheque}) async {
    final response = await post('/services/desktop/api/cheque-online-cashbox', {
      'clientId': cheque['clientId'],
      'clientName': cheque['clientName'],
      'organizationId': cheque['organizationId'],
      'organizationName': cheque['organizationName'],
      'posId': posId,
      'cheque': jsonEncode(cheque),
    });
    return httpOk(response);
  }

  /// Чеки, отложенные кассами этой точки.
  Future<List<PostponedCheque>> list(dynamic posId) async {
    final response = await get('/services/desktop/api/cheque-online-list-cashbox/$posId');
    return parsePostponedList(response);
  }

  /// Чеки, присланные агентами.
  Future<List<PostponedCheque>> cloud(dynamic posId) async {
    final response = await get('/services/desktop/api/cheque-online-list/$posId');
    return parsePostponedList(response);
  }

  /// Удалить чек с сервера (и отложенный кассой, и агентский).
  Future<bool> remove(dynamic id) async {
    if (id == null) return false;
    final response = await del('/services/desktop/api/cheque-online-cashbox/$id');
    return httpOk(response);
  }
}
