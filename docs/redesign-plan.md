# План редизайна и переноса функций mDokon POS (mobile)

Живой документ. Отмечайте `[x]` по мере выполнения — по нему можно продолжить
работу в новой сессии командой «продолжи по docs/redesign-plan.md».

- **Мобильный проект:** `C:\Users\Victus\Desktop\projects\flutter\flutter_mdokon_cashier`
- **Desktop-эталон (React/Electron):** `C:\Users\Victus\Desktop\projects\react\mdokon_cashbox`
- Составлен: 2026-08-25

---

## Границы: что НЕ переносим и почему

Решено окончательно, к обсуждению не возвращаемся.

| Что | Причина |
|---|---|
| **UzQR целиком** | `createInvoice()` требует `fiscal_module` — TerminalID ровно 14 знаков (`src/api/apiUzqr.js:38-52`). Фискальный накопитель физически не подключается к телефону. Сюда же: `UzqrPaymentScreen`, `UzqrReconciliationModal`, `uzqrPolling`, `uzqrErrors`, `uzqrDisplay`, `uzqrCompletePayment` |
| **ОФД-консоль** | `src/components/ofd/`, `apiOfd.js` — прямые команды накопителю (`Api.OpenZReport`, `Api.GetFiscalMemoryInfo`) |
| **`fiscalIkpu.js`** | Проверка ИКПУ нужна только перед собственной фискализацией. Мобилка чек не фискализирует: в `cashbox_model`, `sale_model`, `sale_repository` нет ни одного ofd/fiscal. Поле `fiscal` в `cheques.dart:71` — только фильтр по серверному флагу |
| **Ручные товары (`ManualProducts`)** | Контур ОФД-продажи |
| **Лояльность Tirox** | Не работает |
| **Настройки** `partialFiscalization`, `printOfdInfo`, `uzqrDisplayMode`, `uzqrDisplayIndex`, `isVfdDisplay`, `customerDisplay*`, `isMonoblock` | Следом за ОФД / привязаны к железу моноблока. `isMonoblock` не нужен: его роль уже играет `AppLayout.textScale` / `tapTarget` |
| **Ценники (`priceTags`)** | Нужен принтер этикеток. Отложено, не отменено |

**Проверено, что накопитель НЕ нужен** (поэтому переносим):

- **Click Pass / Payme / Uzum** — прямые HTTP к `api.click.uz`, `checkout.paycom.uz`,
  `mobile.apelsin.uz`. Ни в одном нет `fiscal_module`, нужен только
  `merchant_secret_key` точки + SHA1-подпись. Click Pass на телефоне даже уместнее:
  в payload идёт `otp_data` — код, который кассир сканирует **с телефона покупателя**
  (`Tab.js:3167-3206`), а камера уже есть.
- **Маркировка** — `POST /services/desktop/api/marking-check` через свой бэкенд
  (`src/api/apiMarking.js`). Нужна только камера.
- **Движки** discount / promotion / manualDiscount / debtLimit / smsQuota — чистые
  функции без сети и Electron.

---

## Контекст: адаптив

В работе система брейкпоинтов `lib/core/theme/responsive.dart`:
`compact <600` (телефон) → `medium 600-1023` → `expanded 1024-1279` →
`large ≥1280` (моноблок кассы). Плюс `SideRailLayout`, `MasterDetailLayout`,
`ContentBox` в `lib/shared/widgets/ui/app_responsive.dart` и `CashierTopBar`.

Из-за верхней ступени часть десктопных паттернов возвращается в игру — они
вынесены в **этап 7** и на телефоне не показываются.

---

## Этап 0 — тема (блокер для всего дизайна)

**Проблема.** `AppColors` — `static const` светлые значения, 672 обращения в
39 файлах против 66 `Theme.of(context)`. Переключатель тёмной темы в
`settings.dart:293` тему ставит, но экраны остаются белыми. Плюс
`app.dart:41` задаёт `themeMode: ThemeMode.system` вообще без `darkTheme:`.

**Решение — переключаемая палитра** (выбрано пользователем). `AppColors.surface`
остаётся тем же именем, но становится геттером активной палитры. 600 обращений
не трогаем; правим только `const`-места.

- [x] `AppPalette` — класс палитры со всеми токенами; экземпляры `light` и `dark`.
      Тёмная подобрана под контраст ≥4.5:1, акцент осветлён #5B60E8 → #8B90F5
      (исходный на тёмной поверхности давал 2.4:1), `onPrimary` там тёмный
- [x] `AppColors` — статические геттеры поверх активной палитры + `AppColors.use(bool dark)`
- [x] Снять `const` — оказалось 137 мест, а не 69: анализатор ловит и те, где
      `const` стоял на внешнем виджете строкой выше
