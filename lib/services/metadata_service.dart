import 'dart:async';
import 'package:get/get.dart';
import '../models/route_point_model.dart';
import 'location_service.dart';
import 'signaling_service.dart';

class MetadataService extends GetxService {
  final LocationService _locationService = Get.find();
  final SignalingService _signalingService = Get.find();

  StreamSubscription<RoutePointModel>? _locationSubscription;
  Timer? _sendTimer;

  final List<RoutePointModel> _bufferedPoints = [];
  final _isTracking = false.obs;

  bool get isTracking => _isTracking.value;
  int get bufferedPointsCount => _bufferedPoints.length;

  /// Iniciar envío de metadata GPS
  void startSendingMetadata({bool isPowerSavingMode = false}) {
    if (_isTracking.value) {
      print('⚠️ Ya se está enviando metadata');
      return;
    }

    print('📡 Iniciando envío de metadata GPS...');
    _isTracking.value = true;

    // Suscribirse al stream de ubicación
    _locationSubscription = _locationService.positionStream.listen(
      (point) {
        _bufferedPoints.add(point);
        print(
          '📍 Punto GPS bufferizado: ${point.latitude}, ${point.longitude}',
        );
      },
      onError: (error) {
        print('❌ Error en stream de ubicación: $error');
      },
    );

    // Configurar timer según modo de ahorro
    final duration = isPowerSavingMode
        ? const Duration(seconds: 3) // Cada 3s en modo ahorro
        : const Duration(seconds: 1); // Cada 1s normal

    _sendTimer = Timer.periodic(duration, (_) {
      _sendBufferedPoints();
    });

    print('✅ Metadata service iniciado (intervalo: ${duration.inSeconds}s)');
  }

  /// Enviar puntos bufferizados al servidor
  void _sendBufferedPoints() {
    if (_bufferedPoints.isEmpty) return;

    // Tomar el último punto (más reciente)
    final latestPoint = _bufferedPoints.last;

    try {
      _signalingService.sendGPSData(
        latitude: latestPoint.latitude,
        longitude: latestPoint.longitude,
        speed: latestPoint.speed ?? 0.0,
        heading: latestPoint.heading ?? 0.0,
        altitude: latestPoint.altitude ?? 0.0,
        accuracy: latestPoint.accuracy ?? 0.0,
      );

      print(
        '✅ GPS enviado: ${latestPoint.speedKmh?.toStringAsFixed(1) ?? "0.0"} km/h',
      );

      // Limpiar buffer después de enviar
      _bufferedPoints.clear();
    } catch (e) {
      print('❌ Error al enviar GPS: $e');
      // Mantener puntos en buffer para reintentar
    }
  }

  /// Cambiar intervalo de envío (para power saving mode)
  void updateSendingInterval({required bool isPowerSavingMode}) {
    if (!_isTracking.value) return;

    _sendTimer?.cancel();

    final duration = isPowerSavingMode
        ? const Duration(seconds: 3)
        : const Duration(seconds: 1);

    _sendTimer = Timer.periodic(duration, (_) {
      _sendBufferedPoints();
    });

    print('🔄 Intervalo de envío actualizado: ${duration.inSeconds}s');
  }

  /// Detener envío de metadata
  void stopSendingMetadata() {
    if (!_isTracking.value) return;

    print('⏹️ Deteniendo envío de metadata...');

    _locationSubscription?.cancel();
    _locationSubscription = null;

    _sendTimer?.cancel();
    _sendTimer = null;

    // Enviar puntos restantes antes de detener
    if (_bufferedPoints.isNotEmpty) {
      _sendBufferedPoints();
    }

    _bufferedPoints.clear();
    _isTracking.value = false;

    print('✅ Metadata service detenido');
  }

  /// Obtener estadísticas de puntos
  Map<String, dynamic> getStats() {
    if (_bufferedPoints.isEmpty) {
      return {'totalPoints': 0, 'bufferedPoints': 0};
    }

    return {
      'totalPoints': _bufferedPoints.length,
      'bufferedPoints': _bufferedPoints.length,
      'lastPoint': {
        'latitude': _bufferedPoints.last.latitude,
        'longitude': _bufferedPoints.last.longitude,
        'speed': _bufferedPoints.last.speedKmh,
        'timestamp': _bufferedPoints.last.timestamp.toIso8601String(),
      },
    };
  }

  @override
  void onClose() {
    stopSendingMetadata();
    super.onClose();
  }
}
