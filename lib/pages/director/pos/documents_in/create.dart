import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/data_model.dart';
import 'package:kassa/models/director/documents_in_model.dart';

import 'package:kassa/widgets/custom_app_bar.dart';
import 'package:kassa/widgets/filter/label.dart';
import 'package:kassa/widgets/table/table.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class DocumentsInCreate extends StatelessWidget {
  const DocumentsInCreate({super.key});

  @override
  Widget build(BuildContext context) {
    DataModel dataModel = Provider.of<DataModel>(context, listen: false);
    return Scaffold(
      appBar: CustomAppBar(
        title: context.tr('create'),
        leading: true,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownItem(
                label: 'pos',
                items: dataModel.poses,
                dataKey: 'posId',
              ),
              DropdownItem(
                label: 'organization',
                items: dataModel.organizations,
                dataKey: 'organizationId',
              ),
              DropdownItem(
                label: 'currency',
                items: dataModel.currencies,
                dataKey: 'currencyId',
              ),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Padding(
                  padding: EdgeInsets.zero, // Убираем внешние отступы
                  child: ExpansionTile(
                    title: Text(context.tr("additionally")),
                    tilePadding: EdgeInsets.zero, // Убираем внутренние отступы
                    children: const [
                      // TextFielItem(
                      //   label: 'expenses',
                      //   dataKey: 'expense',
                      // ),
                      TextFielItem(
                        label: 'overhead',
                        dataKey: 'inNumber',
                      ),
                      TextFielItem(
                        label: 'note',
                        dataKey: 'note',
                      ),
                    ],
                  ),
                ),
              ),
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
                    // ListView.builder(itemBuilder: () {}),
                    // for (var i = 1; i < data.length; i++)
                    //   DataRow(
                    //     cells: [
                    //       DataCell(
                    //         SizedBox(
                    //           width: 40,
                    //           child: Text('${data[i]['rowNum']}'),
                    //         ),
                    //       ),
                    //       DataCell(
                    //         SizedBox(
                    //           width: 130,
                    //           child: Text('${data[i]['posName']}'),
                    //         ),
                    //       ),
                    //       DataCell(
                    //         SizedBox(
                    //           width: 100,
                    //           child: Text('${data[i]['organizationName']}'),
                    //         ),
                    //       ),
                    //       DataCell(
                    //         SizedBox(
                    //           width: 120,
                    //           child: Text(
                    //             '${formatMoney(data[i]['totalAmount'])}',
                    //             textAlign: TextAlign.end,
                    //           ),
                    //         ),
                    //       ),
                    //       DataCell(
                    //         SizedBox(
                    //           width: 120,
                    //           child: Text(
                    //             '${formatMoney(data[i]['totalAmount'])}',
                    //             textAlign: TextAlign.end,
                    //           ),
                    //         ),
                    //       ),
                    //       DataCell(
                    //         SizedBox(
                    //           width: 80,
                    //           child: Text('${data[i]['currencyName']}'),
                    //         ),
                    //       ),
                    //       DataCell(
                    //         SizedBox(
                    //           width: 140,
                    //           child: Text(
                    //             '${formatDate(data[i]['createdDate'])}',
                    //             textAlign: TextAlign.center,
                    //           ),
                    //         ),
                    //       ),
                    //       DataCell(
                    //         SizedBox(
                    //           width: 100,
                    //           child: Text(
                    //             '${data[i]['createdBy'] ?? ''}',
                    //             textAlign: TextAlign.end,
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TextFielItem extends StatelessWidget {
  final String label;
  final String dataKey;

  const TextFielItem({
    super.key,
    required this.label,
    required this.dataKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Label(text: label),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width,
          child: Consumer<DocumentsInModel>(
            builder: (context, documentsInModel, chilld) {
              return Container(
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CustomTheme.of(context).cardColor,
                ),
                child: TextFormField(
                  onChanged: (value) {
                    documentsInModel.setDataValue(dataKey, value);
                  },
                  onTapOutside: (PointerDownEvent event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  initialValue: documentsInModel.data[dataKey] ?? '',
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: CustomTheme.of(context).cardColor,
                    enabledBorder: inputBorder,
                    focusedBorder: inputFocusBorder,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DropdownItem extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String label;
  final String dataKey;

  const DropdownItem({
    super.key,
    required this.items,
    required this.label,
    required this.dataKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Label(text: label),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width,
          child: Consumer<DocumentsInModel>(
            builder: (context, documentsInModel, chilld) {
              return Container(
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CustomTheme.of(context).cardColor,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    value: documentsInModel.data[dataKey].toString(),
                    buttonStyleData: const ButtonStyleData(),
                    iconStyleData: const IconStyleData(
                      icon: Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Icon(UniconsLine.angle_down),
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: CustomTheme.of(context).cardColor,
                      ),
                      maxHeight: 300,
                      offset: const Offset(0, -10),
                    ),
                    isDense: true,
                    onChanged: (String? newValue) {},
                    items: items.map(
                      (Map<String, dynamic> item) {
                        return DropdownMenuItem<String>(
                          value: item['id'].toString(),
                          child: Text(item['name']),
                        );
                      },
                    ).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
