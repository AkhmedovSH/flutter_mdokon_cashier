import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:kassa/widgets/custom_app_bar.dart';

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
      appBar: CustomAppBar(
        title: context.tr('documents_in'),
        leading: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: HorizontalDataTable(
              leftHandSideColumnWidth: 50,
              rightHandSideColumnWidth: 600,
              itemCount: 20, // количество строк
              rowSeparatorWidget: const Divider(
                color: Colors.black54,
                height: 1.0,
                thickness: 0.0,
              ), // разделитель строк
              leftHandSideColBackgroundColor: Color(0xFFFFFFFF),
              rightHandSideColBackgroundColor: Color(0xFFFFFFFF),

              isFixedHeader: true,
              headerWidgets: [
                Container(
                  width: 100,
                  height: 56,
                  alignment: Alignment.center,
                  child: Text('Left', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  width: 100,
                  height: 56,
                  alignment: Alignment.center,
                  child: Text('Right 1', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  width: 100,
                  height: 56,
                  alignment: Alignment.center,
                  child: Text('Right 2', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  width: 100,
                  height: 56,
                  alignment: Alignment.center,
                  child: Text('Right 3', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  width: 100,
                  height: 56,
                  alignment: Alignment.center,
                  child: Text('Right 4', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  width: 100,
                  height: 56,
                  alignment: Alignment.center,
                  child: Text('Right 5', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
              rightSideItemBuilder: (context, index) {
                return Row(
                  children: <Widget>[
                    Container(
                      width: 100,
                      height: 52,
                      alignment: Alignment.center,
                      child: Text('R1'),
                    ),
                    Container(
                      width: 100,
                      height: 52,
                      alignment: Alignment.center,
                      child: Text('R2'),
                    ),
                    Container(
                      width: 100,
                      height: 52,
                      alignment: Alignment.center,
                      child: Text('R3'),
                    ),
                    Container(
                      width: 100,
                      height: 52,
                      alignment: Alignment.center,
                      child: Text('R4'),
                    ),
                    Container(
                      width: 100,
                      height: 52,
                      alignment: Alignment.centerRight,
                      child: Text('R5'),
                    ),
                  ],
                );
              },
              leftSideItemBuilder: (context, index) {
                return Container(
                  color: index % 2 == 0 ? Colors.grey[300] : Colors.white,
                  child: Center(child: Text('Row $index')),
                  height: 52,
                  width: 100,
                );
              },
            ),
          )

          // SingleChildScrollView(
          //   scrollDirection: Axis.horizontal,
          //   child: DataTable(
          //     columns: [
          //       DataColumn(
          //         label: SizedBox(
          //           width: 40,
          //           child: Text('№'),
          //         ),
          //       ),
          //       DataColumn(
          //         label: SizedBox(
          //           width: 200,
          //           child: Text('Surname'),
          //         ),
          //       ),
          //       DataColumn(
          //         label: SizedBox(
          //           width: 200,
          //           child: Text('Name'),
          //         ),
          //       ),
          //       DataColumn(
          //         label: SizedBox(
          //           width: 80,
          //           child: Text('Age'),
          //         ),
          //         numeric: true,
          //       ),
          //     ],
          //     rows: [], // Здесь пусто, так как строки будут в другой части
          //   ),
          // ),
          // // Прокручиваемые строки данных
          // Expanded(
          //   child: SingleChildScrollView(
          //     child: SingleChildScrollView(
          //       scrollDirection: Axis.horizontal,
          //       child: Column(
          //         children: [
          //           DataTable(
          //             headingRowHeight: 0,
          //             columns: [
          //               DataColumn(
          //                 label: SizedBox(
          //                   width: 40,
          //                 ), // Пустые заголовки для выравнивания
          //               ),
          //               DataColumn(
          //                 label: SizedBox(
          //                   width: 200,
          //                 ),
          //               ),
          //               DataColumn(
          //                 label: SizedBox(
          //                   width: 200,
          //                 ),
          //               ),
          //               DataColumn(
          //                 label: SizedBox(
          //                   width: 80,
          //                 ),
          //               ),
          //             ],
          //             rows: [
          //               for (var i = 1; i < 100; i++)
          //                 DataRow(
          //                   cells: [
          //                     DataCell(
          //                       SizedBox(
          //                         width: 40,
          //                         child: Text('${i + 1}'),
          //                       ),
          //                     ),
          //                     DataCell(Text('Doe')),
          //                     DataCell(Text('John')),
          //                     DataCell(Text('25')),
          //                   ],
          //                 ),
          //             ],
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  List<Widget> _getTitleWidget() {
    return [
      _getTitleItemWidget('Left'),
      _getTitleItemWidget('Right 1'),
      _getTitleItemWidget('Right 2'),
      _getTitleItemWidget('Right 3'),
      _getTitleItemWidget('Right 4'),
      _getTitleItemWidget('Right 5'),
    ];
  }

  Widget _getTitleItemWidget(String label) {
    return Container(
      width: 50,
      height: 56,
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLeftColumnRow(BuildContext context, int index) {
    return Container(
      color: index % 2 == 0 ? Colors.grey[300] : Colors.white,
      child: Center(child: Text('Row $index')),
      height: 52,
      width: 100,
    );
  }

  Widget _buildRightColumnRow(BuildContext context, int index) {
    return Row(
      children: <Widget>[
        _getRowItemWidget('R1', 100),
        _getRowItemWidget('R2', 100),
        _getRowItemWidget('R3', 100),
        _getRowItemWidget('R4', 100),
        _getRowItemWidget('R5', 100),
      ],
    );
  }

  Widget _getRowItemWidget(String label, double width) {
    return Container(
      width: width,
      height: 52,
      alignment: Alignment.center,
      child: Text(label),
    );
  }
}
