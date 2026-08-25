// Движок акций кассы — чистые функции без Flutter/сети.
//
// Порт `src/helpers/promotionEngine.js` из desktop-кассы (mdokon_cashbox).
// Акция = получение ТОВАРА (подарка), в отличие от скидки (уменьшение цены).
//
// [computePromotions] получает правила, позиции корзины и контекст чека и
// возвращает:
//   gifts    — подарочные ПОЗИЦИИ, которые касса должна добавить в чек;
//   lineFree — бесплатные единицы ВНУТРИ существующей позиции (EVERY_NTH_FREE).
// Ничего не мутирует: интеграция сама создаёт строки чека и ставит им
// `promotionRuleId`.
//
// Защищённость: при пустом списке правил движок молча возвращает пустой
// результат — поведение кассы не меняется.

import 'discount_engine.dart';

const bool kPromotionEngineEnabled = true;

// Механики (поле `type` правила)
const String promotionGiftNM = 'GIFT_N_M';
const String promotionBogo = 'BOGO';
const String promotionEveryNthFree = 'EVERY_NTH_FREE';
const String promotionGiftOnAmount = 'GIFT_ON_AMOUNT';
const String promotionGiftOnCategory = 'GIFT_ON_CATEGORY';

const List<String> kPromotionTypes = [
  promotionGiftNM,
  promotionBogo,
  promotionEveryNthFree,
  promotionGiftOnAmount,
  promotionGiftOnCategory,
];

num _num(dynamic v) {
  if (v is num) return v.isFinite ? v : 0;
  final n = num.tryParse('$v');
  return (n != null && n.isFinite) ? n : 0;
}

String _str(dynamic v) => v == null ? '' : '$v';

bool _isEmpty(dynamic v) => v == null || v == '';

/// Позиция-подарок, добавленная движком акций (её нельзя засчитывать как покупку).
bool isPromotionGiftItem(Map? item) => item?['promotionGift'] == true;

/// id сработавшего правила акции. В локальном чеке его ставит касса, с сервера
/// он приходит в `promotionRuleId` (0 = позиция не по акции).
num? getPromotionRuleId(Map? item) {
  final id = _num(item?['promotionRuleId']);
  return id > 0 ? id : null;
}

/// Позиция получена по акции — и в свежем чеке кассы, и в чеке с сервера.
bool isPromotionItem(Map? item) =>
    isPromotionGiftItem(item) || getPromotionRuleId(item) != null;

/// Позиция отдана полностью бесплатно (скидка акции равна её стоимости) — на
/// чеке такую строку показываем как подарок, а не как обычную уценку.
bool isFreeByPromotion(Map? item) {
  if (!isPromotionItem(item)) return false;
  final gross = _num(item!['quantity']) * _num(item['salePrice']);
  final discount = _num(item['discountAmount']);
  return gross > 0 && discount > 0 && (gross - discount).abs() < 0.01;
}

/// Название акции для печатных форм. Порядок: имя из чека → имя из кэша
/// активных правил точки → пусто (правило удалено/неактивно, показываем позицию
/// просто как подарок).
String getPromotionName(Map? item, List? rules) {
  if (item == null) return '';
  if (!_isEmpty(item['promotionRuleName'])) {
    return _str(item['promotionRuleName']);
  }
  if (!_isEmpty(item['promotionName'])) return _str(item['promotionName']);
  final id = getPromotionRuleId(item);
  if (id == null) return '';
  for (final rule in (rules ?? const []).whereType<Map>()) {
    if (_str(rule['id']) == _str(id)) {
      return _isEmpty(rule['name']) ? '' : _str(rule['name']);
    }
  }
  return '';
}

/// Позиция корзины вместе с её индексом.
typedef _Buyable = ({Map item, int index});

/// Только реально купленные позиции считаются условием акции: подарки движка и
/// legacy-позиции «товар→подарок» (`promotion`) исключаются.
List<_Buyable> _buyableItems(List<Map> items) {
  final out = <_Buyable>[];
  for (var i = 0; i < items.length; i++) {
    final it = items[i];
    if (isPromotionGiftItem(it) || it['promotion'] == true) continue;
    out.add((item: it, index: i));
  }
  return out;
}

