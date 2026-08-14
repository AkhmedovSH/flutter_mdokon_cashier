import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '/models/loading_model.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class TableEmpty extends StatelessWidget {
  const TableEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingModel>(
      builder: (context, loaderModel, child) {
        if (loaderModel.loading == 1) {
          return const SizedBox();
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                UniconsLine.inbox,
                size: 48,
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('list_empty'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
