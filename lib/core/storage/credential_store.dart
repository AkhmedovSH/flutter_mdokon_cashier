import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';

import 'package:flutter_mdokon/core/utils/logger.dart';

/// Пароль пользователя — только здесь, в Android Keystore / iOS Keychain.
///
/// Зачем он вообще хранится: gateway `cabinet.mdokon.uz` выдаёт токен на
/// ~55 минут, а перевыпуска по refresh_token нет ни в одном клиенте (код
/// gateway/UAA локально недоступен, тело `/auth/login` читаем только
/// `access_token`), поэтому `checkToken()` (`core/network/api.dart`) молча
/// перелогинивается паролем.
/// Второе место — подстановка в форму входа при «Запомнить меня».
///
/// Раньше пароль лежал открытым текстом в GetStorage (`user.password`);
/// [migrateLegacy] переносит его сюда при старте.
///
/// Любая ошибка платформы (сброс ключей Keystore после восстановления из
/// бэкапа, нет плагина в тестах) не роняет приложение: пароля просто нет,
/// и кассир войдёт заново.
class CredentialStore {
  static const _passwordKey = 'user_password';

  final FlutterSecureStorage _secure;

  /// Копия в памяти: `checkToken()` зовётся перед каждым запросом, ходить
  /// каждый раз в Keystore незачем.
  String? _cached;
  bool _loaded = false;

  CredentialStore({FlutterSecureStorage? secure})
      : _secure = secure ?? const FlutterSecureStorage();

  Future<String?> readPassword() async {
    if (_loaded) return _cached;
    try {
      _cached = await _secure.read(key: _passwordKey);
    } catch (e) {
      appLog.exception('credentials.read_failed', e);
      _cached = null;
    }
    _loaded = true;
    return _cached;
  }

  Future<void> writePassword(String password) async {
    _cached = password;
    _loaded = true;
    try {
      await _secure.write(key: _passwordKey, value: password);
    } catch (e) {
      appLog.exception('credentials.write_failed', e);
    }
  }

  Future<void> deletePassword() async {
    _cached = null;
    _loaded = true;
    try {
      await _secure.delete(key: _passwordKey);
    } catch (e) {
      appLog.exception('credentials.delete_failed', e);
    }
  }

  /// Перенос пароля из старых версий: `user.password` в GetStorage →
  /// защищённое хранилище, а из GetStorage удаляем. Если записать в
  /// защищённое хранилище не вышло, пароль всё равно убираем — кассир один
  /// раз войдёт заново, зато открытым текстом пароль больше не лежит.
  Future<void> migrateLegacy(GetStorage storage) async {
    // Совсем старый ключ верхнего уровня (его чистит closeApp агента и
    // директора) — переносить нечего, просто убираем.
    if (storage.hasData('password')) await storage.remove('password');

    final user = storage.read('user');
    if (user is! Map || !user.containsKey('password')) return;

    final password = '${user['password'] ?? ''}';
    if (password.isNotEmpty) await writePassword(password);

    await storage.write('user', Map.from(user)..remove('password'));
    appLog.info('credentials.migrated');
  }
}

final CredentialStore credentialStore = CredentialStore();
