// Кредитный лимит клиента — порт `src/helpers/debtLimit.js` из desktop-кассы.
//
// Владелец задаёт клиенту максимальную сумму долга (`clients.debt_limit`), всегда
// В СУМАХ. `0` — без ограничения. Касса получает лимит полем `debtLimit`.
//
// Проверку делает и сервер при создании чека (`error.client.debt.limit`), но касса
// печатает чек ДО синхронизации и умеет работать офлайн — если полагаться только
// на сервер, кассир узнает о превышении тогда, когда чек уже отдан покупателю.
// Поэтому тот же расчёт повторяем локально, до пробития.
//
// Знак баланса: долг хранится ОТРИЦАТЕЛЬНЫМ. Положительный баланс — переплата.
//
// Расчёт намеренно «мягкий»: если чего-то не хватает (курса валюты, самого
// лимита), локальная проверка пропускает продажу и последнее слово остаётся за
// сервером — ложная блокировка кассы хуже, чем поздний отказ синхронизации.

const int currencyUzs = 1;
const int currencyUsd = 2;

/// Погрешность сравнения: суммы после пересчёта USD → сумы дробные, а лимит
/// хранится как numeric(18,3). Без допуска чек ровно «в лимит» иногда падал бы.
const double _epsilon = 0.001;

num _num(dynamic v) {
  if (v is num) return v.isFinite ? v : 0;
  final n = num.tryParse('$v');
  return (n != null && n.isFinite) ? n : 0;
}

bool _isEmpty(dynamic v) => v == null || v == '';

/// Уже использованный долг, посчитанный сервером (`usedDebt`) — всегда В СУМАХ и
/// уже сведён по всем валютам. Самый надёжный источник: курс точки кассе не
/// приходит, а без него долларовую часть баланса локально не пересчитать.
num? readUsedDebt(Map? client) {
  final raw = client?['usedDebt'] ?? client?['used_debt'];
  if (_isEmpty(raw)) return null;
  final value = num.tryParse('$raw');
  if (value == null || !value.isFinite) return null;
  return value.abs();
}

/// Валюта записи баланса: в разных ответах приходит то `currencyId`, то только
/// название.
int resolveCurrencyId(Map? entry) {
  final id = _num(entry?['currencyId']).toInt();
  if (id != 0) return id;
  final name = '${entry?['currencyName'] ?? ''}'.toLowerCase();
  if (name.contains('usd') || name.contains('дол') || name.contains('dol')) {
    return currencyUsd;
  }
  return currencyUzs;
}

/// Курс точки, выведенный из данных самого клиента: скалярный `balance` сведён в
/// сумы, а `balanceList` разложен по валютам, поэтому разница даёт курс, по
/// которому сервер считал долг. Нужен, когда касса курса не знает, а продажа идёт
/// в долларах. 0 — вывести не удалось.
num deriveCurrencyRate(Map? client) {
  final scalar = client?['balance'];
  final list = client?['balanceList'];
  if (_isEmpty(scalar) || list is! List || list.isEmpty) return 0;

  num uzs = 0;
  num usd = 0;
  for (final entry in list.whereType<Map>()) {
    final amount = _num(entry['totalAmount'] ?? entry['balance'] ?? 0);
    if (resolveCurrencyId(entry) == currencyUsd) {
      usd += amount;
    } else {
      uzs += amount;
    }
  }
  if (usd == 0) return 0;

  final rate = (_num(scalar) - uzs) / usd;
  // Отсечка на мусор: курс сума к доллару заведомо в этом диапазоне, а при
  // расхождении данных формула легко даёт ноль или отрицательное число.
  if (!rate.isFinite || rate < 100 || rate > 1000000) return 0;
  return rate;
}

/// Лимит из карточки клиента. Терпим к имени поля: разные эндпоинты кассы отдают
/// то camelCase, то snake_case — при промахе лимит молча стал бы «без ограничения».
num readDebtLimit(Map? client) {
  final raw = client?['debtLimit'] ??
      client?['debt_limit'] ??
      client?['creditLimit'] ??
      client?['credit_limit'];
  return _num(raw);
}

/// Сумма в сумах. `null` — пересчитать нельзя (валюта не сумовая, а курс точки
/// неизвестен).
num? amountToUzs(dynamic amount, dynamic currencyId, dynamic currencyRate) {
  final value = _num(amount);
  if (_num(currencyId).toInt() != currencyUsd) return value;
  final rate = _num(currencyRate);
  if (rate <= 0) return null;
  return value * rate;
}

/// Курс, с которым работает проверка: известный курс точки, иначе выведенный из
/// баланса самого клиента.
num effectiveRate(Map? client, dynamic currencyRate) {
  final known = _num(currencyRate);
  return known != 0 ? known : deriveCurrencyRate(client);
}

