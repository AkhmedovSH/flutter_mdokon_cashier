import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
              SearchItem(),
              SizedBox(
                height: 400,
                child: Consumer<DocumentsInModel>(
                  builder: (context, documentsInModel, chilld) {
                    return TableWidget(
                      headers: [
                        DataColumn(
                          label: SizedBox(
                            width: 40,
                            child: Text('№'),
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
                            child: Text(context.tr('barcode')),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 100,
                            child: Text(
                              context.tr('residue'),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 100,
                            child: Text(
                              context.tr('quantity'),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 100,
                            child: Text(context.tr('unit')),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 100,
                            child: Text(context.tr('admission_price')),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 100,
                            child: Text(context.tr('wholesale_price')),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 100,
                            child: Text(context.tr('bank_price')),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 100,
                            child: Text(context.tr('amount')),
                          ),
                        ),
                      ],
                      rows: [
                        for (var i = 1; i < documentsInModel.data['productList'].length; i++)
                          DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 40,
                                  child: Text('${i + 1}'),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text('${documentsInModel.data['productList'][i]['name']}'),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 150,
                                  child: Text('${documentsInModel.data['productList'][i]['balance']}'),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: Text('${documentsInModel.data['productList'][i]['quantity']}'),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: Text('${documentsInModel.data['productList'][i]['uomName']}'),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: Text('${documentsInModel.data['productList'][i]['price']}'),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: Text('${documentsInModel.data['productList'][i]['wholesalePrice']}'),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: Text('${documentsInModel.data['productList'][i]['bankPrice']}'),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: Text('${documentsInModel.data['productList'][i]['salePrice']}'),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    '${formatMoney(documentsInModel.data['productList'][i]['totalAmount'])}',
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchItem extends StatelessWidget {
  const SearchItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Label(text: 'search'),
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
                  controller: documentsInModel.searchController,
                  onChanged: (value) {
                    documentsInModel.search(value);
                  },
                  onTapOutside: (PointerDownEvent event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
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
