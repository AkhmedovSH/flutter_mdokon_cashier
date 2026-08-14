import 'package:get_storage/get_storage.dart';

import 'package:flutter_mdokon/core/network/api.dart';

/// Единственная точка доступа к API авторизации.
///
/// Слой данных ничего не знает о виджетах и навигации: он только ходит
/// в сеть и пишет токен в хранилище.
class AuthRepository {
  final GetStorage storage;

  AuthRepository({GetStorage? storage}) : storage = storage ?? GetStorage();

  /// POST /auth/login — возвращает `true`, если токен получен и сохранён.
  Future<bool> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    final response = await post(
      '/auth/login',
      {'username': username, 'password': password, 'rememberMe': rememberMe},
      isGuest: true,
    );
    if (!httpOk(response) || response['access_token'] == null) return false;

    storage.write('access_token', response['access_token']);
    return true;
  }

  /// Нужно ли подтверждение по SMS для текущего токена.
  Future<Map> checkOtp() async {
    final response = await get('/services/desktop/api/check-otp');
    return httpOk(response) ? Map.from(response) : {};
  }

  /// Проверка кода из SMS.
  Future<bool> verifyOtp(Map payload) async {
    final response = await post('/services/desktop/api/verify-otp', payload);
    return httpOk(response) && response['success'] == true;
  }

  /// Профиль пользователя с ролями.
  Future<Map> account() async {
    final response = await get('/services/desktop/api/account');
    return httpOk(response) ? Map.from(response) : {};
  }

  /// Доступные точки/кассы либо уже открытая смена.
  Future<Map> accessPos() async {
    final response = await get('/services/desktop/api/get-access-pos');
    return httpOk(response) ? Map.from(response) : {};
  }

  /// Баланс точек — нужен ролям владельца и мерчендайзера.
  Future<dynamic> posBalance() => get('/services/web/api/pos-balance');

  /// Открытие смены на выбранной кассе.
  Future<Map> openShift({
    required dynamic posId,
    required dynamic cashboxId,
    bool offline = false,
  }) async {
    final response = await post('/services/desktop/api/open-shift', {
      'posId': posId,
      'cashboxId': cashboxId,
      'offline': offline,
    });
    return httpOk(response) ? Map.from(response) : {};
  }

  /// Фиксируем время входа — по нему роутер решает, жива ли сессия.
  void writeLastLogin() {
    final now = DateTime.now();
    storage.write('lastLogin', {
      'year': now.year,
      'month': now.month,
      'day': now.day,
      'hour': now.hour,
      'minute': now.minute,
    });
  }
}
