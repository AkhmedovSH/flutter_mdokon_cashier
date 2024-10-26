import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kassa/helpers/api.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/data_model.dart';
import 'package:kassa/models/filter_model.dart';
import 'package:kassa/models/loading_model.dart';
import 'package:kassa/widgets/custom_app_bar.dart';
import 'package:kassa/widgets/filter/dropdown.dart';
import 'package:kassa/widgets/filter/period.dart';
import 'package:kassa/widgets/table/table.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class DocumentsIn extends StatefulWidget {
  const DocumentsIn({super.key});

  @override
  _DocumentsInState createState() => _DocumentsInState();
}

class _DocumentsInState extends State<DocumentsIn> {
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month - 1, DateTime.now().day);
  DateTime endDate = DateTime.now();

  int totalCount = 0;
  List data = [];

  Future<void> getData() async {
    Provider.of<LoadingModel>(context, listen: false).showLoader();
    print(Provider.of<FilterModel>(context, listen: false).currentFilterData);
    final response = await pget(
      '/services/web/api/documents-in-pageList',
      payload: Provider.of<FilterModel>(context, listen: false).currentFilterData,
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
      print(Provider.of<FilterModel>(context, listen: false).posId);
      Provider.of<FilterModel>(context, listen: false).initFilterData({
        'posId': Provider.of<FilterModel>(context, listen: false).posId,
        'startDate': formatDateTime(startDate),
        'endDate': formatDateTime(endDate),
        'organizationId': '',
        'search': '',
        'page': 1,
      });
      getData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'documents_in',
        leading: true,
        actions: [
          IconButton(
            tooltip: context.tr('create'),
            onPressed: () {
              context.go('/director/documents-in/create');
            },
            icon: const Icon(UniconsLine.plus_circle),
          ),
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
                    width: 100,
                    child: Text(context.tr('supplier')),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 120,
                    child: Text(
                      context.tr('receipt_amount'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 120,
                    child: Text(
                      context.tr('sale_amount'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 80,
                    child: Text(context.tr('currency')),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 140,
                    child: Text(
                      context.tr('date_of_receipt'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 100,
                    child: Text(
                      context.tr('received_by'),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
              ],
              rows: [
                for (var i = 1; i < data.length; i++)
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
                          width: 100,
                          child: Text('${data[i]['organizationName']}'),
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
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            '${formatMoney(data[i]['totalAmount'])}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 80,
                          child: Text('${data[i]['currencyName']}'),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 140,
                          child: Text(
                            '${formatDate(data[i]['createdDate'])}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 100,
                          child: Text(
                            '${data[i]['createdBy'] ?? ''}',
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
        Dropdown(
          label: 'pos',
          filterKey: 'pos_id',
          items: Provider.of<DataModel>(context, listen: false).poses,
        ),
        // Dropdown(
        //   label: 'user',
        //   filterKey: 'cashier_login',
        //   items: Provider.of<DataModel>(context, listen: false).cashiers,
        //   itemName: 'first_name',
        //   itemValue: 'login',
        // ),
        const Period(),
      ],
    );
  }
}
