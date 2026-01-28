import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import '/widgets/filter/label.dart';

import '/models/filter_model.dart';

import '/helpers/helper.dart';

class Dropdown extends StatelessWidget {
  final String label;
  final String filterKey;
  final String itemValue;
  final String itemName;
  final List<Map<String, dynamic>> items;
  final bool translate;

  const Dropdown({
    super.key,
    this.label = '',
    this.filterKey = '',
    this.itemValue = 'id',
    this.itemName = 'name',
    this.translate = false,
    required this.items,
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
          child: Consumer<FilterModel>(
            builder: (context, filterModel, chilld) {
              return Container(
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CustomTheme.of(context).cardColor,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    value: filterModel.currentFilterData[filterKey].toString(),
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
                        filterModel.setFilterData(filterKey, newValue);
                      }
                    },
                    items: items.map(
                      (Map<String, dynamic> item) {
                        return DropdownMenuItem<String>(
                          value: item[itemValue].toString(),
                          child: Text(translate ? context.tr(item[itemName] ?? '') : (item[itemName] ?? '')),
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
