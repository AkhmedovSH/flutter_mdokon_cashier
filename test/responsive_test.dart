import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/shared/widgets/ui/app_responsive.dart';

/// Рисует [child] в окне заданного размера — как на конкретном устройстве.
Widget _at(Size size, Widget child) => MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(home: Scaffold(body: child)),
    );

const _phone = Size(390, 844);
const _tabletPortrait = Size(768, 1024);
const _tabletLandscape = Size(1024, 768);
const _phoneLandscape = Size(844, 390);

void main() {
  group('AppLayout', () {
    test('ступени считаются по ширине окна', () {
      expect(AppLayout.sizeOf(390), AppScreenSize.compact);
      expect(AppLayout.sizeOf(599), AppScreenSize.compact);
      expect(AppLayout.sizeOf(600), AppScreenSize.medium);
      expect(AppLayout.sizeOf(1023), AppScreenSize.medium);
      expect(AppLayout.sizeOf(1024), AppScreenSize.expanded);
      expect(AppLayout.sizeOf(1280), AppScreenSize.expanded);
    });

    test('на телефоне телефонная раскладка', () {
      const layout = AppLayout(size: AppScreenSize.compact, screen: _phone);
      expect(layout.isTablet, isFalse);
      expect(layout.useTopNav, isFalse);
      expect(layout.hasSideRail, isFalse);
      expect(layout.useDialogInsteadOfSheet, isFalse);
      expect(layout.contentMaxWidth, double.infinity);
    });

    test('планшет в портрете: верхняя навигация без боковой колонки', () {
      const layout = AppLayout(size: AppScreenSize.medium, screen: _tabletPortrait);
      expect(layout.useTopNav, isTrue);
      expect(layout.hasSideRail, isFalse);
      expect(layout.useDialogInsteadOfSheet, isTrue);
    });

    test('планшет в альбоме: три зоны на экране', () {
      const tablet = AppLayout(size: AppScreenSize.expanded, screen: _tabletLandscape);

      expect(tablet.hasSideRail, isTrue);
      expect(tablet.railWidth, 320);
      expect(tablet.primaryButtonHeight, 64);
      expect(tablet.keypadKey, 68);
    });

    test('телефон в альбоме боковую колонку не получает — не хватает высоты', () {
      const layout = AppLayout(size: AppScreenSize.medium, screen: _phoneLandscape);
      expect(layout.hasSideRail, isFalse);
    });

    test('pick наследует пропущенную ступень', () {
      const expanded = AppLayout(size: AppScreenSize.expanded, screen: _tabletLandscape);
      expect(expanded.pick(compact: 1, medium: 2), 2);
      expect(expanded.pick(compact: 1, medium: 2, expanded: 3), 3);
      expect(expanded.pick(compact: 1), 1);
    });
  });

  group('SideRailLayout', () {
    testWidgets('на телефоне колонка уходит вниз панелью', (tester) async {
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_at(
        _phone,
        const SideRailLayout(
          body: Text('чек'),
          rail: Text('колонка'),
          bottom: Text('панель'),
        ),
      ));

      expect(find.text('панель'), findsOneWidget);
      expect(find.text('колонка'), findsNothing);
    });

    testWidgets('на планшете в альбоме колонка встаёт справа', (tester) async {
      tester.view.physicalSize = _tabletLandscape;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_at(
        _tabletLandscape,
        const SideRailLayout(
          body: Text('чек'),
          rail: Text('колонка'),
          bottom: Text('панель'),
        ),
      ));

      expect(find.text('колонка'), findsOneWidget);
      expect(find.text('панель'), findsNothing);
      // Колонка занимает правые 320 px экрана.
      expect(tester.getSize(find.byType(SideRailLayout)).width, 1024);
      expect(tester.getTopLeft(find.text('колонка')).dx, greaterThan(704 - 1));
    });
  });

  group('MasterDetailLayout', () {
    testWidgets('на телефоне выбранная карточка заменяет список', (tester) async {
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_at(
        _phone,
        const MasterDetailLayout(master: Text('список'), detail: Text('чек')),
      ));

      expect(find.text('чек'), findsOneWidget);
      expect(find.text('список'), findsNothing);
    });

    testWidgets('на планшете список и карточка видны вместе', (tester) async {
      tester.view.physicalSize = _tabletLandscape;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_at(
        _tabletLandscape,
        const MasterDetailLayout(master: Text('список'), detail: Text('чек')),
      ));

      expect(find.text('список'), findsOneWidget);
      expect(find.text('чек'), findsOneWidget);
    });
  });

  group('ContentBox', () {
    testWidgets('на телефоне ширину не режет', (tester) async {
      tester.view.physicalSize = _phone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_at(_phone, const ContentBox(child: SizedBox.expand())));
      expect(tester.getSize(find.byType(SizedBox)).width, 390);
    });

    testWidgets('на планшете в альбоме держит колонку 760', (tester) async {
      tester.view.physicalSize = _tabletLandscape;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_at(_tabletLandscape, const ContentBox(child: SizedBox.expand())));
      expect(tester.getSize(find.byType(SizedBox)).width, 760);
    });
  });
}
