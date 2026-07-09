import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiServices {
  static const String baseUrl = 'http://103.93.135.108:3000/api';
  static const bool DEMO_MODE = false;

  // ==================== HELPER METHODS ====================

  static Future<String?> _getToken() async {
    if (DEMO_MODE) return 'demo-token';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    print('=== DEBUG TOKEN ===');
    print('Token from storage: $token');

    return {
      'Content-Type': 'application/json',
      if (token != null && !DEMO_MODE) 'Authorization': 'Bearer $token',
    };
  }

  // ✅ Helper untuk extract data dari response wrapper
  static dynamic _extractData(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      // Format: {"success": true, "data": ...}
      if (decoded.containsKey('data')) {
        return decoded['data'];
      }
      // Format: {"success": true, "results": ...}
      if (decoded.containsKey('results')) {
        return decoded['results'];
      }
    }
    return decoded;
  }

  // ==================== AUTHENTICATION ====================

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
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

      if (response.body.isEmpty) {
        throw Exception('Server mengembalikan response kosong');
      }

      dynamic data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Extract dari wrapper data
        dynamic innerData = _extractData(data);

        String? token;
        Map<String, dynamic>? userData;

        if (innerData is Map<String, dynamic>) {
          token = innerData['token']?.toString();

          if (innerData.containsKey('user') && innerData['user'] is Map) {
            userData = Map<String, dynamic>.from(innerData['user']);
          }
        }

        if (token != null && userData != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('user_data', json.encode(userData));

          print('=== LOGIN SUCCESS ===');
          print('Token saved: ${token.substring(0, 20)}...');
          print('User: ${userData['nama_lengkap']}');
        } else {
          print('=== LOGIN WARNING ===');
          print('Token: $token');
          print('User: $userData');
        }

        return {'success': true, 'token': token, 'user': userData};
      } else {
        String errorMessage = 'Login gagal';
        if (data is Map<String, dynamic>) {
          errorMessage = data['message']?.toString() ?? 'Login gagal';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('=== LOGIN EXCEPTION ===');
      print('Exception: $e');

      if (e.toString().contains('SocketException')) {
        throw Exception('Tidak dapat terhubung ke server');
      }
      rethrow;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ==================== FACTORIES ====================

  static Future<List<dynamic>> getFactories({int? limit, int? offset}) async {
    final headers = await _getHeaders();

    print('=== GET FACTORIES REQUEST ===');
    print('URL: $baseUrl/factories');

    String url = '$baseUrl/factories';
    if (limit != null) url += '?limit=$limit';
    if (offset != null) url += (limit != null ? '&' : '?') + 'offset=$offset';

    final response = await http.get(Uri.parse(url), headers: headers);

    print('=== GET FACTORIES RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);

      if (data is List) {
        return data;
      } else {
        return [];
      }
    } else if (response.statusCode == 401) {
      throw Exception('Token tidak valid. Silakan login ulang.');
    } else {
      throw Exception('Failed to load factories');
    }
  }

  // Update getStations untuk filter by factory
  static Future<List<dynamic>> getStationsByFactory({
    required int factoryId,
  }) async {
    final headers = await _getHeaders();

    print('=== GET STATIONS BY FACTORY REQUEST ===');
    print('URL: $baseUrl/stations?id_factory=$factoryId');

    final response = await http.get(
      Uri.parse('$baseUrl/stations?id_factory=$factoryId'),
      headers: headers,
    );

    print('=== GET STATIONS BY FACTORY RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);

      if (data is List) {
        return data;
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load stations');
    }
  }

  // ==================== STATIONS ====================

  static Future<List<dynamic>> getStations({int? limit, int? offset}) async {
    final headers = await _getHeaders();

    print('=== GET STATIONS REQUEST ===');
    print('Headers: $headers');

    String url = '$baseUrl/stations';
    if (limit != null) url += '?limit=$limit';
    if (offset != null) url += (limit != null ? '&' : '?') + 'offset=$offset';

    final response = await http.get(Uri.parse(url), headers: headers);

    print('=== GET STATIONS RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);

      if (data is List) {
        return data;
      } else {
        print('Warning: Expected List but got ${data.runtimeType}');
        return [];
      }
    } else if (response.statusCode == 401) {
      throw Exception('Token tidak valid. Silakan login ulang.');
    } else {
      throw Exception('Failed to load stations: ${response.statusCode}');
    }
  }

  // ==================== MACHINES ====================

  static Future<List<dynamic>> getMachines({int? stationId, int? limit}) async {
    final headers = await _getHeaders();

    print('=== GET MACHINES REQUEST ===');
    print('Headers: $headers');

    String url = '$baseUrl/machines';
    if (stationId != null) url += '?id_station=$stationId';
    if (limit != null) url += (stationId != null ? '&' : '?') + 'limit=$limit';

    final response = await http.get(Uri.parse(url), headers: headers);

    print('=== GET MACHINES RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);

      if (data is List) {
        return data;
      } else {
        return [];
      }
    } else if (response.statusCode == 401) {
      throw Exception('Token tidak valid. Silakan login ulang.');
    } else {
      throw Exception('Failed to load machines');
    }
  }

  // ==================== KOMPONEN ====================

  static Future<List<dynamic>> getKomponen({required int mesinId}) async {
    final headers = await _getHeaders();

    print('=== GET KOMPONEN REQUEST ===');
    print('URL: $baseUrl/komponen?id_mesin=$mesinId');
    print('Headers: $headers');

    final response = await http.get(
      Uri.parse('$baseUrl/komponen?id_mesin=$mesinId'),
      headers: headers,
    );

    print('=== GET KOMPONEN RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);

      if (data is List) {
        return data;
      } else {
        return [];
      }
    } else if (response.statusCode == 401) {
      throw Exception('Token tidak valid. Silakan login ulang.');
    } else {
      throw Exception('Failed to load komponen');
    }
  }
}
