import 'package:get/get.dart';

import 'app_routes.dart';
import '../views/login_view.dart';
import '../views/home_view.dart';
import '../views/streaming_view.dart';
import '../bindings/streaming_binding.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.LOGIN, page: () => LoginView()),
    GetPage(name: AppRoutes.HOME, page: () => HomeView()),
    GetPage(
      name: AppRoutes.STREAMING,
      page: () => StreamingView(),
      binding: StreamingBinding(),
    ),
    // TODO: Agregar SETTINGS y ROUTES cuando estén implementadas
  ];
}
