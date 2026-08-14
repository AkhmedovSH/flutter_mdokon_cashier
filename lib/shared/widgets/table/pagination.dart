import 'package:flutter/material.dart';
import '/helpers/helper.dart';
import '/models/filter_model.dart';
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

      // Всегда показываем первую страницу
      pages.add(0);

      // Всегда показываем вторую страницу, если общее число страниц больше 1
      if (totalPages > 1) pages.add(1);

      // Если текущая страница больше 3, добавляем троеточие
      if (currentPage > 3) {
        pages.add(null); // Первое троеточие
      }

      // Добавляем страницы вокруг текущей страницы
      for (int i = currentPage - 1; i <= currentPage + 1; i++) {
        if (i > 1 && i < totalPages - 2) {
          if (!pages.contains(i)) {
            pages.add(i); // Только если этой страницы еще нет в списке
          }
        }
      }

      // Если текущая страница далеко от конца, добавляем троеточие
      if (currentPage < totalPages - 4) {
        pages.add(null); // Второе троеточие
      }

      // Всегда показываем предпоследнюю и последнюю страницы
      if (totalPages > 2 && !pages.contains(totalPages - 2)) {
        pages.add(totalPages - 2);
      }
      if (!pages.contains(totalPages - 1)) {
        pages.add(totalPages - 1);
      }

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
