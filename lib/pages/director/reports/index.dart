import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/widgets/custom_app_bar.dart';
import 'package:unicons/unicons.dart';

class Report extends StatelessWidget {
  const Report({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'reports',
        leading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              SizedBox(height: 15),
              CardItem(
                title: 'balance_report',
                icon: UniconsLine.chart_pie_alt,
                routeName: '/director/balance',
              ),
              CardItem(
                title: 'sales_report',
                icon: UniconsLine.chart_pie_alt,
                routeName: '/director/sales',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const defaultTitleStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w500,
);

class CardItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final String routeName;
  final TextStyle titleStyle;

  const CardItem({
    super.key,
    required this.title,
    required this.icon,
    required this.routeName,
    this.titleStyle = defaultTitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TextButton(
        onPressed: () {
          context.go(routeName);
        },
        style: TextButton.styleFrom(
          backgroundColor: CustomTheme.of(context).cardColor,
          foregroundColor: CustomTheme.of(context).textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(21),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 24),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        context.tr(title),
                        style: titleStyle,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                UniconsLine.angle_right_b,
                size: 28,
              )
            ],
          ),
        ),
      ),
    );
  }
}
