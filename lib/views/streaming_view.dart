import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import '../controllers/streaming_controller.dart';
import '../services/webrtc_streaming_service.dart';
import '../services/network_monitor_service.dart';

class StreamingView extends GetView<StreamingController> {
  final _videoRenderer = RTCVideoRenderer();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (controller.isStreaming) {
          final shouldStop =
              await Get.dialog<bool>(
                AlertDialog(
                  title: Text('Detener transmisión'),
                  content: Text('¿Deseas detener la transmisión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: Text(
                        'Detener',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ) ??
              false;

          if (shouldStop) {
            await controller.stopStreaming();
            return true;
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Video background
            _buildVideoBackground(),

            // Overlay controls
            _buildOverlays(),

            // Reconnecting overlay
            _buildReconnectingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBackground() {
    return Obx(() {
      final localStream = Get.find<WebRTCStreamingService>().localStream;
      if (localStream != null) {
        _videoRenderer.srcObject = localStream;
      }

      return RTCVideoView(
        _videoRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        mirror: false,
      );
    });
  }

  Widget _buildOverlays() {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          _buildTopBar(),

          Spacer(),

          // Bottom bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // Live badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Obx(
                  () => Text(
                    'EN VIVO ${_formatDuration(controller.streamDuration)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 12),

          // Viewers
          Obx(
            () => Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '${controller.viewersCount}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Spacer(),

          // Network quality
          Obx(() => _buildNetworkQualityIndicator()),

          SizedBox(width: 12),

          // Battery
          Obx(() => _buildBatteryIndicator()),
        ],
      ),
    );
  }

  Widget _buildNetworkQualityIndicator() {
    final color = Color(
      int.parse(
        Get.find<NetworkMonitorService>().getQualityColor().replaceFirst(
          '#',
          '0xFF',
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.signal_cellular_alt, color: color, size: 16),
          SizedBox(width: 4),
          Text(
            '${Get.find<NetworkMonitorService>().latency}ms',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryIndicator() {
    final level = controller.batteryLevel;
    final color = level > 50
        ? Colors.green
        : (level > 20 ? Colors.orange : Colors.red);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.battery_full, color: color, size: 16),
          SizedBox(width: 4),
          Text('$level%', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(
                icon: Icons.speed,
                label: 'Velocidad',
                value: Obx(
                  () => Text(
                    '${controller.currentSpeed.toStringAsFixed(1)} km/h',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              _buildStat(
                icon: Icons.data_usage,
                label: 'Datos',
                value: Obx(
                  () => Text(
                    '${controller.estimatedDataUsage.toStringAsFixed(1)} MB',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Power saving mode
              Obx(
                () => _buildControlButton(
                  icon: controller.isPowerSavingMode
                      ? Icons.battery_charging_full
                      : Icons.battery_full,
                  label: 'Ahorro',
                  isActive: controller.isPowerSavingMode,
                  onPressed: () => controller.togglePowerSavingMode(),
                ),
              ),

              // Stop button
              _buildStopButton(),

              // Settings
              _buildControlButton(
                icon: Icons.settings,
                label: 'Config',
                isActive: false,
                onPressed: () => Get.toNamed('/settings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required Widget value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        SizedBox(height: 2),
        value,
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onPressed,
          backgroundColor: isActive
              ? Color(0xFF2563eb)
              : Colors.black.withOpacity(0.6),
          child: Icon(icon, color: Colors.white),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildStopButton() {
    return Column(
      children: [
        FloatingActionButton.extended(
          heroTag: 'stop',
          onPressed: () async {
            await controller.stopStreaming();
            Get.back();
          },
          backgroundColor: Colors.red,
          icon: Icon(Icons.stop, color: Colors.white),
          label: Text(
            'DETENER',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildReconnectingOverlay() {
    return Obx(() {
      if (!controller.isReconnecting) return SizedBox.shrink();

      return Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Reconectando...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
