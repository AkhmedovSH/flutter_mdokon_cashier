import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '/helpers/api.dart';
import '/helpers/helper.dart';
import '/models/data_model.dart';
import '/models/director/documents_in_model.dart';
import '/models/filter_model.dart';
import '/models/loading_model.dart';
import '/widgets/custom_app_bar.dart';
import '/widgets/filter/date.dart';
import '/widgets/filter/dropdown.dart';
import '/widgets/filter/search.dart';
import '/widgets/table/table.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class PosBalance extends StatefulWidget {
  const PosBalance({super.key});

  @override
  _PosBalanceState createState() => _PosBalanceState();
}

class _PosBalanceState extends State<PosBalance> {
  int totalCount = 0;
  List data = [];

  Future<void> getData() async {
    Provider.of<LoadingModel>(context, listen: false).showLoader();
    FilterModel filterModel = Provider.of<FilterModel>(context, listen: false);
    final response = await pget(
      '/services/web/api/report-balance-product/${filterModel.currentFilterData['currencyId']}',
      payload: filterModel.currentFilterData,
    );
    print(response);
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
        'organizationId': '',
        'seasonal': '',
        'dateBalance': '',
        'currencyId': 1,
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
        title: 'balance_report',
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
                    child: Text(context.tr('name_of_product')),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Text(
                      context.tr('barcode'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 120,
                    child: Text(
                      context.tr('quantity'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 100,
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
                          child: Tooltip(
                            message: data[i]['productName'],
                            triggerMode: TooltipTriggerMode.tap,
                            child: Text(
                              '${data[i]['productName']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Text(
                            '${data[i]['productBarcode']}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${formatMoney(data[i]['balance'])} ${data[i]['uomName']}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 100,
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
          label: 'seasonal',
          filterKey: 'seasonal',
          items: Provider.of<DataModel>(context, listen: false).seasons,
          translate: true,
        ),
        Date(
          label: 'date',
          filterKey: 'dateBalance',
        )
        // Dropdown(
        //   label: 'user',
        //   filterKey: 'cashier_login',
        //   items: Provider.of<DataModel>(context, listen: false).cashiers,
        //   itemName: 'first_name',
        //   itemValue: 'login',
        // ),
      ],
    );
  }
}
