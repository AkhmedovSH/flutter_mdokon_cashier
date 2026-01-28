import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';
import 'package:easy_localization/easy_localization.dart';
import '/models/cashier/cashbox_model.dart';
import '/helpers/helper.dart';

class Loyalty extends StatelessWidget {
  const Loyalty({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<CashboxModel>(context);

    final List<Map<String, dynamic>> fieldConfig = [
      {
        'label': 'enter_QR_code_or_phone_number',
        'icon': UniconsLine.chat_bubble_user,
        'enabled': true,
        'controller': model.loyaltyCodeController,
        'onChanged': (val) => model.updateLoyaltyInput(val, 'card'),
      },
      {
        'label': 'client',
        'icon': UniconsLine.user,
        'enabled': false,
        'controller': model.loyaltyInfoController,
      },
      {
        'label': 'accumulated_points',
        'icon': UniconsLine.money_withdraw,
        'enabled': false,
        'controller': model.loyaltyBalanceController,
      },
      {
        'label': 'points_to_be_written_off',
        'icon': UniconsLine.money_insert,
        'enabled': true,
        'controller': model.loyaltyPointsController,
        'onChanged': (val) => model.updateLoyaltyPoints(val),
      },
      {
        'label': 'points_to_be_awarded',
        'icon': UniconsLine.bill,
        'enabled': false,
        'controller': model.loyaltyAwardController,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, model.data['totalPrice']),

            // Рендерим поля лояльности
            ...fieldConfig.map((config) => _buildTextField(context, config)),

            const Divider(height: 32),

            // Рендерим способы оплаты (наличные/терминал) из модели
            ...model.data['paymentTypes'].asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;
              return _buildPaymentTypeField(context, model, item, index);
            }).toList(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic totalPrice) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('TO_PAY'), style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            '${formatMoney(totalPrice)} сум',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(config['label']),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: config['controller'],
            enabled: config['enabled'],
            keyboardType: TextInputType.number,
            onChanged: config['onChanged'],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: Icon(config['icon'], size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeField(BuildContext context, CashboxModel model, dynamic item, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${item['customPaymentTypeName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: TextFormField(
            controller: item['controller'],
            keyboardType: TextInputType.number,
            onChanged: (value) => model.updateInputs(index, value),
            decoration: InputDecoration(
              hintText: '0.00',
              suffixIcon: IconButton(
                icon: const Icon(UniconsLine.money_bill),
                onPressed: () => model.exactAmount(index),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}
