import 'dart:math';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_mdokon/core/state/filter_model.dart';
import 'package:flutter_mdokon/core/theme/app_colors.dart';
import 'package:flutter_mdokon/core/theme/app_typography.dart';
import 'package:flutter_mdokon/shared/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';

import 'package:toastification/toastification.dart';
import 'package:unicons/unicons.dart';

// Глобальные цвета — алиасы токенов дизайн-системы (AppColors).
// Новые экраны используют AppColors напрямую, эти оставлены для совместимости
// с уже написанными экранами.
//
// Именно геттеры, а не переменные: глобальная переменная в Dart вычисляется
// один раз при первом обращении и запомнила бы палитру, активную в тот момент,
// — после переключения темы экран остался бы в старых цветах.
Color get mainColor => AppColors.primary;

Color get bgColor => AppColors.canvas;

Color get blue => AppColors.primary;
Color get grey => AppColors.textSecondary;
Color get black => AppColors.textPrimary;
Color get darkGrey => AppColors.textSecondary;
Color get lightGrey => AppColors.iconMuted;
Color get green => AppColors.success;
Color get red => AppColors.danger;
Color get orange => AppColors.warning;
Color get white => AppColors.surface;
Color get inputColor => AppColors.canvas;
Color get yellow => AppColors.warning;
Color get borderColor => AppColors.border;

Color get tableBorderColor => AppColors.border;
Color get disabledColor => AppColors.disabledSurface;

Color get success => AppColors.success;
Color get warning => AppColors.warning;
Color get danger => AppColors.danger;

Color get a2 => AppColors.iconMuted;
Color get b8 => AppColors.textSecondary;

const systemOverlayStyleLight = SystemUiOverlayStyle(
  statusBarIconBrightness: Brightness.light,
  statusBarColor: Colors.transparent,
);

const systemOverlayStyleDark = SystemUiOverlayStyle(
  statusBarIconBrightness: Brightness.dark,
  statusBarColor: Colors.transparent,
);

BoxShadow get boxShadow => AppDimens.cardShadow.first;

BoxDecoration get border => BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: AppDimens.card,
    );

OutlineInputBorder get inputBorder => OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.border),
      borderRadius: AppDimens.control,
    );

OutlineInputBorder get inputFocusBorder => OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      borderRadius: AppDimens.control,
    );

OutlineInputBorder get inputErrorBorder => OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.danger, width: 1.5),
      borderRadius: AppDimens.control,
    );

final List<Map<String, dynamic>> languages = [
  {
    "id": '1',
    "locale": 'ru',
    "name": 'Русский',
  },
  {
    "id": '3',
    "locale": 'uz',
    "name": 'O`zbekcha',
  },
];

int getUnixTime() {
  return DateTime.now().toUtc().millisecondsSinceEpoch;
}

String generateChequeNumber() {
  return getUnixTime().toString().substring(getUnixTime().toString().length - 8);
}

String generateTransactionId(dynamic posId, dynamic cashboxId, dynamic shiftId) {
  var random = Random();
  return posId.toString() + cashboxId.toString() + shiftId.toString() + getUnixTime().toString() + (random.nextInt(999999).floor().toString());
}

int daysBetween(dynamic from, DateTime to) {
  from = DateTime(from['year'], from['month'], from['day']);
  to = DateTime(to.year, to.month, to.day);
  return (to.difference(from).inHours / 24).round();
}

int minutesBetween(dynamic from, DateTime to) {
  from = DateTime(from['year'], from['month'], from['day'], from['hour'], from['minute']);
  to = DateTime(to.year, to.month, to.day, to.hour, to.minute);
  return to.difference(from).inMinutes;
}

String formatDateTime(dynamic date, {dynamic format = "yyyy-MM-dd"}) {
  return DateFormat(format).format(date);
}

String formatDate(dynamic date) {
  if (date == null) {
    return '';
  }
  DateTime rawDate = DateTime.parse(date);
  return DateFormat("dd.MM.yy HH:mm").format(rawDate);
}

String formatDateBackend(dynamic date, {dynamic format = "yyyy-MM-dd"}) {
  return DateFormat(format).format(date);
}

String formatDateMonth(dynamic date, {dynamic format = "dd.MM.yyyy"}) {
  DateTime rawDate = DateTime.parse(date);
  return DateFormat(format).format(rawDate);
}

String formatDateHour(dynamic date) {
  DateTime rawDate = DateTime.parse(date);
  return DateFormat("HH:mm").format(rawDate);
}

String formatUnixTime(dynamic unixTime) {
  if (unixTime == null) {
    return '';
  }
  var dt = DateTime.fromMillisecondsSinceEpoch(unixTime);
  return DateFormat('dd.MM.yyyy HH:mm:ss').format(dt);
}

dynamic formatPhone(dynamic phone) {
  if (phone.length >= 12) {
    var x = phone.substring(0, 3);
    var y = phone.substring(3, 5);
    var z = phone.substring(5, 8);
    var d = phone.substring(8, 10);
    var q = phone.substring(10, 12);
    return '+$x $y $z $d $q';
  } else {
    return phone;
  }
}

