import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mdokon/models/cashier/cashbox_model.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import '/helpers/helper.dart';

class OnCredit extends StatefulWidget {
  const OnCredit({Key? key}) : super(key: key);

  @override
  _OnCreditState createState() => _OnCreditState();
}

class _OnCreditState extends State<OnCredit> {
  // Контроллеры для полей ввода (инициализируются из модели)
  final _addClientFormKey = GlobalKey<FormState>();

  // Временные данные для формы создания клиента
  final Map<String, dynamic> _newClientData = {'name': '', 'phone1': '', 'phone2': '', 'address': '', 'comment': ''};

  Future<void> _showSelectUserDialog(BuildContext context, CashboxModel model) async {
    await model.fetchClients();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Используем ChangeNotifierProvider.value или Consumer внутри диалога,
        // так как диалог находится в новом контексте
        return Consumer<CashboxModel>(
          builder: (context, model, child) {
            return AlertDialog(
              title: Text(context.tr('clients')),
              titlePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
              insetPadding: EdgeInsets.all(10),
              scrollable: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 40,
                    child: TextField(
                      onChanged: (value) => model.searchClients(value),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        hintText: context.tr('search'),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: SingleChildScrollView(
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(width: 1, color: tableBorderColor, style: BorderStyle.solid),
                        ),
                        children: [
                          TableRow(
                            children: [
                              Text(context.tr('contact'), style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(context.tr('number'), style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(context.tr('comment'), style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          // Генерируем список клиентов из модели
                          for (var i = 0; i < model.clients.length; i++)
                            TableRow(
                              children: [
                                _buildTableCell(model.clients[i]['name'], i, model, context),
                                _buildTableCell(model.clients[i]['phone1'], i, model, context),
                                _buildTableCell(model.clients[i]['comment'] ?? '', i, model, context),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.fromLTRB(10, 0, 10, 5),
                  child: ElevatedButton(
                    onPressed: () {
                      // Выбор уже произошел по клику на ячейку, кнопка просто закрывает
                      // Если нужно подтверждение: проверить model.clients.any((c) => c['selected'])
                      Navigator.pop(context);
                    },
                    child: Text(context.tr('choose')),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTableCell(String text, int index, CashboxModel model, BuildContext context) {
    bool isSelected = model.clients[index]['selected'] ?? false;
    return GestureDetector(
      onTap: () => model.selectClient(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        color: isSelected ? Color(0xFF91a0e7) : Colors.transparent,
        child: Text(
          text,
          style: TextStyle(overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }

  void _showAddClientDialog(BuildContext context, CashboxModel model) {
    final List<Map<String, dynamic>> formFields = [
      {'key': 'name', 'icon': UniconsLine.user, 'type': TextInputType.text, 'label': 'contact_name'},
      {'key': 'phone1', 'icon': UniconsLine.phone, 'type': TextInputType.number, 'label': 'phone'},
      {'key': 'phone2', 'icon': UniconsLine.phone, 'type': TextInputType.number, 'label': 'phone'},
      {'key': 'address', 'icon': UniconsLine.map, 'type': TextInputType.text, 'label': 'address'},
      {'key': 'comment', 'icon': UniconsLine.comment_lines, 'type': TextInputType.text, 'label': 'comment'},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          content: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Form(
              key: _addClientFormKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var field in formFields)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Text(
                              context.tr(field['label']),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: b8),
                            ),
                          ),
                          SizedBox(height: 5),
                          TextFormField(
                            keyboardType: field['type'],
                            validator: (value) => (field['key'] == 'name' && (value == null || value.isEmpty)) ? context.tr('required_field') : null,
                            onChanged: (value) => _newClientData[field['key']] = value,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                              enabledBorder: inputBorder,
                              focusedBorder: inputFocusBorder,
                              suffixIcon: Icon(field['icon']),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(10),
              height: 45,
              child: ElevatedButton(
                onPressed: () async {
                  if (_addClientFormKey.currentState!.validate()) {
                    await model.createNewClient(_newClientData);
                    Navigator.pop(context);
                    _showSelectUserDialog(context, model); // Сразу открываем выбор после создания
                  }
                },
                child: Text(context.tr('save')),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CashboxModel>(
      builder: (context, model, child) {
        // Данные клиента из модели
        String clientName = model.data['clientName'] ?? 'client';

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CLIENT SELECTION HEADER ---
              Container(
                margin: EdgeInsets.only(top: 20, bottom: 5),
                child: Text(
                  '${context.tr('client')}: $clientName',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () => _showSelectUserDialog(context, model),
                        style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFf1b44c)),
                        child: Text(context.tr('choose')),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () => _showAddClientDialog(context, model),
                        child: Text(context.tr('add')),
                      ),
                    ),
                  ),
                ],
              ),

              // --- NOTE FIELD ---
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 5),
                child: Text(
                  context.tr('NOTE'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  initialValue: model.clientComment, // Берем из модели
                  onChanged: (value) => model.setDataKey('comment', value),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                    enabledBorder: inputBorder,
                    focusedBorder: inputFocusBorder,
                    hintText: context.tr('NOTE'),
                    hintStyle: TextStyle(color: a2),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: Text(
                      context.tr('TO_PAY'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${formatMoney(model.data['totalPrice'])} ${model.data['currencyName'] ?? ''}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
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

                  // Text(context.tr('cash'), style: TextStyle(fontWeight: FontWeight.bold)),
                  // SizedBox(height: 5),
                  // TextFormField(
                  //   controller: cashController,
                  //   keyboardType: TextInputType.number,
                  //   onChanged: (value) => model.updateInputs(cash: value),
                  //   decoration: InputDecoration(
                  //     contentPadding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                  //     suffixIcon: Icon(UniconsLine.money_bill, size: 30, color: Color(0xFF7b8190)),
                  //     enabledBorder: inputBorder,
                  //     focusedBorder: inputFocusBorder,
                  //     hintText: '0.00 ${model.data['currencyName'] ?? ''}',
                  //   ),
                  // ),
                  SizedBox(height: 10),
                ],
              ),

              // --- DEBT DISPLAY ---
              SizedBox(height: 15),
              Text(
                '${context.tr('AMOUNT_OF_DEBT')}:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 10, top: 5),
                child: Text(
                  // change в режиме кредита хранит остаток долга (отрицательное число или 0)
                  // Используем .abs() если нужно показать положительное число, или как есть
                  '${formatMoney(model.data['change'])} ${model.data['currencyName'] ?? ''}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
