import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _loading = false;

  String? get token    => _token;
  String? get userName => _user?['name'];
  String? get userRole => _user?['role'];
  String? get userId   => _user?['id'];
  bool   get isAdmin   => _user?['role'] == 'admin';
  bool   get isLogged  => _token != null;
  bool   get loading   => _loading;
  Map<String, dynamic>? get user => _user;

  // ── Restore session on app start ─────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      try {
        _user = await ApiService.getMe();
        wsService.connectUpdates();
      } catch (_) {
        await _clear();
      }
    }
    notifyListeners();
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String adminCode = '',
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService.register(
        name: name, email: email, password: password,
        phone: phone, adminCode: adminCode,
      );
      await _save(data['token'], data['user']);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> login({required String email, required String password}) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService.login(email: email, password: password);
      await _save(data['token'], data['user']);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    wsService.dispose();
    await _clear();
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_token == null) return;
    _user = await ApiService.getMe();
    notifyListeners();
  }

  Future<void> _save(String token, Map<String, dynamic> user) async {
    _token = token;
    _user  = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    wsService.connectUpdates();
    notifyListeners();
  }

  Future<void> _clear() async {
    _token = null;
    _user  = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
