import 'package:get/get.dart';

class Controller extends GetxController {
  dynamic loading = false.obs;
  showLoading() => {
        loading = true.obs,
        update(),
      };

  hideLoading() => {loading = false.obs, update()};
}
