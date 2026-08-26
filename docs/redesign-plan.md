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
- [x] **Встроить `manual_discount.dart` в `SaleModel`** — тот самый баг с «поехавшим»
      процентом закрыт. Формат зафиксирован по `cashbox_model.dart:466`: на сервер
      (`cheque-v2`) чек уходит в БРУТТО со скидкой отдельной суммой, поэтому
      `cheques.dart:112` и `return.dart:684` были правы. Локально же во время
      продажи `totalPrice` остаётся НЕТТО — на этом построен весь поток оплаты.
      Сделано:
      - `_applyDiscount` больше не пишет абсолютные суммы: чек хранит параметры
        (`manualDiscountKey` = f5/f6 + `manualDiscountValue`, у позиции
        `fixedDiscount` для F7), а суммы раскидывает `manualDiscountAmounts()`
      - единый `_recalculate()` вместо трёх расходившихся пересчётов
        (`_recalculateFromPriceMode`, `_recalculate`, `_recalculateTotalsOnly`) —
        скидка переживает смену количества, цены и состава корзины
      - `domain/cheque_format.dart` → `toGrossCheque()`: одна точка перевода
        НЕТТО → БРУТТО. Ею пользуются и отправка на `cheque-v2`, и печать.
        Двойное вычитание скидки при печати (`payment_sample.dart` передавал в
        `printFullCheque` локальный НЕТТО-чек, а тот вычитал `discountAmount`
        второй раз) устранено
      - снята блокировка «Применена скидка» (`home/home.dart`) — со скидкой
        теперь можно открывать каталог и добавлять позиции
      - `test/cheque_format_test.dart` (6 тестов), всего 230 зелёных
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
- [x] Сканирование кода камерой в потоке продажи:
      `scanned_input.dart` (код маркировки → варианты GTIN для поиска товара) и
      свой экран сканера `shared/widgets/scanner/barcode_scanner_page.dart` на
      `mobile_scanner` (DataMatrix + линейные форматы, фонарик, автозум,
      разрешение и ошибка камеры с путём в настройки). `simple_barcode_scanner`
      выпилен: он умел только линейные коды. Поиск в `catalog.dart` и
      `home/search.dart` перебирает варианты GTIN.
- [x] Проверка кода при сканировании и предупреждение кассиру:
      `domain/marking_warning.dart` (`markingWarningLevel`: ok → молчим,
      unknown → жёлтый тост «не проверен», notRegistered/withdrawn → красный) и
      `pages/dashboard/marking_scan.dart` → `checkScannedMarking()`. Вызывается из
      сканера каталога (`catalog.dart`) и поиска (`home/search.dart`) сразу после
      разбора: обычный штрих-код на сервер не уходит вовсе, продажа не блокируется
      ни при каком статусе (касса обязана работать офлайн). Тестов 233 зелёных
- [x] Сборка одинаковых кодов в одну позицию, `+`/`−` открывают список кодов:
      `domain/marking_item.dart` — коды позиции (`markingNumbers`, полный код;
      старое поле `markingNumber` читается для совместимости), количество ВСЕГДА
      равно числу кодов, повторный код отбивается (`marking_already_scanned`),
      остаток проверяется, если не разрешён `saleMinus`. В `SaleModel`:
      `addScannedProducts` кладёт код в существующую строку товара
      (`markingLineIndex`), `addMarkingCodeToLine` / `removeMarkingCodeFromLine`,
      а `setQuantity` на маркировочной позиции отбивается — количество только
      кодами. UI: у такой строки степпер меняет смысл — `+` сразу открывает
      сканер, `−` показывает лист кодов с удалением поштучно
      (`home/widgets/marking_codes_sheet.dart`). Код от сканера каталога
      привязывается к добавляемому товару (`_pendingMarking` в `catalog.dart`).
      Тесты: `test/marking_item_test.dart` (21), всего 254 зелёных.
      Хвост с `home/search.dart` закрыт удалением: экран не был подключён ни к
      роутеру, ни к дашборду, его роль давно играет `catalog.dart`. Заодно ушёл
      мёртвый буфер `DataModel.productList` / `setProductList` / `currentProductList`
      — единственный писатель был там, читателей не было
