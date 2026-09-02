// Мультивкладки чеков — порт `src/helpers/cashboxSession.js` и работы со
// вкладками из `src/components/cashbox/Cashbox.js`.
//
// Кассир набирает несколько чеков параллельно: покупатель ушёл за забытым
// товаром — его чек откладывается во вкладку, следующего обслуживают в новой.
// От «отложенных чеков» (этап 5) отличается тем, что вкладка живёт только
// здесь и сейчас: её не видит ни сервер, ни соседняя касса.
//
// **Почему в памяти, а не в `GetStorage`.** Десктоп держит вкладки в
// `sessionStorage` — они переживают F5 и уход с роутера кассы, но исчезают с
// закрытием окна. `GetStorage` переживает и перезапуск приложения, а чек
// недельной давности, всплывший поверх новой смены, — это чужие суммы в
// корзине. Поэтому вкладки живут ровно столько, сколько живёт `SaleModel`.
//
// Здесь только чистые функции над снимками чеков; состояние — в `SaleModel`.
library;

import 'dart:convert';

import 'package:flutter_mdokon/core/utils/helper.dart';

/// Сколько чеков можно набирать параллельно. Десктоп даёт добавить вкладку,
/// пока их не больше четырёх (`Cashbox.js:79`), то есть потолок — пять.
const int maxSaleTabs = 5;

/// Одна вкладка: снимок чека и его идентификатор.
class SaleTab {
  const SaleTab({required this.id, required this.cheque});

  /// Идентификатор вкладки. Не индекс: после закрытия соседней индексы
  /// разъезжаются, а привязка «активная вкладка» должна пережить закрытие.
  final int id;

  /// Чек в формате кассы — тот же `data`, что лежит в `SaleModel`.
  final Map cheque;

  List get _items => cheque['itemsList'] is List ? cheque['itemsList'] as List : const [];

  int get lineCount => _items.length;

  bool get isEmpty => _items.isEmpty;

  /// Сумма по позициям, а не `totalPrice`: ярлык вкладки рисуется и для чека,
  /// у которого итог верхнего уровня ещё не пересчитан.
  num get total {
    num sum = 0;
    for (final item in _items) {
      if (item is Map) sum += customNumber(item['totalPrice']);
    }
    return sum;
  }

  SaleTab copyWith({Map? cheque}) => SaleTab(id: id, cheque: cheque ?? this.cheque);
}

/// Набор вкладок и та, что открыта сейчас.
class SaleTabsState {
  const SaleTabsState({required this.tabs, required this.activeId});

  final List<SaleTab> tabs;
  final int activeId;

  int get activeIndex {
    final index = tabs.indexWhere((tab) => tab.id == activeId);
    return index == -1 ? 0 : index;
  }

  SaleTab get active => tabs[activeIndex];

  /// Есть ли куда добавлять ещё одну.
  bool get canAdd => tabs.length < maxSaleTabs;

  /// Последнюю вкладку не закрываем: касса без чека — это не состояние.
  bool get canClose => tabs.length > 1;
}

/// Стартовое состояние: одна вкладка с текущим чеком.
SaleTabsState initialSaleTabs(Map cheque) =>
    SaleTabsState(tabs: [SaleTab(id: 1, cheque: cheque)], activeId: 1);

/// Следующий свободный идентификатор.
///
/// Максимум + 1, а не длина списка: после закрытия средней вкладки длина
/// повторила бы уже занятый id, и переключение попало бы не туда.
int nextSaleTabId(List<SaleTab> tabs) {
  var max = 0;
  for (final tab in tabs) {
    if (tab.id > max) max = tab.id;
  }
  return max + 1;
}

/// Сохранить текущий чек в активной вкладке.
///
/// Вызывается перед каждым переключением и закрытием: `SaleModel` правит свою
/// карту `data` на месте, и без снимка вкладка хранила бы ссылку на неё.
SaleTabsState storeActiveCheque(SaleTabsState state, Map cheque) {
  final snapshot = deepCopyCheque(cheque);
  return SaleTabsState(
    tabs: [
      for (final tab in state.tabs) tab.id == state.activeId ? tab.copyWith(cheque: snapshot) : tab,
    ],
    activeId: state.activeId,
  );
}

/// Новая вкладка с пустым чеком [empty]; она же становится активной.
///
/// Потолок достигнут — состояние возвращается как есть: молча подменять
/// чужую вкладку нельзя.
SaleTabsState addSaleTab(SaleTabsState state, Map current, Map empty) {
  if (!state.canAdd) return state;
  final stored = storeActiveCheque(state, current);
  final id = nextSaleTabId(stored.tabs);
  return SaleTabsState(
    tabs: [...stored.tabs, SaleTab(id: id, cheque: empty)],
    activeId: id,
  );
}

/// Переключиться на вкладку [id], сохранив текущий чек в активной.
///
/// Неизвестный id игнорируем: вкладку могли закрыть, пока лист был открыт.
SaleTabsState switchSaleTab(SaleTabsState state, int id, Map current) {
  if (id == state.activeId) return state;
  if (!state.tabs.any((tab) => tab.id == id)) return state;
  final stored = storeActiveCheque(state, current);
  return SaleTabsState(tabs: stored.tabs, activeId: id);
}

/// Закрыть вкладку [id].
///
/// Активной становится соседняя справа, а у последней в списке — слева
/// (`Cashbox.js:91-120`). Закрыли неактивную — активная не меняется: кассир
/// продолжает набирать тот же чек.
SaleTabsState closeSaleTab(SaleTabsState state, int id, Map current) {
  if (!state.canClose) return state;
  final index = state.tabs.indexWhere((tab) => tab.id == id);
  if (index == -1) return state;

  // Текущий чек сохраняем только если закрываем не его: иначе снимок лёг бы в
  // ту самую вкладку, которую сейчас выбросим.
  final stored = id == state.activeId ? state : storeActiveCheque(state, current);
  final tabs = [...stored.tabs]..removeAt(index);

  var activeId = stored.activeId;
  if (id == activeId) {
    activeId = tabs[index < tabs.length ? index : tabs.length - 1].id;
  }
  return SaleTabsState(tabs: tabs, activeId: activeId);
}

/// Копия чека, не разделяющая с оригиналом ни одной вложенной структуры.
///
/// Коды маркировки и позиции лежат вложенными списками — копии верхнего
/// уровня мало: правка корзины в одной вкладке меняла бы чек в соседней.
/// Чек не пережил JSON (в нём оказалось что-то не сериализуемое) — отдаём
/// копию верхнего уровня: потерять чек хуже, чем разделить с ним список.
Map deepCopyCheque(Map cheque) {
  try {
    final decoded = jsonDecode(jsonEncode(cheque));
    if (decoded is Map) return decoded;
  } catch (_) {}
  return Map<String, dynamic>.from(cheque);
}

/// Подпись вкладки: порядковый номер в списке.
///
/// Не `id`: после закрытия третьей из пяти вкладок кассир увидел бы «1 2 4 5».
int saleTabPosition(SaleTabsState state, int id) {
  final index = state.tabs.indexWhere((tab) => tab.id == id);
  return index == -1 ? 1 : index + 1;
}