/// AUTO — применяется само; MANUAL — только если кассир выбрал правило.
bool _passesMode(Map rule, DiscountContext ctx) {
  final mode = rule['applyMode'] == null
      ? 'AUTO'
      : _str(rule['applyMode']).toUpperCase();
  if (mode == 'MANUAL') {
    return ctx.selectedManualRuleIds.contains(_str(rule['id']));
  }
  return true;
}

/// Скидка на подарок: 100 (по умолчанию) = бесплатно, <100 = подарок со скидкой.
num _giftPercent(Map rule) {
  final p = rule['giftDiscountPercent'];
  if (_isEmpty(p)) return 100;
  final n = _num(p);
  if (n <= 0) return 0;
  return n < 100 ? n : 100;
}

/// Сколько единиц подарка выдаётся за одно срабатывание.
/// `gifts[].quantity` приоритетнее; `giftQuantity` (M) — запасной вариант.
/// Специально НЕ перемножаем: вебка часто пишет M в оба поля.
num _giftUnits(Map rule, Map gift) {
  final q = _num(gift['quantity']);
  if (q > 0) return q;
  final m = _num(rule['giftQuantity']);
  return m > 0 ? m : 1;
}

/// Кратность за чек (`maxApply`): null/0 = без лимита.
num _capTimes(num times, Map rule) {
  final max = _num(rule['maxApply']);
  if (max > 0) return times < max ? times : max;
  return times;
}

/// Короткое описание условия правила для диагностики: `PRODUCT:3640855` / `ALL`.
List<String> _describeTargets(Map rule) {
  final list = (rule['targets'] as List?) ?? const [];
  if (list.isEmpty) return ['ALL'];
  return list.map((t) {
    final map = t is Map ? t : const {};
    final type = map['targetType'] == null
        ? 'ALL'
        : _str(map['targetType']).toUpperCase();
    final value = map['targetId'] ?? map['targetValue'];
    return value == null ? type : '$type:$value';
  }).toList();
}

List<Map> _ruleGifts(Map rule) =>
    ((rule['gifts'] as List?) ?? const [])
        .whereType<Map>()
        .where((g) => g['productId'] != null)
        .toList();

/// Сумма подходящих под `targets` единиц товара в чеке.
num _matchedQuantity(Map rule, List<_Buyable> buyable) => buyable.fold<num>(
      0,
      (s, b) => matchesTarget(b.item, rule['targets'] as List?)
          ? s + _num(b.item['quantity'])
          : s,
    );

// ---------------------------------------------------------------------------
// Механики
// ---------------------------------------------------------------------------

/// Сколько раз срабатывает правило (для механик с подарочной позицией).
({num times, String? skip}) _triggerTimes(
    Map rule, String type, List<_Buyable> buyable) {
  if (type == promotionGiftOnAmount) {
    // Порог суммы уже проверен в ruleApplicabilityReason (minChequeAmount); без
    // порога правило считаем недонастроенным, иначе подарок падал бы в любой чек.
    if (_isEmpty(rule['minChequeAmount'])) {
      return (times: 0, skip: 'no_min_amount');
    }
    if (buyable.isEmpty) return (times: 0, skip: 'empty_cheque');
    return (times: 1, skip: null);
  }

  final matched = _matchedQuantity(rule, buyable);
  if (matched <= 0) return (times: 0, skip: 'no_target_items');

  if (type == promotionGiftOnCategory) {
    final n = _num(rule['buyQuantity']);
    return (times: n > 0 ? (matched / n).floor() : 1, skip: null);
  }

  // GIFT_N_M / BOGO: N шт из targets → срабатывание (для BOGO N по умолчанию = 1).
  final buyQuantity = _num(rule['buyQuantity']);
  final n = buyQuantity > 0
      ? buyQuantity
      : type == promotionBogo
          ? 1
          : 0;
  if (n <= 0) return (times: 0, skip: 'no_buy_quantity');
  return (times: (matched / n).floor(), skip: null);
}

