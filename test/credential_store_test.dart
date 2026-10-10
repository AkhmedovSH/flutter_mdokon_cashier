import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:flutter_mdokon/core/storage/credential_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late GetStorage storage;

  setUp(() async {
    // GetStorage пишет файл в папку документов — подменяем её временной.
    tmp = await Directory.systemTemp.createTemp('credential_store_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => tmp.path,
    );
    await GetStorage.init('credential_store_test');
    storage = GetStorage('credential_store_test');
    await storage.erase();
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    try {
      await tmp.delete(recursive: true);
    } catch (_) {}
  });

  test('старый пароль из user уезжает в защищённое хранилище и пропадает из GetStorage', () async {
    await storage.write('user', {'username': 'kassir', 'password': 'secret', 'rememberMe': true});
    final store = CredentialStore();

    await store.migrateLegacy(storage);

    final user = storage.read('user') as Map;
    expect(user.containsKey('password'), isFalse);
    expect(user['username'], 'kassir');
    expect(user['rememberMe'], true);
    expect(await const FlutterSecureStorage().read(key: 'user_password'), 'secret');
    expect(await CredentialStore().readPassword(), 'secret');
  });

  test('ключ password верхнего уровня удаляется', () async {
    await storage.write('password', 'old');
    await CredentialStore().migrateLegacy(storage);
    expect(storage.hasData('password'), isFalse);
  });

  test('без старого пароля миграция ничего не трогает', () async {
    await storage.write('user', {'username': 'kassir'});
    final store = CredentialStore();

    await store.migrateLegacy(storage);

    expect(storage.read('user'), {'username': 'kassir'});
    expect(await store.readPassword(), isNull);
  });

  test('выход стирает пароль', () async {
    final store = CredentialStore();
    await store.writePassword('secret');
    expect(await CredentialStore().readPassword(), 'secret');

    await store.deletePassword();
    expect(await store.readPassword(), isNull);
    expect(await CredentialStore().readPassword(), isNull);
  });
}
