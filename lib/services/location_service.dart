import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/route_point_model.dart';

class LocationService extends GetxService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final _positionStreamController =
      StreamController<RoutePointModel>.broadcast();

  Stream<RoutePointModel> get positionStream =>
      _positionStreamController.stream;

  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5,
  );

  final _isTracking = false.obs;
  final _hasPermission = false.obs;

  bool get isTracking => _isTracking.value;
  bool get hasPermission => _hasPermission.value;

  Future<LocationService> init() async {
    await _checkPermissions();
    return this;
  }

  Future<bool> _checkPermissions() async {
    final status = await Permission.locationWhenInUse.status;
    _hasPermission.value = status.isGranted;
    return status.isGranted;
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    _hasPermission.value = status.isGranted;
    return status.isGranted;
  }

  Future<void> startTracking() async {
    if (_isTracking.value) {
      print('⚠️ Ya se está rastreando la ubicación');
      return;
    }

    if (!_hasPermission.value) {
      final granted = await requestPermissions();
      if (!granted) {
        throw Exception('Permiso de ubicación denegado');
      }
    }

    print('📍 Iniciando GPS tracking...');
    _isTracking.value = true;

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: _locationSettings,
        ).listen(
          (Position position) {
            final point = RoutePointModel(
              latitude: position.latitude,
              longitude: position.longitude,
              speed: position.speed,
              heading: position.heading,
              altitude: position.altitude,
              accuracy: position.accuracy,
              timestamp: DateTime.now(),
            );

            _positionStreamController.add(point);
          },
          onError: (error) {
            print('❌ Error en GPS: $error');
          },
        );
  }

  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking.value = false;
    print('⏹️ GPS tracking detenido');
  }

  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
    } catch (e) {
      print('❌ Error obteniendo ubicación: $e');
      return null;
    }
  }

  @override
  void onClose() {
    _positionStreamController.close();
    _positionStreamSubscription?.cancel();
    super.onClose();
  }
}
