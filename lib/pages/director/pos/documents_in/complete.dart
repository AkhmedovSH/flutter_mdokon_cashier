import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '/helpers/helper.dart';
import '/models/data_model.dart';
import '/models/director/documents_in_model.dart';
import '/widgets/custom_app_bar.dart';
import '/widgets/filter/label.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class DocumentsInComplete extends StatefulWidget {
  const DocumentsInComplete({super.key});

  @override
  State<DocumentsInComplete> createState() => _DocumentsInCompleteState();
}

class _DocumentsInCompleteState extends State<DocumentsInComplete> {
  @override
  Widget build(BuildContext context) {
    DataModel dataModel = Provider.of<DataModel>(context, listen: false);

    final paymentTypes = [
      {'id': 1, 'name': 'safe'},
      {'id': 2, 'name': 'bank'},
    ];

    return Consumer<DocumentsInModel>(builder: (context, documentsInModel, child) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'confirm',
          leading: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RowItem(
                  title: 'pos',
                  value: findFromArrayById(
                    dataModel.poses,
                    documentsInModel.data['posId'],
                  ),
                ),
                SizedBox(height: 10),
                RowItem(
                  title: 'supplier',
                  value: findFromArrayById(
                    dataModel.organizations,
                    documentsInModel.data['organizationId'],
                  ),
                ),
                SizedBox(height: 10),
                RowItem(
                  title: 'currency',
                  value: findFromArrayById(
                    dataModel.currencies,
                    documentsInModel.data['currencyId'],
                  ),
                ),
                SizedBox(height: 10),
                RowItem(
                  title: 'receipt_amount',
                  value: '${formatMoney(documentsInModel.data['totalIncome'])} ${documentsInModel.data['currencyName']}',
                ),
                SizedBox(height: 10),
                RowItem(
                  title: 'sale_amount',
                  value: '${formatMoney(documentsInModel.data['totalSale'])} ${documentsInModel.data['currencyName']}',
                ),
                SizedBox(height: 20),
                DropdownItem(
                  items: paymentTypes,
                  label: 'choose_payment_type',
                  dataKey: 'paymentTypeId',
                  itemName: 'name',
                  itemValue: 'id',
                ),
                if (documentsInModel.data['paymentTypeId'] == '1')
                  DropdownItem(
                    items: dataModel.wallets,
                    label: 'safe',
                    dataKey: 'walletId',
                    itemName: 'walletName',
                    itemValue: 'walletId',
                  )
                else
                  DropdownItem(
                    items: dataModel.banks,
                    label: 'bank',
                    dataKey: 'bankId',
                    itemName: 'bankName',
                    itemValue: 'bankId',
                  ),
                Label(text: 'payment_amount_to_supplier'),
                Stack(
                  children: [
                    SizedBox(
                      height: 45,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: documentsInModel.paidAmountController,
                        onChanged: (value) {
                          documentsInModel.setDataValue('paidAmount', value);
                        },
                        onTapOutside: (PointerDownEvent event) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          height: 45,
                          width: 60,
                          child: TextButton(
                            onPressed: () {
                              documentsInModel.setPaidAmount('paidAmount', documentsInModel.data['totalIncome']);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: mainColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.zero,
                                  bottomLeft: Radius.zero,
                                  topRight: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                            ),
                            child: Icon(
                              UniconsLine.transaction,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                Label(text: 'date_amount_to_supplier'),
                SizedBox(
                  height: 45,
                  child: GestureDetector(
                    onTap: () async {
                      DateTime date = documentsInModel.data['debtPaymentDate'] != null
                          ? DateTime.parse(documentsInModel.data['debtPaymentDate'])
                          : DateTime.now();
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020, 1),
                        lastDate: DateTime.now(),
                        currentDate: DateTime.now(),
                      );
                      if (mounted && picked != null) {
                        documentsInModel.setDataValue('debtPaymentDate', formatDateTime(picked));
                      }
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
                            documentsInModel.data['debtPaymentDate'] != null ? '${formatDateMonth(documentsInModel.data['debtPaymentDate'])}' : '',
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
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
        floatingActionButton: Container(
          height: 50,
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.only(left: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: Consumer<DocumentsInModel>(
                    builder: (context, model, child) {
                      return ElevatedButton(
                        onPressed: model.data['productList'].isNotEmpty
                            ? () {
                                model.saveToDraft(context);
                              }
                            : null,
                        child: Text(
                          context.tr('save_to_draft'),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: Consumer<DocumentsInModel>(
                    builder: (context, model, child) {
                      return ElevatedButton(
                        onPressed: model.data['productList'].isNotEmpty
                            ? () {
                                model.save(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: success,
                        ),
                        child: Text(
                          context.tr('complete'),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class DropdownItem extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String label;
  final String dataKey;
  final String itemValue;
  final String itemName;

  const DropdownItem({
    super.key,
    required this.items,
    required this.label,
    required this.dataKey,
    required this.itemValue,
    required this.itemName,
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
          child: Consumer<DocumentsInModel>(
            builder: (context, documentsInModel, chilld) {
              return Container(
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CustomTheme.of(context).cardColor,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    value: documentsInModel.data[dataKey].toString(),
                    buttonStyleData: const ButtonStyleData(),
                    iconStyleData: const IconStyleData(
                      icon: Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Icon(UniconsLine.angle_down),
                      ),
                    ),
                    dropdownStyleData: DropdownStyleData(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: CustomTheme.of(context).cardColor,
                      ),
                      maxHeight: 300,
                      offset: const Offset(0, -10),
                    ),
                    isDense: true,
                    onChanged: (String? newValue) {
                      documentsInModel.setDataValue(dataKey, newValue);
                    },
                    items: items.map(
                      (Map<String, dynamic> item) {
                        return DropdownMenuItem<String>(
                          value: item[itemValue].toString(),
                          child: Text(context.tr(item[itemName] ?? '-')),
                        );
                      },
                    ).toList(),
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

class RowItem extends StatelessWidget {
  final String title;
  final String value;
  const RowItem({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.tr(title),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
