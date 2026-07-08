import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ SERVER BACKEND ANDA
  static const String baseUrl = 'http://103.93.135.108:3000/api';

  // ✅ CONNECT TO REAL BACKEND
  static const bool DEMO_MODE = false;

  // ==================== HELPER METHODS ====================

  static Future<String?> _getToken() async {
    if (DEMO_MODE) return 'demo-token';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && !DEMO_MODE) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTHENTICATION ====================

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    // Demo mode untuk testing tanpa backend
    if (DEMO_MODE) {
      await Future.delayed(const Duration(seconds: 1));

      if (username == 'admin' && password == 'admin123') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', 'demo-token');
        await prefs.setString(
          'user_data',
          json.encode({
            'id_user': 1,
            'username': 'admin',
            'nama_lengkap': 'Demo Admin',
            'role_user': 'admin',
          }),
        );

        return {
          'success': true,
          'token': 'demo-token',
          'user': {
            'id_user': 1,
            'username': 'admin',
            'nama_lengkap': 'Demo Admin',
            'role_user': 'admin',
          },
        };
      } else {
        throw Exception('Username atau password salah');
      }
    }

    // Real mode - connect to backend
    try {
      print('=== API LOGIN REQUEST ===');
      print('URL: $baseUrl/auth/login');
      print('Username: $username');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      print('=== API LOGIN RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');

      // Check if response body is empty or null
      if (response.body.isEmpty) {
        throw Exception('Server mengembalikan response kosong');
      }

      // Try to decode JSON
      dynamic data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        print('JSON Decode Error: $e');
        throw Exception(
          'Response dari server bukan JSON yang valid: ${response.body}',
        );
      }

      // Check response status
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Ensure data is a Map
        if (data is! Map<String, dynamic>) {
          print('Data is not a Map: ${data.runtimeType}');
          throw Exception('Format response tidak valid');
        }

        // Extract token and user data
        String? token;
        Map<String, dynamic>? userData;

        // Try different response formats
        if (data.containsKey('token')) {
          token = data['token']?.toString();
        } else if (data.containsKey('access_token')) {
          token = data['access_token']?.toString();
        } else if (data.containsKey('data') && data['data'] is Map) {
          final innerData = data['data'];
          token = innerData['token']?.toString();
          userData = innerData['user'] is Map
              ? Map<String, dynamic>.from(innerData['user'])
              : null;
        }

        // Extract user data
        if (userData == null) {
          if (data.containsKey('user') && data['user'] is Map) {
            userData = Map<String, dynamic>.from(data['user']);
          } else if (data.containsKey('data') && data['data'] is Map) {
            userData = Map<String, dynamic>.from(data['data']);
          } else {
            // Create user data from response
            userData = {
              'id_user': data['id_user'] ?? data['id'] ?? 0,
              'username': data['username'] ?? username,
              'nama_lengkap': data['nama_lengkap'] ?? data['nama'] ?? username,
              'role_user': data['role_user'] ?? data['role'] ?? 'user',
            };
          }
        }

        // Save to SharedPreferences
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('user_data', json.encode(userData));

          print('=== LOGIN SUCCESS ===');
          print('Token: $token');
          print('User Data: $userData');
        }

        return {'success': true, 'token': token, 'user': userData, 'raw': data};
      } else {
        // Error response
        String errorMessage = 'Login gagal';

        if (data is Map<String, dynamic>) {
          errorMessage =
              data['message']?.toString() ??
              data['error']?.toString() ??
              'Login gagal dengan status ${response.statusCode}';
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('=== LOGIN EXCEPTION ===');
      print('Exception: $e');
      print('Exception Type: ${e.runtimeType}');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception(
          'Tidak dapat terhubung ke server. Periksa koneksi internet dan pastikan backend running.',
        );
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout. Server tidak merespons.');
      }

      rethrow;
    }
  }

  static Future<void> register({
    required String username,
    required String password,
    required String namaLengkap,
    required String roleUser,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
        'nama_lengkap': namaLengkap,
        'role_user': roleUser,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Registrasi gagal');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return json.decode(userData);
    }
    return null;
  }

  // ==================== STATIONS ====================

  static Future<List<dynamic>> getStations({int? limit, int? offset}) async {
    if (DEMO_MODE) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        {
          'id_station': 1,
          'nama_station': 'Loading Ramp',
          'lokasi_station': 'Area Pemuatan',
          'health_station': 92.0,
        },
        {
          'id_station': 2,
          'nama_station': 'Sterilizer',
          'lokasi_station': 'Unit Sterilisasi',
          'health_station': 85.0,
        },
      ];
    }

    final headers = await _getHeaders();
    String url = '$baseUrl/stations';
    if (limit != null) url += '?limit=$limit';
    if (offset != null) url += (limit != null ? '&' : '?') + 'offset=$offset';

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load stations');
    }
  }

  static Future<Map<String, dynamic>> getStationById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/stations/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Station not found');
    }
  }

  // ==================== MACHINES ====================

  static Future<List<dynamic>> getMachines({int? stationId, int? limit}) async {
    if (DEMO_MODE) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        {'id_mesin': 1, 'nama_mesin': 'Lori No. 1', 'health_mesin': 88.0},
        {'id_mesin': 2, 'nama_mesin': 'Lori No. 2', 'health_mesin': 90.0},
      ];
    }

    final headers = await _getHeaders();
    String url = '$baseUrl/machines';
    if (stationId != null) url += '?id_station=$stationId';
    if (limit != null) url += (stationId != null ? '&' : '?') + 'limit=$limit';

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load machines');
    }
  }

  static Future<Map<String, dynamic>> getMachineById(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/machines/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Machine not found');
    }
  }

  // ==================== KOMPONEN ====================

  static Future<List<dynamic>> getKomponen({required int mesinId}) async {
    if (DEMO_MODE) {
      await Future.delayed(const Duration(milliseconds: 500));
      return [
        {
          'id_komponen': 1,
          'nama_komponen': 'Roda',
          'jenis_komponen': 'Mechanical',
        },
        {
          'id_komponen': 2,
          'nama_komponen': 'Bushing',
          'jenis_komponen': 'Mechanical',
        },
      ];
    }

    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/komponen?id_mesin=$mesinId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load komponen');
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
      throw Exception('Failed to submit reading');
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
      throw Exception('Failed to load history');
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
      throw Exception('Failed to load latest readings');
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
      throw Exception('Failed to submit service history');
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
      throw Exception('Failed to load service history');
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
      throw Exception('Failed to load alerts');
    }
  }

  static Future<void> acknowledgeAlert(int alertId) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/service-alerts/$alertId/acknowledge'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to acknowledge alert');
    }
  }

  static Future<void> resolveAlert(int alertId) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/service-alerts/$alertId/resolve'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to resolve alert');
    }
  }
}
