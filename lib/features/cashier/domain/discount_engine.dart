// Движок скидок кассы — чистые функции без Flutter/сети.
//
// Порт `src/helpers/discountEngine.js` из desktop-кассы (mdokon_cashbox).
// Идея: сервер хранит правила, а ВЕСЬ расчёт скидки — здесь, на кассе.
// [computeDiscounts] получает список правил, позиции корзины и контекст чека и
// возвращает АБСОЛЮТНЫЕ суммы скидок: по позиции (`itemDiscounts[i]`) и на весь
// чек (`chequeDiscount`).
//
// Защищённость: при пустом списке правил (в т.ч. когда backend отдал 404/[])
// движок молча возвращает нули — поведение кассы не меняется.

const bool kDiscountEngineEnabled = true;

const String _valuePercent = 'PERCENT';
const String _valueAmount = 'AMOUNT';
const String _valuePrice = 'PRICE';

const double _eps = 0.001;

num _num(dynamic v) {
  if (v is num) return v.isFinite ? v : 0;
  final n = num.tryParse('$v');
  return (n != null && n.isFinite) ? n : 0;
}

String _str(dynamic v) => v == null ? '' : '$v';

String _upper(dynamic v) => _str(v).toUpperCase();

bool _isEmpty(dynamic v) => v == null || v == '';

/// Цена единицы должна совпадать с расчётом корзины: по `active_price`
/// выбирается оптовая/банковская/розничная цена, а не «сырой» salePrice.
num unitPrice(Map? item) {
  if (item == null) return 0;
  final ap = _num(item['active_price'] ?? item['activePrice']);
  if (ap == 1) return _num(item['wholesalePrice']);
  if (ap == 2) return _num(item['bankPrice']);
  return _num(item['salePrice']);
}

num itemBase(Map? item) => unitPrice(item) * _num(item?['quantity']);

// ---------------------------------------------------------------------------
// Применимость правила
// ---------------------------------------------------------------------------

bool _isRuleActive(Map rule) {
  if (rule['activated'] == false) return false;
  if (rule['status'] != null && _upper(rule['status']) != 'ACTIVE') return false;
  return true;
}

DateTime? _parseDate(dynamic v) {
  if (v == null || v == '') return null;
  if (v is DateTime) return v;
  return DateTime.tryParse('$v');
}

/// ISO: 1=Пн..7=Вс (`DateTime.weekday` уже в этом формате).
int _isoWeekday(DateTime date) => date.weekday;

