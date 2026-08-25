// Платные SMS кассы — порт `src/helpers/smsQuota.js` из desktop-кассы.
//
// С 2026-09-01 первые 500 успешно отправленных SMS точки за календарный месяц
// бесплатны. Сверх лимита каждое SMS списывает `pos.price_sms` (пусто или 0 →
// 150 сум) с того же баланса точки, с которого идёт абонплата. Денег не хватило —
// SMS просто не уходит: продажа, возврат и погашение долга проходят как обычно,
// клиент лишь не получает уведомление.
//
// Касса ничего не считает сама: и лимит, и цену, и решение «можно ли отправить
// сейчас» отдаёт `GET /desktop/api/sms-quota`. Здесь только приведение ответа к
// предсказуемому виду (поля терпимы к пропускам, чтобы недоехавший ответ не
// превратился в ложную блокировку) и выбор того, что показать кассиру.

/// Порог «бесплатные заканчиваются»: с этого остатка предупреждаем при открытии
/// смены.
const int kSmsQuotaLowLeft = 50;

/// Цена SMS по умолчанию — та же, что на бэкенде, если `pos.price_sms` пуста.
const int kSmsDefaultPrice = 150;

num _num(dynamic v) {
  if (v is num) return v.isFinite ? v : 0;
  final n = num.tryParse('$v');
  return (n != null && n.isFinite) ? n : 0;
}

num _atLeastZero(num v) => v > 0 ? v : 0;

/// Что показывать кассиру.
enum SmsQuotaLevel {
  /// Платность ещё не включена (или ответа нет): молчим, как раньше.
  none,

  /// Лимит действует, бесплатных ещё много.
  ok,

  /// Бесплатные заканчиваются.
  low,

  /// Бесплатные кончились, но баланс позволяет отправлять платные.
  paid,

  /// SMS клиентам больше не уходят.
  blocked,
}

/// Ответ `SmsQuotaDTO`, приведённый к предсказуемому виду.
class SmsQuota {
  const SmsQuota({
    required this.paidActive,
    required this.paidFrom,
    required this.freeLimit,
    required this.usedCount,
    required this.freeLeft,
    required this.price,
    required this.balance,
    required this.canSend,
    required this.affordable,
  });

  final bool paidActive;
  final String? paidFrom;
  final num freeLimit;
  final num usedCount;
  final num freeLeft;
  final num price;
  final num balance;
  final bool canSend;

  /// На сколько платных SMS хватит остатка баланса — это и показываем кассиру.
  final int affordable;

  SmsQuotaLevel get level {
    if (!paidActive) return SmsQuotaLevel.none;
    if (!canSend) return SmsQuotaLevel.blocked;
    if (freeLeft <= 0) return SmsQuotaLevel.paid;
    if (freeLeft <= kSmsQuotaLowLeft) return SmsQuotaLevel.low;
    return SmsQuotaLevel.ok;
  }
}

/// Ответ сервера → [SmsQuota]. `null`, если ответа нет (офлайн, старый сервер,
/// 404 до деплоя) — тогда касса ничего не показывает и ведёт себя как раньше.
SmsQuota? normalizeSmsQuota(dynamic raw) {
  if (raw is! Map) return null;

  final paidActive = raw['paidActive'] == true;
  final freeLimit = _atLeastZero(_num(raw['freeLimit']));
  final usedCount = _atLeastZero(_num(raw['usedCount']));
  final freeLeft = raw['freeLeft'] == null
      ? _atLeastZero(freeLimit - usedCount)
      : _atLeastZero(_num(raw['freeLeft']));
  final rawPrice = _num(raw['price']);
  final price = rawPrice > 0 ? rawPrice : kSmsDefaultPrice;
  final balance = _num(raw['balance']);
  // canSend считает сервер; повторяем формулу только если поля нет (старый ответ).
  final canSend = raw['canSend'] is bool
      ? raw['canSend'] as bool
      : (!paidActive || freeLeft > 0 || balance >= price);

  return SmsQuota(
    paidActive: paidActive,
    paidFrom: raw['paidFrom'] == null ? null : '${raw['paidFrom']}',
    freeLimit: freeLimit,
    usedCount: usedCount,
    freeLeft: freeLeft,
    price: price,
    balance: balance,
    canSend: canSend,
    affordable: (_atLeastZero(balance) / price).floor(),
  );
}

/// Уровень квоты. `null` → [SmsQuotaLevel.none].
SmsQuotaLevel smsQuotaLevel(SmsQuota? quota) =>
    quota?.level ?? SmsQuotaLevel.none;

/// Уровни, о которых кассира стоит предупредить при открытии смены.
bool isSmsQuotaAlert(SmsQuotaLevel level) =>
    level == SmsQuotaLevel.low ||
    level == SmsQuotaLevel.paid ||
    level == SmsQuotaLevel.blocked;

/// Ключ перевода и подстановки для кассира. `null` — показывать нечего.
///
/// Локализация остаётся на стороне UI: движок чистый и про `context.tr` не знает.
({String key, Map<String, String> args})? smsQuotaMessage(SmsQuota? quota) {
  final level = smsQuotaLevel(quota);
  if (level == SmsQuotaLevel.none) return null;
  if (level == SmsQuotaLevel.blocked) {
    return (key: 'sms_quota_blocked', args: const {});
  }
  if (level == SmsQuotaLevel.paid) {
    return (
      key: 'sms_quota_paid',
      args: {
        'price': '${quota!.price}',
        'count': '${quota.affordable}',
      }
    );
  }
  return (
    key: level == SmsQuotaLevel.low ? 'sms_quota_low' : 'sms_quota_ok',
    args: {
      'left': '${quota!.freeLeft}',
      'limit': '${quota.freeLimit}',
    }
  );
}
