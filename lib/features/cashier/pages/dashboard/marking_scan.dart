import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/data/marking_repository.dart';
import 'package:flutter_mdokon/features/cashier/domain/marking_warning.dart';
import 'package:flutter_mdokon/features/cashier/domain/marking.dart';
import 'package:flutter_mdokon/features/cashier/domain/marking_item.dart';
import 'package:flutter_mdokon/features/cashier/domain/scanned_input.dart';
import 'package:flutter_mdokon/shared/widgets/scanner/barcode_scanner_page.dart';

/// Проверить отсканированный код маркировки и предупредить кассира.
///
/// Обычный штрих-код на сервер не уходит вовсе. Проверка ничего не блокирует:
/// «не проверен» — жёлтый тост, «не зарегистрирован» / «выведен из оборота» — красный,
/// но добавить товар в чек можно в любом случае.
Future<MarkingCheckResult?> checkScannedMarking(
  BuildContext context,
  ScannedInput scanned,
  dynamic posId, {
  MarkingRepository repository = const MarkingRepository(),
}) async {
  if (!scanned.isMarking) return null;

  final result = await repository.check(scanned.marking!.code, posId);
  if (!context.mounted) return result;

  final key = result.warningKey;
  if (key == null) return result;

  final message = context.tr(key);
  switch (markingWarningLevel(result.status)) {
    case MarkingWarningLevel.danger:
      showDangerToast(message);
    case MarkingWarningLevel.warning:
      showWarningToast(message);
    case MarkingWarningLevel.none:
      break;
  }
  return result;
}

/// Барьер маркировки перед добавлением товара в чек (порт `Tab.js`).
///
/// Маркировочный товар в чек без кода не кладём: по коду на единицу — этим
/// количество такой позиции и задаётся, степпером его потом не поправить.
/// Один штрих-код с упаковки кода не несёт (он в DataMatrix акцизной марки),
/// поэтому подбор руками, быстрый выбор и скан обычного EAN приводят сюда:
/// сразу открываем сканер, отмена означает «товар не добавлен».
///
/// Возвращает `true`, если добавлять можно: товар не маркировочный либо код
/// уже записан в [product] — оттуда его заберёт `SaleModel.addScannedProducts`.
Future<bool> ensureMarkingCode(
  BuildContext context,
  Map product,
  dynamic posId, {
  MarkingRepository repository = const MarkingRepository(),
}) async {
  if (!isMarkingItem(product)) return true;
  if (normalizeScannedCode(product['markingNumber']).isNotEmpty) return true;

  final result = await BarcodeScannerPage.scan(
    context,
    hint: context.tr('scanner_aim_marking_hint'),
  );
  if (!context.mounted) return false;
  if (result == null) {
    // Кассир вышел из сканера: молча ничего не добавлять — это «кнопка не
    // сработала», поэтому говорим, чего не хватило.
    showWarningToast(context.tr('marking_code_required'));
    return false;
  }

  final scanned = parseScannedInput(result);
  if (!scanned.isMarking) {
    showDangerToast(context.tr('marking_code_required'));
    return false;
  }

  // Предупреждение ЦРПТ показываем, но продажу не блокируем: касса обязана
  // работать и без связи — то же правило, что и в листе кодов позиции.
  await checkScannedMarking(context, scanned, posId, repository: repository);
  if (!context.mounted) return false;

  product['markingNumber'] = scanned.marking!.code;
  return true;
}
