# flutter_mdokon_cashier

Экосистема: @../../_ecosystems/mdokon.md

Мобильное приложение «mDokon POS» (Android, `com.mdokon.cabinet`; Dart-пакет `flutter_mdokon`)
для телефона и планшета: касса для кассира, сбор заказов для агента и короткий кабинет
директора/владельца. Функции переносятся с десктопной кассы `../../react/mdokon_cashbox`.

## Команды

```bash
flutter pub get
flutter run                                   # на подключённом устройстве/эмуляторе
flutter analyze                               # линт: flutter_lints, avoid_print выключен
flutter test                                  # все тесты test/*.dart (чистая доменная логика)
flutter test test/discount_engine_test.dart   # один файл
flutter test --plain-name "имя теста"         # один тест
flutter build apk --release                   # подпись из android/key.properties (+ upload-keystore.jks)
flutter build appbundle --release             # для Google Play
dart run flutter_launcher_icons               # иконки из images/build-logo.png
dart run flutter_native_splash:create         # сплэш по flutter_native_splash.yaml
```

`android/key.properties` и `*.jks` в `.gitignore` — без них release собирается не подписанным.
Платформ `windows/` в проекте нет; `ios/`, `macos/`, `linux/`, `web/` — заготовки, не поддерживаются
<!-- TODO: уточнить, нужен ли iOS -->.

## Стек

- Flutter, Dart SDK `^3.10.4`; версия приложения — `version:` в `pubspec.yaml` (`2.0.1+35`).
- Состояние — **Provider** (`ChangeNotifier`), все провайдеры собраны в `lib/app/providers.dart`.
- Роутер — **go_router 17** (`lib/app/router/app_router.dart` + `cashier_routes.dart`,
  `director_routes.dart`, `agent_routes.dart`; переходы — `nativePageBuilder`).
- HTTP — **Dio** (`lib/core/network/api.dart`), хранилище — **GetStorage** (без SQLite: приложение
  работает только онлайн).
- Локализация — **easy_localization**, файлы `assets/i18n/ru.json` и `uz-Latn.json`
  (узбекской кириллицы нет). Обращение — `context.tr('key')`.
- Печать — Bluetooth ESC/POS (`flutter_blue_plus`, `esc_pos_utils_plus`, `charset_converter`) в
  `features/cashier/models/printer_model.dart`. Сканер камеры — `mobile_scanner` (штрихкоды и DataMatrix).
- Обновление — `in_app_update` (Google Play) + проверка версии `/services/admin/api/get-version?name=com.mdokon.cabinet`.

## Архитектура

```
lib/
  main.dart            init GetStorage, EasyLocalization, файлового лога, темы
  app/                 App, провайдеры, роутер
  core/network/api.dart   get / pget / post / put / del, httpOk, statuscheker
  core/state, theme, utils (helper, logger, changelog, permissions), localization
  features/auth        вход, выбор кассы (AuthModel + AuthRepository)
  features/cashier     data/ (репозитории = только сеть), domain/ (чистые функции), models/ (ChangeNotifier), pages/
  features/agent       дашборд агента, его онлайн-чеки
  features/director    дашборд директора, приходы, инвентаризация, отчёты
  shared/              UI-кит (shared/widgets/ui/ui.dart), фильтры, таблица, сканер
```

- **Роли и редирект**: роль лежит в GetStorage (`role`); редирект в `app_router` срабатывает
  только на `/` и `/auth`: `ROLE_CASHIER` → `/cashier`, `ROLE_OWNER`/`ROLE_DIRECTOR` → `/director`,
  `ROLE_AGENT` → `/agent`. Сессия считается живой, если `lastLogin` моложе 55 минут.
- **Сеть**: базовый URL `https://cabinet.mdokon.uz`, пути полные (`/services/desktop/api/...`
  для кассы, `/services/web/api/...` для директора). Перед запросом `checkToken()` перелогинивается
  сохранённым паролем, если токену ≥55 минут. Пароль лежит **только** в `flutter_secure_storage`
  (Keystore/Keychain) через `core/storage/credential_store.dart`, не в GetStorage: пишется при
  входе, стирается при выходе/закрытии смены; старый `user.password` из GetStorage переносится
  при старте (`migrateLegacy` в `main.dart`). Каждая функция при ошибке показывает тост
  через `statuscheker` и **возвращает `false`**, не бросает — проверять ответ через `httpOk()`.
  `pget` возвращает `{data, total}` из заголовка `x-total-count`.
