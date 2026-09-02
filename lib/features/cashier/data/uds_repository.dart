import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/features/cashier/domain/uds.dart';

/// Запросы UDS — порт `src/api/apiUds.js`.
///
/// Эндпоинты живут в том же сервисе `desktop`, что и остальная касса, но
/// мимо `core/network/api.dart`: там любая ошибка гасится тостом и наружу
/// уходит `false`. Здесь ответ сервера нужен целиком — реагируем на
/// `errorKey`, а не на текст.
const _base = '/services/desktop/api';

class UdsRepository {
  UdsRepository({Dio? client, GetStorage? store})
      : _dio = client ??
            Dio(BaseOptions(
              baseUrl: hostUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: const {'Accept': 'application/json'},
            )),
        _store = store ?? GetStorage();

  final Dio _dio;
  final GetStorage _store;

  Options get _auth => Options(
        headers: {'authorization': 'Bearer ${_store.read('access_token') ?? ''}'},
      );

  /// Любую ошибку запроса приводим к [UdsError] — порт `toUdsError`.
  Never _rethrowAsUds(Object error) {
    if (error is UdsError) throw error;
    if (error is DioException && error.response != null) {
      final payload = error.response!.data;
      throw UdsError(
        errorKey: udsErrorKeyOf(payload),
        message: payload is Map ? '${payload['message'] ?? ''}' : null,
        status: error.response!.statusCode,
      );
    }
    // Ответа не было вовсе: связь оборвалась или таймаут.
    throw UdsError(
      errorKey: udsUnavailableKey,
      message: '$error',
      networkFailure: true,
    );
  }

  /// Расчёт покупки: сколько спишется баллов, какая скидка и сколько платить
  /// деньгами. Промокод одноразовый и короткоживущий — между расчётом и
  /// проведением чека его не тянем.
  Future<UdsCalc> calc({
    required dynamic posId,
    String? code,
    String? phone,
    String? uid,
    required double total,
    double points = 0,
    double skipLoyaltyTotal = 0,
  }) async {
    final payload = <String, dynamic>{
      'posId': posId,
      ...udsIdentifierPayload(code: code, phone: phone, uid: uid),
      'total': total,
      'points': points,
      'skipLoyaltyTotal': skipLoyaltyTotal,
    };
    try {
      final response = await _dio.post('$_base/uds-calc', data: payload, options: _auth);
      return parseUdsCalc(response.data);
    } catch (e) {
      _rethrowAsUds(e);
    }
  }

  /// Найти клиента до расчёта. Ответ той же структуры, что у `uds-calc`.
  Future<UdsCalc> find({
    required dynamic posId,
    String? code,
    String? phone,
    String? uid,
  }) async {
    try {
      final response = await _dio.get(
        '$_base/uds-find/$posId',
        queryParameters: udsIdentifierPayload(code: code, phone: phone, uid: uid),
        options: _auth,
      );
      return parseUdsCalc(response.data);
    } catch (e) {
      _rethrowAsUds(e);
    }
  }

  /// Чек с лояльностью UDS. Операцию в UDS проводит сам сервер — до сохранения
  /// чека, поэтому отправляем его отдельно от общего `post()`: при отказе
  /// нужен `errorKey`, а не тост «ошибка».
  ///
  /// Возвращает тело ответа. Отказ — [UdsError].
  Future<dynamic> createCheque(Map<String, dynamic> cheque) async {
    try {
      final response = await _dio.post('$_base/cheque-v2', data: cheque, options: _auth);
      return response.data;
    } catch (e) {
      _rethrowAsUds(e);
    }
  }
}
