import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:unicons/unicons.dart';

import 'package:flutter_mdokon/core/utils/helper.dart';
import 'package:flutter_mdokon/core/utils/logger.dart';
import 'package:flutter_mdokon/shared/widgets/custom_app_bar.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Логи приложения на устройстве.
///
/// Экран поддержки, а не кассира: сюда заходят, когда на точке «что-то пошло не
/// так» и интернета для удалённого разбора нет. Файлы пишет
/// [AppLog] (`lib/core/utils/logger.dart`), хранение — [retentionDays] суток.
///
/// Отдать лог можно двумя способами: скопировать хвост в буфер обмена или
/// собрать все файлы в один и отправить системным «Поделиться» — в поддержку
/// он обычно уходит файлом в Telegram, а не текстом.
class Logs extends StatefulWidget {
  const Logs({super.key});

  @override
  State<Logs> createState() => _LogsState();
}

class _LogsState extends State<Logs> {
  List<File> _files = const [];
  File? _selected;
  String _content = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    appLog.flush();
    final files = appLog.files();
    setState(() {
      _files = files;
      _selected = files.isEmpty ? null : files.first;
    });
    _load();
  }

  void _load() {
    final file = _selected;
    if (file == null) {
      setState(() => _content = '');
      return;
    }
    String text;
    try {
      text = file.readAsStringSync();
    } catch (e) {
      text = '$e';
    }
    // Файл за день бывает на мегабайты — на экране держим хвост, целиком
    // отдаём экспортом.
    const limit = 60000;
    if (text.length > limit) text = text.substring(text.length - limit);
    setState(() => _content = text);
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    final path = await appLog.export();
    if (!mounted) return;
    setState(() => _busy = false);
    if (path == null) {
      showWarningToast(context.tr('settings_logs_empty'));
      return;
    }

    // Системный лист «Поделиться»: кассир отправляет файл тем же Telegram,
    // которым и так пишет в поддержку. Путь к файлу ему ни о чём не говорит.
    final subject = '${context.tr('settings_logs_title')} · ${appLog.dayKey()}';
    try {
      await SharePlus.instance.share(ShareParams(
        files: [XFile(path, mimeType: 'text/plain')],
        subject: subject,
        title: subject,
      ));
    } catch (e) {
      // Нет ни одного приложения, готового принять файл — остаётся путь.
      appLog.exception('log.share_failed', e);
      await Clipboard.setData(ClipboardData(text: path));
      if (!mounted) return;
      showSuccessToast(context.tr('settings_logs_exported'), description: path);
    }
  }

  Future<void> _copy() async {
    if (_content.isEmpty) {
      showWarningToast(context.tr('settings_logs_empty'));
      return;
    }
    await Clipboard.setData(ClipboardData(text: _content));
    if (!mounted) return;
    showSuccessToast(context.tr('copied'));
  }

  void _clear() {
    appLog.clear();
    appLog.info('log.cleared');
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const CustomAppBar(title: 'settings_logs_title', leading: true),
      body: SafeArea(
        top: false,
        child: ContentBox(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_files.isNotEmpty) _dayPicker(),
                const SizedBox(height: AppDimens.gap12),
                Expanded(child: _body()),
                const SizedBox(height: AppDimens.gap12),
                _actions(wide: layout.hasMasterDetail),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dayPicker() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _files.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimens.gap8),
        itemBuilder: (context, index) {
          final file = _files[index];
          final active = file.path == _selected?.path;
          final name = file.uri.pathSegments.last.replaceAll('cashbox-', '').replaceAll('.log', '');
          // Тему чипа задаём здесь, а не в глобальной ChipTheme: выбранный
          // красится в primary, и подпись должна идти по onPrimary — иначе на
          // синем остаётся почти чёрный текст.
          return ChoiceChip(
            label: Text(name),
            selected: active,
            showCheckmark: false,
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            side: BorderSide(color: active ? AppColors.primary : AppColors.border),
            labelStyle: AppText.small.copyWith(
              color: active ? AppColors.onPrimary : AppColors.textPrimary,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
            onSelected: (_) {
              setState(() => _selected = file);
              _load();
            },
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_files.isEmpty || _content.trim().isEmpty) {
      return Center(
        child: Text(
          context.tr('settings_logs_empty'),
          style: AppText.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return AppCard(
      child: SingleChildScrollView(
        reverse: true,
        child: SelectableText(
          _content,
          style: AppText.caption.copyWith(fontFamily: 'monospace', color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _actions({required bool wide}) {
    final buttons = [
      AppButton(
        label: context.tr('copy'),
        icon: UniconsLine.copy,
        variant: AppButtonVariant.secondary,
        expanded: !wide,
        onPressed: _copy,
      ),
      AppButton(
        label: context.tr('settings_logs_export'),
        icon: UniconsLine.export,
        loading: _busy,
        expanded: !wide,
        onPressed: _export,
      ),
      AppButton(
        label: context.tr('clear'),
        icon: UniconsLine.trash_alt,
        variant: AppButtonVariant.danger,
        expanded: !wide,
        onPressed: _files.isEmpty ? null : _clear,
      ),
    ];

    if (wide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (final button in buttons) ...[button, const SizedBox(width: AppDimens.gap8)],
        ],
      );
    }
    return Column(
      children: [
        for (final button in buttons) ...[button, const SizedBox(height: AppDimens.gap8)],
      ],
    );
  }
}
