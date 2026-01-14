import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'settings_service.dart';

class AuthService extends GetxService {
  final SettingsService _settingsService = Get.find<SettingsService>();

  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxnString _token = RxnString();
  final _isLoading = false.obs;

  UserModel? get currentUser => _currentUser.value;
  UserModel? get user => _currentUser.value;
  String? get token => _token.value;
  bool get isLoading => _isLoading.value;

  Future<bool> login(String username, String password) async {
    try {
      _isLoading.value = true;
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = UserModel.fromJson(data);
        _currentUser.value = user;
        _token.value = user.token;

        await _settingsService.saveAuthToken(user.token);
        await _settingsService.saveUserId(user.id);

        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    _currentUser.value = null;
    _token.value = null;
    await _settingsService.clearAuthToken();
    await _settingsService.clearUserId();
  }

  String? getStoredToken() {
    return _settingsService.getAuthToken();
  }

  String? getUserId() {
    return _settingsService.getUserId();
  }

  bool isAuthenticated() {
    return _currentUser.value != null && _token.value != null;
  }

  Future<bool> refreshToken() async {
    try {
      final currentToken = getStoredToken();
      if (currentToken == null) return false;

      final response = await http.post(
        Uri.parse(ApiConfig.refreshTokenEndpoint),
        headers: ApiConfig.getAuthHeaders(currentToken),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['token'] as String;
        await _settingsService.saveAuthToken(newToken);
        return true;
      }
      return false;
    } catch (e) {
      print('Refresh token error: $e');
      return false;
    }
  }
}