- [x] `AppText` — стили переведены на геттеры
- [x] `themes.dart` — одна функция `buildAppTheme(AppPalette)` вместо двух
      расходящихся копий; `DarkThemeColors`/`LightThemeColors` удалены.
      Тёмная тема получила недостающие `appBarTheme`, `cardTheme`, `chipTheme`,
      `switchTheme`, `dataTableTheme`, `bottomNavigationBarTheme`
- [x] `app.dart` — передан `darkTheme:`, `themeMode` берётся из `ThemeModel`
      (было `ThemeMode.system` вообще без `darkTheme`)
- [x] `ThemeModel` — хранит флаг, дёргает `AppColors.use()` до `notifyListeners()`
- [x] Выпилен legacy `CustomTheme` — 63 обращения в 19 файлах
- [x] `test/theme_test.dart` — 16 тестов: переключение палитры, полнота обеих
      тем, контраст WCAG AA для всех семантических пар
- [ ] Проверить оба режима живьём: продажа, каталог, оплата, чеки, профиль

---

## Этап 1 — доделать адаптив по существующему шаблону

Оплата уже переведена (окно по центру на планшете). Дальше тем же приёмом.

- [x] Каталог — постоянная колонка чека (`layout.hasCartRail`)
- [x] Чеки — список + карточка (`layout.hasMasterDetail`)
- [x] Возврат — то же
- [x] Профиль, X-отчёт, остатки, быстрый выбор — `ContentBox`
- [x] Настройки — две колонки на широком экране: при `hasMasterDetail` чипы
      разделов уходят из шапки в колонку слева (`_sectionRail`), справа список
- [x] Логин и выбор кассы

---

## Этап 2 — движки расчёта (чистые функции + тесты)

Порядок важен: `promotionEngine` импортирует `unitPrice`/`matchesTarget` из
`discountEngine`. На десктопе к каждому есть тесты в `src/helpers/__tests__/` —
переносить вместе с логикой.

- [x] `discountEngine.js` (537 строк) → `lib/features/cashier/domain/discount_engine.dart`
- [x] `promotionEngine.js` (312) → `promotion_engine.dart`.
      Механики: `GIFT_N_M`, `BOGO`, `EVERY_NTH_FREE`, `GIFT_ON_AMOUNT`, `GIFT_ON_CATEGORY`
- [x] `manualDiscount.js` → `manual_discount.dart` + 13 тестов. Чистая функция
      готова: чек хранит параметры (F5 процент / F6 сумма / F7 сумма на позицию),
      суммы раскидываются по позициям и пересчитываются после каждого изменения корзины
- [ ] **Встроить `manual_discount.dart` в `SaleModel`** (тот самый баг с «поехавшим»
      процентом) — не сделано осознанно. `_applyDiscount` (sale_model.dart:410) не просто
      хранит абсолютную сумму: он пишет в `data['totalPrice']` НЕТТО (сумма минус скидка),
      тогда как `printer_model.dart:191`, `cheques.dart:112` и `return.dart:684` считают
      `totalPrice − discountAmount`, то есть ждут БРУТТО, как на десктопе. Перед правкой
      нужно зафиксировать формат по `Tab.js` / cheque-v2 и проверить на живом чеке —
      иначе легко получить двойное вычитание скидки в печати и в возврате.
      Заодно снимается блокировка «Применена скидка» (catalog.dart:148, home.dart:66)
- [x] `debtLimit.js` (192) → `debt_limit.dart`. Локальная проверка кредитного лимита
      **до** пробития чека (сервер отвечает `error.client.debt.limit`, но чек уже напечатан)
- [x] `smsQuota.js` (94) → `sms_quota.dart` — текст остаётся за UI: движок отдаёт
      ключ перевода и подстановки (`smsQuotaMessage`), а не готовую строку
- [x] Юнит-тесты портированы вместе с логикой: `discount_engine_test.dart` (50),
      `promotion_engine_test.dart` (51), `debt_limit_test.dart` + `sms_quota_test.dart` (62),
      `manual_discount_test.dart` (13)

---

## Этап 3 — маркировка («Asl Belgisi»)

Если среди точек есть табак или маркированные товары — двигать вперёд этапа 2:
без этого продажа такого товара нелегальна.

- [x] `marking.js` (92) → `lib/features/cashier/domain/marking.dart`: GS1 + табачный
      формат, нормализация префикса сканера (AIM ID), разделитель GS. Тесты
      портированы (`test/marking_test.dart`, 20 штук вместе с проверкой ответа)
