import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

import 'package:flutter_mdokon/core/localization/locale_model.dart';
import 'package:flutter_mdokon/core/state/settings_model.dart';
import 'package:flutter_mdokon/core/theme/theme_model.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/cashier/models/printer_model.dart';
import 'package:flutter_mdokon/shared/widgets/dialogs.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Раздел настроек — он же чип-фильтр в шапке.
enum _Section { general, cashbox, print }

/// Тип контрола в строке настройки.
enum _Control {
  /// Переключатель да/нет.
  toggle,

  /// Выбор из списка значений (язык, ширина чека).
  select,

  /// Числовое значение с шагом ±1 (знаки после запятой).
  stepper,

  /// Сегменты «Светлая / Тёмная».
  theme,

  /// Строка-действие: открывает подключение принтера.
  printer,
}

class _Item {
  final String key;

  /// Номер вида «1.2» — как в десктопной кассе, по нему тоже ищем.
  final String num;
  final String titleKey;
  final String descKey;
  final _Section section;
  final _Control control;

  /// Варианты для [_Control.select]: значение → подпись.
  final List<MapEntry<String, String>> options;

  final double min;
  final double max;

  const _Item({
    required this.key,
    required this.titleKey,
    required this.section,
    required this.control,
    this.num = '',
    this.descKey = '',
    this.options = const [],
    this.min = 0,
    this.max = 0,
  });
}

