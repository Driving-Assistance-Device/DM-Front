import 'dart:async';
import 'package:dm1/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/http/data.dart';
import 'services/http/exceptions.dart';

class AuthManager extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final HttpService _httpService = HttpService();

  Timer? _refreshTimer;
  String? _accessToken;
  String? _refreshToken;
  User? _currentUser;

  bool get isLoggedIn => _accessToken != null && _refreshToken != null;
  User? get currentUser => _currentUser;

  Future<void> init() async {
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');

    if (isLoggedIn) {
      _scheduleTokenRefresh();
      try {
        await getUserProfile();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final response = await _httpService.signIn(email: email, password: password);

    if (response.resultType == 'SUCCESS') {
      _accessToken = response.success!.accessToken;
      _refreshToken = response.success!.refreshToken;

      await _storage.write(key: 'access_token', value: _accessToken);
      await _storage.write(key: 'refresh_token', value: _refreshToken);

      _scheduleTokenRefresh();
      await getUserProfile();
      notifyListeners();
    } else {
      throw ApiException(
        message: response.error?.reason ?? 'Login failed',
        apiError: response.error,
      );
    }
  }

  Future<void> signUpAndLogin({
    required String name,
    required String email,
    required String password,
  }) async {
    final signUpResp = await _httpService.signUp(
      name: name,
      email: email,
      password: password,
    );

    if (signUpResp.resultType == 'SUCCESS') {
      await login(email, password);
    } else {
      throw ApiException(
        message: signUpResp.error?.reason ?? 'Sign up failed',
        apiError: signUpResp.error,
      );
    }
  }

  Future<void> refreshToken() async {
    if (_refreshToken == null) throw Exception('No refresh token available');

    try {
      final response = await _httpService.refreshAccessToken(_refreshToken!);

      if (response.resultType == 'SUCCESS') {
        _accessToken = response.success!.accessToken;
        _refreshToken = response.success!.refreshToken;

        await _storage.write(key: 'access_token', value: _accessToken);
        await _storage.write(key: 'refresh_token', value: _refreshToken);

        _scheduleTokenRefresh();
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await logout();
      }
      rethrow;
    }
  }

  void _scheduleTokenRefresh() {
    const refreshBefore = Duration(minutes: 5);
    _refreshTimer?.cancel();
    _refreshTimer = Timer(refreshBefore, refreshToken);
  }

  Future<void> logout() async {
    if (_accessToken != null) {
      try {
        await _httpService.signOut(_accessToken!);
      } catch (_) {}
    }

    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _refreshTimer?.cancel();
    notifyListeners();
  }

  Future<String> getAccessToken() async {
    if (_accessToken == null) throw Exception('Not authenticated');
    return _accessToken!;
  }

  Future<User> getUserProfile() async {
    final token = await getAccessToken();
    try {
      final resp = await _httpService.getUserProfile(token);
      if (resp.success != null) {
        _currentUser = resp.success!;
        notifyListeners();
        return _currentUser!;
      }
      throw ApiException(
        message: resp.error?.reason ?? 'Failed to load user profile',
        apiError: resp.error,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await logout();
      }
      rethrow;
    }
  }
}
