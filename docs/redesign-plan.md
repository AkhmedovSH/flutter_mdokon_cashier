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
| **Настройки** `partialFiscalization`, `printOfdInfo`, `uzqrDisplayMode`, `uzqrDisplayIndex`, `isVfdDisplay`, `customerDisplay*`, `isMonoblock` | Следом за ОФД / привязаны к железу моноблока. `isMonoblock` не нужен: моноблок не поддерживаем, только телефон и планшет |
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
`compact <600` (телефон) → `medium 600-1023` → `expanded ≥1024` (планшет
в альбоме). Плюс `SideRailLayout`, `MasterDetailLayout`, `ContentBox`
в `lib/shared/widgets/ui/app_responsive.dart` и `CashierTopBar`.

Цель — только телефоны и планшеты; моноблочной ступени в проекте нет.
Часть десктопных паттернов всё же работает на планшете — они вынесены
в **этап 7** и на телефоне не показываются.

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
- [x] Правки по первому живому прогону тёмной темы:
      - **тост** — текст брал `onPrimary`, а он в тёмной палитре тёмный: тёмный
        текст на тёмной плашке. Теперь цвет считается от самой плашки
        (`toastForeground`), одинаково для нейтрального, danger и warning
      - **чёрный заголовок AppBar** — `buildAppTheme(palette)` брал цвета текста
        из `AppText`, то есть из *активной* палитры, а `MaterialApp` собирает
        light и dark за один проход. Цвет теперь переопределяется явно из
        переданной палитры. Плюс `CustomAppBar` имел дефолтный
        `const TextStyle` без цвета
      - **системные панели** — `appBarTheme.systemOverlayStyle` +
        `SystemChrome` при старте и смене темы: статус-бар и панель навигации
        больше не остаются от прежней темы
      - **тема применялась только после перехода** — экраны читают статический
        `AppColors`, а не `Theme.of(context)`, поэтому смена темы их не
        перестраивала. `MaterialApp.builder` оборачивает дерево в `KeyedSubtree`
        с ключом по теме — всё перерисовывается сразу
- [x] Правки по второму прогону:
      - **фирменные заливки** — шапка продажи, блок «К оплате», экраны входа
        красились в `primary`, а он в тёмной палитре осветлён до #8B90F5 под
        контраст мелких элементов: полэкрана становилось светлым пятном.
        Заведён токен `brandSurface` / `onBrandSurface` (dark #3A3F8F, белый
        текст, 9:1) — он остаётся тёмным в обеих темах
      - **статус-бар** — семь экранов задавали `AnnotatedRegion` с прибитым
        `Brightness.dark`, то есть иконки всегда под светлую тему. Все
        переведены на `systemOverlayStyleFor(AppColors.palette)`
      - **чёрный трей** — в `styles.xml` стоял
        `windowDrawsSystemBarBackgrounds=false`: панели заливал сам Android
        своим чёрным, а `statusBarColor` из Flutter не действовал. Включено
        рисование под панелями + `SystemUiMode.edgeToEdge`; область за
        статус-баром красят шапки экранов, они уже в `SafeArea`
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

- [x] Отложить чек online / offline (настройки `postponeOnline` / `postponeOffline`,
      взаимоисключающие)
- [x] Открыть отложенный чек
- [x] Чек из облака
- [x] Взаиморасчёт с поставщиками

Сделано:

- `domain/postponed_cheque.dart` — чистый слой на три источника с одним
  форматом: офлайн (`GetStorage.chequeList`), онлайн
  (`cheque-online-cashbox`) и облако (`cheque-online-list` — чеки агентов).
  Отличается только облако: клиент, организация и агент лежат не внутри
  чека, а рядом с ним, в строке списка, и при восстановлении перебивают то,
  что было в чеке
- Восстановление (`restorePostponed`) — не «взять чек как есть»: чек мог
  пролежать сутки, его набирали на другой кассе, другим кассиром и в другой
  смене. Номер, время, транзакция, `paid`, `paymentTypes` выбрасываются
  (`_volatileKeys`) и выдаются заново при пробитии; касса, точка, смена,
  кассир и валюта проставляются текущие. Копия глубокая: правки корзины не
  должны менять чек, оставшийся в списке (коды маркировки — вложенный список,
  копии верхнего уровня мало)
