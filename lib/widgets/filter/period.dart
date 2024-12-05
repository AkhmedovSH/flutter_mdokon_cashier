import 'package:flutter/material.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/filter_model.dart';
import 'package:kassa/widgets/filter/label.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class Period extends StatefulWidget {
  const Period({super.key});

  @override
  State<Period> createState() => _PeriodState();
}

class _PeriodState extends State<Period> {
  selectDate(BuildContext context, int date) async {
    FilterModel filterModel = Provider.of<FilterModel>(context, listen: false);
    DateTime startDate = DateTime.parse(filterModel.currentFilterData['startDate']);
    DateTime endDate = DateTime.parse(filterModel.currentFilterData['endDate']);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date == 1 ? startDate : endDate,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
    );
    if (mounted && picked != null) {
      if (date == 1) {
        filterModel.setFilterData('startDate', formatDateTime(picked));
      }
      if (date == 2) {
        filterModel.setFilterData('endDate', formatDateTime(picked));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Label(text: 'period'),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width,
          child: Consumer<FilterModel>(
            builder: (context, filterModel, chilld) {
              return Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        selectDate(context, 1);
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
                              '${formatDateMonth(filterModel.currentFilterData['startDate'])}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(UniconsLine.calendar_alt, size: 20)
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        selectDate(context, 2);
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
                              '${formatDateMonth(filterModel.currentFilterData['endDate'])}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(UniconsLine.calendar_alt, size: 20)
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
