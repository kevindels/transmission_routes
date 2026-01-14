import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../config/api_config.dart';

class SignalingService extends GetxService {
  IO.Socket? _socket;
  final _isConnected = false.obs;

  bool get isConnected => _isConnected.value;

  // Callbacks
  Function(String message)? onError;
  Function()? onStreamStopped;
  Function(int count)? onViewerCountUpdate;
  Function(RTCIceCandidate candidate)? onIceCandidateReceived;
  Function(RTCSessionDescription answer)? onAnswerReceived;

  /// Conectar al servidor de señalización
  void connect(String token) {
    if (_socket != null && _socket!.connected) {
      print('⚠️ Ya conectado a Socket.io');
      return;
    }

    print('🔌 Conectando a Socket.io: ${ApiConfig.wsUrl}');

    _socket = IO.io(
      ApiConfig.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _setupListeners();
    _socket!.connect();
  }

  /// Configurar listeners de eventos
  void _setupListeners() {
    _socket!.onConnect((_) {
      print('✅ Conectado a Socket.io');
      _isConnected.value = true;
    });

    _socket!.onDisconnect((_) {
      print('❌ Desconectado de Socket.io');
      _isConnected.value = false;
    });

    _socket!.on('error', (data) {
      print('❌ Error del servidor: $data');
      onError?.call(data['message'] ?? 'Error desconocido');
    });

    _socket!.on('stream-stopped', (_) {
      print('⛔ Stream detenido por el servidor');
      onStreamStopped?.call();
    });

    _socket!.on('viewer-count-update', (data) {
      final count = data['count'] as int;
      print('👥 Viewers: $count');
      onViewerCountUpdate?.call(count);
    });

    _socket!.on('answer', (data) {
      print('📨 Respuesta SDP recibida');
      final answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      onAnswerReceived?.call(answer);
    });

    _socket!.on('ice-candidate', (data) {
      print('🧊 ICE candidate recibido');
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      onIceCandidateReceived?.call(candidate);
    });

    _socket!.onConnectError((data) {
      print('❌ Error de conexión: $data');
      onError?.call('Error al conectar al servidor');
    });

    _socket!.onReconnectAttempt((attempt) {
      print('🔄 Reintento de conexión: $attempt');
    });
  }

  /// Iniciar streaming
  void startStream({
    required RTCSessionDescription offer,
    bool isPowerSavingMode = false,
  }) {
    if (!_isConnected.value) {
      throw Exception('No conectado a Socket.io');
    }

    print('📡 Enviando stream-start...');
    _socket!.emit('stream-start', {
      'offer': {'type': offer.type, 'sdp': offer.sdp},
      'powerSavingMode': isPowerSavingMode,
    });
  }

  /// Reconectar stream existente
  void reconnectStream({
    required String streamId,
    required RTCSessionDescription offer,
  }) {
    if (!_isConnected.value) {
      throw Exception('No conectado a Socket.io');
    }

    print('🔄 Enviando stream-reconnect...');
    _socket!.emit('stream-reconnect', {
      'streamId': streamId,
      'offer': {'type': offer.type, 'sdp': offer.sdp},
    });
  }

  /// Enviar candidato ICE
  void sendIceCandidate(RTCIceCandidate candidate) {
    if (!_isConnected.value) return;

    _socket!.emit('ice-candidate', {
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      },
    });
  }

  /// Enviar datos GPS
  void sendGPSData({
    required double latitude,
    required double longitude,
    required double speed,
    required double heading,
    required double altitude,
    required double accuracy,
  }) {
    if (!_isConnected.value) return;

    _socket!.emit('gps-data', {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Detener stream
  void stopStream() {
    if (!_isConnected.value) return;

    print('⏹️ Enviando stream-stop...');
    _socket!.emit('stream-stop');
  }

  /// Desconectar
  void disconnect() {
    print('🔌 Desconectando Socket.io...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected.value = false;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
