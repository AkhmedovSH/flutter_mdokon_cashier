import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mdokon/models/cashier/cashbox_model.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import '/helpers/helper.dart';

class Payment extends StatefulWidget {
  const Payment({Key? key}) : super(key: key);

  @override
  _PaymentState createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return Consumer<CashboxModel>(
      builder: (context, model, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Text(
                  context.tr('TO_PAY'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 10),
                child: Text(
                  '${formatMoney(model.data['totalPrice'])} ${model.data['currencyName'] ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (customIf(model.data['paymentTypes']))
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var entry in model.data['paymentTypes'].asMap().entries)
                        Builder(
                          builder: (context) {
                            int index = entry.key;
                            var item = entry.value;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${item['customPaymentTypeName']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  child: TextFormField(
                                    controller: item['controller'],
                                    keyboardType: TextInputType.number,
                                    onTapOutside: (PointerDownEvent event) {
                                      FocusManager.instance.primaryFocus?.unfocus();
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return context.tr('required_field');
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      model.updateInputs(index, value);
                                    },
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          model.exactAmount(index);
                                        },
                                        icon: Icon(UniconsLine.money_bill),
                                      ),
                                      enabledBorder: inputBorder,
                                      focusedBorder: inputFocusBorder,
                                      errorBorder: inputErrorBorder,
                                      focusedErrorBorder: inputErrorBorder,
                                      hintText: '0.00 ${model.data['currencyName'] ?? ''}',
                                      hintStyle: TextStyle(color: a2),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              Text(
                '${context.tr('change')}:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 10, top: 5),
                child: Text(
                  '${formatMoney(model.data['change'])} ${model.data['currencyName'] ?? ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
