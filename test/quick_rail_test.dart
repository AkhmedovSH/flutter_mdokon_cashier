import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_mdokon/features/cashier/domain/quick_rail.dart';

/// Позиция набора «быстрый подбор».
Map _item(String name, {String barcode = '', String category = ''}) => {
      'productName': name,
      'productBarcode': barcode,
      if (category.isNotEmpty) 'categoryId': category,
    };

void main() {
  final items = [
    _item('Вода 0.5', barcode: '4780001'),
    _item('Хлеб', barcode: '4780002', category: '10'),
    _item('Молоко', barcode: '4780003', category: '10'),
    _item('Сок', barcode: '4780004', category: '20'),
  ];

  group('quickCategoryId', () {
    test('позиция без категории попадает в «Обычные»', () {
      expect(quickCategoryId(_item('Вода 0.5')), '');
    });

    test('читает и camelCase, и ключ бэкенда', () {
      expect(quickCategoryId({'categoryId': '10'}), '10');
      expect(quickCategoryId({'selectedProductCategoryId': '20'}), '20');
    });
  });

  group('filterQuickItems', () {
    test('список показывает весь набор, категория не при чём', () {
      final visible = filterQuickItems(items, view: QuickRailView.list);
      expect(visible.length, 4);
    });

    test('поиск идёт и по названию, и по штрих-коду', () {
      expect(filterQuickItems(items, search: 'мол').single['productName'], 'Молоко');
      expect(filterQuickItems(items, search: '4780004').single['productName'], 'Сок');
    });

    test('поиск не зависит от регистра и краевых пробелов', () {
      expect(filterQuickItems(items, search: '  ХЛЕБ ').length, 1);
    });

    test('в группах видно только содержимое открытой категории', () {
      final visible = filterQuickItems(
        items,
        categoryId: '10',
        view: QuickRailView.groups,
      );
      expect(visible.map((item) => item['productName']), ['Хлеб', 'Молоко']);
    });

    test('в группах без выбранной категории остаются «Обычные»', () {
      final visible = filterQuickItems(items, view: QuickRailView.groups);
      expect(visible.single['productName'], 'Вода 0.5');
    });

    test('поиск и категория действуют вместе', () {
      final visible = filterQuickItems(
        items,
        search: 'мол',
        categoryId: '20',
        view: QuickRailView.groups,
      );
      expect(visible, isEmpty);
    });
  });

  group('filterQuickCategories', () {
    final categories = [
      {'id': '10', 'categoryName': 'Продукты'},
      {'id': '20', 'name': 'Напитки'},
    ];

    test('без поиска отдаёт все категории', () {
      expect(filterQuickCategories(categories).length, 2);
    });

    test('фильтрует по имени независимо от ключа', () {
      expect(
        filterQuickCategories(categories, search: 'напит').single['name'],
        'Напитки',
      );
    });

    test('внутри открытой категории папок не показываем', () {
      expect(filterQuickCategories(categories, activeCategoryId: '10'), isEmpty);
    });
  });

  group('countQuickItems', () {
    test('считает позиции категории', () {
      expect(countQuickItems(items, '10'), 2);
      expect(countQuickItems(items, '20'), 1);
    });

    test('пустой id — это «Обычные»', () {
      expect(countQuickItems(items, ''), 1);
    });
  });

  group('quickCategoryName / quickCategoryKey', () {
    test('имя берётся из любого из двух ключей', () {
      expect(quickCategoryName({'categoryName': 'Продукты'}), 'Продукты');
      expect(quickCategoryName({'name': 'Напитки'}), 'Напитки');
    });

    test('идентификатор берётся из любого из двух ключей', () {
      expect(quickCategoryKey({'id': '10'}), '10');
      expect(quickCategoryKey({'categoryId': '20'}), '20');
    });
  });
}
