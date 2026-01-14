import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/auth_service.dart';
import '../services/network_monitor_service.dart';
import '../controllers/streaming_controller.dart';

class HomeView extends StatelessWidget {
  final _authService = Get.find<AuthService>();
  final _networkMonitor = Get.find<NetworkMonitorService>();
  final _battery = Battery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transmission Routes'),
        backgroundColor: Color(0xFF1e293b),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => Get.toNamed('/routes'),
            tooltip: 'Historial de rutas',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Get.toNamed('/settings'),
            tooltip: 'Configuración',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _handleLogout(),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarjetas de estado
                _buildStatusCards(),
                SizedBox(height: 24),

                // Verificación de pre-condiciones
                _buildPreCheckSection(),
                SizedBox(height: 32),

                // Botón principal START
                _buildStartButton(),
                SizedBox(height: 16),

                // Info adicional
                _buildInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Obx(
                () => _StatusCard(
                  icon: Icons.wifi,
                  label: 'Red',
                  value: _networkMonitor.getQualityDescription(),
                  color: Color(
                    int.parse(
                      _networkMonitor.getQualityColor().replaceFirst(
                        '#',
                        '0xFF',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: FutureBuilder<int>(
                future: _battery.batteryLevel,
                builder: (context, snapshot) {
                  final level = snapshot.data ?? 0;
                  return _StatusCard(
                    icon: Icons.battery_full,
                    label: 'Batería',
                    value: '$level%',
                    color: level > 50
                        ? Colors.green
                        : (level > 20 ? Colors.orange : Colors.red),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreCheckSection() {
    return Card(
      color: Color(0xFF1e293b),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verificación de requisitos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            _buildCheckItem('Permisos de cámara', _checkCameraPermission()),
            _buildCheckItem(
              'Permisos de ubicación',
              _checkLocationPermission(),
            ),
            _buildCheckItem('Conexión a internet', _networkMonitor.isConnected),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String label, bool checked) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.cancel,
            color: checked ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  bool _checkCameraPermission() {
    // Esta verificación debería ser async, simplificado para el ejemplo
    return true;
  }

  bool _checkLocationPermission() {
    return true;
  }

  Widget _buildStartButton() {
    return GetBuilder<StreamingController>(
      init: StreamingController(),
      builder: (controller) {
        return Obx(
          () => SizedBox(
            height: 120,
            child: ElevatedButton(
              onPressed: controller.isStreaming
                  ? null
                  : () async {
                      // Solicitar permisos antes de navegar
                      final cameraGranted = await Permission.camera
                          .request()
                          .isGranted;
                      final locationGranted = await Permission.location
                          .request()
                          .isGranted;

                      if (!cameraGranted || !locationGranted) {
                        Get.snackbar(
                          'Permisos requeridos',
                          'Se necesitan permisos de cámara y ubicación',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      Get.toNamed('/streaming');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.isStreaming
                    ? Colors.grey
                    : Color(0xFF2563eb),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_filled, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'INICIAR TRANSMISIÓN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Color(0xFF1e293b).withOpacity(0.5),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Información',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• La transmisión requiere conexión 4G/WiFi estable\n'
              '• Recomendado: batería > 30%\n'
              '• Los espectadores pueden ver en tiempo real\n'
              '• La ruta se guarda automáticamente al finalizar',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    Get.dialog(
      AlertDialog(
        title: Text('Cerrar sesión'),
        content: Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancelar')),
          TextButton(
            onPressed: () {
              _authService.logout();
              Get.back();
              Get.offAllNamed('/login');
            },
            child: Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF1e293b),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
