import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_mdokon/core/state/data_model.dart';
import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/features/auth/models/auth_model.dart';
import 'package:flutter_mdokon/features/auth/models/user_model.dart';
import 'package:flutter_mdokon/features/auth/widgets/auth_background.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Экран входа. Вся логика живёт в [AuthModel] — страница только рисует
/// состояние и выполняет переход по маршруту, который вернула модель.
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthModel>();
    auth.ensureDefaultSettings();
    auth.restoreSavedCredentials();
    _loginController.text = auth.username;
    _passwordController.text = auth.password;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserModel>().checkVersion(context);
    });
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() => _run(context.read<AuthModel>().submit);

  /// Демо-вход: поля формы не трогаем, сценарий тот же.
  Future<void> _submitDemo() => _run(context.read<AuthModel>().submitDemo);

  Future<void> _run(Future<AuthRedirect?> Function() action) async {
    FocusScope.of(context).unfocus();
    final redirect = await action();
    if (redirect == null || !mounted) return;

    // Справочники директора грузим фоном, чтобы дашборд открылся сразу.
    if (redirect.path == '/director') context.read<DataModel>().getData();
    context.go(redirect.path, extra: redirect.extra);
  }

  Future<void> _callSupport() async {
    final uri = Uri.parse('tel://+998555000089');
    if (!await launchUrl(uri)) showDangerToast('Не удалось открыть звонок');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthModel>();
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final layout = context.layout;

    final header = AuthLogoHeader(
      subtitle: auth.isOtpStep ? 'Подтверждение по SMS' : 'Вход по логину и паролю',
    );
    final card = _AuthCard(
      auth: auth,
      loginController: _loginController,
      passwordController: _passwordController,
      otpController: _otpController,
      onSubmit: _submit,
      onDemo: _submitDemo,
    );
    final support = _SupportRow(onTap: _callSupport);

    // На широком экране форма уезжает вправо, под руку кассира, а слева
    // остаётся брендовый блок — растягивать поля ввода на 1280 нельзя.
    final bool split = layout.size >= AppScreenSize.expanded;

    return Scaffold(
      backgroundColor: AppColors.brandSurface,
      resizeToAvoidBottomInset: false,
      body: AuthBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  layout.gutter,
                  AppDimens.gap24,
                  layout.gutter,
                  AppDimens.gap24 + viewInsets,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - AppDimens.gap24 * 2),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: split ? 900 : 420),
                      child: split
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      header,
                                      const SizedBox(height: AppDimens.gap24),
                                      support,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppDimens.gap24),
                                SizedBox(width: 420, child: card),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                header,
                                const SizedBox(height: AppDimens.gap24),
                                card,
                                const SizedBox(height: AppDimens.gap16),
                                support,
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Белая карточка формы: поля, ошибка, кнопка, демо-подсказка.
class _AuthCard extends StatelessWidget {
  final AuthModel auth;
  final TextEditingController loginController;
  final TextEditingController passwordController;
  final TextEditingController otpController;
  final VoidCallback onSubmit;
  final VoidCallback onDemo;

  const _AuthCard({
    required this.auth,
    required this.loginController,
    required this.passwordController,
    required this.otpController,
    required this.onSubmit,
    required this.onDemo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.gap24,
        AppDimens.gutter,
        AppDimens.gap24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDimens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (auth.isOtpStep)
            ..._otpFields(context)
          else
            ..._credentialFields(context),
          if (auth.error != null) ...[
            const SizedBox(height: AppDimens.gap12),
            _ErrorBanner(message: auth.error!),
          ],
          const SizedBox(height: AppDimens.gap16),
          Row(
            children: [
              if (auth.isOtpStep) ...[
                AppIconButton(
                  icon: Icons.arrow_back,
                  background: AppColors.canvas,
                  foreground: AppColors.textSecondary,
                  size: AppDimens.heightLarge,
                  onPressed: auth.submitting ? null : auth.backToCredentials,
                ),
                const SizedBox(width: AppDimens.gap12),
              ],
              Expanded(
                child: AppButton(
                  label: auth.isOtpStep ? 'Подтвердить' : 'Войти',
                  loading: auth.submitting,
                  onPressed: auth.canSubmit ? onSubmit : null,
                ),
              ),
            ],
          ),
          if (!auth.isOtpStep) ...[
            const SizedBox(height: AppDimens.gap12),
            _DemoLink(onTap: auth.submitting ? null : onDemo),
          ],
        ],
      ),
    );
  }

  List<Widget> _credentialFields(BuildContext context) => [
        AppInput(
          label: 'Логин',
          hint: 'ID кассира или логин',
          controller: loginController,
          onChanged: auth.setUsername,
          enabled: !auth.submitting,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppDimens.gap12),
        AppInput(
          label: 'Пароль',
          hint: 'Пароль',
          controller: passwordController,
          onChanged: auth.setPassword,
          obscureText: !auth.showPassword,
          enabled: !auth.submitting,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => auth.canSubmit ? onSubmit() : null,
          suffix: _TextAction(
            label: auth.showPassword ? 'Скрыть' : 'Показать',
            onTap: auth.togglePasswordVisibility,
          ),
        ),
        const SizedBox(height: AppDimens.gap8),
        _RememberMe(
          value: auth.rememberMe,
          onChanged: auth.submitting ? null : auth.toggleRememberMe,
        ),
      ];

  List<Widget> _otpFields(BuildContext context) => [
        if (auth.otpOffer.isNotEmpty) ...[
          Text(auth.otpOffer, style: AppText.secondary),
          const SizedBox(height: AppDimens.gap12),
        ],
        AppInput(
          label: 'Код из SMS',
          hint: 'Введите код',
          controller: otpController,
          onChanged: auth.setOtp,
          enabled: !auth.submitting,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => auth.canSubmit ? onSubmit() : null,
        ),
      ];
}

/// Текстовая ссылка «Демо-режим» под кнопкой входа.
class _DemoLink extends StatelessWidget {
  final VoidCallback? onTap;

  const _DemoLink({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        'Демо-режим',
        textAlign: TextAlign.center,
        style: AppText.body.copyWith(
          color: onTap == null ? AppColors.textSecondary : AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RememberMe extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _RememberMe({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppDimens.control,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                activeColor: AppColors.primary,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
              ),
            ),
            const SizedBox(width: AppDimens.gap12),
            Text('Запомнить меня', style: AppText.body),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.gap12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: AppDimens.control,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: AppColors.dangerText),
          const SizedBox(width: AppDimens.gap8),
          Expanded(
            child: Text(
              message,
              style: AppText.secondary.copyWith(color: AppColors.dangerText),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppDimens.control,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimens.control,
        child: Container(
          height: AppDimens.heightMedium,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gap12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.small.copyWith(
              color: AppColors.iconMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  final VoidCallback onTap;

  const _SupportRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final onDark = AppColors.onBrandSurface.withValues(alpha: 0.85);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Нет аккаунта?', style: TextStyle(fontSize: 14, color: onDark)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Свяжитесь с нами',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onBrandSurface,
            ),
          ),
        ),
      ],
    );
  }
}
