import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Assuming these are your existing imports based on the files provided
import 'package:flutter_mdokon/features/cashier/data/online_payment_repository.dart';
import 'package:flutter_mdokon/features/cashier/domain/cheque_format.dart';
import 'package:flutter_mdokon/features/cashier/domain/online_payment.dart';
import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';

class CashboxModel extends ChangeNotifier {
  CashboxModel({OnlinePaymentRepository? onlinePayments})
      : onlinePayments = onlinePayments ?? OnlinePaymentRepository();

  final GetStorage storage = GetStorage();

  bool isLoading = false;
  int currentIndex = 0;
  Map<String, dynamic> data = {
    "paymentTypes": [],
  };
  Map<String, dynamic> cashbox = {};

  String loyaltyPointsInput = "";
  String loyaltyCardInput = "";
  String clientComment = "";

  List<dynamic> clients = [];
  List<dynamic> allClients = [];
  Timer? _debounce;

  /// Код с телефона покупателя для Click Pass / Payme / Uzum.
  final TextEditingController otpController = TextEditingController();
  final OnlinePaymentRepository onlinePayments;

  final TextEditingController loyaltyCodeController = TextEditingController();
  final TextEditingController loyaltyPointsController = TextEditingController();
  final TextEditingController loyaltyInfoController = TextEditingController();
  final TextEditingController loyaltyBalanceController = TextEditingController();
  final TextEditingController loyaltyAwardController = TextEditingController();

  Future<void> init(Map initialData) async {
    data = Map<String, dynamic>.from(initialData);

    final storedCashbox = storage.read('cashbox');
    cashbox = storedCashbox is Map ? Map<String, dynamic>.from(storedCashbox) : {};

    await initializeDataFields();
    notifyListeners();
  }

  Future<void> initializeDataFields() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    final username = (storage.read('user') ?? {})['username'];

    if (storage.read('shift') != null) {
      final shift = storage.read('shift');
      data['shiftId'] = shift['id'];
    } else {
      data['shiftId'] = cashbox['id'];
    }

    final transactionId = generateTransactionId(
      cashbox['posId'].toString(),
      cashbox['cashboxId'].toString(),
      storage.read('shift') != null ? (storage.read('shift')!)['id'] : cashbox['cashboxId'].toString(),
    );

    data['login'] = username;
    data['cashierLogin'] = username;
    data['cashboxId'] = cashbox['cashboxId'];
    data['posName'] = cashbox['posName'];
    data['saleCurrencyId'] = data['currencyId'];
    data['device'] = 'android';
    data['cashboxVersion'] = version;
    data['chequeDate'] = DateTime.now().toUtc().millisecondsSinceEpoch;
    data['posId'] = cashbox['posId'];
    data['chequeNumber'] = generateChequeNumber();
    data['transactionId'] = transactionId;
    final storedPaymentTypes = storage.read('paymentTypes');
    data['paymentTypes'] = storedPaymentTypes is List
        ? storedPaymentTypes.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    for (var i = 0; i < data['paymentTypes'].length; i++) {
      data['paymentTypes'][i]['controller'] = TextEditingController();
    }
    if (data['paymentTypes'].isNotEmpty) {
      data['paymentTypes'][0]['amount'] = (data['totalPrice']).round();
      data['paymentTypes'][0]['controller'].text = (data['totalPrice']).round().toString();
    }