String formatMoney(dynamic amount, {dynamic decimalDigits = 0}) {
  if (decimalDigits == 0) {
    GetStorage storage = GetStorage();
    decimalDigits = ((storage.read('decimalDigits') ?? 0).round());
  }
  if (amount != null && amount != "") {
    amount = double.parse(amount.toString());
    return NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalDigits,
      locale: 'UZ',
    ).format(amount).replaceAll('\u00A0', ' ').replaceAll('\u202F', ' ').trimRight();
  } else {
    return NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalDigits,
      locale: 'UZ',
    ).format(0).trimRight();
  }
}

/// Количество товара: целое — без дробной части, дробное (весовой товар) —
/// без хвостовых нулей. [formatMoney] здесь не подходит: он округляет до
/// настроенной точности сумм и 2,5 кг показывает как «3».
String formatQuantity(dynamic quantity) {
  final value = customNumber(quantity);
  if (value == value.roundToDouble()) return value.round().toString();

  return value
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '')
      .replaceAll('.', ',');
}

Future<bool> hasInternetConnection() async {
  final dio = Dio();
  const url = 'https://backend.mison.uz';

  try {
    final response = await dio.get(url);
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

String findFromArrayById(List<Map<String, dynamic>> array, dynamic id) {
  if (array.isNotEmpty && id != null) {
    var item = array.firstWhere(
      (item) => item['id'].toString() == id.toString(),
      orElse: () => {}, // Return an empty map if not found
    );
    return item['name'] ?? ''; // Use empty string if 'name' is not present
  }
  return '';
}

bool checkRole(dynamic role) {
  GetStorage storage = GetStorage();
  List<dynamic> roles = storage.read<List<dynamic>>('user_roles') ?? [];
  return roles.contains(role);
}

bool customIf(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value == 0) {
    return false;
  }
  if (value is bool) {
    return value;
  }
  if (value is int && value <= 0) {
    return false;
  }
  if (value is String && (value == '' || value == ' ')) {
    return false;
  }
  return true;
}

double customNumber(dynamic value) {
  if (customIf(value)) {
    return double.parse(value.toString());
  }
  return 0;
}

/// Тост дизайн-системы: тёмная плашка #1B2138 (для ошибки/предупреждения —
/// dangerText / warningText), белый текст, радиус 12, высота 48, снизу.
void _showToast(
  dynamic message, {
  required Color background,
  required IconData icon,
  required ToastificationType type,
  dynamic description = "",
  Duration duration = const Duration(seconds: 3),
}) {
  toastification.show(
    title: Text(
      '$message',
      style: AppText.body.copyWith(color: AppColors.onPrimary),
    ),
    description: '$description'.isNotEmpty
        ? Text(
            '$description',
            style: AppText.small.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.72)),
          )
        : null,
    icon: Icon(icon, color: AppColors.onPrimary),
    primaryColor: background,
    backgroundColor: background,
    foregroundColor: AppColors.onPrimary,
    animationDuration: AppDimens.fast,
    autoCloseDuration: duration,
    type: type,
    style: ToastificationStyle.flat,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    margin: const EdgeInsets.symmetric(horizontal: AppDimens.gutter, vertical: AppDimens.gap4),
    alignment: Alignment.bottomCenter,
    borderRadius: AppDimens.control,
    borderSide: BorderSide.none,
    boxShadow: AppDimens.toastShadow,
    closeOnClick: true,
    showProgressBar: false,
    closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
  );
}

void showSuccessToast(dynamic message, {String description = ""}) {
  _showToast(
    message,
    description: description,
    background: AppColors.toast,
    icon: UniconsLine.check_circle,
    type: ToastificationType.success,
  );
}

void showDangerToast(dynamic message, {dynamic description = ""}) {
  _showToast(
    message,
    description: description,
    background: AppColors.dangerText,
    icon: UniconsLine.exclamation_triangle,
    type: ToastificationType.error,
    duration: const Duration(seconds: 4),
  );
}

void showWarningToast(dynamic message, {dynamic description = ""}) {
  _showToast(
    message,
    description: description,
    background: AppColors.warningText,
    icon: UniconsLine.exclamation_triangle,
    type: ToastificationType.warning,
    duration: const Duration(seconds: 4),
  );
}

/// Тост с действием: компактная плашка и кнопка отмены справа
/// (например «Товар · добавлен» + «Убрать»).
void showActionToast(
  BuildContext context,
  dynamic message, {
  required String actionLabel,
  required VoidCallback onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  toastification.showCustom(
    context: context,
    alignment: Alignment.bottomCenter,
    animationDuration: AppDimens.fast,
    autoCloseDuration: duration,
    builder: (context, item) => Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.gutter, vertical: AppDimens.gap4),
      child: Material(
        color: AppColors.toast,
        borderRadius: AppDimens.control,
        clipBehavior: Clip.antiAlias,
        elevation: 6,
        shadowColor: Colors.black26,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppDimens.gap16, AppDimens.gap12, AppDimens.gap8, AppDimens.gap12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$message',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(color: AppColors.onPrimary),
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              TextButton(
                onPressed: () {
                  toastification.dismiss(item);
                  onAction();
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: Text(
                  actionLabel,
                  style: AppText.small.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<Object?>? showFilterModal(BuildContext context, {required List<Widget> children}) async {
  return await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(
          title: 'filter',
          leading: true,
        ),
        body: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...children,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.53,
                    child: TextButton(
                      onPressed: () {
                        Provider.of<FilterModel>(context, listen: false).resetFilterData();
                        context.pop(true);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: black,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            UniconsLine.times,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            context.tr('reset_filter'),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        context.pop(true);
                      },
                      child: Text(context.tr('confirm')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
