import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:kassa/helpers/helper.dart';
import 'package:kassa/models/data_model.dart';
import 'package:kassa/models/director/documents_in_model.dart';

import 'package:kassa/widgets/custom_app_bar.dart';
import 'package:kassa/widgets/filter/label.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';

class DocumentsInCreate extends StatefulWidget {
  const DocumentsInCreate({super.key});

  @override
  _DocumentsInCreateState createState() => _DocumentsInCreateState();
}

class _DocumentsInCreateState extends State<DocumentsInCreate> {
  @override
  Widget build(BuildContext context) {
    DataModel dataModel = Provider.of<DataModel>(context, listen: false);
    return Scaffold(
      appBar: CustomAppBar(
        title: context.tr('create'),
        leading: true,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Label(text: 'pos'),
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: MediaQuery.of(context).size.width,
                child: Consumer<DocumentsInModel>(
                  builder: (context, documentsInModel, chilld) {
                    return Container(
                      height: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: CustomTheme.of(context).cardColor,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<String>(
                          value: documentsInModel.data.posId.toString(),
                          buttonStyleData: const ButtonStyleData(),
                          iconStyleData: const IconStyleData(icon: Icon(UniconsLine.angle_down)),
                          dropdownStyleData: DropdownStyleData(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: CustomTheme.of(context).cardColor,
                            ),
                            maxHeight: 300,
                            offset: const Offset(0, -10),
                          ),
                          isDense: true,
                          onChanged: (String? newValue) {},
                          items: dataModel.poses.map(
                            (Map<String, dynamic> item) {
                              return DropdownMenuItem<String>(
                                value: item['id'].toString(),
                                child: Text(item['name']),
                              );
                            },
                          ).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Padding(
                  padding: EdgeInsets.zero, // Убираем внешние отступы
                  child: ExpansionTile(
                    title: Text(context.tr("additionally")),
                    tilePadding: EdgeInsets.zero, // Убираем внутренние отступы
                    children: <Widget>[
                      ListTile(
                        title: Text("Элемент 1"),
                        contentPadding: EdgeInsets.zero, // Убираем отступы внутри ListTile
                      ),
                      ListTile(
                        title: Text("Элемент 2"),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
