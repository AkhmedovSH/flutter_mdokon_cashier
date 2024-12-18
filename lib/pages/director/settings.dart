import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/helpers/themes.dart';
import 'package:kassa/models/locale_model.dart';
import 'package:kassa/models/settings_model.dart';
import 'package:kassa/models/theme_model.dart';
import 'package:kassa/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsModel = Provider.of<SettingsModel>(context);
    final themeModel = Provider.of<ThemeModel>(context);

    final List<Map<String, dynamic>> languages = [
      {
        "id": '1',
        "locale": 'ru',
        "name": 'Русский',
      },
      {
        "id": '3',
        "locale": 'uz',
        "name": 'O`zbekcha',
      },
    ];

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<UserModel>(
                builder: (context, userModel, child) {
                  print(userModel.user['usermame']);
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21),
                      color: CustomTheme.of(context).cardColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'ID: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: '${userModel.user['posId']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${context.tr('login')}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: '${userModel.user['login']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                ),
                              ),
                              TextSpan(
                                text: ' (${userModel.user['firstName']})',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: CustomTheme.of(context).textColor.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${context.tr('balance2')}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: '${formatMoney(userModel.user['posBalance'])}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                  color: userModel.user['posBalance'] >= 0 ? success : danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Text(
                context.tr('general'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  color: CustomTheme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        context.tr('language'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 115,
                      child: Consumer<LocaleModel>(
                        builder: (context, localeModel, chilld) {
                          return DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              value: localeModel.localeName,
                              buttonStyleData: const ButtonStyleData(width: 125),
                              dropdownStyleData: DropdownStyleData(
                                width: 125,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: CustomTheme.of(context).cardColor,
                                ),
                                offset: const Offset(-10, -10),
                              ),
                              isDense: true,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  print(newValue);
                                  Locale locale = const Locale('ru', '');
                                  if (newValue == 'ru') {
                                    locale = const Locale('ru', '');
                                  }
                                  if (newValue == 'uz') {
                                    locale = const Locale('uz', 'Latn');
                                  }
                                  context.setLocale(locale);
                                  localeModel.setLocale(locale);
                                }
                              },
                              items: languages.map(
                                (Map<String, dynamic> language) {
                                  return DropdownMenuItem<String>(
                                    value: language['locale'],
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      child: Text(language['name']!),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              CardItemSwitch(
                title: context.tr('dark_theme'),
                value: settingsModel.theme,
                onChanged: (value) {
                  settingsModel.updateSetting('theme', value);
                  if (settingsModel.theme) {
                    themeModel.setTheme(darkTheme);
                  } else {
                    themeModel.setTheme(lightTheme);
                  }
                },
              ),
              Text(
                context.tr('other'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 15),
              CardItem(
                icon: UniconsLine.sign_out_alt,
                title: 'logout',
              ),
              CardItem(
                icon: UniconsLine.calling,
                title: 'support',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardItemSwitch extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CardItemSwitch({
    super.key,
    required this.title,
    this.description = '',
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: CustomTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                description != ''
                    ? Tooltip(
                        message: description,
                        triggerMode: TooltipTriggerMode.tap,
                        showDuration: const Duration(seconds: 3),
                        decoration: BoxDecoration(
                          color: CustomTheme.of(context).textColor.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textAlign: TextAlign.center,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(UniconsLine.question_circle),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class CardItem extends StatelessWidget {
  final String title;
  final IconData icon;

  const CardItem({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    GetStorage storage = GetStorage();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
      ),
      child: TextButton(
        onPressed: () {
          if (title == 'logout') {
            storage.remove('user');
            storage.remove('access_token');
            storage.remove('lastLogin');
            context.pushReplacement('/auth');
          }
          if (title == 'support') {
            launchUrl(Uri.parse("tel://+998555000089"));
          }
          //print(response);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          backgroundColor: CustomTheme.of(context).cardColor,
          foregroundColor: CustomTheme.of(context).textColor,
          elevation: 0,
        ),
        child: Row(
          children: [
            Icon(icon),
            SizedBox(width: 10),
            Text(
              context.tr(title),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