String _hhmm(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

/// Время из вебки приходит как "HH:MM:SS" (иногда "HH:MM") — приводим к "HH:MM",
/// иначе строковое сравнение на границе окна врёт ("10:00" < "10:00:00").
String? _normTime(dynamic v) {
  if (v == null) return null;
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch('$v'.trim());
  if (m == null) return null;
  return '${m.group(1)!.padLeft(2, '0')}:${m.group(2)}';
}

bool _inTimeWindow(dynamic timeFrom, dynamic timeTo, DateTime now) {
  final from = _normTime(timeFrom);
  final to = _normTime(timeTo);
  if (from == null || to == null) return true;
  // Вебка пишет 00:00–00:00 (и вообще любое from == to), когда время НЕ
  // ограничено — это «весь день», а не окно нулевой длины.
  if (from == to) return true;
  final t = _hhmm(now);
  // Обычное окно; при from > to — окно через полночь.
  if (from.compareTo(to) <= 0) {
    return t.compareTo(from) >= 0 && t.compareTo(to) <= 0;
  }
  return t.compareTo(from) >= 0 || t.compareTo(to) <= 0;
}

/// Контекст чека для расчёта скидок.
class DiscountContext {
  DiscountContext({
    this.chequeSum = 0,
    this.clientSegments = const [],
    this.paymentTypeId,
    this.paymentTypeIds,
    this.promocode,
    DateTime? now,
    Iterable<dynamic>? selectedManualRuleIds,
  })  : now = now ?? DateTime.now(),
        selectedManualRuleIds =
            (selectedManualRuleIds ?? const []).map(_str).toSet();

  final num chequeSum;
  final List<dynamic> clientSegments;
  final dynamic paymentTypeId;
  final List<dynamic>? paymentTypeIds;
  final String? promocode;
  final DateTime now;
  final Set<String> selectedManualRuleIds;
}

/// Общие условия применимости, кроме режима (AUTO/MANUAL) и области targets —
/// они проверяются отдельно. Незаданные поля не ограничивают.
///
/// Возвращает причину отказа или `null`, если правило применимо, — причина
/// уходит в диагностику, иначе непонятно, почему правило «не сработало».
/// Экспортируется: у правил акций применимость проверяется так же.
String? ruleApplicabilityReason(Map rule, DiscountContext ctx) {
  if (!_isRuleActive(rule)) return 'not_active';

  final now = ctx.now;

  final from = _parseDate(rule['validFrom']);
  final to = _parseDate(rule['validTo']);
  if (from != null && now.isBefore(from)) return 'not_started';
  if (to != null && now.isAfter(to)) return 'expired';

  if (!_isEmpty(rule['weekdays'])) {
    final days = _str(rule['weekdays'])
        .split(',')
        .map((s) => num.tryParse(s.trim()))
        .whereType<num>()
        .where((n) => n >= 1 && n <= 7)
        .toList();
    if (days.isNotEmpty && !days.contains(_isoWeekday(now))) {
      return 'wrong_weekday';
    }
  }

  if (!_inTimeWindow(rule['timeFrom'], rule['timeTo'], now)) {
    return 'out_of_time';
  }

  if (!_isEmpty(rule['minChequeAmount']) &&
      ctx.chequeSum < _num(rule['minChequeAmount'])) {
    return 'below_min_cheque';
  }

  if (!_isEmpty(rule['clientStatusRuleId'])) {
    final segs = ctx.clientSegments.map(_str).toList();
    if (!segs.contains(_str(rule['clientStatusRuleId']))) {
      return 'wrong_client_segment';
    }
  }

  return null;
}

bool isRuleApplicable(Map rule, DiscountContext ctx) =>
    ruleApplicabilityReason(rule, ctx) == null;

/// Режим/тип-специфичная активация: AUTO — всегда; MANUAL — только выбранные
/// кассиром; PROMOCODE — при совпавшем коде; PAYMENT_TYPE — при совпавшем типе
/// оплаты.
bool _passesMode(Map rule, DiscountContext ctx) {
  final type = _upper(rule['type']);

  if (type == 'PROMOCODE') {
    final code = ctx.promocode;
    return code != null && code.isNotEmpty && _str(rule['promocode']) == code;
  }
  if (type == 'PAYMENT_TYPE') {
    // Поддерживаем как один выбранный тип, так и сплит-оплату несколькими
    // типами. Правило срабатывает при совпадении с любым.
    final ids = <String>[];
    final many = ctx.paymentTypeIds;
    if (many != null && many.isNotEmpty) {
      ids.addAll(many.map(_str));
    } else if (ctx.paymentTypeId != null) {
      ids.add(_str(ctx.paymentTypeId));
    }
    return ids.contains(_str(rule['paymentTypeId']));
  }

  final mode = rule['applyMode'] == null ? 'AUTO' : _upper(rule['applyMode']);
  if (mode == 'MANUAL') {
    return ctx.selectedManualRuleIds.contains(_str(rule['id']));
  }
  return true;
}

// ---------------------------------------------------------------------------
// Сопоставление targets (области действия)
// ---------------------------------------------------------------------------

bool matchesTarget(Map item, List? targets) {
  if (targets == null || targets.isEmpty) return true; // пусто = ALL
  return targets.any((t) {
    final map = t is Map ? t : const {};
    final type = _upper(map['targetType']);
    if (type == '' || type == 'ALL') return true;
    if (type == 'PRODUCT') {
      return _str(item['productId']) == _str(map['targetId']);
    }
    if (type == 'CATEGORY') {
      // Дерево категорий (categoryPath) — включая подкатегории — если backend
      // его отдаёт.
      final path = item['categoryPath'];
      if (path is List && path.isNotEmpty) {
        return path.map(_str).contains(_str(map['targetId']));
      }
      if (path is String && path.isNotEmpty) {
        return path
            .split(',')
            .map((s) => s.trim())
            .contains(_str(map['targetId']));
      }
      // Иначе — только точный categoryId (плоский, как сейчас).
      return _str(item['categoryId']) == _str(map['targetId']);
    }
    if (type == 'BRAND') {
      if (_isEmpty(item['brandName'])) return false; // нет данных → не матчим
      return _str(item['brandName']) == _str(map['targetValue']);
    }
    return false;
  });
}

// ---------------------------------------------------------------------------
// Калькуляторы механик
// ---------------------------------------------------------------------------

/// Результат одного калькулятора: суммы по индексам позиций и на чек.
class _CalcResult {
  _CalcResult({Map<int, num>? items, this.cheque = 0, this.skip})
      : items = items ?? <int, num>{};

  final Map<int, num> items;
  final num cheque;
  final String? skip;
}

Map? _pickTier(dynamic tiers, num measure) {
  if (tiers is! List || tiers.isEmpty) return null;
  final sorted = tiers
      .whereType<Map>()
      .where((t) => t['threshold'] != null)
      .toList()
    ..sort((a, b) => _num(a['threshold']).compareTo(_num(b['threshold'])));
  Map? chosen;
  for (final t in sorted) {
    if (_num(t['threshold']) <= measure) chosen = t;
  }
  return chosen;
}

/// value по valueType на позицию: PERCENT — процент от базы; AMOUNT — сумма за
/// единицу × qty; PRICE — новая цена за единицу.
num _valueOnItem(dynamic valueType, dynamic value, Map item) {
  final up = unitPrice(item);
  final q = _num(item['quantity']);
  final vt = _upper(valueType);
  if (vt == _valuePercent) return (up * q * _num(value)) / 100;
  if (vt == _valueAmount) return _num(value) * q;
  if (vt == _valuePrice) return up > _num(value) ? (up - _num(value)) * q : 0;
  return 0;
}

num _valueOnCheque(dynamic valueType, dynamic value, num chequeSum) {
  final vt = _upper(valueType);
  if (vt == _valuePercent) return (chequeSum * _num(value)) / 100;
  if (vt == _valueAmount) return _num(value);
  return 0;
}

void _addItem(Map<int, num> out, int i, num amount) {
  if (amount > 0) out[i] = (out[i] ?? 0) + amount;
}

typedef _Calculator = _CalcResult Function(
    Map rule, List<Map> items, DiscountContext ctx, List<num> base);

/// PERCENT / FIXED / CLIENT_SEGMENT — value по valueType на подходящие позиции.
_CalcResult _calcValueOnItems(
    Map rule, List<Map> items, DiscountContext ctx, List<num> base) {
  final out = <int, num>{};
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (!matchesTarget(item, rule['targets'] as List?)) continue;
    final v = _valueOnItem(rule['valueType'], rule['value'], item);
    _addItem(out, i, v < base[i] ? v : base[i]);
  }
  return _CalcResult(items: out);
}

