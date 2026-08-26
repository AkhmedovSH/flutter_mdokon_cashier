import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/domain/marking_item.dart';
import 'package:flutter_mdokon/features/cashier/domain/return_marking.dart';
import 'package:flutter_mdokon/features/cashier/domain/scanned_input.dart';
import 'package:flutter_mdokon/shared/widgets/scanner/barcode_scanner_page.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Выбор кодов маркировки к возврату.
///
/// Количество такой позиции задаётся не степпером, а кодами: покупатель принёс
/// конкретные пачки. Кассир либо сканирует их, либо отмечает в списке кодов чека
/// — второе нужно, когда код затёрт и камера его не берёт.
///
/// Возвращает новый список отмеченных кодов; `null` — кассир закрыл лист без изменений.
Future<List<String>?> showReturnMarkingSheet(
  BuildContext context, {
  required Map item,
  required List<String> selected,
  required num limit,
  bool scanImmediately = false,
}) {
  return AppModal.sheet<List<String>>(
    context,
    builder: (ctx) => _ReturnMarkingBody(
      item: item,
      selected: selected,
      limit: limit,
      scanImmediately: scanImmediately,
    ),
  );
}

class _ReturnMarkingBody extends StatefulWidget {
  final Map item;
  final List<String> selected;
  final num limit;
  final bool scanImmediately;

  const _ReturnMarkingBody({
    required this.item,
    required this.selected,
    required this.limit,
    required this.scanImmediately,
  });

  @override
  State<_ReturnMarkingBody> createState() => _ReturnMarkingBodyState();
}

class _ReturnMarkingBodyState extends State<_ReturnMarkingBody> {
  late List<String> available = markingCodes(widget.item);
  late List<String> selected = List<String>.from(widget.selected);

  @override
  void initState() {
    super.initState();
    if (widget.scanImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
    }
  }

  int get _cap => widget.limit > 0 ? widget.limit.toInt() : available.length;

  /// Отсканировать принесённую пачку. В отличие от продажи, сервер здесь не нужен:
  /// достаточно того, что код есть в этом чеке.
  Future<void> _scan() async {
    final result = await BarcodeScannerPage.scan(context);
    if (result == null || !mounted) return;

    final scanned = parseScannedInput(result);
    _add(scanned.marking?.code ?? result);
  }

  void _add(String code) {
    final selection = selectReturnCode(
      available: available,
      selected: selected,
      code: code,
      limit: widget.limit,
    );

    switch (selection.result) {
      case ReturnCodeResult.added:
        setState(() => selected = selection.codes);
      case ReturnCodeResult.notFound:
        showDangerToast(context.tr('marking_not_found'));
      case ReturnCodeResult.duplicate:
        showWarningToast(context.tr('marking_already_scanned'));
      case ReturnCodeResult.limitExceeded:
        showDangerToast(context.tr('marking_return_limit'));
    }
  }

  void _toggle(String code) {
    if (selected.contains(code)) {
      setState(() => selected = [...selected]..remove(code));
      return;
    }
    _add(code);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('select_marking_codes'), style: AppText.h2),
        const SizedBox(height: AppDimens.gap4),
        Text(
          '${widget.item['productName'] ?? ''} · ${selected.length}/$_cap',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.small,
        ),
        const SizedBox(height: AppDimens.gap16),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: available.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppDimens.gap8),
            itemBuilder: (_, i) => _CodeRow(
              number: i + 1,
              code: available[i],
              checked: selected.contains(available[i]),
              onTap: () => _toggle(available[i]),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.gap16),
        Row(
          children: [
            Expanded(
              child: AppButton.soft(
                label: context.tr('scan_code'),
                icon: UniconsLine.qrcode_scan,
                onPressed: _scan,
              ),
            ),
            const SizedBox(width: AppDimens.gap8),
            Expanded(
              child: AppButton(
                label: context.tr('apply'),
                onPressed: () => Navigator.of(context).pop(selected),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CodeRow extends StatelessWidget {
  final int number;
  final String code;
  final bool checked;
  final VoidCallback onTap;

  const _CodeRow({
    required this.number,
    required this.code,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppDimens.gap12),
      color: checked ? AppColors.dangerSoft : null,
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
          Icon(
            checked ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: checked ? AppColors.danger : AppColors.iconMuted,
          ),
        ],
      ),
    );
  }
}
