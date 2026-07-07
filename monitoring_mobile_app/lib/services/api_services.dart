import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // GANTI DENGAN URL BACKEND TEMAN ANDA
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  // ⚠️ Kalau di HP real, ganti dengan IP komputer (misal: 192.168.1.100:3000)

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTH ====================

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Simpan token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      await prefs.setString('user_data', json.encode(data['user']));
      return data;
    } else {
      throw Exception('Login gagal: ${response.body}');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ==================== STATIONS ====================

  static Future<List<dynamic>> getStations({int? limit, int? offset}) async {
    final headers = await _getHeaders();
    String url = '$baseUrl/stations';
    if (limit != null) url += '?limit=$limit';
    if (offset != null) url += (limit != null ? '&' : '?') + 'offset=$offset';

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load stations: ${response.body}');
    }
  }

  // ==================== MACHINES ====================

  static Future<List<dynamic>> getMachines({int? stationId, int? limit}) async {
    final headers = await _getHeaders();
    String url = '$baseUrl/machines';
    if (stationId != null) url += '?id_station=$stationId';
    if (limit != null) url += (stationId != null ? '&' : '?') + 'limit=$limit';

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load machines: ${response.body}');
    }
  }

  // ==================== KOMPONEN ====================

  static Future<List<dynamic>> getKomponen({required int mesinId}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/komponen?id_mesin=$mesinId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load komponen: ${response.body}');
    }
  }

  // ==================== SENSOR READINGS ====================

  static Future<Map<String, dynamic>> submitSensorReading({
    required int idKomponen,
    required int idParameter,
    required double nilai,
    String? keterangan,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/sensor-readings'),
      headers: headers,
      body: json.encode({
        'id_komponen': idKomponen,
        'id_parameter': idParameter,
        'nilai': nilai,
        if (keterangan != null) 'keterangan': keterangan,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to submit reading: ${response.body}');
    }
  }

  static Future<List<dynamic>> getSensorHistory({
    required int idKomponen,
    required int idParameter,
  }) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse(
        '$baseUrl/sensor-readings/history?id_komponen=$idKomponen&id_parameter=$idParameter',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load history: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getLatestReadings(int idKomponen) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/sensor-readings/latest/$idKomponen'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load latest: ${response.body}');
    }
  }

  // ==================== SERVICE HISTORY ====================

  static Future<Map<String, dynamic>> submitServiceHistory({
    required int idMesin,
    required String tanggalService,
    required String jenisService,
    String? deskripsi,
    String? teknisi,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/service-history'),
      headers: headers,
      body: json.encode({
        'id_mesin': idMesin,
        'tanggal_service': tanggalService,
        'jenis_service': jenisService,
        if (deskripsi != null) 'deskripsi': deskripsi,
        if (teknisi != null) 'teknisi': teknisi,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to submit service history: ${response.body}');
    }
  }

  static Future<List<dynamic>> getServiceHistory({int? mesinId}) async {
    final headers = await _getHeaders();
    String url = '$baseUrl/service-history';
    if (mesinId != null) url += '?id_mesin=$mesinId';

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load service history: ${response.body}');
    }
  }

  // ==================== ALERTS ====================

  static Future<List<dynamic>> getAlerts({String? status}) async {
    final headers = await _getHeaders();
    String url = '$baseUrl/service-alerts';
    if (status != null) url += '?status=$status';

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load alerts: ${response.body}');
    }
  }
}