- **`chequeOnlineId` ставится только серверному чеку.** Он уходит в `cheque-v2`
  и закрывает исходную строку в облаке; у офлайнового чека его быть не должно —
  иначе продажа удалила бы чужой чек агента. Офлайновый вместо этого уходит из
  `GetStorage` в момент открытия: второго места, где он мог бы закрыться, нет
- Валюта: чек в другой валюте не открывается (`currencyMatches`) — суммы позиций
  посчитаны в валюте набора, пересчитать их касса не может. Валюта не
  проставлена вовсе (старые офлайновые чеки) — чек пропускаем
- `data/postponed_cheque_repository.dart` — два похожих эндпоинта, которые легко
  перепутать: `cheque-online-list-cashbox/{posId}` отдаёт чеки, отложенные
  кассами точки, `cheque-online-list/{posId}` — присланные агентами. Удаляются
  оба через `cheque-online-cashbox/{id}`
- UI: «Отложить чек» — в меню чека (только на непустом чеке и только если
  настройка выбрана), «Открыть отложенный», «Чек из облака» и «Взаиморасчёт с
  поставщиками» — в меню кассы. Список чеков одним листом на все три источника,
  подзаголовок говорит, где чек лежит
- **Отступление от десктопа:** открытие отложенного чека поверх набранной
  корзины спрашивает подтверждение. Десктоп заменяет корзину молча, и набранный
  чек пропадает без следа
- `data/supplier_debt_repository.dart` + лист выдачи: долг поставщику только
  гасится (`amountOut`), увеличить его из кассы нельзя. Отказ приходит с кодом
  200 и `success: false` — сообщение сервера показываем кассиру. Выделение
  строки держим на самом поставщике, а не на индексе: после фильтра поиска
  индексы разъезжаются, и кассир выдал бы деньги не тому
- Тесты: `test/postponed_cheque_test.dart` (26), всего 361 зелёный. Ключи
  переводов `postpone_cheque`, `open_postponed_cheque`, `open_cheque`,
  `cheque_postponed`, `cheque_from_cloud*`, `settlement_with_suppliers`,
  `supplier_payment_text`, `give_out`, `different_currencies` — в `ru.json`
  и `uz-Latn.json`

Не проверено живьём: ответы `cheque-online-list-cashbox` и
`organization-debt-list` разбираются по десктопному коду, на реальных данных
поток не прогонялся.

---

## Этап 6 — настройки

Было 7 пунктов в 3 секциях против ~40 в 5 у десктопа. Стало 24 пункта в 5
разделах: общие, касса, весы, печать, отложенные.

- [x] **`SettingsModel` переписан на карту.** Было поле + геттер + ветка
      `switch` на каждый ключ — три правки на настройку и молчаливая потеря
      значения, если про ветку забыли (так и жили `showChequeProducts`,
      `searchGroupProducts`, `selectUserAftersale`, `offlineDeferment`,
      `additionalInfo`, `language` — ни одного читателя в коде). Теперь
      источник правды один — `SettingsModel.defaults`; добавить настройку =
      дописать строку. Оттуда же берёт дефолты `auth_model.ensureDefaultSettings`
      (свой список успел разойтись). Заодно починен `_persist`: `settings[key] = value`
      падал, если карты `settings` в хранилище ещё нет, и печатал всё в консоль
- [x] **Декларативная схема `_Item`** дотянута до десктопной:
      `control: toggle|select|stepper|number|theme|printer`, `showWhen`
      (право кассира), `disabled` (значение ни на что не влияет),
      `exclusive` (парная настройка гасится при включении).
      `showWhen` прячет подтверждения удаления от кассира без
      `CASHBOX_DELETE_SCAN_ITEM`; `disabled` гасит раздел печати при
      «принтер сломан» — пункт видно, но он выключен, а не молча бездействует
- [x] Касса: `showConfirmModalDeleteItem`, `showConfirmModalDeleteAllItems`,
      `showLastScannedProduct`, `productGrouping`, `showProductOutOfStock`,
      `searchExact`, `amountExceedsLimit`, `accountingBalance`
- [x] Весы: `barcodeFormat` (формат 6/7), `weightPrefix`, `piecePrefix`, `finalPrefix`
- [x] Печать: `showBarcode`, `showQrCode`, `printReturnCheque`,
      `print2cheques`, `printerBroken`
