import 'package:flutter/material.dart';

class DocumentsInCreate extends StatefulWidget {
  const DocumentsInCreate({super.key});

  @override
  _DocumentsInCreateState createState() => _DocumentsInCreateState();
}

class _DocumentsInCreateState extends State<DocumentsInCreate> {
  // Данные для таблицы
  final List<User> _users = [
    User('John', 'Smith', 28),
    User('Jane', 'Doe', 24),
    User('Sam', 'Johnson', 32),
  ];

  // Параметры сортировки
  bool _sortAscending = true;

  // Метод для сортировки таблицы по возрасту
  void _sortData(bool ascending) {
    setState(() {
      _sortAscending = ascending;
      if (ascending) {
        _users.sort((a, b) => a.age.compareTo(b.age));
      } else {
        _users.sort((a, b) => b.age.compareTo(a.age));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        sortAscending: _sortAscending,
        sortColumnIndex: 2, // Индекс столбца, по которому сортируем (возраст)
        columns: [
          DataColumn(label: Text('First Name')),
          DataColumn(label: Text('Last Name')),
          DataColumn(
            label: Text('Age'),
            numeric: true,
            onSort: (int columnIndex, bool ascending) {
              _sortData(ascending);
            },
          ),
        ],
        rows: _users
            .map(
              (user) => DataRow(
                cells: [
                  DataCell(Text(user.firstName)),
                  DataCell(Text(user.lastName)),
                  DataCell(Text(user.age.toString())),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class User {
  final String firstName;
  final String lastName;
  final int age;

  User(this.firstName, this.lastName, this.age);
}