/// Настройки кассы.
///
/// Экран работает с черновиком: переключатели меняют локальную копию, а в
/// [SettingsModel], тему, локаль и принтер всё уезжает только по «Сохранить».
/// Так касса не перестраивается под каждым пальцем и остаётся возможность
/// откатить набор изменений одной кнопкой «Сбросить».
///
/// Исключение — выбор принтера: это подключение к устройству, а не значение,
/// и оно применяется сразу.
class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TextEditingController _searchController = TextEditingController();

  /// Сохранённые значения — точка отсчёта для «Сбросить» и подсветки кнопки.
  Map<String, dynamic> _saved = {};

  /// Правки, ещё не уехавшие в модели.
  Map<String, dynamic> _draft = {};

  String _query = '';
  _Section? _activeSection;
  bool _saving = false;

  static const List<_Item> _items = [
    _Item(
      key: 'theme',
      titleKey: 'appearance_theme',
      descKey: 'settings_description_1',
      section: _Section.general,
      control: _Control.theme,
    ),
    _Item(
      key: 'locale',
      titleKey: 'interface_language',
      descKey: 'settings_description_2',
      section: _Section.general,
      control: _Control.select,
    ),
    _Item(
      key: 'changeCurrencyOnSale',
      num: '1.1',
      titleKey: 'settings_title_12',
      descKey: 'settings_description_12',
      section: _Section.cashbox,
      control: _Control.toggle,
    ),
    _Item(
      key: 'decimalDigits',
      num: '1.2',
      titleKey: 'settings_title_11',
      descKey: 'settings_description_11',
      section: _Section.cashbox,
      control: _Control.stepper,
      min: 0,
      max: 5,
    ),
    _Item(
      key: 'printer',
      num: '2.1',
      titleKey: 'settings_title_7',
      descKey: 'settings_description_7',
      section: _Section.print,
      control: _Control.printer,
    ),
    _Item(
      key: 'printerSize',
      num: '2.2',
      titleKey: 'receipt_print_width',
      descKey: 'receipt_print_width_description',
      section: _Section.print,
      control: _Control.select,
      options: [
        MapEntry('576', '80 mm'),
        MapEntry('512', '72 mm'),
        MapEntry('384', '58 mm'),
      ],
    ),
    _Item(
      key: 'printAfterSale',
      num: '2.3',
      titleKey: 'settings_title_8',
      descKey: 'settings_description_8',
      section: _Section.print,
      control: _Control.toggle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _readCurrentValues();
    _requestBluetoothPermissions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Сканирование принтеров без этих разрешений возвращает пустой список,
  /// поэтому спрашиваем их на входе, а не в момент нажатия.
  Future<void> _requestBluetoothPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void _readCurrentValues() {
    final settings = context.read<SettingsModel>();
    final printer = context.read<PrinterModel>();
    final locale = context.read<LocaleModel>();

    _saved = {
      'theme': settings.theme,
      'locale': locale.localeName,
      'changeCurrencyOnSale': settings.changeCurrencyOnSale,
      'decimalDigits': settings.decimalDigits,
      'printerSize': printer.printerSize,
      'printAfterSale': settings.printAfterSale,
    };
    _draft = Map.of(_saved);
  }

  bool get _dirty => _saved.keys.any((key) => _saved[key] != _draft[key]);

  void _set(String key, dynamic value) => setState(() => _draft[key] = value);

  // --- Список -------------------------------------------------------------

  /// Настройки, прошедшие поиск (но ещё не фильтр по разделу) — по ним же
  /// считаются числа на чипах, чтобы пустых разделов в шапке не оставалось.
  List<_Item> get _found {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _items;

    return _items.where((item) {
      final haystack = [
        item.num,
        context.tr(item.titleKey),
        if (item.descKey.isNotEmpty) _description(item),
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();
  }

  List<_Item> get _visible {
    final found = _found;
    if (_activeSection == null) return found;

    return found.where((item) => item.section == _activeSection).toList();
  }

  int _countIn(_Section? section) => section == null
      ? _found.length
      : _found.where((item) => item.section == section).length;

  String _sectionTitle(_Section section) => switch (section) {
        _Section.general => context.tr('general'),
        _Section.cashbox => context.tr('cashbox'),
        _Section.print => context.tr('print'),
      };

  /// Описание точности сумм показывает пример прямо с черновым значением,
  /// иначе подсказка отстаёт от ползунка до сохранения.
  String _description(_Item item) {
    if (item.key == 'decimalDigits') {
      final digits = customNumber(_draft['decimalDigits']).round();
      final example = NumberFormat.currency(
        symbol: '',
        decimalDigits: digits,
        locale: 'UZ',
      ).format(500.99999).replaceAll(' ', ' ').replaceAll(' ', ' ').trim();

      return context.tr(item.descKey, args: [example]);
    }

    return context.tr(item.descKey);
  }

  // --- Действия -----------------------------------------------------------

  Future<void> _pickPrinter() async {
    final printer = context.read<PrinterModel>();
    printer.startScan();
    await showPrinterPicker(context);
  }

  void _reset() {
    _searchController.clear();
    setState(() {
      _draft = Map.of(_saved);
      _query = '';
    });
  }

  Future<void> _save() async {
    if (!_dirty || _saving) return;
    setState(() => _saving = true);

    final settings = context.read<SettingsModel>();

    for (final key in const [
      'changeCurrencyOnSale',
      'decimalDigits',
      'printAfterSale',
    ]) {
      if (_saved[key] != _draft[key]) settings.updateSetting(key, _draft[key]);
    }

    if (_saved['printerSize'] != _draft['printerSize']) {
      context.read<PrinterModel>().setPrinterSize(_draft['printerSize']);
    }

    if (_saved['theme'] != _draft['theme']) {
      final dark = _draft['theme'] == true;
      context.read<ThemeModel>().setDark(dark);
      settings.updateSetting('theme', dark);
    }

    if (_saved['locale'] != _draft['locale']) {
      final locale = _draft['locale'] == 'uz'
          ? const Locale('uz', 'Latn')
          : const Locale('ru', '');
      await context.setLocale(locale);
      if (!mounted) return;
      context.read<LocaleModel>().setLocale(locale);
    }

    if (!mounted) return;
    setState(() {
      _saved = Map.of(_draft);
      _saving = false;
    });
    showSuccessToast(context.tr('settings_saved'));
  }

  // --- Вёрстка ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // На широком экране разделы переезжают из чипов в колонку слева: чипы там
    // терялись под поиском, а места хватает на постоянный список.
    final split = context.layout.hasMasterDetail;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          _header(split: split),
          Expanded(
            child: split
                ? MasterDetailLayout(
                    masterWidth: 260,
                    master: _sectionRail(),
                    detail: _list(),
                  )
                : ContentBox(child: _list()),
          ),
        ],
      ),
      bottomNavigationBar: _footer(),
    );
  }

  Widget _list() {
    final visible = _visible;

    if (visible.isEmpty) {
      return AppEmptyState(
        icon: UniconsLine.search,
        title: context.tr('nothing_found'),
        text: context.tr('settings_search_empty'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gap12,
        AppDimens.gutter,
        AppDimens.gap16,
      ),
      itemCount: visible.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: AppDimens.gap8),
      itemBuilder: (context, index) {
        if (index == 0) return _countLabel(visible.length);

        return _row(visible[index - 1]);
      },
    );
  }

  /// Колонка разделов слева — замена чипам на широком экране.
  Widget _sectionRail() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gap12,
        AppDimens.gap12,
        AppDimens.gap12,
        AppDimens.gap16,
      ),
      children: [
        _sectionRailItem(null, context.tr('all')),
        for (final section in _Section.values)
          _sectionRailItem(section, _sectionTitle(section)),
      ],
    );
  }

  Widget _sectionRailItem(_Section? section, String label) {
    final count = _countIn(section);
    final selected = _activeSection == section;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: AppDimens.control,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _activeSection = section),
          child: Container(
            height: context.layout.tapTarget,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.secondaryBold.copyWith(
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: AppText.tabular(AppText.small).copyWith(
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header({bool split = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.gutter,
            0,
            AppDimens.gutter,
            AppDimens.gap12,
          ),
          child: Column(
            children: [
              SizedBox(
                height: AppDimens.heightLarge,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppDimens.gap8),
                      child: AppIconButton(
                        icon: UniconsLine.arrow_left,
                        onPressed: () => context.pop(),
                      ),
                    ),
                    Text(context.tr('settings'), style: AppText.h1),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.gap8),
              AppInput(
                controller: _searchController,
                hint: context.tr('settings_search_hint'),
                height: AppDimens.heightMedium,
                prefixIcon: UniconsLine.search,
                onChanged: (value) => setState(() => _query = value),
                suffix: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(
                          UniconsLine.times,
                          size: 18,
                          color: AppColors.iconMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              if (!split) ...[
                const SizedBox(height: AppDimens.gap8),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _tab(null, context.tr('all')),
                      for (final section in _Section.values)
                        _tab(section, _sectionTitle(section)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(_Section? section, String label) {
    final count = _countIn(section);
    final selected = _activeSection == section;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: AppDimens.control,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _activeSection = section),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppDimens.control,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              count > 0 ? '$label  $count' : label,
              style: AppText.secondaryBold.copyWith(
                color: selected ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _countLabel(int count) {
    final section = _activeSection == null
        ? context.tr('all')
        : _sectionTitle(_activeSection!);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.gap4),
      child: AppSectionLabel('$section · $count'),
    );
  }

  Widget _row(_Item item) {
    final isTheme = item.control == _Control.theme;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.gap12,
        vertical: 10,
      ),
      onTap: item.control == _Control.toggle
          ? () => _set(item.key, !(_draft[item.key] == true))
          : item.control == _Control.printer
              ? _pickPrinter
              : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _titleBlock(item)),
              if (!isTheme) ...[
                const SizedBox(width: AppDimens.gap12),
                _control(item),
              ],
            ],
          ),
          if (isTheme) ...[
            const SizedBox(height: AppDimens.gap8),
            _themeSwitcher(),
          ],
        ],
      ),
    );
  }

  Widget _titleBlock(_Item item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.num.isNotEmpty) ...[
          Text(
            item.num,
            style: AppText.tabular(AppText.caption).copyWith(
              color: AppColors.iconMuted,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 1),
        ],
        Text(
          context.tr(item.titleKey),
          style: AppText.bodyMedium.copyWith(fontSize: 14, height: 1.25),
        ),
        if (item.descKey.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            _description(item),
            style: AppText.small.copyWith(fontSize: 11, height: 1.3),
          ),
        ],
      ],
    );
  }

  Widget _control(_Item item) {
    switch (item.control) {
      case _Control.toggle:
        return Transform.scale(
          scale: 0.85,
          alignment: Alignment.centerRight,
          child: Switch.adaptive(
            value: _draft[item.key] == true,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primary,
            onChanged: (value) => _set(item.key, value),
          ),
        );

      case _Control.select:
        return _SelectButton(
          label: _selectLabel(item),
          onTap: () => _openSelect(item),
        );

      case _Control.stepper:
        return _Stepper(
          value: customNumber(_draft[item.key]).round(),
          min: item.min.round(),
          max: item.max.round(),
          onChanged: (value) => _set(item.key, value.toDouble()),
        );

      case _Control.printer:
        return Consumer<PrinterModel>(
          builder: (context, model, child) {
            final connected = customIf(model.selectedDevice);

            return _SelectButton(
              label: connected ? model.selectedDeviceName : context.tr('click_to_connect'),
              icon: connected ? UniconsLine.print : UniconsLine.print_slash,
              onTap: _pickPrinter,
            );
          },
        );

      case _Control.theme:
        return const SizedBox.shrink();
    }
  }

  List<MapEntry<String, String>> _optionsOf(_Item item) {
    if (item.key != 'locale') return item.options;

    return [
      for (final language in languages)
        MapEntry('${language['locale']}', '${language['name']}'),
    ];
  }

  String _selectLabel(_Item item) {
    final value = '${_draft[item.key]}';

    return _optionsOf(item)
        .firstWhere(
          (option) => option.key == value,
          orElse: () => MapEntry(value, value),
        )
        .value;
  }

  Future<void> _openSelect(_Item item) async {
    final options = _optionsOf(item);
    final current = '${_draft[item.key]}';

    final picked = await AppModal.sheet<String>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(item.titleKey), style: AppText.h2),
          const SizedBox(height: AppDimens.gap12),
          for (final option in options)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(option.value, style: AppText.body),
              trailing: option.key == current
                  ? Icon(UniconsLine.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(ctx).pop(option.key),
            ),
        ],
      ),
    );

    if (picked != null) _set(item.key, picked);
  }

  Widget _themeSwitcher() {
    final dark = _draft['theme'] == true;

    return Container(
      padding: const EdgeInsets.all(AppDimens.gap4),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppDimens.control,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ThemeOption(
              label: context.tr('theme_light'),
              selected: !dark,
              onTap: () => _set('theme', false),
            ),
          ),
          const SizedBox(width: AppDimens.gap4),
          Expanded(
            child: _ThemeOption(
              label: context.tr('theme_dark'),
              selected: dark,
              onTap: () => _set('theme', true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        10,
        AppDimens.gutter,
        AppDimens.gap12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: context.tr('reset'),
                size: AppButtonSize.large,
                onPressed: _dirty || _query.isNotEmpty ? _reset : null,
              ),
            ),
            const SizedBox(width: AppDimens.gap8),
            Expanded(
              child: AppButton(
                label: context.tr('save'),
                loading: _saving,
                onPressed: _dirty ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Кнопка-значение: текущий выбор и шеврон, открывает лист вариантов.
class _SelectButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _SelectButton({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Material(
        color: AppColors.canvas,
        borderRadius: AppDimens.control,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: AppDimens.control,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppColors.iconMuted),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: AppText.secondaryBold.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimens.gap8),
                Icon(UniconsLine.angle_down, size: 16, color: AppColors.iconMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Числовое значение с кнопками −/+ (знаки после запятой).
class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(
          icon: UniconsLine.minus,
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppText.tabular(AppText.bodyMedium).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        _StepperButton(
          icon: UniconsLine.plus,
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepperButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Material(
      color: enabled ? AppColors.canvas : AppColors.divider,
      borderRadius: AppDimens.control,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: AppDimens.control,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.textPrimary : AppColors.iconMuted,
          ),
        ),
      ),
    );
  }
}

/// Сегмент переключателя темы.
class _ThemeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surface : Colors.transparent,
      borderRadius: AppDimens.control,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppDimens.control,
            border: Border.all(
              color: selected ? AppColors.border : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: AppText.secondaryBold.copyWith(
              fontSize: 14,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