- [x] Отложенные: `postponeOnline` / `postponeOffline` (взаимоисключающие).
      Сами настройки готовы; поведение — этап 5

Что настройки делают (переключатель без проводки — это не настройка):

- `showConfirmModalDeleteItem` — свайп по позиции спрашивает подтверждение
  (`home/home.dart`, `confirmDismiss` у `DismissiblePane` и кнопка корзины)
- `showConfirmModalDeleteAllItems` — тот же вопрос при очистке чека; раньше он
  был безусловным
- `showLastScannedProduct` — строка над чеком с последней позицией: кассир
  смотрит на сканер, а не на экран
- `productGrouping` / `searchExact` → `domain/product_search.dart`. На десктопе
  оба параметра уходят в локальную базу (`findProducts`), у мобилки базы нет —
  применяются к ответу сервера. Группировка сводит партии одного товара в
  строку с суммарным остатком, ведущей берёт партию с бо́льшим остатком.
  Точный поиск при отсутствии полного совпадения возвращает список как есть:
  пустой экран вместо похожих товаров кассиру не помогает
- `showProductOutOfStock` — окно вместо тоста, когда отсканированный товар не
  нашёлся. Только для сканирования: при наборе руками пустой список — это ещё
  не дописанное слово
- `barcodeFormat` / `weightPrefix` / `piecePrefix` → `domain/scale_barcode.dart`,
  порт `Tab.js:665-750`. Штрих-код весов в базе не лежит: ищем код товара из
  его середины, вес (граммы → кг) подставляем вместо «одной штуки» при
  добавлении. Штучный товар (`uomId == 1`) округляется вниз, нулевой вес даёт
  единицу — иначе сканирование выглядит как несработавшее
- `accountingBalance` — предупреждение при отрицательном учётном остатке;
  продажу не блокирует, как и на десктопе
- `amountExceedsLimit` — чек дороже 99 999 999 не пробивается, пока настройка
  выключена (`payment_sample.dart`, до `createCheque`)
- `printerBroken` — глушит всю печать: чек пробивается, бумага не тратится
- `print2cheques` — `printFullCheque` шлёт байты дважды
- `showBarcode` / `showQrCode` — Code128 номера чека и QR со ссылкой.
  QR печатаем только при непустом `qrcodeURL`: рисовать его из номера чека
  бессмысленно, сканировать будет нечего
- `printReturnCheque` — `printReturnReceipt()`: возврат раньше не печатался
  вовсе. Отдельный метод, а не флаг у `printFullCheque`: у возврата нет оплат
  и скидки, зато обязательна крупная шапка — по ней возвратный чек отличают от
  продажного в одной пачке
- `finalPrefix` — хранится, но ни на что не влияет: на десктопе он тоже
  объявлен в настройках и нигде не читается

Не переносим (в дополнение к разделу «Границы»):

| Что | Причина |
|---|---|
| `advancedSearchMode`, `selectBottomSearch`, `leaveBottomSearchText` | Про фокус между двумя полями поиска на десктопе. У мобилки поле одно |
| `chequeCopy`, `chequeCopyExcel` | Повторная печать чека на мобилке и так есть в карточке чека и правом не ограничена; Excel — десктопный `printTo` |
| `printTo`, `openExcelFile`, `chequeLogoSize` | Печать в Excel/A4/PDF и логотип из файла — Electron |
| `humoTerminal` | Терминал по COM-порту |
| `autoSync`, `xReport`, `showFastPayButtons`, `showNumberOfProducts`, `showFullProductName`, `showCashPaymentF1/F2` | Части десктопного экрана продажи, которых на мобилке нет |

- [x] Тесты: `test/scale_barcode_test.dart` (13), `test/product_search_test.dart` (10),
      всего 331 зелёный. Ключи переводов — в `ru.json` и `uz-Latn.json`

## Этап 7 — только планшет

Показывать при `layout.isTablet` / `hasSideRail`, на телефоне не рисовать.

