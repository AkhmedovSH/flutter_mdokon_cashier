import 'package:flutter_mdokon/core/network/api.dart';

// Проверка кода маркировки в ЦРПТ через бэкенд — порт `src/api/apiMarking.js`.
//
// Вызов «защищённый»: эндпоинта может ещё не быть, ключа точки может не быть, интернета
// может не быть — во всех случаях возвращаем статус `unknown`, продажа при этом не
// блокируется. Кассир видит предупреждение, но чек пробить может.

/// Статус кода маркировки.
enum MarkingStatus {
  /// Код зарегистрирован и в обороте.
  ok,

  notRegistered,

  /// Выведен из оборота (уже продан, списан).
  withdrawn,

  /// Проверить не удалось.
  unknown,
}

/// Ключ перевода предупреждения кассиру. `null` — предупреждать не о чем.
String? markingWarningKey(MarkingStatus status) => switch (status) {
      MarkingStatus.ok => null,
      MarkingStatus.notRegistered => 'marking_not_registered',
      MarkingStatus.withdrawn => 'marking_withdrawn',
      MarkingStatus.unknown => 'marking_not_checked',
    };

const _okValues = [
  'ok',
  'true',
  'introduced',
  'in_circulation',
  'incirculation',
  'registered',
  'active',
  'sold_to_customer_ready',
];
const _notRegisteredValues = [
  'not_registered',
  'notregistered',
  'not_found',
  'notfound',
  'unknown_code',
  'emitted',
];
const _withdrawnValues = [
  'withdrawn',
  'retired',
  'sold',
  'written_off',
  'writtenoff',
  'out_of_circulation',
];

bool _matches(dynamic value, List<String> list) =>
    list.contains('${value ?? ''}'.trim().toLowerCase());

/// Результат проверки кода.
class MarkingCheckResult {
  const MarkingCheckResult({
    required this.status,
    this.gtin = '',
    this.identificationCode = '',
  });

  final MarkingStatus status;
  final String gtin;
  final String identificationCode;

  /// Ключ перевода предупреждения; `null` — всё в порядке.
  String? get warningKey => markingWarningKey(status);
}

const _unknown = MarkingCheckResult(status: MarkingStatus.unknown);

/// Ответ бэкенда → предсказуемый объект.
///
/// Поля терпимы к пропускам: сервер ещё может меняться.
MarkingCheckResult normalizeMarkingCheck(dynamic raw) {
  final data = raw is Map && raw['data'] is Map ? raw['data'] as Map : raw;
  if (data is! Map) return _unknown;

  final rawStatus = data['status'] ?? data['state'] ?? data['markingStatus'];
  var status = MarkingStatus.unknown;
  // `success` — «строка разобрана как код маркировки», это ещё не ответ ЦРПТ.
  // Ответ ЦРПТ есть только при `checked = true`; без него статус остаётся unknown
  // («код не проверен»): нет ключа точки, нет связи, ЦРПТ ответил ошибкой.
  if (data['checked'] == true || rawStatus != null) {
    if (data['registered'] == false) {
      status = MarkingStatus.notRegistered;
    } else if (_matches(rawStatus, _withdrawnValues)) {
      status = MarkingStatus.withdrawn;
    } else if (_matches(rawStatus, _notRegisteredValues)) {
      status = MarkingStatus.notRegistered;
    } else if (_matches(rawStatus, _okValues) || data['checked'] == true) {
      status = MarkingStatus.ok;
    }
  }

  return MarkingCheckResult(
    status: status,
    gtin: '${data['gtin'] ?? data['productCode'] ?? ''}'.replaceAll(RegExp(r'\D'), ''),
    identificationCode: '${data['identificationCode'] ?? data['markingCode'] ?? ''}',
  );
}

/// Доступ к API проверки маркировки.
class MarkingRepository {
  const MarkingRepository();

  /// Проверить код маркировки. Никогда не бросает и никогда не блокирует продажу:
  /// недоступный сервер = статус `unknown` («код не проверен»).
  Future<MarkingCheckResult> check(String code, dynamic posId) async {
    try {
      final response = await post(
        '/services/desktop/api/marking-check',
        {'code': code, 'posId': posId},
      );
      if (!httpOk(response)) return _unknown;
      return normalizeMarkingCheck(response);
    } catch (_) {
      return _unknown;
    }
  }
}
