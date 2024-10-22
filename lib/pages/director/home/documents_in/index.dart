import 'package:flutter/material.dart';

class DocumentsIn extends StatefulWidget {
  const DocumentsIn({super.key});

  @override
  _DocumentsInState createState() => _DocumentsInState();
}

class _DocumentsInState extends State<DocumentsIn> {
  int totalCount = 0;
  List data = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documents In'),
      ),
      body: Column(
        children: [
          // Фиксированные заголовки колонок
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(
                  label: SizedBox(
                    width: 40,
                    child: Text('№'),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 200,
                    child: Text('Surname'),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 200,
                    child: Text('Name'),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 80,
                    child: Text('Age'),
                  ),
                  numeric: true,
                ),
              ],
              rows: [], // Здесь пусто, так как строки будут в другой части
            ),
          ),
          // Прокручиваемые строки данных
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    DataTable(
                      
                      columns: [
                        DataColumn(
                          label: SizedBox(
                            width: 40,
                          ), // Пустые заголовки для выравнивания
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 200,
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 200,
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: 80,
                          ),
                        ),
                      ],
                      rows: [
                        for (var i = 1; i < 100; i++)
                          DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 40,
                                  child: Text('${i + 1}'),
                                ),
                              ),
                              DataCell(Text('Doe')),
                              DataCell(Text('John')),
                              DataCell(Text('25')),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