- [x] Мультивкладки чеков (`src/helpers/cashboxSession.js`) — несколько
      параллельных продаж. `domain/sale_tabs.dart` — чистый слой: до
      `maxSaleTabs` = 5 вкладок (десктоп даёт добавить, пока их не больше
      четырёх), при закрытии активной становится соседняя справа, а у
      последней в списке — слева (`Cashbox.js:91-120`).
      - **Вкладки живут в памяти, а не в `GetStorage`.** Десктоп держит их в
        `sessionStorage`: переживают F5 и уход с роутера кассы, исчезают с
        закрытием окна. `GetStorage` пережил бы и перезапуск приложения, а чек
        недельной давности поверх новой смены — это чужие суммы в корзине
      - Снимок чека глубокий (`deepCopyCheque`): позиции и коды маркировки
        лежат вложенными списками, копии верхнего уровня мало — правка корзины
        в одной вкладке меняла бы чек в соседней
      - `id` вкладки — максимум + 1, а не длина списка: после закрытия средней
        длина повторила бы занятый id и переключение попало бы не туда.
        В подписи при этом порядковый номер (`saleTabPosition`), иначе кассир
        видел бы «1 2 4 5»
      - В `SaleModel` — `addTab` / `switchTab` / `closeTab` и `_syncActiveTab()`
        в трёх местах, где `data` подменяется целиком (`init`, `clearCheque`,
        восстановление отложенного): иначе вкладка держала бы ссылку на карту,
        которой в модели больше нет
      - UI: `home/widgets/sale_tabs_bar.dart`, рисуется только при
        `layout.isTablet`. Закрытие непустой вкладки спрашивает подтверждение
        **всегда**, мимо настройки `showConfirmModalDeleteAllItems`: в отличие
        от отложенного, вкладку никуда не сохранить
      - Тесты: `test/sale_tabs_test.dart` (12), всего 373 зелёных.
        Ключ перевода `new_cheque` — в `ru.json` и `uz-Latn.json`
- [x] Горячие клавиши: `2+` количество, `2000*` цена, `5000-` сумма, `/` упаковка,
      F5/F6/F7 скидки, F9 очистить. `domain/hotkeys.dart` — чистый слой:
      клавиша и накопленный буфер на входе, команда на выходе
      (`Tab.js:handleShortcut`).
      - Операция с пустым буфером не выполняется: `+` без числа обнулил бы
        количество позиции. Исключение — `/`: упаковке число не нужно
      - Запятая кладётся в буфер точкой (цифровой блок и сканер дают разные
        клавиши, а `customNumber` запятую не понимает), вторая точка
        игнорируется
      - У функциональных клавиш `KeyEvent.character` пустой, у цифр он
        учитывает раскладку — `_keyLabel` смотрит оба поля
      - F9 идёт через то же подтверждение, что и «Очистить» из меню
        (`showConfirmModalDeleteAllItems`)
      - `Focus` вешается только при `layout.isTablet`: на телефоне он
        перехватывал бы ввод у экранной клавиатуры
- [x] Панель-подсказка горячих клавиш (`HotkeysPanel.js`) —
      `home/widgets/hotkeys_panel.dart`, открывается из строки горячих клавиш
      над чеком. Там же видно набранное число: иначе кассир жал бы `+` вслепую.
      Ключи `hotkeys`, `hotkeys_hint`. Тесты: `test/hotkeys_test.dart` (13),
      всего 386 зелёных
- [x] Боковая колонка быстрого выбора: список / витрина / категории / клавиатура
      (`Rightbar.js`) — `home/widgets/quick_rail.dart`, фильтрация вынесена в
      `domain/quick_rail.dart`, данные — `data/quick_rail_repository.dart`.
      - Показываем при `layout.hasSideRail`: на 1024 px после чека и колонки
        итогов ширина ещё есть, на телефоне товар ищут каталогом
      - Панель по умолчанию закрыта, видна рельса из четырёх иконок; повторный
        тап по активной закрывает — как на десктопе
      - Витрины «все товары» у мобилки быть не может: локальной базы нет.
        Пустой запрос показывает сам набор карточками, ввод — поиск по
        остаткам точки тем же запросом, что и каталог
      - Группы: к категориям набора добавлена папка «Обычные» — на экране
        настроек товары без категории лежат там же, иначе до них не добраться
      - Экранная клавиатура делит буфер и разбор (`resolveHotkey`) со строкой
        горячих клавиш: набранное видно в обоих местах, раскладка одна
      - Ключи переводов `rightbar_*` взяты с десктопа слово в слово
      - Тесты: `test/quick_rail_test.dart` (15), всего 401 зелёный
