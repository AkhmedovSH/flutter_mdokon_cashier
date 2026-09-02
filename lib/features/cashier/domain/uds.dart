// UDS — вторая программа лояльности, работает параллельно с uGet (вкладка
// «Лояльность»). Порт `src/helpers/udsErrors.js`, `src/api/apiUds.js` и
// состояния `udsInfo` из `src/components/cashbox/Tab.js`.
//
// В одном чеке применяется только одна система: либо uGet, либо UDS, поэтому
// вкладки сбрасывают состояние друг друга.
//
// Главное правило: суммы к оплате касса НЕ считает. Всё берётся из ответа
// `uds-calc` как есть — любой собственный пересчёт сервер отобьёт как
// `error.uds.invalid_checksum`.
//
// Файл чистый: ни сети, ни Flutter — только разбор ответов и правила экрана.
library;

import 'package:flutter_mdokon/features/cashier/domain/promotion_engine.dart';

/// Число из ответа сервера или из поля ввода. В отличие от `customNumber`
/// не падает на мусоре: кассир может набрать в поле баллов одну точку.
double udsNumber(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}'.trim()) ?? 0;
}

/// Как кассир опознаёт клиента. По телефону UDS не разрешает списывать баллы.
enum UdsMode { code, phone }

const String udsUnavailableKey = 'error.uds.unavailable';

const Map<String, String> _errorKeyToI18n = {
  'error.uds.insufficient_funds': 'uds_error_insufficient_funds',
  'error.uds.withdraw_not_permitted': 'uds_error_withdraw_not_permitted',
  'error.uds.discount_limit': 'uds_error_discount_limit',
  'error.uds.invalid_checksum': 'uds_error_invalid_checksum',
  'error.uds.phone_disabled': 'uds_error_phone_disabled',
  'error.uds.price_list_only': 'uds_error_price_list_only',
  'error.uds.unauthorized': 'uds_error_unauthorized',
  'error.uds.not_found': 'uds_error_not_found',
  'error.uds.disabled': 'uds_error_disabled',
  'error.uds.two_loyalty': 'uds_error_two_loyalty',
  udsUnavailableKey: 'uds_error_unavailable',
};

/// Отказ UDS. Реагировать надо на [errorKey], а не на текст: тексты сервера
/// меняются и не переведены.
class UdsError implements Exception {
  const UdsError({this.errorKey, this.message, this.status, this.networkFailure = false});

  final String? errorKey;
  final String? message;

  /// 400 — отказ по существу (кассир может исправить), 503 — UDS недоступен.
  final int? status;

  /// Ответа от сервера не было вовсе (обрыв связи, таймаут): состояние
  /// операции неизвестно, поэтому такие ошибки обрабатываются отдельно.
  final bool networkFailure;

  /// Ключ перевода; `null` — переводить нечего, показываем [message].
  String? get i18nKey => _errorKeyToI18n[errorKey];

  /// UDS недоступен: продажу не блокируем, предлагаем провести чек без лояльности.
  bool get unavailable => networkFailure || status == 503 || errorKey == udsUnavailableKey;

  @override
  String toString() => 'UdsError(${errorKey ?? message ?? 'unknown'})';
}

/// Ключ ошибки из тела ответа: сервер кладёт его то в `errorKey`, то в
/// `key`/`code`, то прямо в `message`.
String? udsErrorKeyOf(dynamic payload) {
  if (payload is! Map) return null;
  for (final field in const ['errorKey', 'key', 'code', 'message']) {
    final value = payload[field];
    if (value is String && value.startsWith('error.uds.')) return value;
  }
  return null;
}

/// Расчёт покупки: что спишется, какая скидка и сколько платить деньгами.
class UdsCalc {
  const UdsCalc({
    this.uid = '',
    this.displayName = '',
    this.phone = '',
    this.balance = 0,
    this.tier = '',
    this.maxPoints = 0,
    this.discountAmount = 0,
    this.points = 0,
    this.cash = 0,
    this.cashBack = 0,
    this.total = 0,
  });

  /// Идентификатор клиента в UDS. По телефону UDS отдаёт `null` — поэтому
  /// «клиент найден» это отдельный флаг состояния, а не непустой uid.
  final String uid;
  final String displayName;
  final String phone;

  /// Баллов на счету.
  final double balance;

  /// Уровень участника («Серебряный» и т.п.).
  final String tier;

  /// Сколько баллов разрешено списать в этой покупке.
  final double maxPoints;
  final double discountAmount;

  /// Сколько баллов списывается по этому расчёту (`purchase.points`).
  final double points;

  /// Сколько остаётся заплатить деньгами.
  final double cash;

  /// Сколько баллов начислится.
  final double cashBack;

  /// Сумма чека, для которой сделан расчёт — по ней ловим изменение корзины.
  final double total;
}

/// Ответ `uds-calc` / `uds-find` в плоскую карточку кассира.
UdsCalc parseUdsCalc(dynamic raw) {
  if (raw is! Map) return const UdsCalc();
  final user = raw['user'] is Map ? raw['user'] as Map : const {};
  final participant = user['participant'] is Map ? user['participant'] as Map : const {};
  final tier = participant['membershipTier'] is Map ? participant['membershipTier'] as Map : const {};
  final purchase = raw['purchase'] is Map ? raw['purchase'] as Map : const {};

  return UdsCalc(
    uid: '${user['uid'] ?? ''}',
    displayName: '${user['displayName'] ?? ''}',
    phone: '${user['phone'] ?? ''}',
    balance: udsNumber(participant['points']),
    tier: '${tier['name'] ?? ''}',
    maxPoints: udsNumber(purchase['maxPoints']),
    discountAmount: udsNumber(purchase['discountAmount']),
    points: udsNumber(purchase['points']),
    cash: udsNumber(purchase['cash']),
    cashBack: udsNumber(purchase['cashBack']),
    total: udsNumber(purchase['total']),
  );
}