- [x] Возврат по коду маркировки: `domain/return_marking.dart` — код должен быть
      в этом чеке (`marking_not_found`), повторно не берётся, больше остатка по
      позиции не отметить (`marking_return_limit`); частично возвращённая позиция
      отдаёт первые `limit` кодов — какие пачки ушли в прошлый возврат, сервер не
      сообщает. UI: `pages/dashboard/widgets/return_marking_sheet.dart` —
      сканирование принесённой пачки или отметка кода в списке (нужно, когда код
      затёрт и камера его не берёт). В `return.dart` у маркировочной строки
      степпер меняет смысл: `+` открывает сканер, `−` — список отмеченных кодов,
      `_setQty` отбивается; «вернуть всё» отмечает все доступные коды; в payload
      уходят `markingNumbers` / `availableMarkingNumbers`, как у десктопа.
      Тесты: `test/return_marking_test.dart` (13), всего 267 зелёных
- [x] Ключи переводов: `marking_not_registered`, `marking_withdrawn`, `marking_not_checked`
      — в `ru.json` и `uz-Latn.json`

---

## Этап 4 — онлайн-оплата (без UzQR)

- [x] Click Pass — SHA1-подпись через пакет `crypto`, сканирование `otp_data`
      с телефона покупателя камерой
- [x] Payme
- [x] Uzum (Apelsin)
- [x] Оплата во вкладках «В долг» и «Лояльность», а не только в «Оплате»
      (на десктопе это сделано в 2.3.0)
- [x] Абонплата картой из кассы (Multicard/Rahmat)

Сделано:

- `domain/online_payment.dart` — общий для трёх провайдеров чистый слой:
  выбор онлайн-способа из `paymentTypes` (`paymentTypeId` 5/6/7), подпись
  `id:sha1(timestamp + secret):timestamp`, payload'ы и разбор ответов.
  Важная деталь, легко ломающаяся: `timestamp` — **миллисекунды**
  (`getTime()` из date-fns в `electron.js:178`), не unix-секунды. Click
  подписывается `merchant_service_user_id`, Uzum — `merchant_id`, Payme
  подписи не использует вовсе (пара `merchant_id:secret`). Суммы: Click — в
  сумах, Uzum и Payme — в тийинах
- `data/online_payment_repository.dart` — прямые запросы к `api.click.uz`,
  `checkout.paycom.uz`, `mobile.apelsin.uz` мимо `core/network/api.dart`:
  это чужие хосты со своей авторизацией, токен кабинета туда слать нельзя.
  Мягкой деградации, в отличие от маркировки, нет: не прошла оплата — чек не
  пробивается. Payme — два шага (`receipts.create` → `receipts.pay`)
- `CashboxModel._payOnline()` вызывается **до** `cheque-v2`; реквизиты
  платежа (`clickPaymentId` / `paymePaymentId` / `uzumPaymentId`, телефон
  покупателя, `QRPaymentProvider = 161`) уходят на сервер вместе с чеком
- `OtpCodeField` в `payment_widgets.dart` показывается на **любой** вкладке
  оплаты, как только в чек внесена сумма онлайн-способом: код с телефона
  покупателя сканируется камерой (`BarcodeScannerPage`) или вводится руками
- Абонплата: `domain/subscription_payment.dart` +
  `data/subscription_payment_repository.dart` +
  `pages/payment/subscription_payment_sheet.dart`, вход — строка в профиле.
  Поток `/points → /invoice → shortLink во внешнем браузере → опрос
  /status/{id}` каждые 5 с, не дольше 15 минут. Оплату подтверждает только
  callback Multicard на сервере, поэтому единственный источник правды —
  статус счёта, а не возврат из браузера
- Тесты: `test/online_payment_test.dart` (24), `test/subscription_payment_test.dart` (13),
  всего 304 зелёных. Ключи переводов `otp_code*`, `online_payment_*`,
  `subscription_pay_*` — в `ru.json` и `uz-Latn.json`

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

- ~~`SaleModel._applyDiscount` — абсолютная сумма вместо параметров скидки~~ починено в этапе 2
- ~~`test/widget_test.dart` — стоковый шаблонный тест Flutter про счётчик~~ удалён,
  `flutter test` зелёный целиком (224 теста) и годится как ворота для этапов 2–3
- Крупные файлы, ещё не прошедшие редизайн: `cheques.dart` (1086),
  `return.dart` (968), `settings.dart` (862), `balance.dart` (729),
  `quick_selection.dart` (720), `x_report.dart` (719), `profile.dart` (627)
- ~~`home/search.dart` — экран-дубль каталога, ни на что не подключённый~~ удалён
  в этапе 3 вместе с буфером `DataModel.productList`
