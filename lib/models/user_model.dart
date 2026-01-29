import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mdokon/helpers/api.dart';
import 'package:flutter_mdokon/helpers/helper.dart';
import 'package:flutter_mdokon/widgets/complete.dart';
import 'package:flutter_mdokon/widgets/update.dart';
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

  Future getPaymentTypes(posId) async {
    final response = await get("/services/desktop/api/payment-type-helper/$posId");
    try {
      if (httpOk(response) && response.length > 0) {
        paymentTypes = response;
        storage.write('paymentTypes', response);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future getCashboxSettings(posId) async {
    final response = await get("/services/desktop/api/cashbox-settings/$posId");
    response['cashboxSettings'] = jsonDecode(response['cashboxSettings']);
    response['chequeSettings'] = jsonDecode(response['chequeSettings']);
    response['userSettings'] = jsonDecode(response['userSettings']);
    cashboxSettings = response;
    storage.write('cashboxSettings', response);
  }

  setVersion(String version) async {
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
