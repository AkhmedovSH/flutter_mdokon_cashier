import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import 'package:kassa/models/data_model.dart';
import 'package:kassa/models/director/inventory_model.dart';

import 'package:kassa/widgets/custom_app_bar.dart';
import 'package:kassa/widgets/filter/label.dart';
import 'package:kassa/widgets/table/table.dart';

import 'package:kassa/helpers/helper.dart';

class InventoryCreate extends StatelessWidget {
  const InventoryCreate({super.key});

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
                  if (MediaQuery.of(context).size.width > 320) ...[
                    TextFielItem(
                      label: '${context.tr('inventory')} №',
                      dataKey: 'inventoryNumber',
                    ),
                    TextFielItem(
                      label: 'note',
                      dataKey: 'note',
                    ),
                  ],
                  SearchItem(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - kToolbarHeight - 160,
                    child: Consumer<InventoryModel>(
                      builder: (context, inventoryModel, chilld) {
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
                                  context.tr('counted'),
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
                                  context.tr('unit'),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 100,
                                child: Text(
                                  context.tr('price'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 150,
                                child: Text(
                                  context.tr('expected_balance'),
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
                            for (var i = 0; i < inventoryModel.data['productList'].length; i++)
                              DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        '${i + 1} ${inventoryModel.data['productList'][i]['productName']}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: TableTextField(
                                        inventoryModel: inventoryModel,
                                        i: i,
                                        keyName: 'actualBalance',
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        '${inventoryModel.data['productList'][i]['barcode']}',
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        '${inventoryModel.data['productList'][i]['uomName']}',
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        '${inventoryModel.data['productList'][i]['price']}',
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        '${inventoryModel.data['productList'][i]['balance']}',
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
                                            inventoryModel.removeProduct(i);
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
                    height: 65,
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
          child: Consumer<InventoryModel>(
            builder: (context, inventoryModel, chilld) {
              return Container(
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CustomTheme.of(context).cardColor,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    value: inventoryModel.data[dataKey].toString(),
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
          child: Consumer<InventoryModel>(
            builder: (context, inventoryModel, chilld) {
              return Container(
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CustomTheme.of(context).cardColor,
                ),
                child: TextFormField(
                  controller: inventoryModel.searchController,
                  focusNode: inventoryModel.searchFocus,
                  onChanged: (value) {
                    print(value);
                    inventoryModel.search(value);
                  },
                  onFieldSubmitted: (value) {
                    // Обработка отсканированного значения
                    print('Отсканировано: $value');
                  },
                  onTapOutside: (PointerDownEvent event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.search, // Устанавливаем тип кнопки "Next"
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
          child: Consumer<InventoryModel>(
            builder: (context, inventoryModel, chilld) {
              return Container(
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CustomTheme.of(context).cardColor,
                ),
                child: TextFormField(
                  onChanged: (value) {
                    inventoryModel.setDataValue(dataKey, value);
                  },
                  onTapOutside: (PointerDownEvent event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  initialValue: (inventoryModel.data[dataKey] ?? '').toString(),
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
  final InventoryModel inventoryModel;
  final int i;
  final String keyName;

  const TableTextField({
    super.key,
    required this.inventoryModel,
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
      child: TextFormField(
        controller: inventoryModel.data['productList'][i]['controller'],
        focusNode: inventoryModel.data['productList'][i]['focus'],
        onChanged: (value) {
          String convertedValue = convertToNumbers(value);
          inventoryModel.setProductListValue(i, keyName, convertedValue);
        },
        onFieldSubmitted: (value) {
          inventoryModel.searchFocus.requestFocus();
        },
        textInputAction: TextInputAction.done, // Устанавливаем тип кнопки "Next"
        keyboardType: TextInputType.number,
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
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Consumer<InventoryModel>(
                        builder: (context, inventoryModel, child) {
                          return ElevatedButton(
                            onPressed: inventoryModel.data['productList'].isNotEmpty
                                ? () {
                                    inventoryModel.saveToDraft(context);
                                  }
                                : null,
                            child: Text(
                              context.tr('save_to_draft'),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Consumer<InventoryModel>(
                        builder: (context, inventoryModel, child) {
                          return ElevatedButton(
                            onPressed: inventoryModel.data['productList'].isNotEmpty
                                ? () {
                                    inventoryModel.save(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: success,
                            ),
                            child: Text(
                              context.tr('complete'),
                              textAlign: TextAlign.center,
                            ),
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
