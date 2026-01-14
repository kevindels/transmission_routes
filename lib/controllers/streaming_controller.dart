import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../services/webrtc_streaming_service.dart';
import '../services/signaling_service.dart';
import '../services/location_service.dart';
import '../services/metadata_service.dart';
import '../services/network_monitor_service.dart';
import '../utils/data_usage_estimator.dart';
import '../models/route_model.dart';
import '../models/route_point_model.dart';

class StreamingController extends GetxController {
  // Servicios
  final _authService = Get.find<AuthService>();
  final _settingsService = Get.find<SettingsService>();
  final _webrtcService = Get.find<WebRTCStreamingService>();
  final _signalingService = Get.find<SignalingService>();
  final _locationService = Get.find<LocationService>();
  final _metadataService = Get.find<MetadataService>();
  final _networkMonitor = Get.find<NetworkMonitorService>();

  final _battery = Battery();

  // Observables
  final _isStreaming = false.obs;
  final _isReconnecting = false.obs;
  final _isPowerSavingMode = false.obs;
  final _streamDuration = 0.obs;
  final _viewersCount = 0.obs;
  final _currentBitrate = 0.obs;
  final _networkQuality = NetworkQuality.disconnected.obs;
  final _currentSpeed = 0.0.obs;
  final _batteryLevel = 100.obs;
  final _estimatedDataUsage = 0.0.obs;

  // Getters
  bool get isStreaming => _isStreaming.value;
  bool get isReconnecting => _isReconnecting.value;
  bool get isPowerSavingMode => _isPowerSavingMode.value;
  int get streamDuration => _streamDuration.value;
  int get viewersCount => _viewersCount.value;
  int get currentBitrate => _currentBitrate.value;
  NetworkQuality get networkQuality => _networkQuality.value;
  double get currentSpeed => _currentSpeed.value;
  int get batteryLevel => _batteryLevel.value;
  double get estimatedDataUsage => _estimatedDataUsage.value;