/// Бесплатные единицы внутри существующей позиции чека.
class PromotionLineFree {
  const PromotionLineFree({
    required this.ruleId,
    required this.ruleName,
    required this.type,
    required this.itemIndex,
    required this.units,
    required this.amount,
    required this.giftDiscountPercent,
  });

  final dynamic ruleId;
  final String? ruleName;
  final String type;
  final int itemIndex;
  final num units;
  final num amount;
  final num giftDiscountPercent;
}

/// Подарочная позиция, которую касса должна добавить в чек.
class PromotionGift {
  const PromotionGift({
    required this.ruleId,
    required this.ruleName,
    required this.type,
    required this.productId,
    required this.quantity,
    required this.giftDiscountPercent,
  });

  final dynamic ruleId;
  final String? ruleName;
  final String type;
  final dynamic productId;
  final num quantity;
  final num giftDiscountPercent;
}

/// Сработавшее правило акции.
class AppliedPromotion {
  const AppliedPromotion({
    required this.ruleId,
    required this.name,
    required this.type,
    required this.times,
  });

  final dynamic ruleId;
  final String? name;
  final String type;
  final num times;
}

/// Правило акции, которое не сработало, и почему.
class SkippedPromotion {
  const SkippedPromotion({
    required this.ruleId,
    required this.name,
    required this.reason,
    this.targets,
  });

  final dynamic ruleId;
  final String? name;
  final String reason;
  final List<String>? targets;
}

/// Итог расчёта акций по чеку.
class PromotionResult {
  const PromotionResult({
    required this.gifts,
    required this.lineFree,
    required this.applied,
    required this.skipped,
  });

  final List<PromotionGift> gifts;
  final List<PromotionLineFree> lineFree;
  final List<AppliedPromotion> applied;
  final List<SkippedPromotion> skipped;
}

/// EVERY_NTH_FREE: на каждые N шт товара из `targets` одна единица бесплатно.
/// Бесплатными делаем САМЫЕ ДЕШЁВЫЕ единицы (обычная практика розницы).
({List<PromotionLineFree> lineFree, num times, String? skip}) _calcEveryNthFree(
    Map rule, List<_Buyable> buyable) {
  final n = _num(rule['buyQuantity']);
  if (n <= 0) {
    return (lineFree: const [], times: 0, skip: 'no_buy_quantity');
  }

  final units = <({int index, num price})>[];
  for (final b in buyable) {
    if (!matchesTarget(b.item, rule['targets'] as List?)) continue;
    final q = _num(b.item['quantity']).floor();
    final price = unitPrice(b.item);
    for (var u = 0; u < q; u++) {
      units.add((index: b.index, price: price));
    }
  }
  if (units.isEmpty) {
    return (lineFree: const [], times: 0, skip: 'no_target_items');
  }

  final free = _capTimes((units.length / n).floor(), rule);
  if (free <= 0) return (lineFree: const [], times: 0, skip: null);

  units.sort((a, b) => a.price.compareTo(b.price));
  final pct = _giftPercent(rule);
  final byIndex = <int, ({num units, num amount})>{};
  for (var k = 0; k < free; k++) {
    final u = units[k];
    final acc = byIndex[u.index] ?? (units: 0, amount: 0);
    byIndex[u.index] =
        (units: acc.units + 1, amount: acc.amount + (u.price * pct) / 100);
  }

  final lineFree = byIndex.entries
      .map((e) => PromotionLineFree(
            ruleId: rule['id'],
            ruleName: rule['name'] as String?,
            type: promotionEveryNthFree,
            itemIndex: e.key,
            units: e.value.units,
            amount: e.value.amount,
            giftDiscountPercent: pct,
          ))
      .toList();
  return (lineFree: lineFree, times: free, skip: null);
}

// ---------------------------------------------------------------------------
// Главная функция
// ---------------------------------------------------------------------------

