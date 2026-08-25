import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/shared/widgets/filter/label.dart';

import 'package:flutter_mdokon/core/state/filter_model.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/core/theme/app_colors.dart';

class Search extends StatelessWidget {
  const Search({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Label(text: context.tr('search')),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: MediaQuery.of(context).size.width,
          child: Consumer<FilterModel>(
            builder: (context, filterModel, chilld) {
              return Container(
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.canvas,
                ),
                child: TextFormField(
                  onChanged: (value) {
                    filterModel.setFilterData('search', value);
                  },
                  onTapOutside: (PointerDownEvent event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  initialValue: filterModel.currentFilterData['search'] ?? '',
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: AppColors.canvas,
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