    data['change'] = 0.0;
    data['paid'] = 0.0;
    // Срок возврата относится только к продаже в долг.
    data['clientReturnDate'] = '';
  }

  void setDataKey(dynamic key, dynamic value) {
    data[key] = value;
    notifyListeners();
  }

  void clearInput(int index) {
    Map<String, dynamic> dataCopy = Map.from(data);
    dataCopy['paymentTypes'] = List.from(data['paymentTypes'].map((e) => Map.from(e)));

    dataCopy['paymentTypes'][index]['amount'] = '';
    dataCopy['paymentTypes'][index]['controller'].text = '';
    data = dataCopy;

    calculateChange();
  }

  void exactAmount(int index) {
    Map<String, dynamic> dataCopy = Map.from(data);
    dataCopy['paymentTypes'] = List.from(data['paymentTypes'].map((e) => Map.from(e)));

    double totalPrice = dataCopy['totalPrice'];
    double paid = 0;

    for (int i = 0; i < dataCopy['paymentTypes'].length; i++) {
      if (index != i) {
        paid += double.tryParse(dataCopy['paymentTypes'][i]['amount'].toString()) ?? 0;
      }
    }

    if (totalPrice > paid) {
      double remaining = totalPrice - paid;
      dataCopy['paymentTypes'][index]['amount'] = remaining.round();
      dataCopy['paymentTypes'][index]['controller'].text = remaining.round().toString();
    }
    data = dataCopy;

    calculateChange();
  }

  void updateInputs(dynamic index, dynamic value) {
    data['paymentTypes'][index]['amount'] = value.toString();
    data['paymentTypes'][index]['controller'].text = value.toString();

    calculateChange();
  }

  void setIndex(int index) {
    currentIndex = index;
    resetStateForTab();
    notifyListeners();
  }

  void resetStateForTab() {
    loyaltyPointsInput = "";
    clientComment = "";

    data['change'] = 0.0;
    data['paid'] = 0.0;

    loyaltyCodeController.clear();
    loyaltyPointsController.clear();
    loyaltyInfoController.clear();
    loyaltyBalanceController.clear();
    loyaltyAwardController.clear();
    data['writeOff'] = 0;

    final paymentTypes = (data['paymentTypes'] as List?) ?? const [];
    for (var i = 0; i < paymentTypes.length; i++) {
      paymentTypes[i]['amount'] = '';
      paymentTypes[i]['controller'].text = '';
    }

    if (paymentTypes.isEmpty) {
      return;
    }

    if (currentIndex == 0) {
      data['paymentTypes'][0]['amount'] = data['totalPrice'].toString();
      data['paymentTypes'][0]['controller'].text = data['totalPrice'].toString();

      calculateChange();
    } else if (currentIndex == 1) {
      double total = double.parse(data['totalPrice'].toString());
      data['change'] = -total;
      calculateChange();
    } else if (currentIndex == 2) {
      data['paymentTypes'][0]['amount'] = data['totalPrice'].toString();
      data['paymentTypes'][0]['controller'].text = data['totalPrice'].toString();
    }
  }

  void calculateChange() {
    double paid = 0.0;

    final paymentTypes = (data['paymentTypes'] as List?) ?? const [];
    for (var i = 0; i < paymentTypes.length; i++) {
      paid += customNumber(paymentTypes[i]['amount']);
    }

    double totalPrice = double.parse(data['totalPrice'].toString());
    double change;

    if (currentIndex == 1) {
      change = paid - totalPrice;
    } else {
      change = paid - totalPrice;
    }

    data['change'] = change;
    data['paid'] = paid;

    if (currentIndex == 1) {
      data['clientComment'] = clientComment;
    }

    notifyListeners();
  }

  void updateLoyaltyInput(String value, String type) {
    if (type == 'card') {
      loyaltyCardInput = value;
      _searchLoyaltyUser();
    } else if (type == 'points') {
      _validatePointsInput(value);
    } else if (type == 'cash') {
      // cashInput = value;
      _calculateLoyaltyAward('cash');
    } else if (type == 'terminal') {
      // terminalInput = value;
      _calculateLoyaltyAward('terminal');
    }
  }

  void _validatePointsInput(String value) {
    double currentBalance = double.tryParse(data['loyaltyClientBalance'].toString()) ?? 0;
    double val = double.tryParse(value) ?? 0;

    if (val > currentBalance) {
      // Logic to prevent input exceeding balance is usually UI handled,
      // but we reset the input here to max balance
      loyaltyPointsInput = currentBalance.toString();
    } else {
      loyaltyPointsInput = value;
    }
    _calculateLoyaltyAward('points');
  }

  void _calculateLoyaltyAward(String triggerType) {
    // double total = double.parse(data['totalPrice'].toString());
    // double points = double.tryParse(loyaltyPointsInput) ?? 0;

    // // Logic from loyalty.dart: update cash if points change
    // if (triggerType == 'points') {
    //   cashInput = (total - points).toStringAsFixed(0);
    // }

    // // Recalculate totals
    // double cash = double.tryParse(cashInput) ?? 0;
    // double terminal = double.tryParse(terminalInput) ?? 0;

    // double totalPaid = points + cash + terminal;

    // data['writeOff'] = points;
    // data['paid'] = totalPaid;
    notifyListeners();
  }

  // --- CLIENTS / CREDIT LOGIC ---

  Future<void> fetchClients() async {
    final response = await get('/services/desktop/api/clients-helper');
    if (response != null) {
      // Add 'selected' key manually as per original logic
      List<dynamic> parsed = [];
      for (var c in response) {
        var map = Map<String, dynamic>.from(c);
        map['selected'] = false;
        parsed.add(map);
      }
      allClients = parsed;
      clients = parsed;
      notifyListeners();
    }
  }

  void searchClients(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        clients = allClients;
      } else {
        clients = allClients.where((client) {
          final nameMatch = client['name']?.toLowerCase().contains(query.toLowerCase()) ?? false;
          final phoneMatch = client['phone1']?.toLowerCase().contains(query.toLowerCase()) ?? false;
          return nameMatch || phoneMatch;
        }).toList();
      }
      notifyListeners();
    });
  }

  void selectClient(int index) {
    for (var i = 0; i < clients.length; i++) {
      clients[i]['selected'] = false;
    }
    clients[index]['selected'] = true;

    // Update data with selected client
    data['clientName'] = clients[index]['name'];
    data['clientId'] = clients[index]['id'];
    data['clientComment'] = clients[index]['comment'];
    notifyListeners();
  }

  Future<void> createNewClient(Map<String, dynamic> clientData) async {
    final response = await post('/services/desktop/api/clients', clientData);
    if (response != null && response['success']) {
      await fetchClients();
    }
  }

  bool get isSubmitDisabled {
    // if (isLoading) {
    //   print(isLoading);
    //   return false;
    // }
    if (currentIndex == 0) {
      print(data['change'] < 0);
      return data['change'] >= 0;
    }
    if (currentIndex == 1) {
      print(data['clientId']);
      return !((data['clientId'] ?? 0) == 0);
    }
    if (currentIndex == 2) {
      bool validClient = data['loyaltyClientName'] != null && data['clientCode'] != null;
      bool fullyPaid = (data['totalPrice'] ?? 0) == (data['paid'] ?? 0);
      return !(validClient && fullyPaid);
    }
    return true;
  }

  Future<bool> createCheque() async {
    // isLoading = true;
    // notifyListeners();

    try {
      Map<String, dynamic> dataCopy = Map.from(data);

      final user = storage.read('user') ?? {};
      final ownerLogin = user['ownerLogin'] ?? '';
      final cashierLogin = user['login'] ?? '';

      if (ownerLogin == "aksiya_market" || ownerLogin == "hp") {
        const requestIdValue = 1;
        const signatureValue = 'a3b5c7d9e1f2a4b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2b4';

        List<Map<String, dynamic>> productsList = [];
        List items = dataCopy['itemsList'] ?? [];

        // Разворачиваем список товаров по количеству (quantity)
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          // Преобразуем quantity в int, на случай если придет double
          int quantity = (double.tryParse(item['quantity'].toString()) ?? 1).toInt();

          for (int j = 0; j < quantity; j++) {
            productsList.add({
              "product_id": "${item['id']}",
              "amount": item['salePrice'],
            });
          }
        }

        final requestBody = {
          "receipt_id": dataCopy['transactionId'], // Убедитесь, что transactionId существует
          "total_amount": dataCopy['totalPrice'],
          "sold_at": DateTime.now().toString(), // Аналог responseDate.localDateTime
          "branch_id": "${dataCopy['posId']}",
          "cashier_id": "$cashierLogin",
          "items": productsList,
          "requestIdValue": requestIdValue,
          "signatureValue": signatureValue,
        };

        try {
          final promoResponse = await post("/services/desktop/api/promogo-generate", requestBody);

          if (!httpOk(promoResponse)) {
            return false;
          }

          if (promoResponse['result'] == null && promoResponse['message'] != null) {
            showDangerToast('${promoResponse['message']}');
            return false;
          }

          final result = promoResponse['result'];
          if (result != null && result['codes'] != null) {
            List codes = result['codes'];

            Map<String, List<String>> codesByProductId = {};
            for (var codeItem in codes) {
              String productIdKey = "${codeItem['product_id']}";
              codesByProductId.putIfAbsent(productIdKey, () => []).add(codeItem['code'].toString());
            }

            List newItemsList = [];

            for (var item in items) {
              Map<String, dynamic> newItem = Map.from(item);
              String productIdKey = "${newItem['id']}";

              int quantity = (double.tryParse(newItem['quantity'].toString()) ?? 1).toInt();

              if (codesByProductId.containsKey(productIdKey)) {
                List<String> availableCodes = codesByProductId[productIdKey]!;

                List<String> assignedCodes = [];

                for (int q = 0; q < quantity; q++) {
                  if (availableCodes.isNotEmpty) {
                    assignedCodes.add(availableCodes.removeAt(0));
                  }
                }

                if (assignedCodes.isNotEmpty) {
                  newItem['promoCodes'] = assignedCodes;
                }
              }
              newItemsList.add(newItem);
            }
            dataCopy['itemsList'] = newItemsList;
          }
        } catch (err) {
          isLoading = false;
          notifyListeners();
          print("Error in promogo-generate: $err");

          return false;
        }
      }

      double paid = 0.0;

      for (var i = 0; i < dataCopy['paymentTypes'].length; i++) {
        paid += customNumber(dataCopy['paymentTypes'][i]['amount']);
        dataCopy['paymentTypes'][i].remove('controller');
        // dataCopy['paymentTypes'][i]['controller'] = '';
      }

      for (var i = 0; i < (dataCopy['itemsList']?.length ?? 0); i++) {
        dataCopy['itemsList'][i]['scrollKey'] = null;
      }

      if (currentIndex == 2) {
        dataCopy['clientId'] = 0;
        dataCopy['clientAmount'] = 0;
        dataCopy['clientComment'] = "";
      }

      if (currentIndex == 1) {
        dataCopy.remove('loyaltyBonus');
        dataCopy.remove('loyaltyClientAmount');
        dataCopy.remove('loyaltyClientName');
      }

      double change = double.parse(dataCopy['change'].toString());

      if ((dataCopy['clientId'] ?? 0) != 0) {
        dataCopy['change'] = 0;
      }

      if ((dataCopy['discount'] ?? 0) > 0) {
        dataCopy = toGrossCheque(dataCopy);
        dataCopy['discount'] = 0;
      }
      dataCopy['discountAmount'] ??= 0;

      if (currentIndex == 0 || currentIndex == 1) {
        dataCopy['paid'] = paid;
        dataCopy['clientAmount'] = change;
      }

      // Онлайн-оплата — до пробития чека: не прошла оплата, не пробиваем чек.
      if (!await _payOnline(dataCopy)) {
        isLoading = false;
        notifyListeners();
        return false;
      }

      // Отправка основного запроса
      final response = await post('/services/desktop/api/cheque-v2', dataCopy);

      if (currentIndex == 2) {
        var sendData = {
          "cashierName": dataCopy['loyaltyClientName'],
          "chequeDate": getUnixTime().toString().substring(0, 10),
          "chequeId": response['id'],
          "clientCode": dataCopy['clientCode'],
          "key": cashbox['loyaltyApi'],
          "products": [],
          "totalAmount": dataCopy['totalPrice'],
          "writeOff": dataCopy['loyaltyBonus'] ?? 0,
        };

        for (var item in dataCopy['itemsList']) {
          sendData['products'].add({
            "amount": item['salePrice'],
            "barcode": item['barcode'],
            "name": item['productName'],
            "quantity": item['quantity'],
            "unit": item['uomId'],
          });
        }
        await lPost('/services/gocashapi/api/create-cheque', sendData);
      }

      // Printer Logic (Commented out in original, kept here for reference)
      // if (settings['printAfterSale']) { ... }
      isLoading = false;
      data = dataCopy;
      notifyListeners();

      if (httpOk(response) && response['success']) {
        return true;
      }
      return false;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print("Error submitting cheque: $e");
      return false;
    }
  }

  // --- ОНЛАЙН-ОПЛАТА (Click Pass / Payme / Uzum) --------------------------

  /// Выбран ли онлайн-способ оплаты — от этого зависит поле кода в UI.
  OnlinePaymentSelection? get onlinePayment =>
      detectOnlinePayment(data['paymentTypes'] as List?);

  String get otpCode => otpController.text.trim();

  /// Провести оплату у провайдера и дописать её реквизиты в чек.
  ///
  /// `true` — платить нечем (обычный чек) или оплата прошла. `false` — оплата
  /// не прошла, кассир уже увидел сообщение провайдера.
  Future<bool> _payOnline(Map<String, dynamic> dataCopy) async {
    final selection = detectOnlinePayment(dataCopy['paymentTypes'] as List?);
    if (selection == null) return true;

    final provider = selection.provider;
    dataCopy['onlaynAmount'] = selection.amount;
    dataCopy['paymentTypeId'] = onlineProviderPaymentTypeId(provider);
    dataCopy['otpCustomPaymentTypeId'] = selection.customPaymentTypeId;

    final code = otpCode;
    if (code.isEmpty) {
      showDangerToast(tr('otp_code_required'));
      return false;
    }

    final rawMerchant = cashbox[onlineProviderCashboxKey(provider)];
    final merchant = rawMerchant is Map ? Map<String, dynamic>.from(rawMerchant) : null;
    final auth = onlineAuthFromCashbox(
      provider,
      merchant,
      DateTime.now().millisecondsSinceEpoch,
    );
    if (auth == null) {
      showDangerToast(tr('online_payment_no_merchant', args: [onlineProviderName(provider)]));
      return false;
    }

    final cashboxCode = onlineCashboxCode(
      posId: cashbox['posId'],
      cashboxId: cashbox['cashboxId'],
      shiftId: dataCopy['shiftId'] ?? cashbox['id'],
    );

    final result = switch (provider) {
      OnlineProvider.click => await onlinePayments.payClick(
          auth: auth,
          payload: clickPayload(
            amount: selection.amount,
            cashboxCode: cashboxCode,
            otpCode: code,
            transactionId: dataCopy['transactionId'],
            serviceId: merchant?['merchant_service_id'],
          ),
        ),
      OnlineProvider.uzum => await onlinePayments.payUzum(
          auth: auth,
          payload: uzumPayload(
            amount: selection.amount,
            cashboxCode: cashboxCode,
            otpCode: code,
            transactionId: dataCopy['transactionId'],
            serviceId: merchant?['merchant_service_id'],
          ),
        ),
      OnlineProvider.payme => await onlinePayments.payPayme(
          auth: auth,
          otpCode: code,
          createPayload: paymeCreatePayload(
            chequeNumber: dataCopy['chequeNumber'],
            amount: selection.amount,
            itemsList: (dataCopy['itemsList'] as List?) ?? const [],
          ),
        ),
    };

    if (!result.ok) {
      showDangerToast(result.error ?? tr('online_payment_failed'));
      return false;
    }

    // Реквизиты платежа уходят на сервер вместе с чеком: по ним потом сверяют
    // выписку провайдера. Названия полей — как у десктопа.
    switch (provider) {
      case OnlineProvider.click:
        dataCopy['clickPaymentId'] = result.paymentId;
        dataCopy['clickClientPhone'] = result.clientPhone;
      case OnlineProvider.payme:
        dataCopy['paymePaymentId'] = result.paymentId;
        dataCopy['paymeClientPhone'] = result.clientPhone;
      case OnlineProvider.uzum:
        dataCopy['uzumPaymentId'] = result.paymentId;
        dataCopy['uzumClientPhone'] = result.clientPhone;
    }
    dataCopy['QRPaymentProvider'] = 161;
    return true;
  }

  void _searchLoyaltyUser() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      String input = loyaltyCodeController.text;
      if (input.length == 6 || input.length == 12) {
        List<Map<String, dynamic>> paymentTypesCopy = (data['paymentTypes'] as List).map((item) {
          var newItem = Map<String, dynamic>.from(item);
          newItem.remove('controller'); // Просто удаляем ключ, чтобы не слать его в API
          return newItem;
        }).toList();

        var sendData = {
          ...Map.from(data),
          'clientCode': input,
          'apiKey': cashbox['loyaltyApi'],
          'lang': "ru",
          'paymentTypes': paymentTypesCopy,
        };
        final response = await lPost('/services/gocashapi/api/user-all-info', {...sendData});

        if (response != null && response['userId'] != null) {
          data['loyaltyClientBalance'] = response['balance'];
          data['loyaltyClientName'] = '${response['firstName']} ${response['lastName']}';
          data['clientCode'] = input;
          data['award'] = response['award'].round();

          // Обновляем текст в контроллерах для отображения в UI
          loyaltyInfoController.text = data['loyaltyClientName'];
          loyaltyBalanceController.text = data['loyaltyClientBalance'].round().toString();
          loyaltyAwardController.text = data['award'].toString();

          notifyListeners();
        }
      }
    });
  }

  // Метод для обработки ввода баллов
  void updateLoyaltyPoints(String value) {
    double balance = double.tryParse(data['loyaltyClientBalance']?.toString() ?? '0') ?? 0;
    double enteredPoints = double.tryParse(value) ?? 0;

    if (enteredPoints > balance) {
      // Если ввели больше чем есть, обрезаем до баланса
      loyaltyPointsController.text = balance.round().toString();
      loyaltyPointsController.selection = TextSelection.fromPosition(
        TextPosition(offset: loyaltyPointsController.text.length),
      );
      data['writeOff'] = balance;
    } else {
      data['writeOff'] = enteredPoints;
    }

    calculateChange(); // Пересчитываем общую сумму к оплате
  }

  @override
  void dispose() {
    otpController.dispose();
    loyaltyCodeController.dispose();
    loyaltyPointsController.dispose();
    loyaltyInfoController.dispose();
    loyaltyBalanceController.dispose();
    loyaltyAwardController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
