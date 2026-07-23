import 'dart:convert';
import 'dart:io';
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

  // ==================== CREATE FACTORY ====================

  static Future<Map<String, dynamic>> createFactory({
    required String namaFactory,
    String? lokasiFactory,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/factories'),
      headers: headers,
      body: json.encode({
        'nama_factory': namaFactory,
        'lokasi_factory': lokasiFactory ?? '',
        'health_factory': 0,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      return _extractData(decoded) as Map<String, dynamic>;
    } else {
      dynamic decoded = json.decode(response.body);
      throw Exception(decoded['message'] ?? 'Gagal menambah factory');
    }
  }

  // ==================== CREATE STATION ====================

  static Future<Map<String, dynamic>> createStation({
    required int factoryId,
    required String namaStation,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/stations'),
      headers: headers,
      body: json.encode({
        'id_factory': factoryId,
        'nama_station': namaStation,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      return _extractData(decoded) as Map<String, dynamic>;
    } else {
      dynamic decoded = json.decode(response.body);
      throw Exception(decoded['message'] ?? 'Gagal menambah station');
    }
  }

  // ==================== STATIONS ====================

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

  // Get vibration machines grouped by kategori (Boiler 1, Kernel Station, dll)
  static Future<List<dynamic>> getVibrationMachines() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/machines/vibration'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      final data = _extractData(decoded);
      return data is List ? data : [];
    } else if (response.statusCode == 401) {
      throw Exception('Token tidak valid. Silakan login ulang.');
    } else {
      throw Exception('Failed to load vibration machines');
    }
  }

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

  // ✅ TAMBAHKAN INI - Create Machine
  static Future<Map<String, dynamic>> createMachine({
    required int stationId,
    required String kodeMesin, // ✅ TAMBAHKAN PARAMETER
    required String namaMesin,
  }) async {
    final headers = await _getHeaders();

    print('=== CREATE MACHINE REQUEST ===');
    print('URL: $baseUrl/machines');
    print(
      'Body: id_station=$stationId, kode_mesin=$kodeMesin, nama_mesin=$namaMesin',
    );

    final response = await http.post(
      Uri.parse('$baseUrl/machines'),
      headers: headers,
      body: json.encode({
        'id_station': stationId,
        'kode_mesin': kodeMesin, // ✅ TAMBAHKAN
        'nama_mesin': namaMesin,
        'health_mesin': 0,
      }),
    );

    print('=== CREATE MACHINE RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      return _extractData(decoded) as Map<String, dynamic>;
    } else {
      dynamic decoded = json.decode(response.body);
      String message = decoded['message'] ?? 'Gagal menambah machine';
      throw Exception(message);
    }
  }

  // ==================== DELETE MACHINE (LORI) ====================

  static Future<void> deleteMachine({required int machineId}) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/machines/$machineId'),
      headers: headers,
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      dynamic decoded = json.decode(response.body);
      throw Exception(decoded['message'] ?? 'Gagal menghapus lori');
    }
  }

  // ==================== DELETE STATION ====================

  static Future<void> deleteStation({required int stationId}) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/stations/$stationId'),
      headers: headers,
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      dynamic decoded = json.decode(response.body);
      throw Exception(decoded['message'] ?? 'Gagal menghapus station');
    }
  }

  // ==================== DELETE FACTORY ====================

  static Future<void> deleteFactory({required int factoryId}) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/factories/$factoryId'),
      headers: headers,
    );
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else {
      dynamic decoded = json.decode(response.body);
      throw Exception(decoded['message'] ?? 'Gagal menghapus factory');
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

  // ==================== SENSOR READINGS ====================

  // Ambil daftar parameter untuk komponen tertentu
  static Future<List<dynamic>> getParametersByKomponen(int idKomponen) async {
    final headers = await _getHeaders();

    print('=== GET PARAMETERS REQUEST ===');
    print('URL: $baseUrl/sensor-readings/parameters/$idKomponen');

    final response = await http.get(
      Uri.parse('$baseUrl/sensor-readings/parameters/$idKomponen'),
      headers: headers,
    );

    print('=== GET PARAMETERS RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);
      return data is List ? data : [];
    } else {
      throw Exception('Gagal memuat parameter');
    }
  }

  // Kirim data sensor reading
  static Future<Map<String, dynamic>> submitSensorReading({
    required int idKomponen,
    required int idParameter,
    required double nilai,
  }) async {
    final headers = await _getHeaders();

    print('=== SUBMIT SENSOR READING REQUEST ===');
    print('URL: $baseUrl/sensor-readings');
    print(
      'Body: id_komponen=$idKomponen, id_parameter=$idParameter, nilai=$nilai',
    );

    final response = await http.post(
      Uri.parse('$baseUrl/sensor-readings'),
      headers: headers,
      body: json.encode({
        'id_komponen': idKomponen,
        'id_parameter': idParameter,
        'nilai': nilai,
      }),
    );

    print('=== SUBMIT SENSOR READING RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      return _extractData(decoded) as Map<String, dynamic>;
    } else {
      dynamic decoded = json.decode(response.body);
      String message = decoded['message'] ?? 'Gagal menyimpan data';
      throw Exception(message);
    }
  }

  // Ambil history sensor reading
  static Future<List<dynamic>> getSensorHistory({
    required int idKomponen,
    int limit = 10,
    int offset = 0,
  }) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse(
        '$baseUrl/sensor-readings/history/$idKomponen?limit=$limit&offset=$offset',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);
      return data is List ? data : [];
    } else {
      throw Exception('Gagal memuat history');
    }
  }

  // Ambil sensor reading terbaru
  static Future<Map<String, dynamic>?> getLatestSensorReading(
    int idKomponen,
  ) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/sensor-readings/latest/$idKomponen'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);
      return data is Map<String, dynamic> ? data : null;
    } else {
      throw Exception('Gagal memuat data terbaru');
    }
  }

  // ==================== MONITORING ====================

  // Kirim sesi monitoring lengkap (HM + RPM + remarks + readings)
  static Future<Map<String, dynamic>> submitMonitoringSession({
    required int machineId,
    double? hm,
    double? rpm,
    String? remarks,
    required List<Map<String, dynamic>> readings,
  }) async {
    final headers = await _getHeaders();

    print('=== SUBMIT MONITORING SESSION REQUEST ===');
    print('URL: $baseUrl/monitoring/machines/$machineId/sessions');
    print('Readings count: ${readings.length}');

    final response = await http.post(
      Uri.parse('$baseUrl/monitoring/machines/$machineId/sessions'),
      headers: headers,
      body: json.encode({
        'id_mesin': machineId,
        if (hm != null) 'hm': hm,
        if (rpm != null) 'rpm': rpm,
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
        'readings': readings,
      }),
    );

    print('=== SUBMIT MONITORING SESSION RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      return _extractData(decoded) as Map<String, dynamic>;
    } else {
      dynamic decoded = json.decode(response.body);
      String message = decoded['message'] ?? 'Gagal menyimpan monitoring';
      throw Exception(message);
    }
  }

  // Ambil sesi monitoring terbaru untuk mesin
  static Future<Map<String, dynamic>?> getLatestMonitoringSession(int machineId) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/monitoring/machines/$machineId/latest'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);
      return data is Map<String, dynamic> ? data : null;
    } else {
      throw Exception('Gagal memuat monitoring terbaru');
    }
  }

  // Ambil history sesi monitoring untuk mesin
  static Future<List<dynamic>> getMonitoringHistory({
    required int machineId,
    int limit = 20,
  }) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/monitoring/machines/$machineId/history?limit=$limit'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);
      return data is List ? data : [];
    } else {
      throw Exception('Gagal memuat history monitoring');
    }
  }

  // Ambil daftar parameter yang tersedia
  static Future<List<dynamic>> getMonitoringParameters() async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/parameters'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);
      return data is List ? data : [];
    } else {
      throw Exception('Gagal memuat parameter');
    }
  }

  // ==================== INSPECTION ====================

  // Submit inspeksi lengkap (1 request = semua komponen + history)
  static Future<Map<String, dynamic>> submitInspection({
    required int machineId,
    required String tanggalInspeksi,
    required String pic,
    String? keterangan,
    required List<Map<String, dynamic>> komponenConditions,
    double? healthOverall,
  }) async {
    final headers = await _getHeaders();

    print('=== SUBMIT INSPECTION REQUEST ===');
    print('URL: $baseUrl/machines/$machineId/inspection');
    print('PIC: $pic');
    print('Komponen count: ${komponenConditions.length}');

    final body = <String, dynamic>{
      'tanggal_inspeksi': tanggalInspeksi,
      'pic': pic,
      'keterangan': keterangan,
      'komponen_conditions': komponenConditions,
    };
    if (healthOverall != null) {
      body['health_overall'] = healthOverall;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/machines/$machineId/inspection'),
      headers: headers,
      body: json.encode(body),
    );

    print('=== SUBMIT INSPECTION RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      return _extractData(decoded) as Map<String, dynamic>;
    } else {
      dynamic decoded = json.decode(response.body);
      String message = decoded['message'] ?? 'Gagal menyimpan inspeksi';
      throw Exception(message);
    }
  }

  // Update inspeksi (PUT) - staff & admin
  static Future<Map<String, dynamic>> updateInspection({
    required int machineId,
    required int serviceId,
    required String tanggalInspeksi,
    required String pic,
    String? keterangan,
    required List<Map<String, dynamic>> komponenConditions,
  }) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/machines/$machineId/inspection/$serviceId'),
      headers: headers,
      body: json.encode({
        'tanggal_inspeksi': tanggalInspeksi,
        'pic': pic,
        'keterangan': keterangan,
        'komponen_conditions': komponenConditions,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      dynamic decoded = json.decode(response.body);
      return _extractData(decoded) as Map<String, dynamic>;
    } else {
      dynamic decoded = json.decode(response.body);
      String message = decoded['message'] ?? 'Gagal mengupdate inspeksi';
      throw Exception(message);
    }
  }

  // Get detail inspeksi (service_history + komponen readings)
  static Future<Map<String, dynamic>> getInspectionDetail({
    required int machineId,
    required int serviceId,
  }) async {
    final headers = await _getHeaders();

    print('=== GET INSPECTION DETAIL REQUEST ===');
    print('URL: $baseUrl/machines/$machineId/inspection/$serviceId');

    final response = await http.get(
      Uri.parse('$baseUrl/machines/$machineId/inspection/$serviceId'),
      headers: headers,
    );

    print('=== GET INSPECTION DETAIL RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      return _extractData(decoded) as Map<String, dynamic>;
    } else {
      dynamic decoded = json.decode(response.body);
      String message = decoded['message'] ?? 'Gagal memuat detail inspeksi';
      throw Exception(message);
    }
  }

  // Get global inspection history (semua pabrik) - join factory/station/lori
  static Future<List<dynamic>> getGlobalHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/service-history/global?limit=$limit&offset=$offset'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      return _extractData(decoded) as List<dynamic>;
    } else {
      dynamic decoded = json.decode(response.body);
      throw Exception(decoded['message'] ?? 'Gagal memuat history global');
    }
  }

  // Upload foto inspeksi (multipart)
  static Future<List<dynamic>> uploadInspectionPhotos({
    required int machineId,
    required int serviceId,
    required List<File> photos,
    String? caption,
  }) async {
    final token = await _getToken();

    print('=== UPLOAD INSPECTION PHOTOS ===');
    print('URL: $baseUrl/machines/$machineId/inspection/$serviceId/photos');
    print('Photos count: ${photos.length}');

    final uri = Uri.parse(
      '$baseUrl/machines/$machineId/inspection/$serviceId/photos',
    );

    final request = http.MultipartRequest('POST', uri);

    if (token != null && !DEMO_MODE) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (caption != null && caption.isNotEmpty) {
      request.fields['caption'] = caption;
    }

    for (final photo in photos) {
      request.files.add(
        await http.MultipartFile.fromPath('photos', photo.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('=== UPLOAD PHOTOS RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      return _extractData(decoded) as List<dynamic>;
    } else {
      dynamic decoded = json.decode(response.body);
      String message = decoded['message'] ?? 'Gagal upload foto';
      throw Exception(message);
    }
  }

  // ==================== MACHINE HM & PM ====================

  // Update HM
  static Future<Map<String, dynamic>> updateHM({
    required int machineId,
    required double hmCurrent,
  }) async {
    final headers = await _getHeaders();

    print('=== UPDATE HM REQUEST ===');
    print('URL: $baseUrl/machines/$machineId/hm');
    print('Body: hm_current=$hmCurrent');

    final response = await http.post(
      Uri.parse('$baseUrl/machines/$machineId/hm'),
      headers: headers,
      body: json.encode({'hm_current': hmCurrent}),
    );

    print('=== UPDATE HM RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      return _extractData(decoded) as Map<String, dynamic>;
    } else {
      dynamic decoded = json.decode(response.body);
      String message = decoded['message'] ?? 'Gagal update HM';
      throw Exception(message);
    }
  }

  // Record PM
  static Future<Map<String, dynamic>> recordPM({
    required int machineId,
    DateTime? tanggalService,
    String? keterangan,
  }) async {
    final headers = await _getHeaders();

    print('=== RECORD PM REQUEST ===');
    print('URL: $baseUrl/machines/$machineId/pm');

    final response = await http.post(
      Uri.parse('$baseUrl/machines/$machineId/pm'),
      headers: headers,
      body: json.encode({
        'tanggal_service': tanggalService?.toIso8601String(),
        'keterangan': keterangan,
      }),
    );

    print('=== RECORD PM RESPONSE ===');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      return _extractData(decoded) as Map<String, dynamic>;
    } else {
      dynamic decoded = json.decode(response.body);
      String message = decoded['message'] ?? 'Gagal record PM';
      throw Exception(message);
    }
  }

  // Get service history
  static Future<List<dynamic>> getServiceHistory({
    required int machineId,
    int limit = 10,
    int offset = 0,
  }) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse(
        '$baseUrl/machines/$machineId/history?limit=$limit&offset=$offset',
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);
      return data is List ? data : [];
    } else {
      throw Exception('Gagal memuat history');
    }
  }

  // Get PM status
  static Future<Map<String, dynamic>> getPMStatus(int machineId) async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/machines/$machineId/pm-status'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      dynamic decoded = json.decode(response.body);
      dynamic data = _extractData(decoded);
      return data is Map<String, dynamic> ? data : {};
    } else {
      throw Exception('Gagal memuat PM status');
    }
  }
}
