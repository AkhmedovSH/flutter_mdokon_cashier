import 'package:permission_handler/permission_handler.dart';

/// Итог запроса разрешения. `permanentlyDenied` отделён от `denied`
/// намеренно: в первом случае системный диалог больше не покажется и
/// единственный выход — отправить кассира в настройки приложения.
enum PermissionOutcome { granted, denied, permanentlyDenied }

extension PermissionOutcomeX on PermissionOutcome {
  bool get isGranted => this == PermissionOutcome.granted;
  bool get needsSettings => this == PermissionOutcome.permanentlyDenied;
}

/// Разрешения, которые нужны кассе: камера для сканера и Bluetooth для
/// чекового принтера. Собраны в одном месте, чтобы правила «что и когда
/// спрашивать» не расползались по экранам.
class AppPermissions {
  const AppPermissions._();

  /// Камера — сканирование штрих-кодов и кодов маркировки.
  static Future<PermissionOutcome> camera() => _ensure(Permission.camera);

  /// Bluetooth для поиска и подключения принтера.
  ///
  /// На Android 12+ достаточно BLUETOOTH_SCAN/CONNECT, причём скан объявлен
  /// с `neverForLocation`, поэтому геолокацию там не спрашиваем вовсе.
  /// На Android 11 и ниже скан без геолокации возвращает пустой список —
  /// туда и уходит запрос location, но только если scan-разрешение не дали
  /// (на старых версиях оно не существует).
  static Future<PermissionOutcome> bluetooth() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    final connect = statuses[Permission.bluetoothConnect] ?? PermissionStatus.granted;
    final scan = statuses[Permission.bluetoothScan] ?? PermissionStatus.granted;

    if (connect.isPermanentlyDenied || scan.isPermanentlyDenied) {
      return PermissionOutcome.permanentlyDenied;
    }
    if (connect.isGranted && scan.isGranted) return PermissionOutcome.granted;

    // Android ≤ 30: BLUETOOTH_SCAN как отдельного разрешения нет, вместо него
    // система требует доступ к местоположению.
    return _ensure(Permission.locationWhenInUse);
  }

  static Future<PermissionOutcome> _ensure(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied) return PermissionOutcome.permanentlyDenied;

    status = await permission.request();
    if (status.isGranted) return PermissionOutcome.granted;
    if (status.isPermanentlyDenied) return PermissionOutcome.permanentlyDenied;

    return PermissionOutcome.denied;
  }

  /// Открыть системные настройки приложения — единственный путь после
  /// «Больше не спрашивать».
  static Future<bool> openSettings() => openAppSettings();
}
