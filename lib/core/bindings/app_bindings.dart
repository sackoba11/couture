import 'package:get/get.dart';

import '../../presentation/views/client/controller/client_controller.dart';
import '../../presentation/views/home/controller/home_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Get.put<SplashController>(SplashController(), permanent: true);
    // Get.put(NavController(), permanent: true);
    // ==================== DATA SOURCE ====================
    // Get.lazyPut<AnnouncesRemoteDataSource>(
    //   () => AnnouncesRemoteDataSourceImpl(),
    //   fenix: true,
    // );
    // ==================== REPOSITORIES ====================
    // Get.lazyPut<AnnounceRepository>(
    //   () => AnnounceRepositoryImpl(
    //     announcesRemoteDataSource: Get.find<AnnouncesRemoteDataSource>(),
    //   ),
    //   fenix: true,
    // );

    // ==================== CONTROLLERS ====================
    Get.lazyPut(() => HomeController(), fenix: true);
    Get.lazyPut(() => ClientController(), fenix: true);
  }
}
