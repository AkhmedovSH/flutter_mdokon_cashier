import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/filter_model.dart';
import '/widgets/filter/label.dart';

import '/helpers/helper.dart';

class Input extends StatelessWidget {
  final String label;
  final String filterKey;
  final bool numeric;

  const Input({
    super.key,
    this.label = '',
    this.filterKey = '',
    this.numeric = false,
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
              return SizedBox(
                // height: 45,
                width: MediaQuery.of(context).size.width,
                child: TextField(
                  onTapOutside: (PointerDownEvent event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  onChanged: (value) {
                    filterModel.setFilterData(filterKey, value);
                  },
                  keyboardType: numeric ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(top: 10, left: 16),
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: inputFocusBorder,
                    errorBorder: inputErrorBorder,
                    focusedErrorBorder: inputErrorBorder,
                    filled: true,
                    fillColor: CustomTheme.of(context).inputColor,
                    // hintText: context.tr(label),
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
