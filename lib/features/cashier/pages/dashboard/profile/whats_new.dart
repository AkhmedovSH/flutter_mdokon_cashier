import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:flutter_mdokon/core/utils/changelog.dart';
import 'package:flutter_mdokon/shared/widgets/custom_app_bar.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

/// Ключ последней версии, чей список изменений кассир уже видел.
/// Лежит рядом с настройками устройства: экран показывается один раз на версию.
const String kChangelogSeenKey = 'changelogSeenVersion';

/// Код локали в том же виде, в каком названы файлы переводов: `ru`, `uz-Latn`.
String localeCode(Locale locale) {
  final country = locale.countryCode ?? '';
  return country.isEmpty ? locale.languageCode : '${locale.languageCode}-$country';
}

/// Нужно ли показать «Что нового» при запуске: версия сменилась и для неё
/// есть описание. Отметку ставит сам экран — до тех пор диалог считается
/// непоказанным, даже если кассир закрыл приложение на полпути.
Future<bool> shouldShowWhatsNew() async {
  final info = await PackageInfo.fromPlatform();
  if (releaseFor(info.version) == null) return false;
  return GetStorage().read(kChangelogSeenKey) != info.version;
}

/// «Что нового» — список изменений по версиям.
///
/// Открывается сам после установки новой версии и вручную из профиля: кассиру
/// нужно понимать, почему привычный экран вдруг выглядит иначе.
class WhatsNew extends StatefulWidget {
  const WhatsNew({super.key});

  @override
  State<WhatsNew> createState() => _WhatsNewState();
}

class _WhatsNewState extends State<WhatsNew> {
  @override
  void initState() {
    super.initState();
    _markSeen();
  }

  Future<void> _markSeen() async {
    final info = await PackageInfo.fromPlatform();
    await GetStorage().write(kChangelogSeenKey, info.version);
  }

  @override
  Widget build(BuildContext context) {
    final code = localeCode(context.locale);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const CustomAppBar(title: 'whats_new', leading: true),
      body: SafeArea(
        top: false,
        child: ContentBox(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: changelog.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppDimens.gap16),
            itemBuilder: (context, index) => _ReleaseCard(
              release: changelog[index],
              localeCode: code,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  final ReleaseNote release;
  final String localeCode;

  const _ReleaseCard({required this.release, required this.localeCode});

  @override
  Widget build(BuildContext context) {
    final notes = release.notesFor(localeCode);
    final date = release.date;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                release.version,
                style: AppText.h2.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                date == null
                    ? context.tr('soon')
                    : DateFormat('dd.MM.yyyy').format(DateTime.parse(date)),
                style: AppText.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.gap12),
          for (final note in notes) _NoteRow(text: note),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final String text;

  const _NoteRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7, right: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(text, style: AppText.body.copyWith(height: 1.35)),
          ),
        ],
      ),
    );
  }
}