/// Текущий долг клиента в сумах.
/// `unknown = true` — часть сумм не пересчитана (нет курса), итог занижен.
///
/// Порядок источников важен:
///   1. `usedDebt` — сервер уже свёл весь долг клиента в сумы, курс не нужен;
///   2. `balance` — скаляр, тоже ВСЕГДА в сумах (не зависит от валюты точки);
///   3. `balanceList` — запасной путь: разложен по валютам, и без курса
///      долларовая строка не пересчитывается (unknown).
({num debt, bool unknown}) clientDebtUzs(Map? client, dynamic currencyRate) {
  final used = readUsedDebt(client);
  if (used != null) return (debt: used, unknown: false);

  final scalar = client?['balance'];
  if (!_isEmpty(scalar)) {
    final value = _num(scalar);
    return (debt: value < 0 ? -value : 0, unknown: false);
  }

  final list = client?['balanceList'];
  final rate = effectiveRate(client, currencyRate);
  num signed = 0;
  var unknown = false;

  if (list is List && list.isNotEmpty) {
    for (final entry in list.whereType<Map>()) {
      final amount = entry['totalAmount'] ?? entry['balance'] ?? 0;
      final uzs = amountToUzs(amount, resolveCurrencyId(entry), rate);
      if (uzs == null) {
        unknown = true;
        continue;
      }
      signed += uzs;
    }
  }

  return (debt: signed < 0 ? -signed : 0, unknown: unknown);
}

/// Состояние лимита клиента для показа кассиру.
class DebtLimitInfo {
  const DebtLimitInfo({
    required this.unlimited,
    required this.unknown,
    required this.limit,
    required this.currentDebt,
    required this.available,
  });

  final bool unlimited;
  final bool unknown;
  final num limit;
  final num currentDebt;

  /// `double.infinity`, когда лимита нет.
  final num available;
}

/// Состояние лимита клиента.
/// [pendingDebtUzsAmount] — долг по локальным (ещё не синхронизированным) чекам
/// этого клиента: офлайн баланс с сервера устаревает после первой же продажи в долг.
DebtLimitInfo debtLimitInfo(Map? client, dynamic currencyRate,
    [dynamic pendingDebtUzsAmount = 0]) {
  final limit = readDebtLimit(client);
  final debt = clientDebtUzs(client, currencyRate);
  final currentDebt = debt.debt + _num(pendingDebtUzsAmount);
  final rest = limit - currentDebt;
  return DebtLimitInfo(
    unlimited: limit <= 0,
    unknown: debt.unknown,
    limit: limit,
    currentDebt: currentDebt,
    available: limit > 0 ? (rest > 0 ? rest : 0) : double.infinity,
  );
}

/// Вердикт локальной проверки кредитного лимита.
/// `checked = false` — проверка не проводилась (лимита нет или не хватило данных),
/// `exceeded = true` — сервер такой чек отклонит, пробивать нельзя.
class DebtLimitCheck {
  const DebtLimitCheck({
    required this.checked,
    required this.exceeded,
    required this.limit,
    required this.currentDebt,
    required this.newDebt,
    required this.total,
    required this.available,
    required this.unknownPart,
  });

  final bool checked;
  final bool exceeded;
  final num limit;
  final num currentDebt;
  final num newDebt;
  final num total;
  final num available;
  final bool unknownPart;
}

/// Пройдёт ли продажа в долг на сумму [addAmount] (в валюте [addCurrencyId]).
DebtLimitCheck checkClientDebtLimit({
  Map? client,
  dynamic addAmount,
  dynamic addCurrencyId,
  dynamic currencyRate,
  dynamic pendingDebtUzsAmount = 0,
}) {
  final info = debtLimitInfo(client, currencyRate, pendingDebtUzsAmount);
  DebtLimitCheck unchecked({bool exceeded = false, num? newDebt, num? total}) =>
      DebtLimitCheck(
        checked: false,
        exceeded: exceeded,
        limit: info.limit,
        currentDebt: info.currentDebt,
        newDebt: newDebt ?? 0,
        total: total ?? info.currentDebt,
        available: info.available,
        unknownPart: info.unknown,
      );

  if (info.unlimited) return unchecked();

  final newDebt = amountToUzs(_num(addAmount).abs(), addCurrencyId,
      effectiveRate(client, currencyRate));
  // Сумму нового долга не пересчитать — решает сервер.
  if (newDebt == null) return unchecked();

  final total = info.currentDebt + newDebt;
  final exceeded = total - info.limit > _epsilon;

  // Часть долга не пересчитана (нет курса) — она может долг только УВЕЛИЧИТЬ.
  // Поэтому «превышено» по известной части достоверно и блокирует продажу,
  // а «не превышено» — нет, тут последнее слово за сервером.
  if (info.unknown && !exceeded) return unchecked();

  return DebtLimitCheck(
    checked: true,
    exceeded: exceeded,
    limit: info.limit,
    currentDebt: info.currentDebt,
    newDebt: newDebt,
    total: total,
    available: info.available,
    unknownPart: info.unknown,
  );
}

/// Долг по локальным несинхронизированным чекам клиента, в сумах.
/// [rows] — `[{clientCurrencyId, amount}]` из локальной БД.
num pendingDebtUzs(List? rows, dynamic currencyRate) {
  if (rows == null) return 0;
  num total = 0;
  for (final row in rows.whereType<Map>()) {
    final uzs = amountToUzs(
        _num(row['amount']).abs(), row['clientCurrencyId'], currencyRate);
    if (uzs == null) continue;
    total += uzs;
  }
  return total;
}
