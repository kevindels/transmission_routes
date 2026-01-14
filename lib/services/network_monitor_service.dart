import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

enum NetworkQuality { excellent, good, fair, poor, disconnected }

class NetworkMonitorService extends GetxService {
  final _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  final _networkQuality = NetworkQuality.disconnected.obs;
  final _isConnected = false.obs;
  final _latency = 0.obs;

  NetworkQuality get networkQuality => _networkQuality.value;
  bool get isConnected => _isConnected.value;
  int get latency => _latency.value;

  Timer? _latencyCheckTimer;

  @override
  void onInit() {
    super.onInit();
    _startMonitoring();
  }

  /// Iniciar monitoreo de conectividad
  void _startMonitoring() {
    // Check inicial
    _checkConnectivity();

    // Escuchar cambios en la conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      _handleConnectivityChange([result]);
    });

    // Medir latencia cada 10 segundos
    _latencyCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _measureLatency(),
    );
  }

  /// Verificar conectividad actual
  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _handleConnectivityChange([result]);
  }

  /// Manejar cambios de conectividad
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isConnected = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi,
    );

    _isConnected.value = isConnected;

    if (isConnected) {
      print('✅ Conectado: ${results.first}');
      _measureLatency();
    } else {
      print('❌ Sin conexión');
      _networkQuality.value = NetworkQuality.disconnected;
      _latency.value = 0;
    }
  }

  /// Medir latencia (RTT) al servidor
  Future<void> _measureLatency() async {
    if (!_isConnected.value) return;

    try {
      final stopwatch = Stopwatch()..start();
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/health'))
          .timeout(const Duration(seconds: 5));

      stopwatch.stop();

      if (response.statusCode == 200) {
        _latency.value = stopwatch.elapsedMilliseconds;
        _calculateNetworkQuality(stopwatch.elapsedMilliseconds);
      }
    } catch (e) {
      print('⚠️ Error al medir latencia: $e');
      _latency.value = 9999;
      _networkQuality.value = NetworkQuality.poor;
    }
  }

  /// Calcular calidad de red según latencia
  void _calculateNetworkQuality(int latencyMs) {
    if (latencyMs < 100) {
      _networkQuality.value = NetworkQuality.excellent;
    } else if (latencyMs < 300) {
      _networkQuality.value = NetworkQuality.good;
    } else if (latencyMs < 600) {
      _networkQuality.value = NetworkQuality.fair;
    } else {
      _networkQuality.value = NetworkQuality.poor;
    }

    print('📊 Latencia: ${latencyMs}ms - Calidad: ${_networkQuality.value}');
  }

  /// Obtener string descriptivo de la calidad
  String getQualityDescription() {
    switch (_networkQuality.value) {
      case NetworkQuality.excellent:
        return 'Excelente';
      case NetworkQuality.good:
        return 'Buena';
      case NetworkQuality.fair:
        return 'Regular';
      case NetworkQuality.poor:
        return 'Pobre';
      case NetworkQuality.disconnected:
        return 'Sin conexión';
    }
  }

  /// Obtener color según calidad
  String getQualityColor() {
    switch (_networkQuality.value) {
      case NetworkQuality.excellent:
        return '#10b981'; // Verde
      case NetworkQuality.good:
        return '#3b82f6'; // Azul
      case NetworkQuality.fair:
        return '#f59e0b'; // Amarillo
      case NetworkQuality.poor:
        return '#ef4444'; // Rojo
      case NetworkQuality.disconnected:
        return '#6b7280'; // Gris
    }
  }

  /// Verificar si la calidad es suficiente para streaming
  bool isQualitySufficientForStreaming() {
    return _networkQuality.value == NetworkQuality.excellent ||
        _networkQuality.value == NetworkQuality.good ||
        _networkQuality.value == NetworkQuality.fair;
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _latencyCheckTimer?.cancel();
    super.onClose();
  }
}
