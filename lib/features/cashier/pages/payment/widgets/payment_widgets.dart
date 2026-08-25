import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/models/cashbox_model.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Общие блоки экрана оплаты.
///
/// Все три вкладки («Оплата», «В долг», «Лояльность») работают с одним списком
/// `data['paymentTypes']`. Суммы вводятся не в столбик полей, а в одну строку
/// внизу экрана: сверху плитки способов оплаты (какой активен), внизу — сумма
/// активного способа и клавиатура. Так основная работа кассира остаётся под
/// большим пальцем, а системная клавиатура не перекрывает итог.

/// UI-состояние экрана оплаты: активный способ оплаты и открытая клавиатура.
///
/// Живёт отдельно от [CashboxModel]: это состояние экрана, а не чека.
class PaymentUiState extends ChangeNotifier {
  int _activeIndex = 0;
  bool _padOpen = true;

  int get activeIndex => _activeIndex;
  bool get padOpen => _padOpen;

  void setActive(int index) {
    if (_activeIndex == index) return;
    _activeIndex = index;
    notifyListeners();
  }

  void togglePad() {
    _padOpen = !_padOpen;
    notifyListeners();
  }

  void openPad() {
    if (_padOpen) return;
    _padOpen = true;
    notifyListeners();
  }

  /// При смене вкладки поля обнуляются — активным снова становится первый способ.
  void reset() {
    _activeIndex = 0;
    notifyListeners();
  }
}

/// Записывает сумму в способ оплаты и держит курсор в конце строки.
///
/// [CashboxModel.updateInputs] сам переписывает текст контроллера, из-за чего
/// курсор прыгает в начало — поэтому возвращаем его на место.
void setPaymentAmount(CashboxModel model, int index, String value) {
  model.updateInputs(index, value);

  final controller = model.data['paymentTypes'][index]['controller'] as TextEditingController;
  controller.selection = TextSelection.fromPosition(
    TextPosition(offset: controller.text.length),
  );
}

/// Фиолетовая шапка с главной суммой: что осталось внести, сдача либо долг.
class PaymentHero extends StatelessWidget {
  final String label;
  final double value;
  final String currency;

  /// Подпись под суммой: «Чек X · внесено Y».
  final String subtitle;

  /// Бейдж справа: процент сбора либо «готово».
  final String badge;
  final bool done;

  /// Переключатель вкладок под суммой.
  final Widget tabs;

  const PaymentHero({
    super.key,
    required this.label,
    required this.value,
    required this.currency,
    required this.subtitle,
    required this.badge,
    required this.done,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(layout.gutter, 14, layout.gutter, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: AppText.caption.copyWith(
                        letterSpacing: 0.88,
                        color: AppColors.onPrimary.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: AppDimens.gap4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              formatMoney(value),
                              style: AppText.display.copyWith(
                                fontSize: layout.scaled(38),
                                height: 1,
                                letterSpacing: -1.14,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currency,
                          style: AppText.secondary.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? AppColors.surface : AppColors.onPrimary.withValues(alpha: 0.18),
                  borderRadius: AppDimens.pill,
                ),
                child: Text(
                  badge,
                  style: AppText.tabular(AppText.small).copyWith(
                    fontWeight: FontWeight.w700,
                    color: done ? AppColors.successText : AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap4),
          Text(
            subtitle,
            style: AppText.tabular(AppText.small).copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.75),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          tabs,
        ],
      ),
    );
  }
}

/// Вкладка на фиолетовой шапке: активная — белая, остальные — полупрозрачные.
class PaymentHeroTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PaymentHeroTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surface : AppColors.onPrimary.withValues(alpha: 0.18),
      borderRadius: AppDimens.pill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap8),
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.small.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.36,
              color: selected ? AppColors.primary : AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Строка клиента: карточка-кнопка, открывающая лист выбора.
class ClientBar extends StatelessWidget {
  final String label;
  final String title;
  final String? subtitle;

