/// Суммы ручной скидки F5/F6/F7 по позициям чека.
///
/// Порт `src/helpers/manualDiscount.js` из desktop-кассы.
///
/// Касса не должна записывать скидку в позицию абсолютной суммой: после смены
/// количества старая сумма осталась бы прежней и процент «поехал» бы. Чек хранит
/// ПАРАМЕТРЫ скидки, а суммы пересчитываются этой функцией после каждого
/// изменения корзины — поэтому со скидкой можно добавлять товар, менять
/// количество и цену.
///
/// Скидка всегда раскидывается по позициям, а не хранится одной суммой на чек:
/// именно построчная скидка уходит в печатный чек.
library;

/// Вид ручной скидки на весь чек: F5 — процент, F6 — сумма.
enum ManualDiscountKey { f5, f6 }

/// Ручная скидка на весь чек.
class ManualDiscount {
  const ManualDiscount(this.key, this.value);

  final ManualDiscountKey key;
  final num value;
}

num _num(dynamic v) {
  if (v is num) return v.isFinite ? v : 0;
  final n = num.tryParse('$v');
  return (n != null && n.isFinite) ? n : 0;
}

num _clamp(dynamic value, num min, num max) {
  final v = _num(value);
  if (v < min) return min;
  if (v > max) return max;
  return v;
}

/// Сумма скидки по каждой позиции, не больше её стоимости.
///
/// [base] — стоимость позиций (цена × количество).
/// [fixed] — фиксированная сумма скидки на позицию (F7); `null` в элементе
/// означает, что скидка на эту позицию не задана.
/// [manualDiscount] — скидка на весь чек (F5/F6) или `null`.
List<num> manualDiscountAmounts(
  List<num>? base,
  List<num?>? fixed,
  ManualDiscount? manualDiscount,
) {
  final lines = (base ?? const <num>[]).map<num>(_num).toList();
  final overrides = fixed ?? const <num?>[];
  final key = manualDiscount?.key;
  final gross = lines.fold<num>(0, (s, b) => s + b);

  List<num> amounts;
  if (key == ManualDiscountKey.f5) {
    final percent = _clamp(manualDiscount!.value, 0, 100);
    amounts = lines.map<num>((b) => (b * percent) / 100).toList();
  } else if (key == ManualDiscountKey.f6) {
    // Сумма скидки фиксирована: раскидываем пропорционально стоимости позиций,
    // последней отдаём остаток — тогда Σ по позициям совпадает с введённой суммой.
    final total = _clamp(manualDiscount!.value, 0, gross);
    num allocated = 0;
    amounts = List<num>.generate(lines.length, (i) {
      final share = i == lines.length - 1
          ? total - allocated
          : (gross != 0 ? (total * lines[i]) / gross : 0);
      allocated += share;
      return share;
    });
  } else {
    amounts = List<num>.filled(lines.length, 0);
  }

  // F7 перекрывает процент/сумму чека по своей позиции. Скидка не может съесть
  // больше стоимости позиции — иначе итог строки уйдёт в минус.
  return List<num>.generate(amounts.length, (i) {
    final override = i < overrides.length ? overrides[i] : null;
    return _clamp(override ?? amounts[i], 0, lines[i]);
  });
}
