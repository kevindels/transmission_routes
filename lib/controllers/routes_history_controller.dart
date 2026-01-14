import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/route_model.dart';

class RoutesHistoryController extends GetxController {
  final _authService = Get.find<AuthService>();

  final _routes = <RouteModel>[].obs;
  final _isLoading = false.obs;

  List<RouteModel> get routes => _routes;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    loadMyRoutes();
  }

  /// Cargar rutas del usuario desde el servidor
  Future<void> loadMyRoutes() async {
    if (!_authService.isAuthenticated()) {
      Get.snackbar(
        'Error',
        'Debes iniciar sesión',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _isLoading.value = true;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.myRoutesEndpoint}'),
        headers: ApiConfig.getAuthHeaders(_authService.token!),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routesList = data['routes'] as List;

        _routes.value = routesList
            .map((json) => RouteModel.fromJson(json))
            .toList();

        print('✅ ${_routes.length} rutas cargadas');
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al cargar rutas: $e');
      Get.snackbar(
        'Error',
        'No se pudieron cargar las rutas',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Obtener detalles completos de una ruta (con puntos GPS)
  Future<RouteModel?> getRouteDetails(String routeId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/routes/$routeId'),
        headers: ApiConfig.getAuthHeaders(_authService.token!),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RouteModel.fromJson(data['route']);
      }

      throw Exception('Error ${response.statusCode}');
    } catch (e) {
      print('❌ Error al obtener detalles: $e');
      Get.snackbar(
        'Error',
        'No se pudieron cargar los detalles',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Exportar ruta
  Future<void> exportRoute(
    String routeId,
    String format, {
    bool anonymize = false,
    int anonymizationRadius = 0,
  }) async {
    try {
      final params = {
        'format': format,
        if (anonymize) 'anonymize': 'true',
        if (anonymize) 'radius': anonymizationRadius.toString(),
      };

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/routes/$routeId/export',
      ).replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: ApiConfig.getAuthHeaders(_authService.token!),
      );

      if (response.statusCode == 200) {
        // TODO: Guardar archivo usando share_plus
        Get.snackbar(
          'Exportado',
          'Ruta exportada como $format',
          snackPosition: SnackPosition.BOTTOM,
        );

        print('✅ Ruta exportada: ${response.body.substring(0, 100)}...');
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al exportar: $e');
      Get.snackbar(
        'Error',
        'No se pudo exportar la ruta',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Eliminar ruta
  Future<void> deleteRoute(String routeId) async {
    try {
      final confirmed =
          await Get.dialog<bool>(
            AlertDialog(
              title: Text('Eliminar ruta'),
              content: Text(
                '¿Estás seguro de eliminar esta ruta? No se puede deshacer.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed) return;

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/routes/$routeId'),
        headers: ApiConfig.getAuthHeaders(_authService.token!),
      );

      if (response.statusCode == 200) {
        _routes.removeWhere((route) => route.id == routeId);
        Get.snackbar(
          'Eliminado',
          'Ruta eliminada correctamente',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al eliminar: $e');
      Get.snackbar(
        'Error',
        'No se pudo eliminar la ruta',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Refrescar lista
  Future<void> refresh() async {
    await loadMyRoutes();
  }
}
