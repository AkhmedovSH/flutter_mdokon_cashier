import 'package:flutter/cupertino.dart';

import 'package:provider/provider.dart';
import '/models/filter_model.dart';
import '/widgets/filter/label.dart';

class FilterSwitch extends StatelessWidget {
  final String label;
  final String filterKey;

  const FilterSwitch({
    super.key,
    required this.label,
    required this.filterKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Label(text: label),
        Consumer<FilterModel>(
          builder: (context, filterModel, chilld) {
            return CupertinoSwitch(
              value: filterModel.currentFilterData[filterKey],
              onChanged: (value) {
                filterModel.setFilterData(filterKey, value);
              },
            );
          },
        ),
      ],
    );
  }
}