/// Идентификатор клиента — ровно один: QR-промокод, телефон или uid.
Map<String, dynamic> udsIdentifierPayload({String? code, String? phone, String? uid}) {
  if (code != null && code.trim().isNotEmpty) return {'code': code.trim()};
  if (phone != null && phone.trim().isNotEmpty) return {'phone': phone.trim()};
  if (uid != null && uid.trim().isNotEmpty) return {'uid': uid.trim()};
  return {};
}

/// Сумма чека вне лояльности — порт `calcUdsSkipLoyaltyTotal` (`Tab.js:6180`).
///
/// UDS не начисляет и не скидывает на то, что уже продано со скидкой или
/// отдано подарком по акции. Скидка на весь чек выводит из лояльности чек
/// целиком.
double calcUdsSkipLoyaltyTotal(Map? cheque) {
  if (cheque == null) return 0;
  if (udsNumber(cheque['discountAmount']) > 0) return udsNumber(cheque['totalPrice']);

  final items = cheque['itemsList'];
  if (items is! List) return 0;

  double sum = 0;
  for (final item in items) {
    if (item is! Map) continue;
    if (udsNumber(item['discountAmount']) > 0 || isPromotionGiftItem(item)) {
      sum += udsNumber(item['totalPrice']);
    }
  }
  return sum;
}

/// Состояние вкладки UDS. Неизменяемое: расчёт заменяется целиком, чтобы
/// нельзя было показать половину старых цифр и половину новых.
class UdsState {
  const UdsState({
    this.mode = UdsMode.code,
    this.search = '',
    this.found = false,
    this.calculated = false,
    this.pointsInput = '',
    this.calc = const UdsCalc(),
    this.skipLoyaltyTotal = 0,
  });

  final UdsMode mode;

  /// Что ввёл кассир — QR-промокод или телефон.
  final String search;

  /// Клиент найден. Отдельно от [calculated]: расчёт мог устареть.
  final bool found;

  /// Расчёт получен, его цифры можно отправлять в чек.
  final bool calculated;

  /// Баллы к списанию — ввод кассира; пересчёт запрашивается у сервера.
  final String pointsInput;

  final UdsCalc calc;
  final double skipLoyaltyTotal;

  UdsState copyWith({
    UdsMode? mode,
    String? search,
    bool? found,
    bool? calculated,
    String? pointsInput,
    UdsCalc? calc,
    double? skipLoyaltyTotal,
  }) =>
      UdsState(
        mode: mode ?? this.mode,
        search: search ?? this.search,
        found: found ?? this.found,
        calculated: calculated ?? this.calculated,
        pointsInput: pointsInput ?? this.pointsInput,
        calc: calc ?? this.calc,
        skipLoyaltyTotal: skipLoyaltyTotal ?? this.skipLoyaltyTotal,
      );

  /// Корзина изменилась после расчёта — старые цифры UDS уже не подходят.
  bool isStale(double total) => calculated && !_sameMoney(calc.total, total);

  /// Можно пробивать: расчёт свежий и внесённая сумма равна `cash` из расчёта.
  bool isValidated(double paid, double total) =>
      calculated && !isStale(total) && _sameMoney(paid, calc.cash);

  /// Списание запрещено: по телефону — правилами UDS, по QR — когда UDS вернул
  /// `maxPoints = 0` (оплата баллами отключена, лимит 0% или баллов ещё нет).
  bool get pointsDisabled => !found || mode != UdsMode.code || calc.maxPoints <= 0;

  /// Ввод баллов: только цифры и точка, не больше разрешённого максимума.
  String clampPoints(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    if (udsNumber(cleaned) > calc.maxPoints) return udsPointsText(calc.maxPoints);
    return cleaned;
  }

  /// Нужен ли новый расчёт после правки поля баллов.
  bool get needsRecalc => found && udsNumber(pointsInput) != calc.points;
}

/// Баллы в поле ввода: целое — без хвоста «.0».
String udsPointsText(double value) =>
    value == value.roundToDouble() ? value.round().toString() : '$value';

/// Сравнение денег до копеек: `12.005` и `12.0049` — одна и та же сумма.
bool _sameMoney(double a, double b) => (a - b).abs() < 0.005;

/// Поля UDS в чеке — порт `Tab.js:3049-3072`. Значения берём из последнего
/// расчёта и не пересчитываем.
Map<String, dynamic> udsChequeFields(UdsState state) {
  final search = state.search.trim();
  return {
    'change': 0,
    if (state.mode == UdsMode.phone)
      'udsPhone': state.calc.phone.isNotEmpty ? state.calc.phone : search,
    if (state.mode == UdsMode.code) 'udsCode': search,
    'udsPoints': state.calc.points,
    'udsCash': state.calc.cash,
    'udsDiscount': state.calc.discountAmount,
    'udsSkipLoyaltyTotal': state.skipLoyaltyTotal,
    // Для истории и печати чека
    'udsCustomerUid': state.calc.uid,
    'udsCustomerName': state.calc.displayName,
    'udsCashback': state.calc.cashBack,
    'udsBalance': state.calc.balance,
  };
}
