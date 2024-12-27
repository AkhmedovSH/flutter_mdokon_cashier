import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/data_model.dart';
import 'package:kassa/models/director/documents_in_model.dart';

import 'package:kassa/widgets/custom_app_bar.dart';
import 'package:kassa/widgets/filter/label.dart';
import 'package:kassa/widgets/loading_layout.dart';
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
        title: 'create',
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
                                width: 150,
                                child: Text(context.tr('name_of_product')),
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
                            DataColumn(
                              label: SizedBox(
                                width: 40,
                              ),
                            ),
                          ],
                          rows: [
                            for (var i = 0; i < documentsInModel.data['productList'].reversed.toList().length; i++)
                              DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        '${i + 1} ${documentsInModel.data['productList'][i]['name']}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
                    onChanged: (String? newValue) {
                      documentsInModel.setDataValue(dataKey, newValue);
                    },
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
                  focusNode: documentsInModel.searchFocus,
                  onChanged: (value) {
                    documentsInModel.search(value);
                  },
                  onTapOutside: (PointerDownEvent event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  textInputAction: TextInputAction.search,
                  keyboardType: TextInputType.number,
                  scrollPadding: EdgeInsets.only(bottom: 700),
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () {
                        showProductDialog(context);
                      },
                      icon: Icon(UniconsLine.plus_circle),
                    ),
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

  // Функция для преобразования символов в цифры
  String convertToNumbers(String input) {
    final Map<String, String> charToNumber = {
      '@': '1',
      'a': '2',
      'd': '3',
      'g': '4',
      'j': '5',
      'm': '6',
      'p': '7',
      't': '8',
      'w': '9',
    };

    return input
        .split('') // Разбиваем строку на символы
        .map((char) => charToNumber[char] ?? char) // Преобразуем символ или оставляем без изменений
        .join(); // Объединяем символы обратно в строку
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 5),
      height: 35,
      child: TextFormField(
        // initialValue: keyName == 'quantity'
        //     ? null
        //     : documentsInModel.data['productList'][i][keyName] == '0'
        //         ? null
        //         : documentsInModel.data['productList'][i][keyName].toString(),
        controller: keyName == 'quantity' ? documentsInModel.data['productList'][i]['controller'] : null,
        focusNode: keyName == 'quantity' ? documentsInModel.data['productList'][i]['focus'] : null,
        onChanged: (value) {
          String convertedValue = convertToNumbers(value);
          documentsInModel.setProductListValue(i, keyName, convertedValue);
        },
        onFieldSubmitted: (value) {
          documentsInModel.searchFocus.requestFocus();
        },
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        scrollPadding: EdgeInsets.only(bottom: 100),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          enabledBorder: inputBorder,
          focusedBorder: inputFocusBorder,
          border: inputFocusBorder,
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
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: Consumer<DocumentsInModel>(
                  builder: (context, documentsInModel, child) {
                    return ElevatedButton(
                      onPressed: documentsInModel.data['productList'].isNotEmpty
                          ? () async {
                              documentsInModel.redirect(context);
                            }
                          : null,
                      child: Text(context.tr('save')),
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

showProductDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      DataModel dataModel = Provider.of<DataModel>(context, listen: false);

      return LoadingLayout(
        body: Scaffold(
          appBar: CustomAppBar(
            title: 'new_product',
            leading: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ProductField(
                  label: 'name_of_product',
                  productKey: 'name',
                ),
                ProductField(
                  label: 'barcode',
                  productKey: 'barcode',
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Label(text: 'unit_of_measurement'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      width: MediaQuery.of(context).size.width,
                      child: Consumer<DocumentsInModel>(
                        builder: (context, model, chilld) {
                          return Container(
                            height: 45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: CustomTheme.of(context).cardColor,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton2<String>(
                                value: model.product['uomId'].toString(),
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
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    model.setProductValue('uomId', newValue);
                                  }
                                },
                                items: dataModel.uoms.map(
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
                ),
                // ProductField(
                //   label: 'unit_of_measurement',
                //   productKey: 'uomId',
                // ),
                ProductField(
                  label: 'artikul',
                  productKey: 'artikul',
                ),
                ProductField(
                  label: 'ИКПУ',
                  productKey: 'gtin',
                ),
                SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: Container(
            height: 50,
            width: MediaQuery.of(context).size.width,
            margin: EdgeInsets.only(left: 32),
            child: ElevatedButton(
              onPressed: () {
                Provider.of<DocumentsInModel>(context, listen: false).createProduct(context);
              },
              child: Text(context.tr('create')),
            ),
          ),
        ),
      );
    },
  );
}

class ProductField extends StatelessWidget {
  final String label;
  final String productKey;
  const ProductField({
    super.key,
    this.label = '',
    this.productKey = '',
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
                  controller: documentsInModel.productControllers[productKey],
                  onChanged: (value) {},
                  onTapOutside: (PointerDownEvent event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  scrollPadding: EdgeInsets.only(bottom: 100),
                  decoration: InputDecoration(
                    suffixIcon: label == 'barcode'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  documentsInModel.generateBarcode();
                                },
                                icon: Icon(UniconsLine.redo),
                              ),
                              IconButton(
                                onPressed: () {
                                  documentsInModel.getOfdProduct();
                                },
                                icon: Icon(UniconsLine.shield_check),
                              ),
                            ],
                          )
                        : SizedBox(),
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
