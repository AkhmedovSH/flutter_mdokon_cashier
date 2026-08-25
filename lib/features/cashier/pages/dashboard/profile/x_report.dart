import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mdokon/features/cashier/models/dashboard_model.dart';
import 'package:flutter_mdokon/features/cashier/models/printer_model.dart';
import 'package:flutter_mdokon/core/state/loading_model.dart';
import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/shared/widgets/ui/app_responsive.dart';
import 'package:flutter_mdokon/shared/widgets/loading_layout.dart';

import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';

class XReport extends StatefulWidget {
  const XReport({super.key});

  @override
  State<XReport> createState() => _XReportState();
}

class _XReportState extends State<XReport> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GetStorage storage = GetStorage();

  Map report = {};
  List reportList = [];
  Map cashbox = {};

  Future<void> printXReport({bool zReport = false}) async {
    final labels = {
      'x_report': context.tr('x_report'),
      'z_report': context.tr('z_report'),
      'phone': context.tr('phone'),
      'cashier': context.tr('cashier'),
      'shift_ID': context.tr('shift_ID'),
      'cashbox_number': context.tr('cashbox_number'),
      'inn': context.tr('inn'),
      'date': context.tr('date'),
      'shift_duration': context.tr('shift_duration'),
      'number_of_receipts': context.tr('number_of_receipts'),
      'number_of_returned_receipts': context.tr('number_of_returned_receipts'),
      'number_of_returned_products': context.tr('number_of_returned_products'),
      'deleted': context.tr('deleted'),
      'sales_amount': context.tr('sales_amount'),
      'discount_amount': context.tr('discount_amount'),
      'return_amount': context.tr('return_amount'),
      'income': context.tr('income'),
      'expense': context.tr('expense'),
      'cashbox_balance': context.tr('cashbox_balance'),
      'total_cash': context.tr('total_cash'),
      'total_bank': context.tr('total_bank'),
      'number_of_x_reports': context.tr('number_of_x_reports'),
    };

    LoadingModel loadingModel = Provider.of<LoadingModel>(context, listen: false);
    PrinterModel printerModel = Provider.of<PrinterModel>(context, listen: false);
    loadingModel.showLoader(num: 2);
    await Future.delayed(Duration(milliseconds: 100));
    report['isZReport'] = zReport;
    if (context.mounted) await printerModel.printXReport(report, cashbox, labels);
    loadingModel.hideLoader();
  }

  void closeShift() async {
    LoadingModel loadingModel = Provider.of<LoadingModel>(context, listen: false);
    loadingModel.showLoader(num: 2);

    int id = 0;
    dynamic shift = {'id': null};
    Map response = {
      'success': true,
    };
    if (storage.read('shift') != null) {
      shift = (storage.read('shift')!);
    }
    if (shift['id'] != null) {
      id = shift['id'];
    } else {
      id = cashbox['id'];
    }
    response = await post('/services/desktop/api/close-shift', {
      'cashboxId': cashbox['cashboxId'],
      'posId': cashbox['posId'],
      'offline': false,
      'id': id,
    });

    storage.remove('user');
    if (response['success'] && mounted) {
      printXReport(zReport: true);
      Provider.of<DashboardModel>(context, listen: false).setCurrentIndex(0);
      context.pushReplacement('/auth');
    }
  }

  Future<void> getReport() async {
    LoadingModel loaderModel = Provider.of<LoadingModel>(context, listen: false);

    loaderModel.showLoader(num: 2);

    final prefsCashbox = storage.read('cashbox');
    int cashboxId = 0;
    if (prefsCashbox['id'] != null) {
      cashboxId = prefsCashbox['id'];
      cashbox = prefsCashbox;
    } else {
      final shift = (storage.read('shift')!);
      cashboxId = shift['id'];
      cashbox = shift;
    }
    final response = await get('/services/desktop/api/shift-xreport-v2/$cashboxId');
    loaderModel.hideLoader();

    report = response;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getReport();
    });
  }

  bool get isZReport => report['isZReport'] == true;

  @override
  Widget build(BuildContext context) {
    return LoadingLayout(
      body: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.canvas,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ContentBox(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildSections(),
                  ),
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- шапка

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(UniconsLine.arrow_left, size: 28, color: AppColors.textPrimary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isZReport ? context.tr('z_report') : context.tr('x_report'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _headerSubtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    final salesAmount = _first(report['salesList'])?['salesAmount'] ?? 0;
    final balance = _first(report['balanceList'])?['balance'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: _statCard(context.tr('sales'), formatMoney(salesAmount))),
          const SizedBox(width: 10),
          Expanded(child: _statCard(context.tr('in_cashbox'), formatMoney(balance))),
          const SizedBox(width: 10),
          Expanded(child: _statCard(context.tr('receipts'), '${report['totalCountCheque'] ?? 0}')),
        ],
      ),
    );
  }

  String _headerSubtitle() {
    final parts = <String>[];
    if ((report['posName'] ?? '').toString().isNotEmpty) parts.add('${report['posName']}');
    parts.add(isZReport ? context.tr('report_final') : context.tr('report_intermediate'));
    if (report['shiftNumber'] != null) parts.add('${context.tr('shift')} ${report['shiftNumber']}');
    return parts.join(' · ');
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: _panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.iconMuted,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- тело

  List<Widget> _buildSections() {
    final sections = <Widget>[_buildStatCards()];

    // СМЕНА
    final tin = report['tin'] ?? cashbox['tin'];
    sections.add(_sectionLabel(context.tr('shift')));
    sections.add(_panel([
      if (tin != null) _row(context.tr('inn'), '$tin'),
      _row(context.tr('cashier'), '${report['cashierName'] ?? ''}'),
      _row(context.tr('cashbox'), '${report['cashboxName'] ?? cashbox['cashboxName'] ?? report['shiftNumber'] ?? ''}'),
      _row(context.tr('shift_open_date'), '${report['shiftOpenDate'] ?? ''}'),
      _row(context.tr('opening_cash'), formatMoney(report['openingCash'] ?? 0)),
      if (report['shiftId'] != null) _row('${context.tr('shift')} ID', '${report['shiftId']}'),
      if (report['shiftDuration'] != null) _row(context.tr('shift_duration'), '${report['shiftDuration']}'),
    ]));

    // ЧЕКИ
    final totalCheque = report['totalCountCheque'] ?? 0;
    sections.add(_sectionLabel(context.tr('cheques_section')));
    sections.add(_panel([
      _row(context.tr('receipts'), '$totalCheque'),
      _row(context.tr('number_of_returned_receipts'), '${report['countReturnedCheque'] ?? 0}',
          muted: (report['countReturnedCheque'] ?? 0) == 0),
      _row(context.tr('number_of_returned_products'), '${report['countReturnedProducts'] ?? 0}',
          muted: (report['countReturnedProducts'] ?? 0) == 0),
      if ((report['countDeletedCheque'] ?? 0) > 0)
        _row('${context.tr('number_of_receipts')} [${context.tr('deleted')}]', '${report['countDeletedCheque']}'),
      if ((report['countDeletedProducts'] ?? 0) > 0)
        _row('${context.tr('number_of_products')} [${context.tr('deleted')}]', '${report['countDeletedProducts']}'),
      if ((report['countChequeUget'] ?? 0) > 0) _row('uGet', '${report['countChequeUget']}'),
      if ((report['countChequeUget'] ?? 0) > 0) _row(context.tr('cashback'), formatMoney(report['ugetBonus'] ?? 0)),
      if (totalCheque > 0)
        _row(
          context.tr('average_check'),
          formatMoney(((_first(report['salesList'])?['salesAmount'] ?? 0) / totalCheque).round()),
        ),
    ]));

    // СУММЫ
    final salesList = report['salesList'];
    if (salesList is List && salesList.isNotEmpty) {
      for (final item in salesList) {
        sections.add(_sectionLabel(
          '${context.tr('amounts_section')}${salesList.length > 1 ? ' (${item['currencyName'] ?? ''})' : ''}',
        ));
        sections.add(_panel([
          _row(context.tr('sales_amount'), formatMoney(item['salesAmount'] ?? 0)),
          _row(
            context.tr('discount_amount'),
            '${(item['discountAmount'] ?? 0) > 0 ? '−' : ''}${formatMoney(item['discountAmount'] ?? 0)}',
            color: (item['discountAmount'] ?? 0) > 0 ? AppColors.warningText : null,
            muted: (item['discountAmount'] ?? 0) == 0,
          ),
          _row(context.tr('return_amount'), formatMoney(item['returnAmount'] ?? 0),
              muted: (item['returnAmount'] ?? 0) == 0),
          if (item['debtAmount'] != null)
            _row(context.tr('debt_amount'), formatMoney(item['debtAmount'] ?? 0),
                color: (item['debtAmount'] ?? 0) > 0 ? AppColors.dangerText : null,
                muted: (item['debtAmount'] ?? 0) == 0),
          if (item['ugetAmount'] != null)
            _row(context.tr('uget_paid'), formatMoney(item['ugetAmount'] ?? 0), muted: (item['ugetAmount'] ?? 0) == 0),
        ]));
      }
    }

    // ДВИЖЕНИЕ ПО КАССЕ
    final xReportList = report['xReportList'];
    if (xReportList is List && xReportList.isNotEmpty) {
      final rows = <Widget>[];
      for (final item in xReportList) {
        final name = '${item['paymentTypeName'] ?? ''} ${item['paymentPurposeName'] ?? ''}'.trim();
        if ((item['amountIn'] ?? 0) != 0) {
          rows.add(_row('$name · ${context.tr('income')}', formatMoney(item['amountIn'])));
        }
        if ((item['amountOut'] ?? 0) != 0) {
          rows.add(_row('$name · ${context.tr('expense')}', formatMoney(item['amountOut']), color: AppColors.dangerText));
        }
      }
      if (rows.isNotEmpty) {
        sections.add(_sectionLabel(context.tr('cash_movement')));
        sections.add(_panel(rows));
      }
    }

    // ПРИХОД · ФАКТИЧЕСКАЯ СУММА
    final factRows = <Widget>[];
    final amountInList = report['amountInList'];
    if (amountInList is List) {
      for (final item in amountInList) {
        factRows.add(_factRow(
          color: item['paymentTypeId'] == 1 ? AppColors.success : AppColors.primary,
          name: '${item['paymentTypeName'] ?? ''} ${item['paymentPurposeName'] ?? ''}'.trim(),
          amount: formatMoney(item['amountIn'] ?? 0),
          currency: '${item['currencyName'] ?? ''}',
        ));
      }
    }
    final amountOutList = report['amountOutList'];
    if (amountOutList is List) {
      for (final item in amountOutList) {
        factRows.add(_factRow(
          color: AppColors.danger,
          name: '${item['paymentTypeName'] ?? ''} ${item['paymentPurposeName'] ?? ''} · ${context.tr('expense')}'.trim(),
          amount: formatMoney(item['amountOut'] ?? 0),
          currency: '${item['currencyName'] ?? ''}',
        ));
      }
    }

    final totalRows = <Widget>[];
    final balanceList = report['balanceList'];
    if (balanceList is List) {
      for (final item in balanceList) {
        totalRows.add(_totalRow(
          context.tr('cashbox_balance'),
          '${formatMoney(item['balance'] ?? 0)}${balanceList.length > 1 ? ' ${item['currencyName'] ?? ''}' : ''}',
        ));
      }
    }

    final subRows = <Widget>[];
    final totalList = report['totalList'];
    if (totalList is List) {
      for (final item in totalList) {
        if ((item['totalCash'] ?? 0) > 0) {
          subRows.add(_subRow('${context.tr('total_cash')} (${item['currencyName'] ?? ''})', formatMoney(item['totalCash'])));
        }
        if ((item['totalBank'] ?? 0) > 0) {
          subRows.add(_subRow('${context.tr('total_bank')} (${item['currencyName'] ?? ''})', formatMoney(item['totalBank'])));
        }
        if ((item['totalExpense'] ?? 0) > 0) {
          subRows.add(_subRow('${context.tr('total_expense')} (${item['currencyName'] ?? ''})', formatMoney(item['totalExpense'])));
        }
      }
    }
    if ((report['countRequest'] ?? 0) > 0) {
      subRows.add(_subRow(context.tr('number_of_x_reports'), '${report['countRequest']}'));
    }

    if (factRows.isNotEmpty || totalRows.isNotEmpty || subRows.isNotEmpty) {
      sections.add(_sectionLabel(context.tr('actual_income_amount')));
      sections.add(Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        decoration: _panelDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._withDividers(factRows),
            ...totalRows,
            ...subRows,
          ],
        ),
      ));
    }

    return sections;
  }

  Map? _first(dynamic list) {
    if (list is List && list.isNotEmpty && list.first is Map) return list.first as Map;
    return null;
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.iconMuted,
        ),
      ),
    );
  }

  BoxDecoration get _panelDecoration => BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      );

  Widget _panel(List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withDividers(rows),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> rows) {
    final result = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      result.add(rows[i]);
      if (i != rows.length - 1) {
        result.add(Divider(height: 1, thickness: 1, color: AppColors.divider));
      }
    }
    return result;
  }

  Widget _row(String label, String value, {bool muted = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color ?? (muted ? AppColors.iconMuted : AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _factRow({required Color color, required String name, required String amount, required String currency}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          if (currency.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(currency, style: TextStyle(fontSize: 11.5, color: AppColors.iconMuted)),
          ],
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _subRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.iconMuted))),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.iconMuted)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- футер

  Widget _buildFooter() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => printXReport(),
                    icon: const Icon(UniconsLine.print, size: 18),
                    label: Text(
                      '${context.tr('print')} ${isZReport ? context.tr('z_report') : context.tr('x_report')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => openModal(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerText,
                      side: BorderSide(color: AppColors.border),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      context.tr('close_shift'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(21),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.only(
            top: 15,
            right: 15,
            left: 15,
            bottom: 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(21),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('are_you_sure_you_want_to_close_your_shift'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          context.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.canvas,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          context.tr('cancel'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () async {
                          context.pop();
                          closeShift();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          context.tr('confirm'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
