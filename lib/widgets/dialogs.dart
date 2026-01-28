import 'package:flutter/material.dart';
import 'package:flutter_mdokon/models/cashier/print_model.dart';
import 'package:provider/provider.dart';

showPrinterPicker(context) async {
  return await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Позволяет BottomSheet адаптироваться под контент
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Consumer<PrinterModel>(
      builder: (context, model, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Принтеры',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: model.scanResults.length,
                  itemBuilder: (context, index) {
                    final result = model.scanResults[index];
                    if (result.device.platformName.isEmpty) return const SizedBox();

                    return ListTile(
                      title: Text(result.device.platformName),
                      subtitle: Text(result.device.remoteId.str),
                      onTap: () {
                        model.selectDevice(result.device);
                        Navigator.pop(context, true);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