- [x] Лояльность UDS (uGet уже был вкладкой «Лояльность»; Tirox — нет)
      - `domain/uds.dart` — порт `udsErrors.js`, `apiUds.js` и состояния `udsInfo`
        из `Tab.js`: разбор ответа, `UdsError` с `errorKey`, `UdsState` (устаревание
        расчёта, правила поля баллов), `calcUdsSkipLoyaltyTotal`, `udsChequeFields`
      - `data/uds_repository.dart` — `uds-calc`, `uds-find` и чек `cheque-v2` мимо
        `core/network/api.dart`: там ошибка гасится тостом, а тут нужен `errorKey`
      - Суммы к оплате касса не считает: всё из ответа `uds-calc` как есть, иначе
        сервер отобьёт чек как `error.uds.invalid_checksum`. Расчёт устарел
        (правили корзину) — кнопка «Принять» блокируется
      - Списание баллов только по QR-промокоду; по телефону поле заблокировано
      - Пересчёт после паузы в вводе баллов (600 мс) — каждое значение это
        отдельный запрос к серверу
      - Вкладка «UDS» в оплате — четвёртая, показывается при `cashbox.udsEnabled`
        (флаг прокинут в `auth_model` вместе с `udsCompanyId`)
      - Отличие от десктопа: локальной очереди чеков в мобилке нет, поэтому при
        обрыве связи чек не «докатывается» — кассиру говорим проверить список
        чеков (`uds_offline_check_cheque`), чтобы не задвоить списание баллов
      - Ключи переводов `uds_*` взяты с десктопа слово в слово
      - Тесты: `test/uds_test.dart` (22), всего 423 зелёных

---

## Мелочи (дёшево, в любой момент)

- [x] Экран «Что нового» — `lib/core/utils/changelog.dart` (формат записи повторяет
  десктопный `src/data/changelog.js`: `version` / `date` / `notes` по локалям,
  ключ `uz-Cyrl` зарезервирован заранее) + экран
  `profile/whats_new.dart`, маршрут `/cashier/profile/whats-new`.
  - Показывается сам один раз на версию: `shouldShowWhatsNew()` сверяет
    `PackageInfo.version` с `changelogSeenVersion` в `GetStorage`, дашборд
    открывает экран в `addPostFrameCallback` — вход кассира не перебивается
  - Из профиля открывается вручную (пункт «Что нового» с номером версии)
  - Тексты для мобилки свои: перенесены не десктопные записи, а сводка этапов
    0–7 этого плана (тема, планшет, вкладки, маркировка, оплата, отложенные, UDS)
  - Тесты: `test/changelog_test.dart` (6), всего 429 зелёных
- [x] Логи приложения на устройстве (`src/helpers/logger.js` + `public/logger.js`,
  14 дней) — `lib/core/utils/logger.dart`, единый `appLog`
  - Формат JSONL, файл на сутки `cashbox-ГГГГ-ММ-ДД.log` в папке документов
    приложения, хранение `retentionDays = 14`, потолок 25 МБ на файл
  - Буфер + флаш раз в 2 с (или на 50 записях); `error` и `audit` пишутся сразу.
    Логгер никогда не бросает: нет папки/диск занят/payload не сериализуется —
    касса продолжает работать
  - Уровни как на десктопе: `info` / `warn` / `error` / `audit`, `debug` — только
    при включённом «Расширенном логе». Флаг `verboseLog` — настройка кассы
    (device-local, раздел «Общие»), логгер держит его полем и перечитывает
    по «Сохранить», а не дёргает хранилище на каждый скан
  - ПД режем `logTail()` (хвост кода маркировки/телефона), длинные строки — до 300
  - Глобальный перехват падений: `FlutterError.onError` +
    `PlatformDispatcher.onError` — раньше такие ошибки не видел никто
  - Экран `profile/logs.dart` (`/cashier/profile/logs`, пункт в профиле): выбор
    дня, хвост файла, копирование в буфер, очистка и «Выгрузить для поддержки» —
    все файлы склеиваются в один и уходят в системный лист «Поделиться»
    (`share_plus`), то есть файлом в Telegram; если принять файл некому,
    остаётся прежний путь в буфере обмена
  - Первые точки вызова: `app.start`, `auth.submit_failed`,
    `sale.line_deleted`, `sale.cheque_cleared`, `log.verbose_changed`
  - Тесты: `test/logger_test.dart` (16), всего 445 зелёных
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
