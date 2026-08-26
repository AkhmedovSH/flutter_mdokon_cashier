/// Перевод чека из формата кассы в серверный.
///
/// Пока чек набирается, `totalPrice` — это НЕТТО, сумма к оплате: на ней
/// построен весь поток оплаты (`CashboxModel`, `payment_sample.dart`).
/// Сервер (`cheque-v2`) и печать ждут БРУТТО и отдельную сумму скидки —
/// они сами вычитают `discountAmount`. Без конвертации скидка вычиталась бы
/// дважды.
library;

import 'package:flutter_mdokon/core/utils/helper.dart';

/// Копия чека в серверном формате: `totalPrice` — БРУТТО, скидка отдельно.
Map<String, dynamic> toGrossCheque(Map data) {
  final copy = Map<String, dynamic>.from(data);
  final gross = customNumber(data['totalPriceBeforeDiscount']);

  copy['totalPrice'] = gross > 0 ? gross : customNumber(data['totalPrice']);
  copy['discountAmount'] = customNumber(data['discountAmount']);

  final items = data['itemsList'];
  if (items is List) {
    copy['itemsList'] = items.map((item) {
      if (item is! Map) return item;
      final line = Map<String, dynamic>.from(item);
      final lineGross = customNumber(item['totalPriceBeforeDiscount']);
      line['totalPrice'] = lineGross > 0 ? lineGross : customNumber(item['totalPrice']);
      return line;
    }).toList();
  }
  return copy;
}
