import 'package:flutter_mdokon/features/cashier/data/marking_repository.dart';

/// Насколько серьёзно предупреждение о коде маркировки.
///
/// Продажу не блокируем ни в одном случае (см. [MarkingRepository]): «не проверен» —
/// это чаще всего отсутствие связи, а касса обязана работать офлайн. Но
/// «не зарегистрирован» и «выведен из оборота» кассир должен увидеть как ошибку.
enum MarkingWarningLevel { none, warning, danger }

MarkingWarningLevel markingWarningLevel(MarkingStatus status) => switch (status) {
      MarkingStatus.ok => MarkingWarningLevel.none,
      MarkingStatus.unknown => MarkingWarningLevel.warning,
      MarkingStatus.notRegistered => MarkingWarningLevel.danger,
      MarkingStatus.withdrawn => MarkingWarningLevel.danger,
    };
