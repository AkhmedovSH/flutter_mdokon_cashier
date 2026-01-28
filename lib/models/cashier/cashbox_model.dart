import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Assuming these are your existing imports based on the files provided
import '/helpers/api.dart';
import '/helpers/helper.dart';

class CashboxModel extends ChangeNotifier {
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

  final TextEditingController loyaltyCodeController = TextEditingController();
  final TextEditingController loyaltyPointsController = TextEditingController();
  final TextEditingController loyaltyInfoController = TextEditingController();
  final TextEditingController loyaltyBalanceController = TextEditingController();
  final TextEditingController loyaltyAwardController = TextEditingController();

  Future<void> init(Map initialData) async {
    data = Map.from(initialData);
    cashbox = storage.read('cashbox') ?? {};

    await initializeDataFields();
    notifyListeners();
  }

  Future<void> initializeDataFields() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    final username = storage.read('user')['username'];

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
    data['device'] = 'android';
    data['cashboxVersion'] = version;
    data['chequeDate'] = DateTime.now().toUtc().millisecondsSinceEpoch;
    data['posId'] = cashbox['posId'];
    data['chequeNumber'] = generateChequeNumber();
    data['transactionId'] = transactionId;
    data['paymentTypes'] = [...storage.read('paymentTypes')];
    for (var i = 0; i < data['paymentTypes'].length; i++) {
      data['paymentTypes'][i]['controller'] = TextEditingController();
    }
    data['paymentTypes'][0]['controller'].text = (data['totalPrice']).round().toString();

    data['change'] = 0.0;
    data['paid'] = 0.0;
  }

  setDataKey(key, value) {
    data[key] = value;
    notifyListeners();
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

  void updateInputs(index, value) {
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

    for (var i = 0; i < data['paymentTypes'].length; i++) {
      data['paymentTypes'][i]['amount'] = '';
      data['paymentTypes'][i]['controller'].text = '';
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

    for (var i = 0; i < data['paymentTypes'].length; i++) {
      paid += customNumber(data['paymentTypes'][i]['amount']);
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
      return (data['clientId'] ?? 0) == 0;
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
    notifyListeners();

    try {
      // var settings = jsonDecode(storage.read('settings'));

      Map<String, dynamic> dataCopy = Map.from(data);
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
        dataCopy['totalPrice'] = dataCopy['totalPriceBeforeDiscount'];
        dataCopy['discount'] = 0;
      }
      dataCopy['discountAmount'] ??= 0;

      // Credit specific logic for amounts
      if (currentIndex == 1) {
        dataCopy['paid'] = paid;
        dataCopy['clientAmount'] = change;
      }

      log(jsonEncode(dataCopy));
      log(jsonEncode(dataCopy['itemsList']));

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
      print(response);
      isLoading = false;
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
    loyaltyCodeController.dispose();
    loyaltyPointsController.dispose();
    loyaltyInfoController.dispose();
    loyaltyBalanceController.dispose();
    loyaltyAwardController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
