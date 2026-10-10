import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

import 'package:flutter_mdokon/core/storage/credential_store.dart';
import 'package:flutter_mdokon/core/utils/logger.dart';
import 'package:flutter_mdokon/core/state/settings_model.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/auth/data/auth_repository.dart';
import 'package:flutter_mdokon/features/auth/models/auth_roles.dart';
import 'package:flutter_mdokon/features/auth/models/user_model.dart';

/// Куда уйти после успешного входа. Саму навигацию делает страница —
/// модель не знает ни про BuildContext, ни про go_router.
class AuthRedirect {
  final String path;
  final Object? extra;

  const AuthRedirect(this.path, {this.extra});
}

/// Шаг формы авторизации.
enum AuthStep { credentials, otp }

/// Состояние и сценарий входа: логин → (SMS) → аккаунт → роль → смена.
class AuthModel extends ChangeNotifier {
  /// Логин и пароль демо-доступа — вход по ним идёт обычным сценарием.
  static const demoUsername = '2';
  static const demoPassword = '2';

  final AuthRepository repository;
  final UserModel userModel;
  final GetStorage storage;
  final CredentialStore credentials;

  AuthModel({
    required this.userModel,
    AuthRepository? repository,
    GetStorage? storage,
    CredentialStore? credentials,
  })  : repository = repository ?? AuthRepository(),
        storage = storage ?? GetStorage(),
        credentials = credentials ?? credentialStore;

  // --- Форма -----------------------------------------------------------
  String username = '';
  String password = '';
  String otp = '';
  bool rememberMe = false;
  bool showPassword = false;

  AuthStep step = AuthStep.credentials;
  String otpOffer = '';

  bool _submitting = false;
  String? _error;

  bool get submitting => _submitting;
  String? get error => _error;
  bool get isOtpStep => step == AuthStep.otp;

  bool get canSubmit => isOtpStep
      ? otp.trim().isNotEmpty
      : username.trim().isNotEmpty && password.trim().isNotEmpty;

  void setUsername(String value) => _update(() {
        username = value;
        _error = null;
      });

  void setPassword(String value) => _update(() {
        password = value;
        _error = null;
      });

  void setOtp(String value) => _update(() {
        otp = value;
        _error = null;
      });

  void toggleRememberMe([bool? value]) => _update(() => rememberMe = value ?? !rememberMe);

  void togglePasswordVisibility() => _update(() => showPassword = !showPassword);

  /// Вход демо-доступом: креды не попадают в поля формы, сценарий обычный.
  /// Если войти не удалось — возвращаем форме то, что в ней было.
  Future<AuthRedirect?> submitDemo() async {
    if (_submitting) return null;

    final prevUsername = username;
    final prevPassword = password;
    _update(() {
      step = AuthStep.credentials;
      username = demoUsername;
      password = demoPassword;
      otp = '';
      _error = null;
    });

    final redirect = await submit();
    if (redirect == null && step == AuthStep.credentials) {
      _update(() {
        username = prevUsername;
        password = prevPassword;
      });
    }
    return redirect;
  }

  /// Вернуться со шага SMS к логину и паролю.
  void backToCredentials() => _update(() {
        step = AuthStep.credentials;
        otp = '';
        _error = null;
      });

  /// Подставить сохранённые логин и пароль, если стояла галочка «Запомнить меня».
  /// Пароль читается из защищённого хранилища ([CredentialStore]).
  Future<void> restoreSavedCredentials() async {
    final saved = storage.read('user');
    if (saved is! Map || customIf(saved['rememberMe']) != true) return;

    // Логин и галочку ставим сразу (до первого кадра), пароль — когда
    // ответит хранилище, и только если кассир не успел ввести свой.
    username = '${saved['username'] ?? ''}';
    rememberMe = true;
    final savedPassword = await credentials.readPassword() ?? '';
    if (password.isEmpty && savedPassword.isNotEmpty) {
      _update(() => password = savedPassword);
    }
  }

  /// Дефолтные настройки при первом запуске. Список один на всё приложение —
  /// [SettingsModel.defaults]; дублировать его здесь было нечем, кроме как
  /// расхождениями.
  void ensureDefaultSettings() {
    if (storage.read('settings') != null) return;
    storage.write('settings', Map<String, dynamic>.from(SettingsModel.defaults));
  }