  String? _currentStreamId;
  Timer? _durationTimer;
  Timer? _statsTimer;
  StreamSubscription<RoutePointModel>? _locationSubscription;
  final List<RoutePointModel> _recordedPoints = [];

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
    _loadInitialSettings();
  }

  /// Cargar configuración inicial
  void _loadInitialSettings() {
    _isPowerSavingMode.value = _settingsService.getPowerSavingMode();
    _updateBatteryLevel();
  }

  /// Configurar listeners de servicios
  void _setupListeners() {
    // Signaling callbacks
    _signalingService.onError = (message) {
      Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
    };

    _signalingService.onStreamStopped = () {
      Get.snackbar(
        'Stream detenido',
        'El servidor detuvo la transmisión',
        snackPosition: SnackPosition.BOTTOM,
      );
      stopStreaming();
    };

    _signalingService.onViewerCountUpdate = (count) {
      _viewersCount.value = count;
    };

    _signalingService.onAnswerReceived = (answer) async {
      await _webrtcService.setRemoteAnswer(answer);
    };

    _signalingService.onIceCandidateReceived = (candidate) async {
      await _webrtcService.addIceCandidate(candidate);
    };

    // Network quality
    ever(_networkMonitor.networkQuality.obs, (quality) {
      _networkQuality.value = quality;

      // Auto power saving si red es mala
      if (_settingsService.getAutoPowerSaving() && _isStreaming.value) {
        if (quality == NetworkQuality.poor || quality == NetworkQuality.fair) {
          if (!_isPowerSavingMode.value) {
            print('📉 Activando modo ahorro por red pobre');
            togglePowerSavingMode();
          }
        }
      }
    });
  }

  /// Validaciones antes de iniciar stream
  Future<bool> _validatePreConditions() async {
    // 1. Verificar autenticación
    if (!_authService.isAuthenticated()) {
      Get.snackbar(
        'Error',
        'Debes iniciar sesión',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // 2. Verificar batería mínima
    final batteryLevel = await _battery.batteryLevel;
    final minBattery = _settingsService.getMinBatteryLevel();
    if (batteryLevel < minBattery) {
      Get.snackbar(
        'Batería baja',
        'Se requiere al menos $minBattery% de batería',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // 3. Verificar conectividad
    if (!_networkMonitor.isConnected) {
      Get.snackbar(
        'Sin conexión',
        'No hay conexión a internet',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    // 4. Verificar calidad de red
    if (!_networkMonitor.isQualitySufficientForStreaming()) {
      final proceed =
          await Get.dialog<bool>(
            AlertDialog(
              title: Text('Red pobre'),
              content: Text(
                'La calidad de red es pobre. ¿Continuar de todos modos?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: Text('Continuar'),
                ),
              ],
            ),
          ) ??
          false;

      if (!proceed) return false;
    }

    return true;
  }

  /// Iniciar streaming
  Future<void> startStreaming() async {
    if (_isStreaming.value) {
      print('⚠️ Ya está transmitiendo');
      return;
    }

    try {
      // Validaciones
      if (!await _validatePreConditions()) return;

      print('🚀 Iniciando streaming...');

      // 1. Habilitar wakelock
      await WakelockPlus.enable();

      // 2. Conectar signaling
      final token = _authService.token!;
      _signalingService.connect(token);
      await Future.delayed(Duration(seconds: 1)); // Esperar conexión

      // 3. Obtener servidores TURN
      final iceServers = await _getTurnServers(token);

      // 4. Inicializar cámara
      await _webrtcService.initializeCamera(
        isPowerSavingMode: _isPowerSavingMode.value,
      );

      // 5. Crear peer connection
      await _webrtcService.createPeerConnection(iceServers);

      // 6. Crear oferta
      final offer = await _webrtcService.createOffer();

      // 7. Enviar oferta al servidor
      _signalingService.startStream(
        offer: offer,
        isPowerSavingMode: _isPowerSavingMode.value,
      );

      // 8. Iniciar seguimiento GPS
      await _locationService.startTracking();
      _metadataService.startSendingMetadata(
        isPowerSavingMode: _isPowerSavingMode.value,
      );

      // 9. Suscribirse a puntos GPS para grabar
      _locationSubscription = _locationService.positionStream.listen((point) {
        _recordedPoints.add(point);
        _currentSpeed.value = point.speedKmh ?? 0.0;
      });

      // 10. Iniciar timers
      _startDurationTimer();
      _startStatsTimer();

      _isStreaming.value = true;
      print('✅ Streaming iniciado');

      Get.snackbar(
        'Transmisión iniciada',
        'Transmitiendo en vivo',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Error al iniciar streaming: $e');
      Get.snackbar(
        'Error',
        'No se pudo iniciar la transmisión: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      await _cleanup();
    }
  }

  /// Detener streaming
  Future<void> stopStreaming() async {
    if (!_isStreaming.value) return;

    print('⏹️ Deteniendo streaming...');

    try {
      // 1. Detener envío de metadata
      _metadataService.stopSendingMetadata();

      // 2. Detener GPS
      await _locationService.stopTracking();

      // 3. Notificar al servidor
      _signalingService.stopStream();

      // 4. Guardar ruta
      await _saveRoute();

      // 5. Limpiar recursos
      await _cleanup();

      _isStreaming.value = false;
      print('✅ Streaming detenido');

      Get.snackbar(
        'Transmisión finalizada',
        'Ruta guardada correctamente',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ Error al detener streaming: $e');
      await _cleanup();
    }
  }

  /// Alternar modo de ahorro de energía
  Future<void> togglePowerSavingMode() async {
    if (!_isStreaming.value) {
      _isPowerSavingMode.value = !_isPowerSavingMode.value;
      _settingsService.setPowerSavingMode(_isPowerSavingMode.value);
      return;
    }

    _isPowerSavingMode.value = !_isPowerSavingMode.value;
    print('🔋 Modo ahorro: ${_isPowerSavingMode.value ? "ON" : "OFF"}');

    // Ajustar bitrate
    await _webrtcService.adjustBitrate(
      isPowerSavingMode: _isPowerSavingMode.value,
    );

    // Ajustar intervalo de metadata
    _metadataService.updateSendingInterval(
      isPowerSavingMode: _isPowerSavingMode.value,
    );

    _settingsService.setPowerSavingMode(_isPowerSavingMode.value);
  }

  /// Reconexión automática (TODO: implementar lógica completa)
  /*
  Future<void> _handleReconnection() async {
    if (_isReconnecting.value) return;

    _isReconnecting.value = true;
    print('🔄 Intentando reconectar...');

    try {
      // Obtener servidores TURN
      final token = _authService.token!;
      final iceServers = await _getTurnServers(token);

      // Reconectar WebRTC
      await _webrtcService.reconnectStream(
        iceServers: iceServers,
        isPowerSavingMode: _isPowerSavingMode.value,
      );

      // Crear nueva oferta
      final offer = await _webrtcService.createOffer();

      // Reconectar en el servidor
      _signalingService.reconnectStream(
        streamId: _currentStreamId!,
        offer: offer,
      );

      _isReconnecting.value = false;
      print('✅ Reconexión exitosa');
    } catch (e) {
      print('❌ Error en reconexión: $e');
      _isReconnecting.value = false;
      await stopStreaming();
    }
  }
  */

  /// Obtener servidores TURN
  Future<List<Map<String, dynamic>>> _getTurnServers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.turnEndpoint}'),
        headers: ApiConfig.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['iceServers']);
      }

      throw Exception('Error al obtener servidores TURN');
    } catch (e) {
      print('⚠️ Error obteniendo TURN servers: $e');
      // Fallback a Google STUN
      return [
        {'urls': 'stun:stun.l.google.com:19302'},
      ];
    }
  }

  /// Guardar ruta en el servidor
  Future<void> _saveRoute() async {
    if (_recordedPoints.isEmpty) {
      print('⚠️ No hay puntos para guardar');
      return;
    }

    try {
      final route = RouteModel(
        id:
            _currentStreamId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _authService.user!.id,
        streamId: _currentStreamId ?? '',
        name: 'Ruta ${DateTime.now().toString().split(' ')[0]}',
        totalDistance: 0.0,
        averageSpeed: 0.0,
        maxSpeed: 0.0,
        startTime: _recordedPoints.first.timestamp,
        endTime: _recordedPoints.last.timestamp,
        points: _recordedPoints,
        powerSavingModeUsed: _isPowerSavingMode.value,
      );

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.saveRouteEndpoint}'),
        headers: {
          ...ApiConfig.getAuthHeaders(_authService.token!),
          'Content-Type': 'application/json',
        },
        body: json.encode(route.toJson()),
      );

      if (response.statusCode == 201) {
        print('✅ Ruta guardada en servidor');
      } else {
        print('⚠️ Error al guardar ruta: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error guardando ruta: $e');
    }
  }

  /// Timer de duración
  void _startDurationTimer() {
    _streamDuration.value = 0;
    _durationTimer = Timer.periodic(Duration(seconds: 1), (_) {
      _streamDuration.value++;

      // Actualizar estimación de datos
      final bitrateKbps = _isPowerSavingMode.value ? 400 : 1500;
      _estimatedDataUsage.value = DataUsageEstimator.estimateDataUsage(
        bitrateKbps,
        Duration(seconds: _streamDuration.value),
      );

      // Verificar límite de duración
      final maxDuration = _settingsService.getMaxStreamDuration();
      if (_streamDuration.value >= maxDuration) {
        Get.snackbar(
          'Tiempo límite',
          'Se alcanzó el tiempo máximo de transmisión',
          snackPosition: SnackPosition.BOTTOM,
        );
        stopStreaming();
      }
    });
  }

  /// Timer de estadísticas
  void _startStatsTimer() {
    _statsTimer = Timer.periodic(Duration(seconds: 3), (_) async {
      _updateBatteryLevel();

      // Obtener bitrate actual
      final stats = await _webrtcService.getConnectionStats();
      if (stats.containsKey('bytesSent')) {
        // Calcular bitrate aproximado
        _currentBitrate.value = ((stats['bytesSent'] as int) * 8 / 1000)
            .round();
      }
    });
  }

  /// Actualizar nivel de batería
  Future<void> _updateBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      _batteryLevel.value = level;

      // Auto-detener si batería muy baja
      if (_isStreaming.value && level < 10) {
        Get.snackbar(
          'Batería crítica',
          'Deteniendo transmisión por batería baja',
          snackPosition: SnackPosition.BOTTOM,
        );
        await stopStreaming();
      }
    } catch (e) {
      print('⚠️ Error obteniendo nivel de batería: $e');
    }
  }

  /// Limpiar recursos
  Future<void> _cleanup() async {
    _durationTimer?.cancel();
    _statsTimer?.cancel();
    _locationSubscription?.cancel();

    await _webrtcService.dispose();
    _signalingService.disconnect();
    await WakelockPlus.disable();

    _recordedPoints.clear();
    _streamDuration.value = 0;
    _viewersCount.value = 0;
  }

  @override
  void onClose() {
    if (_isStreaming.value) {
      stopStreaming();
    }
    super.onClose();
  }
}
