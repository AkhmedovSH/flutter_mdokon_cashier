import 'package:flutter/material.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/filter_model.dart';
import 'package:provider/provider.dart';

class Pagination extends StatelessWidget {
  final Function getData;
  final int total;
  const Pagination({
    super.key,
    required this.getData,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (total / 20).ceil();

    final currentPage = context.watch<FilterModel>().currentFilterData['page'] ?? 0;

    // Генерация списка страниц с учетом логики
    List<int?> generatePageNumbers(int totalPages, int currentPage) {
      List<int?> pages = [];

      // Всегда показываем первую и вторую страницы
      pages.add(0);
      if (totalPages > 1) pages.add(1);

      // Логика для троеточий
      if (currentPage > 3) {
        pages.add(null); // Первое троеточие
      }

      // Добавляем центральные страницы в зависимости от текущей
      for (int i = currentPage - 1; i <= currentPage + 1; i++) {
        if (i > 1 && i < totalPages - 2) {
          pages.add(i);
        }
      }

      if (currentPage < totalPages - 4) {
        pages.add(null); // Второе троеточие
      }

      // Всегда показываем предпоследнюю и последнюю страницы
      if (totalPages > 2) pages.add(totalPages - 2);
      pages.add(totalPages - 1);

      return pages;
    }

    void onDotTap(int? dotPosition) {
      int newPage = 0;
      if (dotPosition == null) {
        // Определение новой страницы при нажатии на троеточие
        if (currentPage < 3) {
          newPage = 3;
        } else if (currentPage >= totalPages - 4) {
          newPage = totalPages - 4;
        } else {
          newPage = currentPage + 3; // Шаг вперёд по страницам
        }
      } else {
        newPage = dotPosition;
      }

      // Обновляем фильтр и вызываем загрузку данных
      context.read<FilterModel>().setFilterData('page', newPage);
      getData();
    }

    return totalPages > 1
        ? Consumer<FilterModel>(
            builder: (context, filterModel, child) {
              final pages = generatePageNumbers(totalPages, filterModel.currentFilterData['page'] ?? 0);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    for (var i in pages)
                      if (i != null)
                        GestureDetector(
                          onTap: () {
                            onDotTap(i);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFf0f0f0)),
                              borderRadius: BorderRadius.circular(5),
                              color: i == filterModel.currentFilterData['page'] ? mainColor : CustomTheme.of(context).bgColor,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: i == filterModel.currentFilterData['page'] ? white : CustomTheme.of(context).textColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () {
                            onDotTap(null);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFf0f0f0)),
                              borderRadius: BorderRadius.circular(5),
                              color: i == filterModel.currentFilterData['page'] ? mainColor : CustomTheme.of(context).bgColor,
                            ),
                            child: Text(
                              '...',
                              style: TextStyle(color: CustomTheme.of(context).textColor),
                            ),
                          ),
                        ),
                  ],
                ),
              );
            },
          )
        : const SizedBox();
  }
}
