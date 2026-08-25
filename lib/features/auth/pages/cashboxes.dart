import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:flutter_mdokon/features/auth/models/auth_model.dart';
import 'package:flutter_mdokon/features/auth/widgets/auth_background.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Выбор кассы после входа. Оформление повторяет экран [Login]:
/// фирменный фон, логотип-хедер и белая карточка со списком касс.
class CashBoxes extends StatelessWidget {
  final List poses;

  const CashBoxes({super.key, required this.poses});

  Future<void> _select(BuildContext context, Map pos, Map cashbox) async {
    final redirect = await context.read<AuthModel>().selectCashbox(
          pos: Map.from(pos),
          cashbox: Map.from(cashbox),
        );
    if (redirect == null || !context.mounted) return;
    context.go(redirect.path, extra: redirect.extra);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthModel>();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AuthBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              AppDimens.gap24,
              AppDimens.gutter,
              AppDimens.gap24,
            ),
            child: ContentBox(
              maxWidth: 560,
              child: Column(
                children: [
                  const AuthLogoHeader(subtitle: 'Выберите кассу, чтобы открыть смену'),
                  const SizedBox(height: AppDimens.gap24),
                  Expanded(child: _CashboxCard(poses: poses, auth: auth, onSelect: _select)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Белая карточка со списком точек и их касс.
class _CashboxCard extends StatelessWidget {
  final List poses;
  final AuthModel auth;
  final Future<void> Function(BuildContext, Map, Map) onSelect;

  const _CashboxCard({
    required this.poses,
    required this.auth,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gap24,
        AppDimens.gutter,
        AppDimens.gap16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDimens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Свободные кассы', style: AppText.h1),
          const SizedBox(height: AppDimens.gap4),
          Text('Смена откроется сразу после выбора', style: AppText.secondary),
          const SizedBox(height: AppDimens.gap16),
          if (auth.error != null) ...[
            AppBanner.danger(title: auth.error!),
            const SizedBox(height: AppDimens.gap12),
          ],
          Expanded(child: _list(context)),
          const SizedBox(height: AppDimens.gap12),
          AppButton.secondary(
            label: '← Выйти',
            onPressed: auth.submitting ? null : () => context.go('/auth'),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    if (poses.isEmpty) {
      return const AppEmptyState(
        icon: Icons.point_of_sale_outlined,
        title: 'Свободных касс нет',
        text: 'Все кассы точки заняты. Дождитесь закрытия смены или обратитесь к директору.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: poses.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimens.gap16),
      itemBuilder: (context, i) {
        final pos = poses[i] as Map;
        final cashboxes = (pos['cashboxList'] as List?) ?? const [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionLabel('${pos['posName'] ?? ''}'),
            const SizedBox(height: AppDimens.gap8),
            for (var j = 0; j < cashboxes.length; j++) ...[
              if (j > 0) const SizedBox(height: AppDimens.gap8),
              _CashboxTile(
                name: '${cashboxes[j]['name'] ?? ''}',
                enabled: !auth.submitting,
                onTap: () => onSelect(context, pos, cashboxes[j] as Map),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Строка кассы: иконка, название и стрелка.
class _CashboxTile extends StatelessWidget {
  final String name;
  final bool enabled;
  final VoidCallback onTap;

  const _CashboxTile({
    required this.name,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.gap12,
          vertical: AppDimens.gap8,
        ),
        onTap: enabled ? onTap : null,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: AppDimens.control,
              ),
              child: Icon(
                Icons.point_of_sale_outlined,
                size: 20,
                color: AppColors.iconMuted,
              ),
            ),
            const SizedBox(width: AppDimens.gap12),
            Expanded(child: Text(name, style: AppText.bodyMedium)),
            Icon(Icons.chevron_right, size: 20, color: AppColors.iconMuted),
          ],
        ),
      ),
    );
  }
}