  /// Подпись действия справа: «Найти» либо «Изменить».
  final String action;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const ClientBar({
    super.key,
    required this.label,
    required this.title,
    this.subtitle,
    required this.action,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppDimens.card,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppDimens.card,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.iconMuted,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primarySoft : AppColors.canvas,
                  borderRadius: AppDimens.control,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.iconMuted,
                ),
              ),
              const SizedBox(width: AppDimens.gap12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: AppText.caption.copyWith(fontSize: 10, color: AppColors.iconMuted),
                    ),
                    Text(
                      title,
                      style: AppText.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        style: AppText.tabular(AppText.small),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.gap8),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppDimens.pill,
                ),
                child: Text(
                  action,
                  style: AppText.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Плитки способов оплаты: выбранная плитка — та, что редактируется внизу.
class PaymentTypeTiles extends StatelessWidget {
  final CashboxModel model;
  final PaymentUiState ui;

  const PaymentTypeTiles({super.key, required this.model, required this.ui});

  List get _types => (model.data['paymentTypes'] as List?) ?? const [];

  @override
  Widget build(BuildContext context) {
    if (_types.isEmpty) return const SizedBox.shrink();

    final bool dense = _types.length > 4;
    final int columns = dense ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('payment_type').toUpperCase(),
                style: AppText.caption.copyWith(color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppDimens.gap8),
            _ResetButton(
              onPressed: () {
                for (var i = 0; i < _types.length; i++) {
                  model.clearInput(i);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: AppDimens.gap8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _types.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppDimens.gap8,
            crossAxisSpacing: AppDimens.gap8,
            mainAxisExtent: dense ? 54 : 58,
          ),
          itemBuilder: (context, index) {
            final item = _types[index];
            final double value = customNumber(item['amount']);
            final bool active = ui.activeIndex == index;

            return Material(
              color: active ? AppColors.primarySoft : AppColors.surface,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => ui.setActive(index),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: dense ? 10 : AppDimens.gap12,
                    vertical: dense ? AppDimens.gap8 : 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.border,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${item['customPaymentTypeName'] ?? ''}'.toUpperCase(),
                        style: AppText.caption.copyWith(
                          fontSize: dense ? 9 : 10,
                          fontWeight: FontWeight.w700,
                          color: active ? AppColors.primary : AppColors.iconMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatMoney(value),
                          style: AppText.price.copyWith(
                            fontSize: dense ? 14 : 16,
                            color: value > 0 ? AppColors.textPrimary : AppColors.iconMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Нижняя панель: сумма активного способа, клавиатура и кнопка «Принять».
class PaymentAmountBar extends StatelessWidget {
  final CashboxModel model;
  final PaymentUiState ui;

  /// Подпись и обработчик основной кнопки.
  final String acceptLabel;
  final VoidCallback? onAccept;

  /// Колонка справа вместо панели снизу: на планшете клавиатура и сумма
  /// встают рядом со способами оплаты, а не под ними — иначе экран 800 px
  /// в высоту не вмещает и то, и другое.
  final bool vertical;

  /// Купюры для быстрого добавления.
  static const List<int> quickAdds = [5000, 10000, 20000, 50000, 100000];

  static const List<String> _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', '⌫'];

  const PaymentAmountBar({
    super.key,
    required this.model,
    required this.ui,
    required this.acceptLabel,
    this.onAccept,
    this.vertical = false,
  });

  List get _types => (model.data['paymentTypes'] as List?) ?? const [];

  /// Индекс активного способа с защитой от смены списка типов оплаты.
  int get _index => ui.activeIndex < _types.length ? ui.activeIndex : 0;

  String get _text => '${_types[_index]['controller'].text}';

  void _press(String key) {
    final current = _text;
    final next = key == '⌫'
        ? (current.isEmpty ? '' : current.substring(0, current.length - 1))
        : '${current == '0' ? '' : current}$key';

    if (next.length > 12) return;
    setPaymentAmount(model, _index, next);
  }

  void _add(int value) {
    setPaymentAmount(model, _index, (customNumber(_text) + value).round().toString());
  }

  @override
  Widget build(BuildContext context) {
    if (_types.isEmpty) {
      return _wrapper(context, body: const [], footer: AppButton(label: acceptLabel, onPressed: onAccept));
    }

    final item = _types[_index];
    final bool empty = customNumber(item['amount']) <= 0;

    return _wrapper(context, body: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item['customPaymentTypeName'] ?? ''}'.toUpperCase(),
                  style: AppText.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                TextField(
                  controller: item['controller'],
                  keyboardType: TextInputType.number,
                  // Пока открыта своя клавиатура, системную не поднимаем.
                  readOnly: ui.padOpen,
                  showCursor: true,
                  onTap: ui.padOpen ? null : () {},
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => setPaymentAmount(model, _index, value),
                  cursorColor: AppColors.primary,
                  style: AppText.amount.copyWith(
                    fontSize: 26,
                    color: empty ? AppColors.iconMuted : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                    hintStyle: AppText.amount.copyWith(fontSize: 26, color: AppColors.iconMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.gap8),
          AppIconButton(
            icon: Icons.keyboard_alt_outlined,
            background: ui.padOpen ? AppColors.primary : AppColors.canvas,
            foreground: ui.padOpen ? AppColors.onPrimary : AppColors.textSecondary,
            size: 34,
            iconSize: 18,
            pill: true,
            onPressed: ui.togglePad,
          ),
          const SizedBox(width: 6),
          AppButton(
            label: context.tr('remainder'),
            variant: AppButtonVariant.soft,
            size: AppButtonSize.small,
            expanded: false,
            pill: true,
            onPressed: () => model.exactAmount(_index),
          ),
          const SizedBox(width: 6),
          AppButton(
            label: context.tr('clear'),
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.small,
            expanded: false,
            pill: true,
            onPressed: () => model.clearInput(_index),
          ),
        ],
      ),
      if (ui.padOpen) ...[
        const SizedBox(height: 10),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quickAdds.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) => AppChip(
              label: '+${formatMoney(quickAdds[index])}',
              onTap: () => _add(quickAdds[index]),
            ),
          ),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _keys.length,
          // Клавиша растёт с экраном: 52 на телефоне, 76 на планшете. В
          // колонке справа она ниже, зато втрое шире — иначе последний ряд
          // не помещается в окно оплаты.
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            mainAxisExtent: vertical ? 56 : context.layout.keypadKey,
          ),
          itemBuilder: (context, index) {
            final key = _keys[index];
            final bool backspace = key == '⌫';

            return Material(
              color: backspace ? AppColors.primarySoft : AppColors.canvas,
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _press(key),
                child: Center(
                  child: backspace
                      ? Icon(Icons.backspace_outlined, size: 20, color: AppColors.primary)
                      : Text(
                          key,
                          style: AppText.tabular(AppText.h1).copyWith(
                            fontSize: key == '000' ? 20 : 24,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ],
    ], footer: SizedBox(
      height: context.layout.primaryButtonHeight,
      child: AppButton(label: acceptLabel, onPressed: onAccept),
    ));
  }

  Widget _wrapper(BuildContext context, {required List<Widget> body, required Widget footer}) {
    final layout = context.layout;
    final padding = EdgeInsets.fromLTRB(layout.gutter, 10, layout.gutter, AppDimens.gap12);

    if (vertical) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(left: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          left: false,
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Клавиатура выше колонки не станет — лишнее уезжает в скролл,
                // кнопка приёма остаётся приколотой снизу.
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: body,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                footer,
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F1C264A),
            blurRadius: 20,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [...body, const SizedBox(height: 10), footer],
          ),
        ),
      ),
    );
  }
}

/// Компактная «Сброс» у заголовка секции: 24px, чтобы не спорить с заголовком.
class _ResetButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ResetButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dangerSoft,
      borderRadius: AppDimens.pill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          child: Text(
            context.tr('reset').toUpperCase(),
            style: AppText.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.dangerText,
            ),
          ),
        ),
      ),
    );
  }
}
