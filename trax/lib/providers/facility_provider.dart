import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class FacilityProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _facilities = [];
  bool _loading = false;

  List<Map<String, dynamic>> get facilities => _facilities;
  bool get loading => _loading;

  FacilityProvider() {
    // Listen for real-time facility updates from admin
    wsService.addUpdateListener(_onWsEvent);
  }

  void _onWsEvent(String event, Map<String, dynamic> data) {
    if (event == 'facility_updated') {
      final idx = _facilities.indexWhere((f) => f['id'] == data['id']);
      if (idx != -1) {
        _facilities[idx] = Map<String, dynamic>.from(data);
        notifyListeners();  // ← UI rebuilds instantly with new price / open status
      }
    } else if (event == 'facility_created') {
      _facilities.add(Map<String, dynamic>.from(data));
      notifyListeners();
    } else if (event == 'facility_deleted') {
      _facilities.removeWhere((f) => f['id'] == data['id']);
      notifyListeners();
    }
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final raw = await ApiService.getFacilities();
      _facilities = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    wsService.removeUpdateListener(_onWsEvent);
    super.dispose();
  }
}