_CalcResult _calcQuantityPrice(
    Map rule, List<Map> items, DiscountContext ctx, List<num> base) {
  final out = <int, num>{};
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (!matchesTarget(item, rule['targets'] as List?)) continue;
    final tier = _pickTier(rule['tiers'], _num(item['quantity']));
    if (tier == null) continue;
    final vt = tier['valueType'] ?? rule['valueType'];
    _addItem(out, i, _valueOnItem(vt, tier['value'], item));
  }
  return _CalcResult(items: out);
}

_CalcResult _calcChequeThreshold(
    Map rule, List<Map> items, DiscountContext ctx, List<num> base) {
  final tier = _pickTier(rule['tiers'], ctx.chequeSum);
  if (tier == null) return _CalcResult();
  final vt = tier['valueType'] ?? rule['valueType'];
  return _CalcResult(cheque: _valueOnCheque(vt, tier['value'], ctx.chequeSum));
}

_CalcResult _calcBundle(
    Map rule, List<Map> items, DiscountContext ctx, List<num> base) {
  final targets = (rule['targets'] as List?) ?? const [];
  if (targets.isEmpty) return _CalcResult();

  // По одному подходящему товару (не менее 1 шт) на каждый элемент набора.
  final memberIndexes = <int>[];
  for (final t in targets) {
    var idx = -1;
    for (var i = 0; i < items.length; i++) {
      if (memberIndexes.contains(i)) continue;
      if (matchesTarget(items[i], [t]) && _num(items[i]['quantity']) >= 1) {
        idx = i;
        break;
      }
    }
    if (idx == -1) return _CalcResult(skip: 'bundle_incomplete');
    memberIndexes.add(idx);
  }

  final sumMembers =
      memberIndexes.fold<num>(0, (s, i) => s + unitPrice(items[i]));
  final setDisc = sumMembers - _num(rule['value']);
  if (setDisc <= 0 || sumMembers <= 0) return _CalcResult();

  // Распределить скидку набора по позициям пропорционально цене; остаток — на
  // последнюю.
  final out = <int, num>{};
  num allocated = 0;
  for (var k = 0; k < memberIndexes.length; k++) {
    final i = memberIndexes[k];
    num share;
    if (k == memberIndexes.length - 1) {
      share = setDisc - allocated;
    } else {
      share = (setDisc * unitPrice(items[i])) / sumMembers;
      allocated += share;
    }
    _addItem(out, i, share);
  }
  return _CalcResult(items: out);
}

