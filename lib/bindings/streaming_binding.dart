import 'package:get/get.dart';

import '../controllers/streaming_controller.dart';
import '../services/webrtc_streaming_service.dart';
import '../services/signaling_service.dart';

class StreamingBinding extends Bindings {
  @override
  void dependencies() {
    // Controlador de streaming (se crea al entrar a la vista)
    Get.lazyPut<StreamingController>(() => StreamingController());

    // Asegurar que servicios de streaming estén disponibles
    if (!Get.isRegistered<WebRTCStreamingService>()) {
      Get.put(WebRTCStreamingService());
    }
    if (!Get.isRegistered<SignalingService>()) {
      Get.put(SignalingService());
    }
  }
}
