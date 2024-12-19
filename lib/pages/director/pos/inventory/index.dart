import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/data_model.dart';
import 'package:kassa/models/director/inventory_model.dart';
import 'package:kassa/models/filter_model.dart';
import 'package:kassa/widgets/custom_app_bar.dart';
import 'package:kassa/widgets/filter/dropdown.dart';
import 'package:kassa/widgets/filter/period.dart';
import 'package:kassa/widgets/table/pagination.dart';
import 'package:kassa/widgets/table/table.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class Inventory extends StatefulWidget {
  const Inventory({super.key});

  @override
  _InventoryState createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month - 1, DateTime.now().day);
  DateTime endDate = DateTime.now();

  getData() {
    Provider.of<InventoryModel>(context, listen: false).getPageList(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FilterModel filterModel = Provider.of<FilterModel>(context, listen: false);
      Provider.of<FilterModel>(context, listen: false).initFilterData({
        'posId': filterModel.posId,
        'startDate': formatDateTime(startDate),
        'endDate': formatDateTime(endDate),
        'search': '',
        'page': 0,
      });
      Provider.of<InventoryModel>(context, listen: false).getPageList(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'inventory',
        leading: true,
        actions: [
          IconButton(
            tooltip: context.tr('create'),
            onPressed: () {
              DataModel dataModel = Provider.of<DataModel>(context, listen: false);
              Provider.of<InventoryModel>(context, listen: false).clearData();
              Provider.of<InventoryModel>(context, listen: false).setDataValue('posId', dataModel.posId);
              context.go('/director/inventory/create');
            },
            icon: const Icon(UniconsLine.plus_circle),
          ),
          IconButton(
            tooltip: context.tr('filter'),
            onPressed: () async {
              var result = await showFilterDialog();
              if (mounted) {
                if (result == true) {
                  Provider.of<InventoryModel>(context, listen: false).getPageList(context);
                }
              }
            },
            icon: const Icon(UniconsLine.filter),
          ),
        ],
      ),
      body: Consumer<InventoryModel>(
        builder: (context, model, child) {
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
                        child: Text(context.tr('created_by')),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 100,
                        child: Text(context.tr('document')),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 120,
                        child: Text(
                          context.tr('begin_date'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 120,
                        child: Text(
                          context.tr('end_date'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 100,
                        child: Text(context.tr('completed_by')),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 100,
                        child: Text(
                          context.tr('status'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 40,
                        child: Text(
                          context.tr('action'),
                          textAlign: TextAlign.center,
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
                              child: Text('${model.pageList[i]['createdBy']}'),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: Text('${model.pageList[i]['inventoryNumber'] ?? ''}'),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: Text(
                                '${formatDate(model.pageList[i]['beginDate'])}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: Text(
                                '${formatDate(model.pageList[i]['endDate'])}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: Text('${model.pageList[i]['completedBy'] ?? '-'}'),
                            ),
                          ),
                          DataCell(
                            model.pageList[i]['completed']
                                ? Center(
                                    child: Container(
                                      width: 90,
                                      decoration: BoxDecoration(
                                        color: success,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        context.tr('closed'),
                                        style: TextStyle(
                                          color: white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Container(
                                      width: 90,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF74788d),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        context.tr('expected'),
                                        style: TextStyle(
                                          color: white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                          ),
                          DataCell(
                            Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Provider.of<InventoryModel>(context, listen: false).redirect(context, model.pageList[i]['id']);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Icon(
                                    UniconsLine.edit_alt,
                                    size: 16,
                                  ),
                                ),
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
