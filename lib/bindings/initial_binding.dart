import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/webrtc_streaming_service.dart';
import '../services/signaling_service.dart';
import '../services/location_service.dart';
import '../services/metadata_service.dart';
import '../services/network_monitor_service.dart';

class InitialBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    // Servicios core (permanentes)
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    Get.put(settings, permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.put(NetworkMonitorService(), permanent: true);
    Get.put(LocationService(), permanent: true);

    // Servicios de streaming (permanentes para reutilización)
    Get.put(WebRTCStreamingService(), permanent: true);
    Get.put(SignalingService(), permanent: true);
    Get.put(MetadataService(), permanent: true);
  }
}
