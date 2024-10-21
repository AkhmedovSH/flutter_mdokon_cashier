import 'package:flutter/material.dart';
import 'package:kassa/widgets/custom_app_bar.dart';
import 'package:material_table_view/material_table_view.dart';

class DocumentsIn extends StatefulWidget {
  const DocumentsIn({super.key});

  @override
  _DocumentsInState createState() => _DocumentsInState();
}

class _DocumentsInState extends State<DocumentsIn> {
  // Данные для таблицы
  final List<User> _users = [
    User('John', 'Smith', 28),
    User('Jane', 'Doe', 24),
    User('Sam', 'Johnson', 32),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'documents-in',
        leading: true,
      ),
      body: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: FittedBox(
            child: DataTable(
              columnSpacing: 5,
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
                    width: 80,
                    child: Text('Age'),
                  ),
                  numeric: true,
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
                      DataCell(Text('25')),
                    ],
                  ),
              ],
            ),
          ),
        ),
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
