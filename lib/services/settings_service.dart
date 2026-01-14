import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyBaseUrl = 'base_url';
  static const String _keyLimitStreamDuration = 'limit_stream_duration';
  static const String _keyMaxStreamDuration = 'max_stream_duration_minutes';
  static const String _keyVideoQuality = 'video_quality';
  static const String _keyPowerSavingManual = 'power_saving_manual_enabled';
  static const String _keyAutoPowerSaving = 'auto_power_saving_enabled';
  static const String _keyAnonymizeExports = 'anonymize_exports_enabled';
  static const String _keyAnonymizationRadius = 'anonymization_radius_meters';
  static const String _keyUseFrontCamera = 'use_front_camera';
  static const String _keyShowPip = 'show_pip';
  static const String _keyMiniMapPosition = 'mini_map_position';
  static const String _keyMapZoom = 'map_zoom';
  static const String _keyGpsFrequency = 'gps_frequency';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // Auth
  String? getAuthToken() => _prefs.getString(_keyAuthToken);
  Future<void> saveAuthToken(String token) =>
      _prefs.setString(_keyAuthToken, token);
  Future<void> clearAuthToken() => _prefs.remove(_keyAuthToken);

  String? getUserId() => _prefs.getString(_keyUserId);
  Future<void> saveUserId(String userId) =>
      _prefs.setString(_keyUserId, userId);
  Future<void> clearUserId() => _prefs.remove(_keyUserId);

  // Server
  String getBaseUrl() =>
      _prefs.getString(_keyBaseUrl) ?? 'http://localhost:3000';
  Future<void> saveBaseUrl(String url) => _prefs.setString(_keyBaseUrl, url);

  // Streaming
  bool getLimitStreamDuration() =>
      _prefs.getBool(_keyLimitStreamDuration) ?? false;
  Future<void> setLimitStreamDuration(bool value) =>
      _prefs.setBool(_keyLimitStreamDuration, value);

  int getMaxStreamDuration() => _prefs.getInt(_keyMaxStreamDuration) ?? 60;
  Future<void> setMaxStreamDuration(int minutes) =>
      _prefs.setInt(_keyMaxStreamDuration, minutes);

  String getVideoQuality() => _prefs.getString(_keyVideoQuality) ?? 'Auto';
  Future<void> setVideoQuality(String quality) =>
      _prefs.setString(_keyVideoQuality, quality);

  // Power Saving
  bool isPowerSavingManualEnabled() =>
      _prefs.getBool(_keyPowerSavingManual) ?? false;
  Future<void> setPowerSavingManualEnabled(bool value) =>
      _prefs.setBool(_keyPowerSavingManual, value);

  bool isAutoPowerSavingEnabled() =>
      _prefs.getBool(_keyAutoPowerSaving) ?? false;
  Future<void> setAutoPowerSavingEnabled(bool value) =>
      _prefs.setBool(_keyAutoPowerSaving, value);

  // Métodos requeridos por StreamingController
  bool getPowerSavingMode() => _prefs.getBool(_keyPowerSavingManual) ?? false;
  Future<void> setPowerSavingMode(bool value) =>
      _prefs.setBool(_keyPowerSavingManual, value);

  bool getAutoPowerSaving() => _prefs.getBool(_keyAutoPowerSaving) ?? false;

  int getMinBatteryLevel() => _prefs.getInt('min_battery_level') ?? 20;

  // Privacy
  bool isAnonymizationEnabled() =>
      _prefs.getBool(_keyAnonymizeExports) ?? false;
  Future<void> setAnonymizationEnabled(bool value) =>
      _prefs.setBool(_keyAnonymizeExports, value);

  int getAnonymizationRadius() => _prefs.getInt(_keyAnonymizationRadius) ?? 0;
  Future<void> setAnonymizationRadius(int meters) =>
      _prefs.setInt(_keyAnonymizationRadius, meters);

  // Camera
  bool useFrontCamera() => _prefs.getBool(_keyUseFrontCamera) ?? false;
  Future<void> setUseFrontCamera(bool value) =>
      _prefs.setBool(_keyUseFrontCamera, value);

  bool showPip() => _prefs.getBool(_keyShowPip) ?? false;
  Future<void> setShowPip(bool value) => _prefs.setBool(_keyShowPip, value);

  // Map
  String getMiniMapPosition() =>
      _prefs.getString(_keyMiniMapPosition) ?? 'bottom-right';
  Future<void> setMiniMapPosition(String position) =>
      _prefs.setString(_keyMiniMapPosition, position);

  double getMapZoom() => _prefs.getDouble(_keyMapZoom) ?? 15.0;
  Future<void> setMapZoom(double zoom) => _prefs.setDouble(_keyMapZoom, zoom);

  // GPS
  int getGpsFrequency() => _prefs.getInt(_keyGpsFrequency) ?? 1;
  Future<void> setGpsFrequency(int seconds) =>
      _prefs.setInt(_keyGpsFrequency, seconds);
}
