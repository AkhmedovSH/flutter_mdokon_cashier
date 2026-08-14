import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/core/theme/themes.dart';
import 'package:flutter_mdokon/shared/widgets/ui/ui.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: lightTheme,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('кнопки всех вариантов рисуются и кликаются', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(
      Column(
        children: [
          AppButton(label: 'Продать', onPressed: () => taps++),
          const SizedBox(height: 8),
          const AppButton.secondary(label: 'Наличные', onPressed: null),
          const SizedBox(height: 8),
          const AppButton.soft(label: '+ Добавить'),
          const SizedBox(height: 8),
          const AppButton.danger(label: 'Очистить'),
          const SizedBox(height: 8),
          const AppButton(label: 'Загрузка', loading: true),
          const SizedBox(height: 8),
          const AppChip(label: 'Оплата', selected: true),
          const SizedBox(height: 8),
          AppIconButton.floating(icon: Icons.qr_code_scanner, onPressed: () {}),
        ],
      ),
    ));

    await tester.tap(find.text('ПРОДАТЬ'));
    expect(taps, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('поле ввода показывает лейбл, ошибку и переключение пароля', (tester) async {
    await tester.pumpWidget(_wrap(
      Column(
        children: [
          AppInput(
            label: 'Пароль',
            controller: TextEditingController(),
            obscureText: true,
            togglePassword: true,
            errorText: 'Неверный пароль',
          ),
          const SizedBox(height: 12),
          AppInput.money(label: 'Naqd', controller: TextEditingController(text: '20 000')),
          const SizedBox(height: 12),
          AppSearchField(controller: TextEditingController(text: 'cola')),
          const SizedBox(height: 12),
          AppStepper(value: 1, onChanged: (_) {}),
        ],
      ),
    ));

    expect(find.text('ПАРОЛЬ'), findsOneWidget);
    expect(find.text('Неверный пароль'), findsOneWidget);
    await tester.tap(find.text('Показать'));
    await tester.pump();
    expect(find.text('Скрыть'), findsOneWidget);
  });

  testWidgets('модалка подтверждения возвращает результат', (tester) async {
    bool? result;
    await tester.pumpWidget(_wrap(
      Builder(
        builder: (context) => AppButton(
          label: 'Открыть',
          onPressed: () async {
            result = await AppModal.confirm(
              context,
              title: 'Очистить чек?',
              text: 'Все позиции будут удалены.',
              confirmLabel: 'Очистить',
              tone: AppModalTone.danger,
            );
          },
        ),
      ),
    ));

    await tester.tap(find.text('ОТКРЫТЬ'));
    await tester.pumpAndSettle();
    expect(find.text('Очистить чек?'), findsOneWidget);

    await tester.tap(find.text('ОЧИСТИТЬ'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('лоадеры и карточки рисуются', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(
        children: [
          AppLoader(),
          SizedBox(height: 12),
          AppLoaderCard(label: 'Проведение оплаты…'),
          SizedBox(height: 12),
          AppBanner(title: 'Нет связи с сервером', text: 'Чеки сохраняются локально.'),
          SizedBox(height: 12),
          AppCard(selected: true, child: Text('Coca cola 1 l')),
          SizedBox(height: 12),
          AppSectionLabel('К оплате'),
        ],
      ),
    ));

    expect(find.text('Проведение оплаты…'), findsOneWidget);
    expect(find.text('К ОПЛАТЕ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