  // --- Сценарий --------------------------------------------------------

  /// Основное действие кнопки: вход или подтверждение SMS.
  /// Возвращает маршрут для перехода либо `null`, если переход не нужен
  /// (ошибка, либо мы остались на шаге SMS).
  Future<AuthRedirect?> submit() async {
    if (_submitting) return null;
    if (!canSubmit) {
      _fail('Заполните логин и пароль');
      return null;
    }

    _setSubmitting(true);
    try {
      final redirect = isOtpStep ? await _confirmOtp() : await _signIn();
      // Вход не удался (и не ждём код из SMS) — не оставляем полуоткрытую сессию:
      // после перезапуска роутер пустил бы в кассу по user + lastLogin.
      if (redirect == null && !isOtpStep && step != AuthStep.otp) _dropSession();
      return redirect;
    } catch (e) {
      appLog.exception('auth.submit_failed', e);
      _dropSession();
      // Кассир на точке не пойдёт в логи: показываем, на чём именно споткнулись.
      _fail('Вход прерван: ${_reason(e)}');
      return null;
    } finally {
      _setSubmitting(false);
    }
  }

  /// Забываем прошлую сессию: токен, роль, `user`, `lastLogin`, смену. Корзину
  /// (`saleSession`) оставляем только тому же логину, иначе чужой чек уехал бы
  /// к другому кассиру.
  void _dropSession({bool keepSale = false}) {
    if (!keepSale) storage.remove('saleSession');
    for (final key in const [
      'access_token',
      'lastLogin',
      'user',
      'role',
      'user_roles',
      'shift',
    ]) {
      storage.remove(key);
    }
  }

  Future<AuthRedirect?> _signIn() async {
    final prev = storage.read('user');
    final sameUser = prev is Map && '${prev['username']}' == username.trim();
    _dropSession(keepSale: sameUser);

    final ok = await repository.login(
      username: username.trim(),
      password: password,
      rememberMe: rememberMe,
    );
    if (!ok) {
      _fail(repository.lastLoginError);
      return null;
    }

    final checkOtp = await repository.checkOtp();
    if (customIf(checkOtp['sendSms'])) {
      _update(() {
        step = AuthStep.otp;
        otp = '';
        otpOffer = '${checkOtp['offer'] ?? ''}';
      });
      return null;
    }

    return _loadAccount();
  }

  Future<AuthRedirect?> _confirmOtp() async {
    final ok = await repository.verifyOtp({'otp': otp.trim(), 'sendSms': false});
    if (!ok) {
      _fail('Неверный код из SMS');
      return null;
    }
    return _loadAccount();
  }

  /// Профиль, роль и точка входа для этой роли.
  Future<AuthRedirect?> _loadAccount() async {
    final account = await repository.account();
    if (account.isEmpty) {
      _fail('Сервер не вернул профиль пользователя. Проверьте связь и повторите');
      return null;
    }

    // Пароль нужен для тихого перелогина, но в GetStorage (`user`) он не
    // попадает — только в Keystore/Keychain.
    await credentials.writePassword(password);
    userModel.setUser({
      'username': username.trim(),
      'rememberMe': rememberMe,
      ...account,
    });
    repository.writeLastLogin();

    final role = AuthRoles.resolve(account['authorities']);
    storage.write('user_roles', account['authorities']);
    storage.write('role', role ?? '');

    return switch (role) {
      AuthRoles.cashier => await _openCashierSession(),
      AuthRoles.agent => await _openAgentSession(),
      AuthRoles.owner || AuthRoles.merchandiser => await _openDirectorSession(),
      _ => _fail(
          'У пользователя нет роли для входа в кассу '
          '(права: ${_authorities(account['authorities'])})',
        ),
    };
  }

