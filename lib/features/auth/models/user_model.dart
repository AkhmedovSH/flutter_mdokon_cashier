import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/shared/widgets/complete_dialog.dart';
import 'package:flutter_mdokon/shared/widgets/update.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UserModel extends ChangeNotifier {
  GetStorage storage = GetStorage();

  String localVersion = '';
  Map _user = {};
  Map _cashbox = {};
  Map cashboxSettings = {};
  List paymentTypes = [];

  UserModel(this._user, this._cashbox, this.paymentTypes);

  Map get user => _user;
  Map get cashbox => _cashbox;

  void setUser(Map payload) {
    log(payload.toString());
    _user = payload;
    storage.write('user', payload);
    notifyListeners();
  }

  void setCashbox(Map payload) {
    _cashbox = payload;
    storage.write('cashbox', payload);
    notifyListeners();
  }

  /// Почему в прошлый раз не вышло загрузить типы оплаты: пустой справочник
  /// на точке и отказ сервера — разные беды, а кассир видел один и тот же
  /// текст. Сообщение отсюда показывает экран входа.
  String paymentTypesError = '';

  Future getPaymentTypes(dynamic posId) async {
    paymentTypesError = '';
    final response = await get("/services/desktop/api/payment-type-helper/$posId");
    try {
      if (httpOk(response) && response.length > 0) {
        paymentTypes = response;
        storage.write('paymentTypes', response);
        return true;
      }
      paymentTypesError = httpOk(response)
          ? 'На точке (ID $posId) не настроен ни один тип оплаты. '
              'Добавьте их в кабинете и войдите снова'
          : 'Сервер не отдал типы оплаты для точки ID $posId: '
              '${_responseReason(response)}';
      return false;
    } catch (e) {
      paymentTypesError = 'Не разобрали ответ по типам оплаты (точка ID $posId): $e';
      return false;
    }
  }

  Future getCashboxSettings(dynamic posId) async {
    final response = await get("/services/desktop/api/cashbox-settings/$posId");
    if (!httpOk(response) || response is! Map) {
      throw Exception(
        'Настройки кассы (точка ID $posId) не получены: ${_responseReason(response)}',
      );
    }
    // Любая из трёх секций может прийти пустой — тогда говорим, какая именно,
    // вместо безымянного падения jsonDecode.
    response['cashboxSettings'] = _decodeSettings(response['cashboxSettings'], 'cashboxSettings', posId);
    response['chequeSettings'] = _decodeSettings(response['chequeSettings'], 'chequeSettings', posId);
    response['userSettings'] = _decodeSettings(response['userSettings'], 'userSettings', posId);
    cashboxSettings = response;
    storage.write('cashboxSettings', response);
  }

  dynamic _decodeSettings(dynamic raw, String name, dynamic posId) {
    if (raw == null) {
      throw Exception('Настройки «$name» пустые на точке ID $posId');
    }
    if (raw is! String) return raw;
    try {
      return jsonDecode(raw);
    } catch (e) {
      throw Exception('Настройки «$name» (точка ID $posId) пришли битыми: $e');
    }
  }

  /// Что именно сказал сервер — текст ошибки, код или «нет ответа».
  String _responseReason(dynamic response) {
    if (response == null) return 'нет ответа от сервера';
    if (response is Map) {
      final message = response['message'] ?? response['error'] ?? response['detail'];
      if (message != null && '$message'.isNotEmpty) return '$message';
      if (response['status'] != null) return 'код ${response['status']}';
    }
    return 'неожиданный ответ';
  }

  Future<void> setVersion(String version) async {
    localVersion = version;
    notifyListeners();
  }

  void checkVersion(BuildContext context) async {
    bool isRequired = false;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setVersion(packageInfo.version);
    String versionUrl = '/services/admin/api/get-version?name=com.mdokon.cabinet';
    var playMarketVersion = await get(versionUrl, isGuest: true);

    if (playMarketVersion == null || kDebugMode) {
      return;
    }
    try {
      int v1Number = getExtendedVersionNumber(packageInfo.version);
      int v2Number = getExtendedVersionNumber(playMarketVersion['version']);

      if (v2Number > v1Number) {
        if (customIf(playMarketVersion['required'])) {
          isRequired = true;
        } else {
          isRequired = false;
        }

        if (Platform.isIOS) {
          Future.delayed(Duration.zero, () async {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const UpdateDialog();
                },
              );
            }
          });
        } else {
          final info = await InAppUpdate.checkForUpdate();
          if (info.updateAvailability == UpdateAvailability.updateAvailable) {
            if (isRequired) {
              await InAppUpdate.performImmediateUpdate();
            } else {
              await InAppUpdate.startFlexibleUpdate();

              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const CompleteDialog();
                  },
                );
              }
            }
          } else {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const UpdateDialog();
                },
              );
            }
          }
        }
      }
    } catch (e) {
      showDangerToast(e);
    }
  }

  int getExtendedVersionNumber(String version) {
    List versionCells = version.split('.');
    versionCells = versionCells.map((i) => int.parse(i)).toList();
    return versionCells[0] * 100000 + versionCells[1] * 1000 + versionCells[2];
  }
}
