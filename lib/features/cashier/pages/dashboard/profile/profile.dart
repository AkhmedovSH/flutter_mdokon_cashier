import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_mdokon/core/network/api.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/auth/models/user_model.dart';
import 'package:flutter_mdokon/features/cashier/models/dashboard_model.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Профиль — вкладка нижней навигации.
///
/// Экран отвечает на два вопроса кассира: «под кем и на какой кассе я работаю»
/// и «что уже произошло за смену». Поэтому сверху — карточка кассира, под ней —
/// итоги смены из X-отчёта (чеки, продажи, возвраты, остаток в кассе), и только
/// потом список переходов. Действия, которые заканчивают работу — закрытие
/// смены и выход — вынесены вниз отдельно от навигации, чтобы их не задели
/// случайно при скролле списка.
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  static const String supportPhone = '998555000089';

  final GetStorage storage = GetStorage();

  Map cashbox = {};
  Map shift = {};

  /// Итоги смены (X-отчёт v2). Пусто, пока не загрузились или у агента.
  Map report = {};
  bool loadingReport = false;

  /// Связь с сервером: `null` — ещё проверяем.

  String version = '';

  @override
  void initState() {
    super.initState();
    // Касса и смена лежат в локальном хранилище — читаем до первого кадра,
    // чтобы состав экрана (у агента нет смены) не менялся после отрисовки.
    _readStorage();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  // --- Данные ------------------------------------------------------------

  bool get _isAgent => cashbox['isAgent'] == true;

  void _readStorage() {
    final storedCashbox = storage.read('cashbox');
    final storedShift = storage.read('shift');
    cashbox = storedCashbox is Map ? storedCashbox : {};
    shift = storedShift is Map ? storedShift : {};
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(_readStorage);

    await Future.wait([_loadVersion(), _loadReport()]);
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => version = '${info.version} (${info.buildNumber})');
  }

  /// Итоги смены берём из того же X-отчёта, что печатает касса, — цифры на
  /// экране и на бумаге совпадают. У агента смены нет, запрос не делаем.
  Future<void> _loadReport() async {
    final id = cashbox['id'] ?? shift['id'];
    if (_isAgent || id == null) return;

    setState(() => loadingReport = true);
    final response = await get('/services/desktop/api/shift-xreport-v2/$id');
    if (!mounted) return;

    setState(() {
      loadingReport = false;
      report = httpOk(response) && response is Map ? response : {};
    });
  }

  /// Продажи и остаток приходят списком по валютам — на экране показываем
  /// основную (первую), детализация по остальным остаётся в X-отчёте.
  Map get _sales {
    final list = report['salesList'];
    return list is List && list.isNotEmpty ? list.first : {};
  }

  Map get _balance {
    final list = report['balanceList'];
    return list is List && list.isNotEmpty ? list.first : {};
  }

  String _currency(Map source) => '${source['currencyName'] ?? context.tr('sum')}';

  // --- Действия ----------------------------------------------------------

  void _open(String path) => context.go(path);

  Future<void> _callSupport() async {
    final uri = Uri.parse('tel://+$supportPhone');
    if (!await launchUrl(uri) && mounted) showDangerToast(context.tr('error'));
  }

  Future<void> _confirmLogout() async {
    final confirmed = await AppModal.confirm(
      context,
      title: context.tr('are_you_sure_you_want_to_go_out'),
      confirmLabel: context.tr('logout'),
      cancelLabel: context.tr('cancel'),
      tone: AppModalTone.danger,
    );
    if (!confirmed || !mounted) return;
    _logout();
  }

  void _logout() {
    storage.remove('user');
    storage.remove('access_token');
    storage.remove('lastLogin');
    Provider.of<DashboardModel>(context, listen: false).setCurrentIndex(0);
    context.go('/auth');
  }

  // --- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>().user;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  AppDimens.gap12,
                  AppDimens.gutter,
                  AppDimens.gap24,
                ),
                children: [
                  _userCard(user),
                  if (!_isAgent) ...[
                    const SizedBox(height: AppDimens.gap12),
                    _shiftCard(),
                  ],
                  const SizedBox(height: AppDimens.gap12),
                  _menuCard(),
                  const SizedBox(height: AppDimens.gap16),
                  if (!_isAgent) ...[
                    AppButton.secondary(
                      label: context.tr('close_shift'),
                      onPressed: () => _open('/cashier/profile/x-report'),
                    ),
                    const SizedBox(height: AppDimens.gap8),
                  ],
                  AppButton.danger(
                    label: context.tr('logout'),
                    onPressed: _confirmLogout,
                  ),
                  const SizedBox(height: AppDimens.gap16),
                  Text(
                    'mDokon POS${version.isEmpty ? '' : ' $version'}',
                    textAlign: TextAlign.center,
                    style: AppText.tabular(AppText.small),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Белая шапка: заголовок и состояние связи с сервером — офлайн кассир должен
  /// заметить до того, как чек уйдёт в очередь.
  Widget _header() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              AppDimens.gap12,
              AppDimens.gutter,
              AppDimens.gap12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('profile'),
                    style: AppText.h1.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Кассир, точка и касса — то, что подставится в чек.
  Widget _userCard(Map user) {
    final name = [
      '${user['lastName'] ?? ''}'.trim(),
      '${user['firstName'] ?? ''}'.trim(),
    ].where((part) => part.isNotEmpty).join(' ');

    final meta = [
      if (customIf(user['login'])) '${user['login']}',
      if (customIf(cashbox['posId'])) 'ID: ${cashbox['posId']}',
      if (customIf(cashbox['posName'])) '${cashbox['posName']}',
      if (customIf(cashbox['cashboxName'])) '${cashbox['cashboxName']}',
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.gap16),
      child: Row(
        children: [
          _Avatar(name: name),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.isEmpty ? '${user['username'] ?? '—'}' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.price.copyWith(fontWeight: FontWeight.w600),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: AppDimens.gap4),
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.tabular(AppText.secondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Итоги смены. Пока X-отчёт не пришёл — плитки показывают прочерк, чтобы
  /// карточка не прыгала по высоте после загрузки.
  Widget _shiftCard() {
    final meta = [
      if (customIf(report['shiftNumber'])) '№ ${report['shiftNumber']}',
      if (customIf(report['shiftOpenDate'])) '${report['shiftOpenDate']}',
      if (customIf(report['shiftDuration'])) '${report['shiftDuration']}',
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(AppDimens.gap16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AppSectionLabel(context.tr('shift'))),
              if (loadingReport)
                const AppLoader(size: 18, strokeWidth: 2)
              else
                _StatusPill(
                  label: context.tr('shift_opened'),
                  background: AppColors.canvas,
                  foreground: AppColors.textPrimary,
                  dotColor: AppColors.success,
                ),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: AppDimens.gap4),
            Text(
              meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.tabular(AppText.small),
            ),
          ],
          const SizedBox(height: AppDimens.gap12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(
                  label: context.tr('number_of_receipts'),
                  value: report.isEmpty ? '—' : '${customNumber(report['totalCountCheque']).round()}',
                  large: true,
                ),
              ),
              const SizedBox(width: AppDimens.gap12),
              Expanded(
                child: _Stat(
                  label: context.tr('sales_amount'),
                  value: report.isEmpty ? '—' : formatMoney(_sales['salesAmount']),
                  unit: report.isEmpty ? null : _currency(_sales),
                  large: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(
                  label: context.tr('cashbox_balance'),
                  value: report.isEmpty ? '—' : formatMoney(_balance['balance']),
                  unit: report.isEmpty ? null : _currency(_balance),
                ),
              ),
              const SizedBox(width: AppDimens.gap12),
              Expanded(
                child: _Stat(
                  label: context.tr('return_amount'),
                  value: report.isEmpty ? '—' : formatMoney(_sales['returnAmount']),
                  unit: report.isEmpty ? null : _currency(_sales),
                  // Возврат — единственная цифра, которую хочется заметить сразу.
                  color: customNumber(_sales['returnAmount']) > 0 ? AppColors.dangerText : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Переходы одним списком: у каждой строки — иконка, название и подсказка
  /// справа, чтобы не открывать экран ради того, что видно строкой.
  Widget _menuCard() {
    final items = <_MenuItem>[
      if (!_isAgent)
        _MenuItem(
          icon: UniconsLine.clipboard_alt,
          title: context.tr('x_report'),
          value: context.tr('shift'),
          onTap: () => _open('/cashier/profile/x-report'),
        ),
      if (checkRole('CASHBOX_BRANCH_BALANCE'))
        _MenuItem(
          icon: UniconsLine.box,
          title: context.tr('residues'),
          value: context.tr('products'),
          onTap: () => _open(_isAgent ? '/agent/profile/balance' : '/cashier/profile/balance'),
        ),
      if (!_isAgent)
        _MenuItem(
          icon: UniconsLine.bolt,
          title: context.tr('quick_selection'),
          value: context.tr('products'),
          onTap: () => _open('/cashier/profile/quick-selection'),
        ),
      if (!_isAgent)
        _MenuItem(
          icon: UniconsLine.cog,
          title: context.tr('settings'),
          onTap: () => _open('/cashier/profile/settings'),
        ),
      _MenuItem(
        icon: UniconsLine.calling,
        title: context.tr('support'),
        value: formatPhone(supportPhone),
        onTap: _callSupport,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.card,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.divider, indent: 62),
            _MenuRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

/// Строка меню профиля.
class _MenuItem {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
  });
}

class _MenuRow extends StatelessWidget {
  final _MenuItem item;

  const _MenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppDimens.gap12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppDimens.control,
                ),
                child: Icon(item.icon, size: 19, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body,
                ),
              ),
              // Подсказка занимает ровно свою ширину (но не больше половины
              // строки) — иначе она делит свободное место с названием: шеврон
              // отходит от правого края, а название обрезается раньше времени.
              if (item.value != null) ...[
                const SizedBox(width: AppDimens.gap8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    item.value!,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.tabular(AppText.small),
                  ),
                ),
              ],
              const SizedBox(width: AppDimens.gap4),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Плитка итога смены: подпись сверху, цифра — крупно и моноширинно.
class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? color;
  final bool large;

  const _Stat({
    required this.label,
    required this.value,
    this.unit,
    this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.small,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: large ? 22 : 17,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: color ?? AppColors.textPrimary,
            fontFeatures: AppText.tabularFigures,
          ),
        ),
        if (unit != null)
          Text(
            unit!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.small,
          ),
      ],
    );
  }
}

/// Плашка состояния: точка + подпись (связь с сервером, статус смены).
class _StatusPill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color dotColor;

  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: background, borderRadius: AppDimens.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppDimens.gap8),
          Text(
            label,
            style: AppText.small.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Аватар кассира: инициалы на фирменном фоне.
class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    return parts.take(2).map((part) => part.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppDimens.card,
      ),
      child: Text(
        _initials,
        style: AppText.h1.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
