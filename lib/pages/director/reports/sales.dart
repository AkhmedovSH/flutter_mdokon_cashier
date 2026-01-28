import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '/helpers/api.dart';
import '/helpers/helper.dart';
import '/models/data_model.dart';
import '/models/director/documents_in_model.dart';
import '/models/filter_model.dart';
import '/models/loading_model.dart';

import '/widgets/custom_app_bar.dart';
import '/widgets/filter/dropdown.dart';
import '/widgets/filter/period.dart';
import '/widgets/filter/search.dart';
import '/widgets/filter/switch.dart';
import '/widgets/table/table.dart';

import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class PosSales extends StatefulWidget {
  const PosSales({super.key});

  @override
  _PosSalesState createState() => _PosSalesState();
}

class _PosSalesState extends State<PosSales> {
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month - 1, DateTime.now().day);
  DateTime endDate = DateTime.now();

  int totalCount = 0;
  List data = [];

  Future<void> getData() async {
    Provider.of<LoadingModel>(context, listen: false).showLoader();
    FilterModel filterModel = Provider.of<FilterModel>(context, listen: false);
    final response = await pget(
      '/services/web/api/report-sales',
      payload: filterModel.currentFilterData,
    );
    if (mounted) {
      if (httpOk(response)) {
        setState(() {
          data = response['data'];
          totalCount = response['total'];
        });
      }
      Provider.of<LoadingModel>(context, listen: false).hideLoader();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FilterModel filterModel = Provider.of<FilterModel>(context, listen: false);
      DataModel dataModel = Provider.of<DataModel>(context, listen: false);
      Provider.of<DocumentsInModel>(context, listen: false).setDataValue('posId', filterModel.posId);
      Provider.of<DocumentsInModel>(context, listen: false).setDataValue('organizationId', dataModel.organizations[0]['id']);
      Provider.of<FilterModel>(context, listen: false).initFilterData({
        'posId': filterModel.posId,
        'currencyId': 1,
        'startDate': formatDateBackend(startDate),
        'endDate': formatDateBackend(endDate),
        'organizationId': '',
        'seasonal': '',
        'cashierId': '',
        'agentId': '',
        'uomId': '',
        'paymentTypeId': '',
        'groupBy': false,
        'search': '',
        'page': 0,
      });
      getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'sales_report',
        leading: true,
        actions: [
          IconButton(
            tooltip: context.tr('filter'),
            onPressed: () async {
              var result = await showFilterDialog();
              if (mounted) {
                if (result == true) {
                  getData();
                }
              }
            },
            icon: const Icon(UniconsLine.filter),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TableWidget(
              headers: [
                DataColumn(
                  label: SizedBox(
                    width: 40,
                    child: Text('№'),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 130,
                    child: Text(context.tr('pos')),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 200,
                    child: Text(context.tr('supplier')),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Text(context.tr('cashier')),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Text(context.tr('agent')),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 200,
                    child: Text(context.tr('name_of_product')),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 120,
                    child: Text(
                      context.tr('barcode'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 100,
                    child: Text(
                      context.tr('quantity'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 120,
                    child: Text(
                      context.tr('sale_price'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 200,
                    child: Text(
                      context.tr('cheque'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 120,
                    child: Text(
                      context.tr('cheque_date'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 120,
                    child: Text(
                      context.tr('total_amount'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
              ],
              rows: [
                for (var i = 0; i < data.length; i++)
                  DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 40,
                          child: Text('${data[i]['rowNum']}'),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 130,
                          child: Text('${data[i]['posName']}'),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(
                            '${data[i]['organizationName'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            '${data[i]['cashierName']}',
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            '${data[i]['agentName'] ?? '-'}',
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text('${data[i]['productName']}'),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${data[i]['productBarcode']}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 100,
                          child: Text(
                            '${data[i]['quantity']} ${data[i]['uomName']}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${formatMoney(data[i]['salePrice'])}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(
                            '${data[i]['chequeNumber']}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${formatDate(data[i]['chequeDate'])}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${formatMoney(data[i]['totalAmount'])}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  showFilterDialog() async {
    return await showFilterModal(
      context,
      children: [
        Search(),
        Dropdown(
          label: 'pos',
          filterKey: 'posId',
          items: Provider.of<DataModel>(context, listen: false).poses,
        ),
        Dropdown(
          label: 'currency',
          filterKey: 'currencyId',
          items: Provider.of<DataModel>(context, listen: false).currencies,
        ),
        Dropdown(
          label: 'organization',
          filterKey: 'organizationId',
          items: Provider.of<DataModel>(context, listen: false).organizations,
        ),
        Dropdown(
          label: 'cashier',
          filterKey: 'cashierId',
          items: Provider.of<DataModel>(context, listen: false).cashiers,
        ),
        Dropdown(
          label: 'agent',
          filterKey: 'agentId',
          items: Provider.of<DataModel>(context, listen: false).agents,
        ),
        Dropdown(
          label: 'payment_method',
          filterKey: 'paymentTypeId',
          items: Provider.of<DataModel>(context, listen: false).paymentTypes,
        ),
        Dropdown(
          label: 'unit_of_measurement',
          filterKey: 'uomId',
          items: Provider.of<DataModel>(context, listen: false).uoms,
        ),
        Dropdown(
          label: 'seasonal',
          filterKey: 'seasonal',
          items: Provider.of<DataModel>(context, listen: false).seasons,
          translate: true,
        ),
        Period(),
        FilterSwitch(
          label: 'grouping',
          filterKey: 'groupBy',
        ),
      ],
    );
  }
}