- [x] `apiMarking.js` → `lib/features/cashier/data/marking_repository.dart`:
      `marking-check` с мягкой деградацией — недоступный сервер, отсутствующий
      эндпоинт и пустой ответ дают `MarkingStatus.unknown`, продажа не блокируется
- [ ] Сканирование кода камерой в потоке продажи — сделана точка входа:
      `scanned_input.dart` (код маркировки → варианты GTIN для поиска товара) и
      свой экран сканера `shared/widgets/scanner/barcode_scanner_page.dart` на
      `mobile_scanner` (DataMatrix + линейные форматы, фонарик, автозум,
      разрешение и ошибка камеры с путём в настройки). `simple_barcode_scanner`
      выпилен: он умел только линейные коды. Поиск в `catalog.dart` и
      `home/search.dart` перебирает варианты GTIN.
      Осталось: вызов `MarkingRepository.check` при добавлении позиции и показ
      предупреждения кассиру
- [ ] Сборка одинаковых кодов в одну позицию, `+`/`−` открывают список кодов
- [ ] Возврат по коду маркировки
- [x] Ключи переводов: `marking_not_registered`, `marking_withdrawn`, `marking_not_checked`
      — в `ru.json` и `uz-Latn.json`

---

## Этап 4 — онлайн-оплата (без UzQR)

- [ ] Click Pass — SHA1-подпись через пакет `crypto`, сканирование `otp_data`
      с телефона покупателя камерой
- [ ] Payme
- [ ] Uzum (Apelsin)
- [ ] Оплата во вкладках «В долг» и «Лояльность», а не только в «Оплате»
      (на десктопе это сделано в 2.3.0)
- [ ] Абонплата картой из кассы (Multicard/Rahmat)

---

## Этап 5 — отложенные чеки

- [ ] Отложить чек online / offline (настройки `postponeOnline` / `postponeOffline`,
      взаимоисключающие)
- [ ] Открыть отложенный чек
- [ ] Чек из облака
- [ ] Взаиморасчёт с поставщиками

---

## Этап 6 — настройки

Сейчас 7 пунктов в 3 секциях (`settings.dart:97-155`) против ~40 в 5 секциях у
десктопа (`src/components/settings/settingsSections.js`). Заодно дотянуть `_Item`
до десктопной декларативной схемы: `type: toggle|select|number|range|printer`,
`showWhen`, `exclusive`, `disabled`.

- [ ] Касса: `showConfirmModalDeleteItem`, `showConfirmModalDeleteAllItems`,
      `showLastScannedProduct`, `productGrouping`, `showProductOutOfStock`,
      `searchExact`, `advancedSearchMode`, `amountExceedsLimit`, `accountingBalance`
- [ ] Весы: `barcodeFormat` (формат 6/7), `weightPrefix`, `piecePrefix`, `finalPrefix`
- [ ] Печать: `chequeCopy`, `showBarcode`, `showQrCode`, `printReturnCheque`,
      `print2cheques`, `printerBroken`
- [ ] Отложенные: `postponeOnline` / `postponeOffline`

---

## Этап 7 — только планшет и моноблок

Показывать при `layout.isTablet` / `hasSideRail`, на телефоне не рисовать.

- [ ] Мультивкладки чеков (`src/helpers/cashboxSession.js`) — несколько
      параллельных продаж
- [ ] Горячие клавиши: `2+` количество, `2000*` цена, `5000-` сумма, `/` упаковка,
      F5/F6/F7 скидки, F9 очистить
- [ ] Панель-подсказка горячих клавиш (`HotkeysPanel.js`)
- [ ] Боковая колонка быстрого выбора: список / витрина / категории / клавиатура
      (`Rightbar.js`)
- [ ] Лояльность UDS и Uget (Tirox — нет)

---

## Мелочи (дёшево, в любой момент)

- [ ] Экран «Что нового» из `src/data/changelog.js` — `in_app_update` уже подключён
- [ ] Логи приложения на устройстве (`src/helpers/logger.js`, 14 дней)
- [ ] Третий язык `uz-Cyrl` — сейчас 2 языка и 686 ключей против 3 и 780 у десктопа

---

## Технический долг, замеченный попутно

- `SaleModel._applyDiscount` — абсолютная сумма вместо параметров скидки (чинится в этапе 2)
- ~~`test/widget_test.dart` — стоковый шаблонный тест Flutter про счётчик~~ удалён,
  `flutter test` зелёный целиком (224 теста) и годится как ворота для этапов 2–3
- Крупные файлы, ещё не прошедшие редизайн: `cheques.dart` (1086),
  `return.dart` (968), `settings.dart` (862), `balance.dart` (729),
  `quick_selection.dart` (720), `x_report.dart` (719), `profile.dart` (627)
