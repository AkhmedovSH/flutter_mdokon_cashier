import 'package:flutter/material.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/core/state/filter_model.dart';
import 'package:flutter_mdokon/shared/widgets/filter/label.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter_mdokon/core/theme/app_colors.dart';

class Date extends StatefulWidget {
  final String label;
  final String filterKey;
  const Date({
    super.key,
    required this.label,
    required this.filterKey,
  });

  @override
  State<Date> createState() => _DateState();
}

class _DateState extends State<Date> {
  Future<void> selectDate(BuildContext context) async {
    FilterModel filterModel = Provider.of<FilterModel>(context, listen: false);
    DateTime date =
        filterModel.currentFilterData[widget.filterKey] != '' ? DateTime.parse(filterModel.currentFilterData[widget.filterKey]) : DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
    );
    if (mounted && picked != null) {
      filterModel.setFilterData(widget.filterKey, formatDateTime(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Label(text: widget.label),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width,
          child: Consumer<FilterModel>(
            builder: (context, filterModel, chilld) {
              bool format = true;
              if (filterModel.currentFilterData[widget.filterKey] == '') {
                format = false;
              }
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
                    color: AppColors.canvas,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        format ? formatDateMonth(filterModel.currentFilterData[widget.filterKey]) : '',
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
