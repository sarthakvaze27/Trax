import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ── Change this to your machine IP when testing on a physical device ────────
  static const String baseUrl = 'https://trax-uc1u.onrender.com';

  // ── Auth token ───────────────────────────────────────────────────────────────
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = jsonDecode(res.body);
      throw Exception(body['detail'] ?? 'Request failed (${res.statusCode})');
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String adminCode = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'admin_code': adminCode,
      }),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _headers(),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Facilities ────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getFacilities() async {
    final res = await http.get(
      Uri.parse('$baseUrl/facilities/'),
      headers: await _headers(),
    );
    _check(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getSlots(String facilityId, String date) async {
    final res = await http.get(
      Uri.parse('$baseUrl/facilities/$facilityId/slots?date=$date'),
      headers: await _headers(),
    );
    _check(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> updateFacility(
      String id, Map<String, dynamic> updates) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/facilities/$id'),
      headers: await _headers(),
      body: jsonEncode(updates),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Bookings ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createBooking({
    required String facilityId,
    required String date,
    required List<String> slots,
    required String timeLabel,
    int splitCount = 1,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/bookings/'),
      headers: await _headers(),
      body: jsonEncode({
        'facility_id': facilityId,
        'date': date,
        'slots': slots,
        'time_label': timeLabel,
        'split_count': splitCount,
      }),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getMyBookings() async {
    final res = await http.get(
      Uri.parse('$baseUrl/bookings/my'),
      headers: await _headers(),
    );
    _check(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<void> cancelBooking(String bookingId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
      headers: await _headers(),
    );
    _check(res);
  }

  // ── Grievances ────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> submitGrievance({
    required String title,
    String? description,
    String? facilityId,
    String priority = 'medium',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/grievances/'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'facility_id': facilityId,
        'priority': priority,
      }),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getAdminGrievances() async {
    final res = await http.get(
      Uri.parse('$baseUrl/grievances/admin/all'),
      headers: await _headers(),
    );
    _check(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<void> updateGrievanceStatus(String id, String status) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/grievances/$id/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    _check(res);
  }

  // ── Tournaments ───────────────────────────────────────────────────────────
  static Future<List<dynamic>> getTournaments() async {
    final res = await http.get(
      Uri.parse('$baseUrl/tournaments/'),
      headers: await _headers(),
    );
    _check(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<void> registerTournament(String tournamentId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tournaments/$tournamentId/register'),
      headers: await _headers(),
    );
    _check(res);
  }

  static Future<void> updateTournamentStatus(String id, String status) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/tournaments/$id?status=$status'),
      headers: await _headers(),
    );
    _check(res);
  }

  static Future<Map<String, dynamic>> createTournament({
    required String name,
    required String sport,
    required String startDate,
    required String endDate,
    String location = '',
    int maxTeams = 16,
    String? prizePool,
    String status = 'upcoming',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tournaments/'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'sport': sport,
        'start_date': startDate,
        'end_date': endDate,
        'location': location,
        'max_teams': maxTeams,
        'prize_pool': prizePool,
        'status': status,
      }),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Admin dashboard ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: await _headers(),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getAdminBookings() async {
    final res = await http.get(
      Uri.parse('$baseUrl/bookings/admin/all'),
      headers: await _headers(),
    );
    _check(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  // ── Chat ──────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getChatHistory(String roomId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/chat/history/$roomId'),
      headers: await _headers(),
    );
    _check(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getChatContacts() async {
    final res = await http.get(
      Uri.parse('$baseUrl/chat/contacts'),
      headers: await _headers(),
    );
    _check(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<List<dynamic>> getMyGroups() async {
    final res = await http.get(
      Uri.parse('$baseUrl/chat/groups/my'),
      headers: await _headers(),
    );
    _check(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createGroup({
    required String name,
    required List<String> memberIds,
    String avatarColor = '#4CAF50',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chat/groups'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'member_ids': memberIds,
        'avatar_color': avatarColor,
      }),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createBroadcast({
    required String title,
    required String message,
    String facilityName = '',
    String location = '',
    String date = '',
    String timeLabel = '',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chat/broadcasts'),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'message': message,
        'facility_name': facilityName,
        'location': location,
        'date': date,
        'time_label': timeLabel,
      }),
    );
    _check(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getBroadcasts({String location = ''}) async {
    final uri = location.trim().isEmpty
        ? Uri.parse('$baseUrl/chat/broadcasts')
        : Uri.parse(
            '$baseUrl/chat/broadcasts?location=${Uri.encodeQueryComponent(location.trim())}');
    final res = await http.get(
      uri,
      headers: await _headers(),
    );
    _check(res);
    return jsonDecode(res.body) as List<dynamic>;
  }
}
