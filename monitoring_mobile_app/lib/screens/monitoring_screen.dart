import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';
import '../app_notify.dart';

class MonitoringSessionScreen extends StatefulWidget {
  final String machineName;
  final int machineId;

  const MonitoringSessionScreen({
    super.key,
    required this.machineName,
    required this.machineId,
  });

  @override
  State<MonitoringSessionScreen> createState() => _MonitoringSessionScreenState();
}

class _MonitoringSessionScreenState extends State<MonitoringSessionScreen> {
  bool _saving = false;
  bool _loadingLatest = true;
  bool _loadingParams = true;
  Map<String, dynamic>? _latestSession;
  List<dynamic> _parameters = [];

  final TextEditingController _hmController = TextEditingController();
  final TextEditingController _rpmController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  final Map<String, TextEditingController> _readingControllers = {
    'vibration_horizontal': TextEditingController(),
    'vibration_vertical': TextEditingController(),
    'bearing_inner': TextEditingController(),
    'bearing_outer': TextEditingController(),
    'bearing_temp': TextEditingController(),
  };

  final Map<String, String> _readingLabels = {
    'vibration_horizontal': 'Vibration Horizontal',
    'vibration_vertical': 'Vibration Vertikal',
    'bearing_inner': 'Bearing Bagian Dalam',
    'bearing_outer': 'Bearing Bagian Luar',
    'bearing_temp': 'Bearing Temp',
  };