- **Продажа кассира**: корзина и вкладки чеков — `domain/sale_session.dart`, `sale_tabs.dart`
  (сессия переживает перезапуск в GetStorage, ключ `saleSession`); пересчёт через
  `discount_engine.dart` / `promotion_engine.dart` / `manual_discount.dart`; чек —
  `POST /services/desktop/api/cheque-v2` без фискализации. Агент отправляет корзину на кассу
  как онлайн-чек (`cheque-online`), кассир может отложить чек (`cheque-online-cashbox`).
- **Домен** `features/cashier/domain/*.dart` — порты чистых функций из
  `mdokon_cashbox/src/helpers/*.js`, тесты в `test/` — порты соответствующих JS-тестов.
  Меняя формулу здесь, сверить с JS-эталоном (и наоборот).
- **Лог** — `core/utils/logger.dart` (`appLog`): JSONL-файл на сутки в папке приложения, те же
  правила, что на десктопе (события `домен.действие`, ПД через `logTail`, `debug` только при
  «Расширенном логе»). Не использовать `print` для диагностики продажи.
- **«Что нового»** — `core/utils/changelog.dart`, формат как у десктопного `changelog.js`
  (ключи `ru`, `uz-Latn`, `uz-Cyrl`), новые версии в начало, `date: null` пока не вышло в маркет.

## Конвенции

- Отступы 2 пробела, форматтер с `trailing_commas: preserve`; импорты пакета —
  `package:flutter_mdokon/...`.
- UI — только через кит `shared/widgets/ui/ui.dart` (`AppButton`, `AppInput`, `AppModal`,
  `AppSurface`, `AppColors`, `AppTypography`) и брейкпоинты `core/theme/responsive.dart`
  (<600 телефон, 600–1023 планшет-портрет, ≥1024 планшет-альбом; макет под 390×844).
  Цвета — `AppColors.*`, не хардкод: тема переключается в рантайме.
- Новый экран кассира: виджет в `features/cashier/pages/...` → `GoRoute` в
  `app/router/cashier_routes.dart` → ключи в оба файла `assets/i18n/`.
- Работа над редизайном и переносом функций идёт по чеклисту `docs/redesign-plan.md`
  (этапы с `[ ]`/`[x]`); на «продолжи» — читать его и брать первый незакрытый пункт.

## Подводные камни

- **Не переносить с десктопа**: UzQR, ОФД-консоль, проверку ИКПУ (`fiscalIkpu`), «Ручные товары»,
  настройки моноблока/дисплея покупателя — к телефону не подключается фискальный модуль.
  Лояльность Tirox не подключать — не работает. Click Pass / Payme / Uzum и маркировку
  (`/services/desktop/api/marking-check`) переносить можно.
- `put()` в `api.dart`, в отличие от остальных, не вызывает `checkToken()`.
- Часть текстов тостов в `statuscheker` — русские фразы как ключи `tr(...)`.
- Демо-вход (логин `2`) — это `ROLE_CASHIER`. Чтобы посмотреть экраны агента на эмуляторе,
  подменить `"role"` на `ROLE_AGENT` в `app_flutter/GetStorage.gs` приложения через
  `adb shell run-as` (после переименования пакета — `com.mdokon.cabinet`, раньше было
  `com.example.flutter_mdokon`) и вернуть обратно, удалив `saleSession`.
- В рабочей копии `pubspec.yaml` русские комментарии превратились в кракозябры (файл
  пересохранён не в UTF-8). Редактировать yaml/dart только в UTF-8 без перекодировки; в
  PowerShell — с `-Encoding utf8`.
- Remote — GitHub (`AkhmedovSH/flutter_mdokon_cashier`), ветка `master`, а не GitLab, как у
  остальных проектов mDokon.
