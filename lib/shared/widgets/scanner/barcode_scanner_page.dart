import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

/// Сканер штрих-кодов и кодов маркировки на камере устройства.
///
/// Заменил `simple_barcode_scanner`: тот открывал внешний экран пакета и умел
/// только линейные штрих-коды, а коды маркировки «Asl Belgisi» — это DataMatrix.
/// Здесь набор форматов задаётся явно ([_formats]), поэтому одной кнопкой
/// сканируются и EAN с упаковки, и DataMatrix с акцизной марки.
///
/// Экран возвращает сырую строку кода или `null`, если кассир вышел назад:
/// разбор — не его дело, этим занимается `parseScannedInput`.
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key, this.title});

  /// Заголовок в шапке; по умолчанию — «Сканирование».
  final String? title;

  /// Открыть сканер. `null` — камеру не дали или кассир вышел назад.
  ///
  /// Разрешение спрашивается здесь же: до `Navigator.push` его нет смысла
  /// откладывать, а каждый вызывающий экран повторял этот код у себя.
  static Future<String?> scan(BuildContext context, {String? title}) async {
    final granted = await _ensureCameraPermission();
    if (!granted || !context.mounted) return null;

    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => BarcodeScannerPage(title: title)),
    );
  }

  static Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

/// Что ищем в кадре. DataMatrix — коды маркировки, остальное — обычные
/// товарные штрих-коды. Ограниченный список ускоряет распознавание и не даёт
/// поймать посторонний QR с рекламы на упаковке.
const List<BarcodeFormat> _formats = [
  BarcodeFormat.dataMatrix,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.itf14,
  BarcodeFormat.itf2of5,
  BarcodeFormat.codabar,
  BarcodeFormat.qrCode,
];

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: _formats,
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoZoom: true,
  );

  /// Экран закрывается по первому коду; флаг гасит повторные срабатывания,
  /// пока анимация закрытия ещё идёт.
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (code.isEmpty) return;

    _handled = true;
    Vibration.vibrate(amplitude: 10, duration: 30);
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    // Поверх камеры цвета всегда светлые на тёмном — кадр не зависит от темы.
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          widget.title ?? context.tr('scan_code'),
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          tooltip: context.tr('back'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, child) {
              final on = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(on ? Icons.flash_on : Icons.flash_off),
                onPressed: state.isInitialized ? () => _controller.toggleTorch() : null,
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ScannerError(error: error),
          ),
          const IgnorePointer(child: _ScannerFrame()),
        ],
      ),
    );
  }
}

/// Рамка прицела: подсказывает, куда наводить, и закрывает края кадра.
class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.78,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white70, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

/// Камера не поднялась: показываем причину и путь в настройки — иначе экран
/// остаётся чёрным и кассир не понимает, что делать.
class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                context.tr(denied ? 'camera_access_denied' : 'camera_unavailable'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              if (denied) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: openAppSettings,
                  child: Text(context.tr('settings')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
