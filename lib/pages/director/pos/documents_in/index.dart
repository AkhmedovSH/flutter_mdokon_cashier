import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/data_model.dart';
import 'package:kassa/models/director/documents_in_model.dart';
import 'package:kassa/models/filter_model.dart';
import 'package:kassa/widgets/custom_app_bar.dart';
import 'package:kassa/widgets/filter/dropdown.dart';
import 'package:kassa/widgets/filter/period.dart';
import 'package:kassa/widgets/loading_layout.dart';
import 'package:kassa/widgets/table/pagination.dart';
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

  getData() {
    Provider.of<DocumentsInModel>(context, listen: false).getPageList(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FilterModel filterModel = Provider.of<FilterModel>(context, listen: false);
      filterModel.initFilterData({
        'posId': filterModel.posId,
        'startDate': formatDateTime(startDate),
        'endDate': formatDateTime(endDate),
        'organizationId': '',
        'search': '',
        'page': 0,
      });
      Provider.of<DocumentsInModel>(context, listen: false).getPageList(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingLayout(
      onlySecond: true,
      body: Scaffold(
        appBar: CustomAppBar(
          title: 'documents_in',
          leading: true,
          actions: [
            IconButton(
              tooltip: context.tr('create'),
              onPressed: () async {
                DataModel dataModel = Provider.of<DataModel>(context, listen: false);

                Provider.of<DocumentsInModel>(context, listen: false).setDataValue('posId', dataModel.posId);
                Provider.of<DocumentsInModel>(context, listen: false).setDataValue('organizationId', dataModel.organizations[1]['id']);
                context.push('/director/documents-in/create');
              },
              icon: const Icon(UniconsLine.plus_circle),
            ),
            IconButton(
              tooltip: context.tr('filter'),
              onPressed: () async {
                var result = await showFilterDialog();
                if (mounted) {
                  if (result == true) {
                    Provider.of<DocumentsInModel>(context, listen: false).getPageList(context);
                  }
                }
              },
              icon: const Icon(UniconsLine.filter),
            ),
          ],
        ),
        body: Consumer<DocumentsInModel>(
          builder: (context, model, child) {
            print(model.totalCount);
            return Column(
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
                      DataColumn(
                        label: SizedBox(
                          width: 100,
                          child: Text(
                            context.tr('action'),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                    ],
                    rows: [
                      for (var i = 0; i < model.pageList.length; i++)
                        DataRow(
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 40,
                                child: Text('${model.pageList[i]['rowNum']}'),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 130,
                                child: Text('${model.pageList[i]['posName']}'),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text('${model.pageList[i]['organizationName']}'),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 120,
                                child: Text(
                                  '${formatMoney(model.pageList[i]['totalAmount'])}',
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 120,
                                child: Text(
                                  '${formatMoney(model.pageList[i]['totalAmount'])}',
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 80,
                                child: Text('${model.pageList[i]['currencyName']}'),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 140,
                                child: Text(
                                  '${formatDate(model.pageList[i]['createdDate'])}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text(
                                  '${model.pageList[i]['createdBy'] ?? ''}',
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: model.pageList[i]['completed']
                                    ? SizedBox()
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            onPressed: () async {
                                              await Provider.of<DocumentsInModel>(context, listen: false).getData(context, model.pageList[i]['id']);
                                              context.push('/director/documents-in/create');
                                            },
                                            icon: Icon(UniconsLine.edit_alt),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Pagination(
                  getData: getData,
                  total: model.totalCount,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  showFilterDialog() async {
    return await showFilterModal(
      context,
      children: [
        Dropdown(
          label: 'pos',
          filterKey: 'posId',
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