_CalcResult _calcSecondItem(
    Map rule, List<Map> items, DiscountContext ctx, List<num> base) {
  // Развернуть подходящие ЦЕЛЫЕ единицы, отсортировать по цене вниз, скидка на
  // каждую вторую.
  final units = <({num price, int i})>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (!matchesTarget(item, rule['targets'] as List?)) continue;
    final q = _num(item['quantity']).floor();
    final up = unitPrice(item);
    for (var u = 0; u < q; u++) {
      units.add((price: up, i: i));
    }
  }
  units.sort((a, b) => b.price.compareTo(a.price));

  final vt = _upper(rule['valueType']);
  final out = <int, num>{};
  for (var k = 1; k < units.length; k += 2) {
    final unit = units[k];
    num disc = 0;
    if (vt == _valuePercent) {
      disc = (unit.price * _num(rule['value'])) / 100;
    } else if (vt == _valueAmount) {
      disc = _num(rule['value']);
    }
    _addItem(out, unit.i, disc);
  }
  return _CalcResult(items: out);
}

// Окно уже проверено в isRuleApplicable; внутри — как PERCENT/FIXED на targets.
_CalcResult _calcTime(
        Map rule, List<Map> items, DiscountContext ctx, List<num> base) =>
    _calcValueOnItems(rule, items, ctx, base);

_CalcResult _calcExpiry(
    Map rule, List<Map> items, DiscountContext ctx, List<num> base) {
  final out = <int, num>{};
  final now = ctx.now;
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (!matchesTarget(item, rule['targets'] as List?)) continue;
    final exp = _parseDate(item['expDate']);
    if (exp == null) continue; // нет срока годности → пропуск
    final days =
        (exp.difference(now).inMicroseconds / Duration.microsecondsPerDay)
            .ceil();
    if (days > _num(rule['expiryDays'])) continue;
    final v = _valueOnItem(rule['valueType'], rule['value'], item);
    _addItem(out, i, v < base[i] ? v : base[i]);
  }
  return _CalcResult(items: out);
}

_CalcResult _calcPaymentType(
        Map rule, List<Map> items, DiscountContext ctx, List<num> base) =>
    _CalcResult(
        cheque: _valueOnCheque(rule['valueType'], rule['value'], ctx.chequeSum));

_CalcResult _calcPromocode(
    Map rule, List<Map> items, DiscountContext ctx, List<num> base) {
  if (_upper(rule['limitScope']) == 'CHEQUE') {
    return _CalcResult(
        cheque: _valueOnCheque(rule['valueType'], rule['value'], ctx.chequeSum));
  }
  return _calcValueOnItems(rule, items, ctx, base);
}

const Map<String, _Calculator> _calculators = {
  'QUANTITY_PRICE': _calcQuantityPrice,
  'CHEQUE_THRESHOLD': _calcChequeThreshold,
  'PERCENT': _calcValueOnItems,
  'FIXED': _calcValueOnItems,
  'BUNDLE': _calcBundle,
  'SECOND_ITEM': _calcSecondItem,
  'TIME': _calcTime,
  'CLIENT_SEGMENT': _calcValueOnItems,
  'PAYMENT_TYPE': _calcPaymentType,
  'EXPIRY': _calcExpiry,
  'PROMOCODE': _calcPromocode,
};

/// Кэпы самого правила (maxDiscountAmount / maxDiscountPercent), если заданы
/// (0/null = без ограничения).
num _capByRule(num amount, Map rule, num capBase) {
  var a = amount;
  if (rule['maxDiscountAmount'] != null && _num(rule['maxDiscountAmount']) > 0) {
    final m = _num(rule['maxDiscountAmount']);
    if (m < a) a = m;
  }
  if (rule['maxDiscountPercent'] != null &&
      _num(rule['maxDiscountPercent']) > 0) {
    final m = (capBase * _num(rule['maxDiscountPercent'])) / 100;
    if (m < a) a = m;
  }
  return a;
}