  /// Кассир: либо возвращаемся в открытую смену, либо идём выбирать кассу.
  Future<AuthRedirect?> _openCashierSession() async {
    final response = await repository.accessPos();
    if (response.isEmpty) return _fail('Сервер не вернул ни одной кассы для этого кассира');

    if (customIf(response['openShift'])) {
      storage.remove('shift');
      final shift = Map.from(response['shift'] ?? {});
      shift['defaultCurrencyName'] = shift['defaultCurrency'] == 2 ? 'USD' : "So'm";
      userModel.setCashbox(shift);

      final ready = await userModel.getPaymentTypes(shift['posId']);
      await userModel.getCashboxSettings(shift['posId']);
      if (ready != true) return _fail(userModel.paymentTypesError);

      return const AuthRedirect('/cashier');
    }

    return AuthRedirect(
      '/auth/cashboxes',
      extra: {'posList': response['posList'] ?? []},
    );
  }

  Future<AuthRedirect?> _openAgentSession() async {
    final response = await repository.accessPos();
    if (response.isEmpty) return _fail('Сервер не вернул ни одной точки для агента');

    response['isAgent'] = true;
    response['defaultCurrencyName'] = response['defaultCurrency'] == 2 ? 'USD' : "So'm";
    userModel.setCashbox(response);
    return const AuthRedirect('/agent');
  }

  Future<AuthRedirect?> _openDirectorSession() async {
    final posBalance = await repository.posBalance();
    userModel.setUser({...userModel.user, 'posBalance': posBalance});
    return const AuthRedirect('/director');
  }

  /// Выбор кассы на экране «Свободные кассы»: открываем смену и уходим в кассу.
  Future<AuthRedirect?> selectCashbox({
    required Map pos,
    required Map cashbox,
  }) async {
    if (_submitting) return null;
    _setSubmitting(true);
    try {
      userModel.setCashbox({
        'defaultCurrency': cashbox['defaultCurrency'],
        'defaultCurrencyName': cashbox['defaultCurrency'] == 2 ? 'USD' : "So'm",
        'hidePriceIn': pos['hidePriceIn'],
        'loyaltyApi': pos['loyaltyApi'],
        // UDS — вторая программа лояльности. Ключи лежат на сервере, кассе
        // нужно знать только, подключена ли она на точке: от этого зависит
        // вкладка «UDS» в оплате.
        'udsEnabled': pos['udsEnabled'] == true,
        'udsCompanyId': pos['udsCompanyId'],
        'saleMinus': pos['saleMinus'],
        'posId': pos['posId'],
        'posName': pos['posName'],
        'posAddress': pos['posAddress'],
        'posPhone': pos['posPhone'],
        'cashboxId': cashbox['id'],
        'cashboxName': cashbox['name'],
      });

      final shift = await repository.openShift(
        posId: pos['posId'],
        cashboxId: cashbox['id'],
      );
      if (customIf(shift['success']) != true) {
        final message = '${shift['message'] ?? ''}'.trim();
        return _fail(
          message.isEmpty
              ? 'Смена на кассе «${cashbox['name']}» не открылась — сервер отказал без пояснения'
              : 'Смена на кассе «${cashbox['name']}» не открылась: $message',
        );
      }
      storage.write('shift', shift);

      final ready = await userModel.getPaymentTypes(pos['posId']);
      await userModel.getCashboxSettings(pos['posId']);
      if (ready != true) return _fail(userModel.paymentTypesError);

      return const AuthRedirect('/cashier');
    } catch (e) {
      appLog.exception('auth.open_shift_failed', e);
      return _fail('Смена не открылась: ${_reason(e)}');
    } finally {
      _setSubmitting(false);
    }
  }

  // --- Служебное -------------------------------------------------------

  /// Человекочитаемая причина из исключения: свой текст Exception показываем
  /// как есть, служебный префикс `Exception:` убираем.
  String _reason(Object error) {
    final text = error is Exception
        ? error.toString().replaceFirst('Exception: ', '')
        : error.toString();
    return text.isEmpty ? 'неизвестная ошибка' : text;
  }

  String _authorities(dynamic value) {
    if (value is List && value.isNotEmpty) return value.join(', ');
    return 'список пуст';
  }

  AuthRedirect? _fail(String message) {
    _error = message.trim().isEmpty ? 'Неизвестная ошибка входа' : message.trim();
    notifyListeners();
    appLog.warn('auth.failed', {'message': _error});
    showDangerToast(_error!);
    return null;
  }

  void _setSubmitting(bool value) => _update(() => _submitting = value);

  void _update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
