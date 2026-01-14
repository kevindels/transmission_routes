import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';

class WebRTCStreamingService extends GetxService {
  webrtc.RTCPeerConnection? _peerConnection;
  webrtc.MediaStream? _localStream;
  final _isInitialized = false.obs;

  bool get isInitialized => _isInitialized.value;
  webrtc.MediaStream? get localStream => _localStream;

  /// Inicializar cámara y capturar stream local
  Future<void> initializeCamera({bool isPowerSavingMode = false}) async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': false,
        'video': {
          'facingMode': 'environment', // Cámara trasera
          'width': isPowerSavingMode ? 426 : 640,
          'height': isPowerSavingMode ? 240 : 480,
          'frameRate': isPowerSavingMode ? 15 : 30,
        },
      };

      _localStream = await webrtc.navigator.mediaDevices.getUserMedia(
        mediaConstraints,
      );
      _isInitialized.value = true;
      print(
        '✅ Cámara inicializada: ${isPowerSavingMode ? "426x240@15fps" : "640x480@30fps"}',
      );
    } catch (e) {
      print('❌ Error al inicializar cámara: $e');
      rethrow;
    }
  }

  /// Crear peer connection con servidores TURN
  Future<void> createPeerConnection(
    List<Map<String, dynamic>> iceServers,
  ) async {
    try {
      final configuration = {
        'iceServers': iceServers,
        'sdpSemantics': 'unified-plan',
      };

      _peerConnection = await webrtc.createPeerConnection(configuration);

      // Agregar stream local al peer connection
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }

      // Listeners para ICE
      _peerConnection!.onIceCandidate = (webrtc.RTCIceCandidate candidate) {
        print('🧊 Nuevo ICE candidate generado');
        // Se enviará mediante SignalingService
      };

      _peerConnection!.onIceConnectionState =
          (webrtc.RTCIceConnectionState state) {
            print('📡 ICE Connection State: $state');
          };

      print('✅ Peer connection creado');
    } catch (e) {
      print('❌ Error al crear peer connection: $e');
      rethrow;
    }
  }

  /// Crear oferta SDP
  Future<webrtc.RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) {
      throw Exception('Peer connection no inicializado');
    }

    try {
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': false,
        'offerToReceiveVideo': false,
      });

      await _peerConnection!.setLocalDescription(offer);
      print('✅ Oferta SDP creada');
      return offer;
    } catch (e) {
      print('❌ Error al crear oferta: $e');
      rethrow;
    }
  }

  /// Establecer respuesta SDP remota (de un viewer)
  Future<void> setRemoteAnswer(webrtc.RTCSessionDescription answer) async {
    if (_peerConnection == null) {
      throw Exception('Peer connection no inicializado');
    }

    try {
      await _peerConnection!.setRemoteDescription(answer);
      print('✅ Respuesta SDP establecida');
    } catch (e) {
      print('❌ Error al establecer respuesta remota: $e');
      rethrow;
    }
  }

  /// Agregar candidato ICE remoto
  Future<void> addIceCandidate(webrtc.RTCIceCandidate candidate) async {
    if (_peerConnection == null) {
      throw Exception('Peer connection no inicializado');
    }

    try {
      await _peerConnection!.addCandidate(candidate);
      print('✅ ICE candidate agregado');
    } catch (e) {
      print('❌ Error al agregar ICE candidate: $e');
    }
  }

  /// Ajustar bitrate según modo de ahorro de energía
  Future<void> adjustBitrate({required bool isPowerSavingMode}) async {
    if (_peerConnection == null) return;

    try {
      final senders = await _peerConnection!.getSenders();
      for (var sender in senders) {
        if (sender.track?.kind == 'video') {
          final parameters = sender.parameters;

          // Ajustar bitrate máximo
          if (parameters.encodings != null &&
              parameters.encodings!.isNotEmpty) {
            parameters.encodings![0].maxBitrate = isPowerSavingMode
                ? 400000 // 400 kbps en modo ahorro
                : 1500000; // 1.5 Mbps normal

            await sender.setParameters(parameters);
            print(
              '✅ Bitrate ajustado: ${isPowerSavingMode ? "400kbps" : "1.5Mbps"}',
            );
          }
        }
      }
    } catch (e) {
      print('⚠️ Error al ajustar bitrate: $e');
    }
  }

  /// Reconectar stream después de desconexión
  Future<void> reconnectStream({
    required List<Map<String, dynamic>> iceServers,
    bool isPowerSavingMode = false,
  }) async {
    print('🔄 Reconectando stream...');

    // Limpiar conexión anterior
    await dispose();

    // Reinicializar todo
    await initializeCamera(isPowerSavingMode: isPowerSavingMode);
    await createPeerConnection(iceServers);
  }

  /// Obtener estadísticas de conexión
  Future<Map<String, dynamic>> getConnectionStats() async {
    if (_peerConnection == null) return {};

    try {
      final stats = await _peerConnection!.getStats();
      // Filtrar por video outbound
      final stat = stats.firstWhere(
        (stat) =>
            stat.type == 'outbound-rtp' && stat.values['mediaType'] == 'video',
        orElse: () => stats.first,
      );
      return Map<String, dynamic>.from(stat.values);
    } catch (e) {
      print('⚠️ Error al obtener stats: $e');
      return {};
    }
  }

  /// Liberar recursos
  Future<void> dispose() async {
    print('🧹 Limpiando recursos WebRTC...');

    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
    _localStream = null;

    await _peerConnection?.close();
    _peerConnection?.dispose();
    _peerConnection = null;

    _isInitialized.value = false;
  }

  @override
  void onClose() {
    dispose();
    super.onClose();
  }
}
