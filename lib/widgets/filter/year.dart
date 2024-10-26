import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/filter_model.dart';
import 'package:kassa/widgets/filter/label.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class Year extends StatefulWidget {
  const Year({super.key});

  @override
  State<Year> createState() => _YearState();
}

class _YearState extends State<Year> {
  List years = [
    '${DateTime.now().year - 5}',
    '${DateTime.now().year - 4}',
    '${DateTime.now().year - 3}',
    '${DateTime.now().year - 2}',
    '${DateTime.now().year - 1}',
    '${DateTime.now().year}',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Label(text: 'year'),
        Container(
          height: 45,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: CustomTheme.of(context).cardColor,
          ),
          child: Consumer<FilterModel>(
            builder: (context, filterModel, chilld) {
              return DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  value: filterModel.currentFilterData['start_date'].toString(),
                  iconStyleData: const IconStyleData(icon: Icon(UniconsLine.angle_down)),
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
                      filterModel.setFilterData('start_date', newValue);
                    }
                  },
                  items: years.map(
                    (item) {
                      return DropdownMenuItem<String>(
                        value: '$item-01-01',
                        child: Text('$item'),
                      );
                    },
                  ).toList(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10)
      ],
    );
  }
}
