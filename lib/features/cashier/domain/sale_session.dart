// Сохранение окна продажи между запусками приложения.
//
// Вкладки чеков живут в памяти (`sale_tabs.dart`), и до сих пор кассир,
// свернувший приложение или получивший его перезапуск от системы, возвращался
// к пустой корзине. Набор из тридцати позиций набирается заново дольше, чем
// длится сама продажа, поэтому снимок вкладок кладётся в `GetStorage` и
// поднимается при следующем открытии кассы.
//
// **Почему это не отменяет комментария в `sale_tabs.dart`.** Опасность там
// названа верно: чужой чек недельной давности, всплывший поверх новой смены, —
// это чужие суммы в корзине. Снимок поэтому подписан кассой, сменой и логином
// кассира и живёт [saleSessionMaxAge]; не совпало хоть что-то — сессия молча
// выбрасывается, и касса открывается пустой, как раньше.
//
// Здесь только чистые функции над снимком; состояние — в `SaleModel`.
library;

import 'dart:convert';

import 'package:flutter_mdokon/features/cashier/domain/sale_tabs.dart';

/// Ключ `GetStorage`, под которым лежит снимок окна продажи.
const String saleSessionStorageKey = 'saleSession';

/// Сколько живёт снимок. Смены обычно закрывают, но не всегда: касса могла
/// простоять выходные с тем же `shiftId`, и поднимать позавчерашнюю корзину
/// уже нельзя.
const Duration saleSessionMaxAge = Duration(hours: 12);

/// Чья это сессия. Снимок принадлежит паре «касса + смена + кассир»: сменился
/// любой из них — корзина уже не та, которую оставили.
class SaleSessionOwner {
  const SaleSessionOwner({this.posId, this.cashboxId, this.shiftId, this.login = ''});

  final dynamic posId;
  final dynamic cashboxId;
  final dynamic shiftId;
  final String login;

  Map<String, dynamic> toJson() => {
        'posId': '${posId ?? ''}',
        'cashboxId': '${cashboxId ?? ''}',
        'shiftId': '${shiftId ?? ''}',
        'login': login,
      };

  bool matches(Map? other) {
    if (other == null) return false;
    final mine = toJson();
    for (final key in mine.keys) {
      if ('${other[key] ?? ''}' != mine[key]) return false;
    }
    return true;
  }
}

/// Снимок вкладок строкой JSON или `null`, если чек не пережил сериализацию.
///
/// Строка, а не карта: `GetStorage` пишет файл сам и на не сериализуемом
/// значении падает уже при записи — здесь же промах виден сразу и стоит
/// ровно потерянной сессии.
String? encodeSaleSession({
  required SaleTabsState tabs,
  required SaleSessionOwner owner,
  required int savedAt,
}) {
  try {
    return jsonEncode({
      'owner': owner.toJson(),
      'savedAt': savedAt,
      'activeId': tabs.activeId,
      'tabs': [
        for (final tab in tabs.tabs) {'id': tab.id, 'cheque': tab.cheque},
      ],
    });
  } catch (_) {
    return null;
  }
}

/// Вкладки из снимка или `null`, если поднимать нечего.
///
/// Пустая сессия (все вкладки без позиций) — тоже `null`: восстанавливать в ней
/// нечего, а лишняя пара вкладок поверх новой смены только мешает.
SaleTabsState? decodeSaleSession(
  dynamic raw, {
  required SaleSessionOwner owner,
  required int now,
  Duration maxAge = saleSessionMaxAge,
}) {
  if (raw is! String || raw.isEmpty) return null;

  Map decoded;
  try {
    final value = jsonDecode(raw);
    if (value is! Map) return null;
    decoded = value;
  } catch (_) {
    return null;
  }

  if (!owner.matches(decoded['owner'] is Map ? decoded['owner'] as Map : null)) return null;

  final savedAt = decoded['savedAt'];
  if (savedAt is! int || now - savedAt > maxAge.inMilliseconds || savedAt > now) return null;

  final rawTabs = decoded['tabs'];
  if (rawTabs is! List || rawTabs.isEmpty) return null;

  final tabs = <SaleTab>[];
  for (final entry in rawTabs) {
    if (entry is! Map) continue;
    final id = entry['id'];
    final cheque = entry['cheque'];
    if (id is! int || cheque is! Map) continue;
    if (cheque['itemsList'] is! List) continue;
    tabs.add(SaleTab(id: id, cheque: cheque));
  }
  if (tabs.isEmpty || tabs.length > maxSaleTabs) return null;
  if (tabs.every((tab) => tab.isEmpty)) return null;

  final activeId = decoded['activeId'];
  final active = tabs.any((tab) => tab.id == activeId) ? activeId as int : tabs.first.id;
  return SaleTabsState(tabs: tabs, activeId: active);
}