PromotionResult computePromotions({
  List? rules,
  List? items,
  DiscountContext? context,
}) {
  const empty = PromotionResult(
      gifts: [], lineFree: [], applied: [], skipped: []);

  if (!kPromotionEngineEnabled) return empty;
  if (rules == null || rules.isEmpty) return empty;

  final safeItems = (items ?? const []).whereType<Map>().toList();
  final ctx = context ?? DiscountContext();

  final buyable = _buyableItems(safeItems);
  final gifts = <PromotionGift>[];
  final lineFree = <PromotionLineFree>[];
  final applied = <AppliedPromotion>[];
  final skipped = <SkippedPromotion>[];

  // Применимость (период, дни, часы, сегмент, порог) — та же, что у скидок.
  // Причину отказа кладём в skipped: иначе непонятно, почему акция «не сработала».
  final applicable = <Map>[];
  for (final rule in rules.whereType<Map>()) {
    if (!_passesMode(rule, ctx)) {
      skipped.add(SkippedPromotion(
        ruleId: rule['id'],
        name: rule['name'] as String?,
        reason: 'manual_not_selected',
      ));
      continue;
    }
    final reason = ruleApplicabilityReason(rule, ctx);
    if (reason != null) {
      skipped.add(SkippedPromotion(
        ruleId: rule['id'],
        name: rule['name'] as String?,
        reason: reason,
      ));
      continue;
    }
    applicable.add(rule);
  }
  applicable.sort((a, b) {
    final byPriority = _num(a['priority']).compareTo(_num(b['priority']));
    if (byPriority != 0) return byPriority;
    return _num(a['id']).compareTo(_num(b['id']));
  });

  for (final rule in applicable) {
    final type = _str(rule['type']).toUpperCase();
    final name = rule['name'] as String?;
    if (!kPromotionTypes.contains(type)) {
      skipped.add(SkippedPromotion(
          ruleId: rule['id'], name: name, reason: 'unknown_type'));
      continue;
    }

    if (type == promotionEveryNthFree) {
      final res = _calcEveryNthFree(rule, buyable);
      if (res.skip != null) {
        skipped.add(SkippedPromotion(
          ruleId: rule['id'],
          name: name,
          reason: res.skip!,
          targets: _describeTargets(rule),
        ));
      }
      if (res.times > 0) {
        lineFree.addAll(res.lineFree);
        applied.add(AppliedPromotion(
            ruleId: rule['id'], name: name, type: type, times: res.times));
      }
      continue;
    }

    final list = _ruleGifts(rule);
    if (list.isEmpty) {
      skipped.add(SkippedPromotion(
          ruleId: rule['id'], name: name, reason: 'no_gifts'));
      continue;
    }

    final trigger = _triggerTimes(rule, type, buyable);
    if (trigger.skip != null) {
      skipped.add(SkippedPromotion(
        ruleId: rule['id'],
        name: name,
        reason: trigger.skip!,
        targets: _describeTargets(rule),
      ));
    }
    final times = _capTimes(trigger.times, rule);
    if (times <= 0) continue;

    final pct = _giftPercent(rule);
    for (final g in list) {
      final quantity = _giftUnits(rule, g) * times;
      if (quantity <= 0) continue;
      gifts.add(PromotionGift(
        ruleId: rule['id'],
        ruleName: name,
        type: type,
        productId: g['productId'],
        quantity: quantity,
        giftDiscountPercent: pct,
      ));
    }
    applied.add(AppliedPromotion(
        ruleId: rule['id'], name: name, type: type, times: times));
  }

  return PromotionResult(
      gifts: gifts, lineFree: lineFree, applied: applied, skipped: skipped);
}

/// Скидка подарочной позиции: giftDiscountPercent% от её стоимости
/// (100% = бесплатно).
num giftLineDiscount(Map? item) {
  if (!isPromotionGiftItem(item)) return 0;
  final pct =
      item!['giftDiscountPercent'] == null ? 100 : _num(item['giftDiscountPercent']);
  final base = unitPrice(item) * _num(item['quantity']);
  final byPercent = (base * pct) / 100;
  final capped = byPercent < base ? byPercent : base;
  return capped > 0 ? capped : 0;
}
