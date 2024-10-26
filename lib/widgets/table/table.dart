import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/loading_model.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

const List<DataColumn> dataColumns = [];
const List<DataRow> dataRows = [];

class TableWidget extends StatefulWidget {
  final List<DataColumn> headers;
  final List<DataRow> rows;
  final List<DataColumn> fixedLeftHeaders;
  final List<DataRow> fixedLeftRows;
  final double fixedLeftWidth;
  const TableWidget({
    super.key,
    required this.headers,
    required this.rows,
    this.fixedLeftHeaders = dataColumns,
    this.fixedLeftRows = dataRows,
    this.fixedLeftWidth = 0,
  });

  @override
  _TableWidgetState createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  late final ScrollController horizontalScrollController1;
  late final ScrollController horizontalScrollController2;
  late final ScrollController verticalScrollController1;
  late final ScrollController verticalScrollController2;

  @override
  void initState() {
    super.initState();
    horizontalScrollController1 = ScrollController();
    horizontalScrollController2 = ScrollController();

    horizontalScrollController1.addListener(() {
      if (horizontalScrollController1.offset != horizontalScrollController2.offset) {
        horizontalScrollController2.jumpTo(horizontalScrollController1.offset);
      }
    });
    horizontalScrollController2.addListener(() {
      if (horizontalScrollController1.offset != horizontalScrollController2.offset) {
        horizontalScrollController1.jumpTo(horizontalScrollController2.offset);
      }
    });
    // Vertical
    verticalScrollController1 = ScrollController();
    verticalScrollController2 = ScrollController();

    verticalScrollController1.addListener(() {
      if (verticalScrollController1.offset != verticalScrollController2.offset) {
        verticalScrollController2.jumpTo(verticalScrollController1.offset);
      }
    });
    verticalScrollController2.addListener(() {
      if (verticalScrollController1.offset != verticalScrollController2.offset) {
        verticalScrollController1.jumpTo(verticalScrollController2.offset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(left: widget.fixedLeftWidth),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: horizontalScrollController1,
                child: DataTable(
                  columns: widget.headers,
                  rows: const [],
                ),
              ),
              Consumer<LoadingModel>(
                builder: (context, loaderModel, child) {
                  if (loaderModel.currentLoading == 1) {
                    return Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: CircularProgressIndicator(
                        color: mainColor,
                      ),
                    );
                  }
                  if (loaderModel.currentLoading == 0 && widget.rows.isEmpty) {
                    return Column(
                      children: [
                        SizedBox(height: 100),
                        Icon(
                          UniconsLine.inbox,
                          size: 48,
                        ),
                        SizedBox(height: 15),
                        Text(
                          context.tr('EMPTY_LIST'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  // controller: verticalScrollController1,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: horizontalScrollController2,
                    child: DataTable(
                      headingRowHeight: 0,
                      columns: widget.headers,
                      rows: widget.rows,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // widget.fixedLeftHeaders.isNotEmpty
        //     ? Positioned(
        //         left: 0,
        //         top: 0,
        //         child: SizedBox(
        //           width: widget.fixedLeftWidth,
        //           height: MediaQuery.of(context).size.height,
        //           child: Column(
        //             children: [
        //               DataTable(
        //                 columns: widget.fixedLeftHeaders,
        //                 rows: const [],
        //               ),
        //               Expanded(
        //                 child: SingleChildScrollView(
        //                   controller: verticalScrollController2,
        //                   child: DataTable(
        //                     headingRowHeight: 0,
        //                     columns: widget.fixedLeftHeaders,
        //                     rows: widget.fixedLeftRows,
        //                   ),
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ))
        //     : SizedBox(),
      ],
    );
  }
}
