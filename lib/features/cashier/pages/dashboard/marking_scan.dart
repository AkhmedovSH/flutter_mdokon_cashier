import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/data/marking_repository.dart';
import 'package:flutter_mdokon/features/cashier/domain/marking_warning.dart';
import 'package:flutter_mdokon/features/cashier/domain/scanned_input.dart';

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
