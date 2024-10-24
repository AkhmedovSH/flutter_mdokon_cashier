import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:kassa/widgets/custom_app_bar.dart';
import 'package:kassa/widgets/table/table.dart';

class DocumentsIn extends StatefulWidget {
  const DocumentsIn({super.key});

  @override
  _DocumentsInState createState() => _DocumentsInState();
}

class _DocumentsInState extends State<DocumentsIn> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.tr('documents_in'),
        leading: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: TableWidget(
              headers: const [
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
          ),
        ],
      ),
    );
  }
}
