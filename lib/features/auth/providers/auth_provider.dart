import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/user_model.dart';

// ─── Auth States ──────────────────────────────────────────────────────────────
abstract class AuthState {
  const AuthState();
  T maybeWhen<T>({
    T Function()? loading,
    T Function(UserModel user)? authenticated,
    T Function(String? error)? unauthenticated,
    required T Function() orElse,
  }) {
    if (this is AuthLoading && loading != null) return loading();
    if (this is AuthAuthenticated && authenticated != null) return authenticated((this as AuthAuthenticated).user);
    if (this is AuthUnauthenticated && unauthenticated != null) return unauthenticated((this as AuthUnauthenticated).error);
    return orElse();
  }
}

class AuthLoading extends AuthState { const AuthLoading(); }
class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}
class AuthUnauthenticated extends AuthState {
  final String? error;
  const AuthUnauthenticated({this.error});
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._api, this._storage) : super(const AuthLoading()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      final userData = await _storage.read(key: AppConstants.userDataKey);

      if (token != null && userData != null) {
        final user = UserModel.fromJson(jsonDecode(userData));
        state = AuthAuthenticated(user);

        // Validate token in background
        try {
          final response = await _api.get('/auth/me');
          final freshUser = UserModel.fromJson(response.data['data']);
          await _storage.write(key: AppConstants.userDataKey, value: jsonEncode(freshUser.toJson()));
          state = AuthAuthenticated(freshUser);
        } catch (_) {
          // Token expired, try refresh
          await _tryRefreshToken();
        }
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) {
        state = const AuthUnauthenticated();
        return;
      }
      final response = await _api.post('/auth/refresh', data: {'refreshToken': refreshToken});
      await _storage.write(key: AppConstants.accessTokenKey, value: response.data['data']['accessToken']);
      await _checkAuthStatus();
    } catch (_) {
      await _storage.deleteAll();
      state = const AuthUnauthenticated();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      debugPrint('🔐 Starting login for: $email');
      state = const AuthLoading();
      final deviceId = await _getDeviceId();
      debugPrint('📱 Device ID: $deviceId');

      final response = await _api.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      debugPrint('✅ Login API response received');
      final data = response.data['data'];
      debugPrint('📄 Response data keys: ${data.keys}');
      
      final user = UserModel.fromJson(data['user']);
      debugPrint('👤 User parsed: ${user.fullName} (${user.role})');

      await Future.wait([
        _storage.write(key: AppConstants.accessTokenKey, value: data['accessToken']),
        _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']),
        _storage.write(key: AppConstants.userDataKey, value: jsonEncode(user.toJson())),
        _storage.write(key: AppConstants.deviceIdKey, value: deviceId),
      ]);

      debugPrint('💾 Tokens and user data saved');
      state = AuthAuthenticated(user);
      debugPrint('🎉 Auth state set to authenticated');
      return null; // success
    } catch (e) {
      debugPrint('❌ Login error: $e');
      state = const AuthUnauthenticated();
      if (e is Exception) {
        return e.toString().replaceAll('Exception: ', '');
      }
      return 'Login failed. Please try again.';
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      await _api.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {}
    await _storage.deleteAll();
    state = const AuthUnauthenticated();
  }

  Future<UserModel?> getUser() async {
    return state.maybeWhen(authenticated: (user) => user, orElse: () => null);
  }

  Future<String> _getDeviceId() async {
    final cached = await _storage.read(key: AppConstants.deviceIdKey);
    if (cached != null) return cached;

    final deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown';
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      deviceId = info.id;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      deviceId = info.identifierForVendor ?? 'ios-unknown';
    }
    return deviceId;
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  const storage = FlutterSecureStorage();
  return AuthNotifier(api, storage);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
});
