import 'package:flutter/material.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/filter_model.dart';
import 'package:kassa/widgets/filter/label.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class Date extends StatefulWidget {
  const Date({super.key});

  @override
  State<Date> createState() => _DateState();
}

class _DateState extends State<Date> {
  selectDate(BuildContext context) async {
    FilterModel filterModel = Provider.of<FilterModel>(context, listen: false);
    DateTime date = DateTime.parse(filterModel.currentFilterData['date']);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
    );
    if (mounted && picked != null) {
      filterModel.setFilterData('date', formatDateTime(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Label(text: 'date'),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width,
          child: Consumer<FilterModel>(
            builder: (context, filterModel, chilld) {
              return GestureDetector(
                onTap: () {
                  selectDate(context);
                },
                child: Container(
                  height: 45,
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: CustomTheme.of(context).cardColor,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${formatDateMonth(filterModel.currentFilterData['date'])}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(UniconsLine.calendar_alt, size: 20)
                    ],
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