// ---------------------------------------------------------------------------
// Лимит кассира (CASHIER_LIMIT) — вердикт для UX; сервер проверяет повторно.
// ---------------------------------------------------------------------------

/// Вердикт по лимиту кассира. Существование объекта и есть нарушение.
class DiscountLimitVerdict {
  const DiscountLimitVerdict({
    required this.scope,
    required this.ruleId,
    required this.allowed,
    required this.requested,
    this.itemIndex,
  });

  final String scope; // ITEM | CHEQUE
  final dynamic ruleId;
  final num allowed;
  final num requested;
  final int? itemIndex;
}

DiscountLimitVerdict? _evaluateLimit(
  List rules,
  DiscountContext ctx,
  List<Map> items,
  List<num> base,
  List<num> itemDiscounts,
  num totalDiscount,
) {
  final limitRules = rules
      .whereType<Map>()
      .where((r) => _upper(r['type']) == 'CASHIER_LIMIT' && _isRuleActive(r));

  for (final rule in limitRules) {
    final scope =
        rule['limitScope'] == null ? 'CHEQUE' : _upper(rule['limitScope']);
    final maxA = (rule['maxDiscountAmount'] != null &&
            _num(rule['maxDiscountAmount']) > 0)
        ? _num(rule['maxDiscountAmount'])
        : double.infinity;
    final maxP = (rule['maxDiscountPercent'] != null &&
            _num(rule['maxDiscountPercent']) > 0)
        ? _num(rule['maxDiscountPercent'])
        : double.infinity;

    if (scope == 'ITEM') {
      for (var i = 0; i < items.length; i++) {
        if (itemDiscounts[i] <= 0) continue;
        final byPercent = (base[i] * maxP) / 100;
        final allowed = maxA < byPercent ? maxA : byPercent;
        if (itemDiscounts[i] > allowed + _eps) {
          return DiscountLimitVerdict(
            scope: 'ITEM',
            ruleId: rule['id'],
            allowed: allowed,
            requested: itemDiscounts[i],
            itemIndex: i,
          );
        }
      }
    } else {
      final byPercent = (ctx.chequeSum * maxP) / 100;
      final allowed = maxA < byPercent ? maxA : byPercent;
      if (totalDiscount > allowed + _eps) {
        return DiscountLimitVerdict(
          scope: 'CHEQUE',
          ruleId: rule['id'],
          allowed: allowed,
          requested: totalDiscount,
        );
      }
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Результат
// ---------------------------------------------------------------------------

/// Сработавшее правило — для диагностики и печати в чеке.
class AppliedDiscountRule {
  const AppliedDiscountRule({
    required this.ruleId,
    required this.name,
    required this.type,
    required this.scope,
    required this.amount,
    required this.itemIndexes,
  });

  final dynamic ruleId;
  final String? name;
  final String type;
  final String scope; // ITEM | CHEQUE
  final num amount;
  final List<int> itemIndexes;
}

/// Правило, которое не сработало, и почему.
class SkippedDiscountRule {
  const SkippedDiscountRule(this.ruleId, this.reason);

  final dynamic ruleId;
  final String reason;
}

/// Итог расчёта скидок по чеку.
class DiscountResult {
  const DiscountResult({
    required this.itemDiscounts,
    required this.chequeDiscount,
    required this.totalDiscount,
    required this.appliedRules,
    required this.limit,
    required this.skipped,
  });

  final List<num> itemDiscounts;
  final num chequeDiscount;
  final num totalDiscount;
  final List<AppliedDiscountRule> appliedRules;
  final DiscountLimitVerdict? limit;
  final List<SkippedDiscountRule> skipped;
}

// ---------------------------------------------------------------------------
// Главная функция
// ---------------------------------------------------------------------------

DiscountResult computeDiscounts({
  List? rules,
  List? items,
  DiscountContext? context,
}) {
  final safeItems = (items ?? const []).whereType<Map>().toList();

  DiscountResult zero() => DiscountResult(
        itemDiscounts: List<num>.filled(safeItems.length, 0),
        chequeDiscount: 0,
        totalDiscount: 0,
        appliedRules: const [],
        limit: null,
        skipped: const [],
      );

  if (!kDiscountEngineEnabled) return zero();
  if (rules == null || rules.isEmpty) return zero();

  final ctx = context ?? DiscountContext();

  final base = safeItems.map(itemBase).toList();
  final itemDiscounts = List<num>.filled(safeItems.length, 0);
  final itemDiscounted = List<bool>.filled(safeItems.length, false);
  num chequeDiscount = 0;
  var chequeDiscounted = false;
  final appliedRules = <AppliedDiscountRule>[];
  final skipped = <SkippedDiscountRule>[];

  final applicable = rules
      .whereType<Map>()
      .where((r) =>
          _upper(r['type']) != 'CASHIER_LIMIT' &&
          _passesMode(r, ctx) &&
          isRuleApplicable(r, ctx))
      .toList()
    ..sort((a, b) {
      final byPriority = _num(a['priority']).compareTo(_num(b['priority']));
      if (byPriority != 0) return byPriority;
      return _num(a['id']).compareTo(_num(b['id']));
    });

  for (final rule in applicable) {
    final type = _upper(rule['type']);
    final calc = _calculators[type];
    if (calc == null) {
      skipped.add(SkippedDiscountRule(rule['id'], 'unknown_type'));
      continue;
    }

    final res = calc(rule, safeItems, ctx, base);
    if (res.skip != null) {
      skipped.add(SkippedDiscountRule(rule['id'], res.skip!));
    }

    final stackable =
        rule['stackable'] == true || _str(rule['stackable']) == 'true';
    final itemIndexes = <int>[];
    num ruleApplied = 0;

    for (final entry in res.items.entries) {
      final i = entry.key;
      var amount = _num(entry.value);
      if (amount <= 0) continue;
      if (itemDiscounted[i] && !stackable) {
        skipped.add(SkippedDiscountRule(rule['id'], 'not_stackable_item'));
        continue;
      }
      amount = _capByRule(amount, rule, base[i]);
      // Жёсткий кэп: скидка позиции не больше базы.
      final remaining = base[i] - itemDiscounts[i];
      if (amount > remaining) amount = remaining;
      if (amount <= 0) continue;
      itemDiscounts[i] += amount;
      itemDiscounted[i] = true;
      ruleApplied += amount;
      itemIndexes.add(i);
    }

    if (res.cheque > 0) {
      if (chequeDiscounted && !stackable) {
        skipped.add(SkippedDiscountRule(rule['id'], 'not_stackable_cheque'));
      } else {
        var amount = _capByRule(res.cheque, rule, ctx.chequeSum);
        // Скидка чека не больше суммы чека.
        final remaining = ctx.chequeSum -
            itemDiscounts.fold<num>(0, (s, x) => s + x) -
            chequeDiscount;
        if (amount > remaining) amount = remaining;
        if (amount > 0) {
          chequeDiscount += amount;
          chequeDiscounted = true;
          ruleApplied += amount;
        }
      }
    }

    if (ruleApplied > _eps) {
      appliedRules.add(AppliedDiscountRule(
        ruleId: rule['id'],
        name: rule['name'] as String?,
        type: type,
        scope: res.cheque > 0 ? 'CHEQUE' : 'ITEM',
        amount: ruleApplied,
        itemIndexes: itemIndexes,
      ));
    }
  }

  final totalDiscount =
      itemDiscounts.fold<num>(0, (s, x) => s + x) + chequeDiscount;
  final limit =
      _evaluateLimit(rules, ctx, safeItems, base, itemDiscounts, totalDiscount);

  return DiscountResult(
    itemDiscounts: itemDiscounts,
    chequeDiscount: chequeDiscount,
    totalDiscount: totalDiscount,
    appliedRules: appliedRules,
    limit: limit,
    skipped: skipped,
  );
}

/// Сброс скидок движка на копии чека.
Map? clearEngineDiscounts(Map? data) {
  if (data == null) return data;
  final items = data['itemsList'];
  if (items is List) {
    for (final it in items.whereType<Map>()) {
      it['discountAmount'] = 0;
    }
  }
  data['discountAmount'] = 0;
  data['totalPriceBeforeDiscount'] = 0;
  data['discountSource'] = '';
  data['appliedDiscountRules'] = [];
  return data;
}
