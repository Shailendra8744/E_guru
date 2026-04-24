import 'dart:convert';


import 'package:e_guru/core/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionUser {
  SessionUser({
    required this.id,
    required this.name,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
    this.xp = 0,
  });

  final int id;
  final String name;
  final String role;
  final String accessToken;
  final String refreshToken;
  final int xp;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'xp': xp,
  };

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
    id: json['id'] as int,
    name: json['name'] as String,
    role: json['role'] as String,
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    xp: json['xp'] as int? ?? 0,
  );
}

final sessionMessageProvider = StateProvider<String?>((ref) => null);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    'https://engineerfarm.in/backend/public/api/v1',
    onUnauthorized: () {
      // Use microtask to avoid updating state during build if called from there
      Future.microtask(() {
        ref.read(sessionMessageProvider.notifier).state = 'Session expired. Please login again.';
        ref.read(authSessionProvider.notifier).logout();
      });
    },
  );
});

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, SessionUser?>(
      AuthSessionNotifier.new,
    );

class AuthSessionNotifier extends AsyncNotifier<SessionUser?> {
  @override
  Future<SessionUser?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('session_user');
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final session = SessionUser.fromJson(decoded);
    final api = ref.read(apiClientProvider);
    api.accessToken = session.accessToken;
    api.refreshToken = session.refreshToken;
    return session;
  }

  Future<void> login(String email, String password) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    final user = res['user'] as Map<String, dynamic>;
    final tokens = res['tokens'] as Map<String, dynamic>;
    final session = SessionUser(
      id: user['id'] as int,
      name: user['full_name'] as String,
      role: user['role'] as String,
      accessToken: tokens['access_token'] as String,
      refreshToken: tokens['refresh_token'] as String,
      xp: user['xp'] as int? ?? 0,
    );
    api.accessToken = session.accessToken;
    api.refreshToken = session.refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_user', jsonEncode(session.toJson()));
    state = AsyncData(session);
  }

  Future<void> logout() async {
    final api = ref.read(apiClientProvider);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('session_user');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final refresh = decoded['refreshToken'] as String?;
        api.accessToken = decoded['accessToken'] as String?;
        if (refresh != null) {
          await api.post('/auth/logout', {'refresh_token': refresh});
        }
      } catch (_) {
        // ignore revoke errors on logout
      }
    }
    await prefs.remove('session_user');
    api.accessToken = null;
    api.refreshToken = null;
    state = const AsyncData(null);
  }
}
