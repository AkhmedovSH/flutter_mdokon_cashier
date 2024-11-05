import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
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
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SingleChildScrollView(
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
                    label: 'supplier',
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
                        tilePadding: EdgeInsets.symmetric(horizontal: 3), // Убираем внутренние отступы
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
                          TextFielItem(
                            label: 'VAT',
                            dataKey: 'defaultVat',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SearchItem(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - 220,
                    child: Consumer<DocumentsInModel>(
                      builder: (context, documentsInModel, chilld) {
                        return TableWidget(
                          headers: [
                            DataColumn(
                              label: SizedBox(
                                width: 40,
                              ),
                            ),
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
                                  context.tr('residue'),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 100,
                                child: Text(
                                  context.tr('quantity'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 100,
                                child: Text(
                                  context.tr('unit'),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 140,
                                child: Text(
                                  context.tr('admission_price'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 140,
                                child: Text(
                                  context.tr('wholesale_price'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 140,
                                child: Text(
                                  context.tr('bank_price'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 140,
                                child: Text(
                                  context.tr('sale_price'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 100,
                                child: Text(
                                  context.tr('amount'),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ),
                          ],
                          rows: [
                            for (var i = 0; i < documentsInModel.data['productList'].length; i++)
                              DataRow(
                                cells: [
                                  DataCell(
                                    Center(
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            documentsInModel.removeProduct(i);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            backgroundColor: danger,
                                          ),
                                          child: Icon(
                                            UniconsLine.times,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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
                                      child: Text(
                                        '${documentsInModel.data['productList'][i]['barcode']}',
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        '${documentsInModel.data['productList'][i]['balance']}',
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: TableTextField(
                                        documentsInModel: documentsInModel,
                                        i: i,
                                        keyName: 'quantity',
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        '${documentsInModel.data['productList'][i]['uomName']}',
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: TableTextField(
                                        documentsInModel: documentsInModel,
                                        i: i,
                                        keyName: 'price',
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: TableTextField(
                                        documentsInModel: documentsInModel,
                                        i: i,
                                        keyName: 'wholesalePrice',
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: TableTextField(
                                        documentsInModel: documentsInModel,
                                        i: i,
                                        keyName: 'bankPrice',
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: TableTextField(
                                        documentsInModel: documentsInModel,
                                        i: i,
                                        keyName: 'salePrice',
                                      ),
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
                  SizedBox(
                    height: 130,
                  )
                ],
              ),
            ),
          ),
          TotalAmountItem()
        ],
      ),
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
                  textInputAction: TextInputAction.next, // Устанавливаем тип кнопки "Next"
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).nextFocus(); // Переход на следующий инпут
                  },
                  scrollPadding: EdgeInsets.only(bottom: 700),
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
                  initialValue: (documentsInModel.data[dataKey] ?? '').toString(),
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

class TableTextField extends StatelessWidget {
  final DocumentsInModel documentsInModel;
  final int i;
  final String keyName;

  const TableTextField({
    super.key,
    required this.documentsInModel,
    required this.i,
    required this.keyName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5),
      child: TextFormField(
        initialValue: (documentsInModel.data['productList'][i][keyName] ?? '').toString(),
        onChanged: (value) {
          documentsInModel.setProductListValue(i, keyName, value);
        },
        onTapOutside: (PointerDownEvent event) {
          FocusManager.instance.primaryFocus?.unfocus();
          // if (documentsInModel.data['productList'][i + 1] != null) {
          //   FocusScope.of(context).requestFocus(documentsInModel.data['productList'][i + 1]['focusNode']);
          // } else {
          // }
        },
        textInputAction: TextInputAction.next, // Устанавливаем тип кнопки "Next"
        keyboardType: TextInputType.number,
        onFieldSubmitted: (_) {},
        textAlign: TextAlign.center,
        scrollPadding: EdgeInsets.only(bottom: 100),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class TotalAmountItem extends StatelessWidget {
  const TotalAmountItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: CustomTheme.of(context).bgColor),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('total_quantity'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Consumer<DocumentsInModel>(
                    builder: (context, documentsInModel, child) {
                      return Text(
                        '${formatMoney(documentsInModel.data['totalQuantity'])}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('receipt_amount'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Consumer<DocumentsInModel>(
                    builder: (context, documentsInModel, child) {
                      return Text(
                        '${formatMoney(documentsInModel.data['totalIncome'])}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('sale_amount'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Consumer<DocumentsInModel>(
                    builder: (context, documentsInModel, child) {
                      return Text(
                        '${formatMoney(documentsInModel.data['totalSale'])}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          context.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: danger,
                        ),
                        child: Text(context.tr('cancel')),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: Consumer<DocumentsInModel>(
                        builder: (context, documentsInModel, child) {
                          return ElevatedButton(
                            onPressed: documentsInModel.data['productList'].isNotEmpty
                                ? () {
                                    documentsInModel.checkData(context);
                                  }
                                : null,
                            child: Text(context.tr('save')),
                          );
                        },
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