  final Map<String, String> _readingUnits = {
    'vibration_horizontal': 'mm/s',
    'vibration_vertical': 'mm/s',
    'bearing_inner': 'gE',
    'bearing_outer': 'gE',
    'bearing_temp': '°C',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadLatest(),
      _loadParameters(),
    ]);
  }

  Future<void> _loadParameters() async {
    setState(() => _loadingParams = true);
    try {
      final params = await ApiServices.getMonitoringParameters();
      if (mounted) {
        setState(() {
          _parameters = params;
          _loadingParams = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingParams = false);
    }
  }

  Future<void> _loadLatest() async {
    setState(() => _loadingLatest = true);
    try {
      final latest = await ApiServices.getLatestMonitoringSession(widget.machineId);
      if (mounted) {
        setState(() {
          _latestSession = latest;
          _loadingLatest = false;
        });
        _seedFromLatest(latest);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingLatest = false);
      }
    }
  }

  void _seedFromLatest(Map<String, dynamic>? latest) {
    if (latest == null) return;
    final session = latest['session'] ?? latest;
    if (session is Map) {
      _hmController.text = _safeDouble(session['hm'])?.toStringAsFixed(1) ?? '';
      _rpmController.text = _safeDouble(session['rpm'])?.toStringAsFixed(0) ?? '';
      _remarksController.text = (session['remarks'] ?? '').toString();
    }
    final readings = latest['readings'];
    if (readings is List) {
      for (final r in readings) {
        if (r is Map) {
          final name = (r['nama_parameter'] ?? '').toString().toLowerCase();
          final nilai = _safeDouble(r['nilai']);
          if (name.contains('vibrasi') || name.contains('vibration')) {
            if (name.contains('vertikal') || name.contains('vertical')) {
              _readingControllers['vibration_vertical']?.text = nilai?.toStringAsFixed(2) ?? '';
            } else if (name.contains('horizontal')) {
              _readingControllers['vibration_horizontal']?.text = nilai?.toStringAsFixed(2) ?? '';
            }
          } else if (name.contains('bearing')) {
            if (name.contains('temp') || name.contains('suhu')) {
              _readingControllers['bearing_temp']?.text = nilai?.toStringAsFixed(1) ?? '';
            } else if (name.contains('inner') || name.contains('dalam')) {
              _readingControllers['bearing_inner']?.text = nilai?.toStringAsFixed(2) ?? '';
            } else if (name.contains('outer') || name.contains('luar')) {
              _readingControllers['bearing_outer']?.text = nilai?.toStringAsFixed(2) ?? '';
            }
          }
        }
      }
    }
  }

  double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _resolveParamId(String normalizedKey) {
    final key = normalizedKey.toLowerCase();
    final targetName = _readingLabels[normalizedKey]?.toLowerCase() ?? key;
    for (final p in _parameters) {
      final raw = (p['nama_parameter'] ?? p['name'] ?? '').toString().toLowerCase();
      if (raw.isEmpty) continue;
      if (key.contains('vibration_vertical') && (raw.contains('vertical') || raw.contains('vertikal') || raw.contains('vibrasi') && raw.contains('vertikal'))) {
        return _toInt(p['id_parameter'] ?? p['id']);
      }
      if (key.contains('vibration_horizontal') && (raw.contains('horizontal') || raw.contains('vibrasi') && raw.contains('horizontal'))) {
        return _toInt(p['id_parameter'] ?? p['id']);
      }
      if (key.contains('bearing_temp') && (raw.contains('temp') || raw.contains('temperature') || raw.contains('suhu'))) {
        return _toInt(p['id_parameter'] ?? p['id']);
      }
      if (key.contains('bearing_inner') && (raw.contains('inner') || raw.contains('dalam'))) {
        return _toInt(p['id_parameter'] ?? p['id']);
      }
      if (key.contains('bearing_outer') && (raw.contains('outer') || raw.contains('luar'))) {
        return _toInt(p['id_parameter'] ?? p['id']);
      }
    }
    return null;
  }

  int _toInt(dynamic value) {
    if (value == null) return -1;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? -1;
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2332),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.machineName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Monitoring Session',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
      ),
      body: _loadingLatest && _loadingParams
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSessionInfoCard(),
                  const SizedBox(height: 16),
                  _buildHmRpmCard(),
                  const SizedBox(height: 16),
                  _buildReadingCard('vibration_horizontal'),
                  const SizedBox(height: 12),
                  _buildReadingCard('vibration_vertical'),
                  const SizedBox(height: 12),
                  _buildReadingCard('bearing_inner'),
                  const SizedBox(height: 12),
                  _buildReadingCard('bearing_outer'),
                  const SizedBox(height: 12),
                  _buildReadingCard('bearing_temp'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _remarksController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Remarks',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submitMonitoring,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan Monitoring Session'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSessionInfoCard() {
    final recordedAt = _latestSession != null
        ? DateTime.tryParse((_latestSession!['session']?['recorded_at'] ?? '').toString())
        : null;
    final formatted = recordedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(recordedAt) : 'Belum ada sesi';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, color: Color(0xFF2196F3)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesi Terakhir',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  formatted,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHmRpmCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _hmController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'HM',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _rpmController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'RPM',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(String key) {
    final controller = _readingControllers[key]!;
    final label = _readingLabels[key] ?? key;
    final unit = _readingUnits[key] ?? '';
    final double? value = _safeDouble(controller.text);
    final status = _deriveStatus(key, value);
    final statusColor = _statusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.analytics, color: Color(0xFF2196F3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  onChanged: (v) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nilai ($unit)',
                    isDense: true,
                    suffixText: unit.isEmpty ? null : unit,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value != null ? value.toStringAsFixed(2) : '--',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _deriveStatus(String key, double? value) {
    final v = value;
    if (v == null) return '--';
    if (key.contains('vibration')) {
      if (v <= 2.8) return 'Good';
      if (v >= 4.8) return 'Danger';
      return 'Alert';
    }
    if (key.toLowerCase().contains('temp')) {
      if (v <= 50) return 'Good';
      if (v >= 70) return 'Danger';
      return 'Alert';
    }
    if (key.contains('bearing')) {
      if (v <= 2.0) return 'Good';
      if (v >= 4.0) return 'Danger';
      return 'Alert';
    }
    return '--';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Good':
        return Colors.green;
      case 'Alert':
        return Colors.orange;
      case 'Danger':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _submitMonitoring() async {
    setState(() => _saving = true);
    try {
      final hm = _safeDouble(_hmController.text);
      final rpm = _safeDouble(_rpmController.text);
      final remarks = _remarksController.text.trim();

      final readings = <Map<String, dynamic>>[];
      for (final entry in _readingControllers.entries) {
        final value = _safeDouble(entry.value.text);
        if (value == null) continue;
        final idParam = _resolveParamId(entry.key);
        if (idParam == null || idParam <= 0) continue;
        readings.add({
          'id_parameter': idParam,
          'nilai': value,
        });
      }

      if (readings.isEmpty) {
        throw Exception('Minimal isi 1 data monitoring');
      }

      await ApiServices.submitMonitoringSession(
        machineId: widget.machineId,
        hm: hm,
        rpm: rpm,
        remarks: remarks.isEmpty ? null : remarks,
        readings: readings,
      );

      if (mounted) {
        AppNotify.success(context, 'Monitoring session disimpan');
      }
      await _loadLatest();
    } catch (e) {
      if (mounted) AppNotify.error(context, 'Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _hmController.dispose();
    _rpmController.dispose();
    _remarksController.dispose();
    for (final c in _readingControllers.values) c.dispose();
    super.dispose();
  }
}
