import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/domain/marking_item.dart';
import 'package:flutter_mdokon/features/cashier/domain/scanned_input.dart';
import 'package:flutter_mdokon/features/cashier/models/sale_model.dart';
import 'package:flutter_mdokon/features/cashier/pages/dashboard/marking_scan.dart';
import 'package:flutter_mdokon/shared/widgets/scanner/barcode_scanner_page.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Список кодов маркировки позиции: по коду на единицу товара.
///
/// Количество такой позиции = число кодов, поэтому «+» здесь — это сканирование
/// нового кода, а «−» — удаление конкретного кода из списка.
Future<void> showMarkingCodesSheet(
  BuildContext context,
  SaleModel model,
  int index, {
  bool scanImmediately = false,
}) {
  return AppModal.sheet<void>(
    context,
    builder: (ctx) => _MarkingCodesBody(
      model: model,
      index: index,
      scanImmediately: scanImmediately,
    ),
  );
}

class _MarkingCodesBody extends StatefulWidget {
  final SaleModel model;
  final int index;
  final bool scanImmediately;

  const _MarkingCodesBody({
    required this.model,
    required this.index,
    required this.scanImmediately,
  });

  @override
  State<_MarkingCodesBody> createState() => _MarkingCodesBodyState();
}

class _MarkingCodesBodyState extends State<_MarkingCodesBody> {
  @override
  void initState() {
    super.initState();
    if (widget.scanImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
    }
  }

  Map? get _item {
    final items = widget.model.items;
    if (widget.index < 0 || widget.index >= items.length) return null;
    return items[widget.index] as Map;
  }

  /// Отсканировать ещё один код на ту же позицию.
  Future<void> _scan() async {
    final result = await BarcodeScannerPage.scan(context);
    if (result == null || !mounted) return;

    final scanned = parseScannedInput(result);
    if (!scanned.isMarking) {
      showDangerToast(context.tr('marking_not_checked'));
      return;
    }
    // Предупреждение показываем, но добавить код всё равно даём:
    // касса обязана работать и без связи с ЦРПТ.
    await checkScannedMarking(context, scanned, widget.model.cashbox['posId']);
    if (!mounted) return;

    widget.model.addMarkingCodeToLine(widget.index, scanned.marking!.code);
    setState(() {});
  }

  void _remove(String code) {
    final wasLast = markingCodes(_item).length <= 1;
    widget.model.removeMarkingCodeFromLine(widget.index, code);
    if (!mounted) return;
    // Последний код удаляет саму позицию — листу больше нечего показывать.
    if (wasLast) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final codes = markingCodes(item);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('marking_codes'), style: AppText.h2),
        const SizedBox(height: AppDimens.gap4),
        Text(
          '${item?['productName'] ?? ''} · ${codes.length}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.small,
        ),
        const SizedBox(height: AppDimens.gap16),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: codes.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppDimens.gap8),
            itemBuilder: (_, i) => _CodeRow(
              number: i + 1,
              code: codes[i],
              onRemove: () => _remove(codes[i]),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.gap16),
        AppButton(
          label: context.tr('scan_code'),
          icon: UniconsLine.qrcode_scan,
          onPressed: _scan,
        ),
      ],
    );
  }
}

class _CodeRow extends StatelessWidget {
  final int number;
  final String code;
  final VoidCallback onRemove;

  const _CodeRow({required this.number, required this.code, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppDimens.gap12),
      child: Row(
        children: [
          Text('$number', style: AppText.small),
          const SizedBox(width: AppDimens.gap12),
          Expanded(
            child: Text(
              markingLabel(code),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.tabular(AppText.bodyMedium),
            ),
          ),
          AppIconButton(
            icon: UniconsLine.trash_alt,
            background: Colors.transparent,
            foreground: AppColors.dangerText,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
