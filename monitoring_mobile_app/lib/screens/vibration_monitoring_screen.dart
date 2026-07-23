import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';
import '../app_notify.dart';

class VibrationMonitoringScreen extends StatefulWidget {
  final String machineName;
  final int machineId;

  const VibrationMonitoringScreen({
    super.key,
    required this.machineName,
    required this.machineId,
  });

  @override
  State<VibrationMonitoringScreen> createState() => _VibrationMonitoringScreenState();
}

class _VibrationMonitoringScreenState extends State<VibrationMonitoringScreen> {
  bool _loading = true;
  bool _saving = false;
  List<dynamic> _komponen = [];
  String? _error;

  // controller untuk nilai input riil (mm/s, gE, °C) per komponen
  final Map<int, TextEditingController> _nilaiControllers = {};
  final TextEditingController _hmController = TextEditingController();
  final TextEditingController _rpmController = TextEditingController();
  final TextEditingController _picController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKomponen();
  }

  Future<void> _loadKomponen() async {
    try {
      final list = await ApiServices.getKomponen(mesinId: widget.machineId);
      if (mounted) {
        setState(() {
          _komponen = list;
          for (final k in list) {
            _nilaiControllers[k['id_komponen']] = TextEditingController();
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  // Konversi nilai riil (mm/s, gE, °C) -> penilaian 0-100
  // Standar tabel: Good -> 100, Alert -> 60, Danger -> 30
  double _toPenilaian(String? satuan, double nilai) {
    if (nilai <= 0) return 0;
    switch (satuan) {
      case 'mm/s': // Vibration Fan: Good <=2.8, Alert 2.8-4.8, Danger >=4.8
        if (nilai <= 2.8) return 100;
        if (nilai < 4.8) return 60;
        return 30;
      case 'gE': // Bearing: Good <=2.0, Alert 2.0-4.0, Danger >=4.0
        if (nilai <= 2.0) return 100;
        if (nilai < 4.0) return 60;
        return 30;
      case '°C': // Bearing Temp: Good <=50, Alert 50-70, Danger >=70
        if (nilai <= 50) return 100;
        if (nilai < 70) return 60;
        return 30;
      default:
        return nilai; // fallback: anggap sudah 0-100
    }
  }

  double _penilaianOf(Map<String, dynamic> k) {
    final id = k['id_komponen'];
    final nilai = _toDouble(_nilaiControllers[id]?.text);
    return _toPenilaian(k['satuan'], nilai);
  }

  // Kondisi total per komponen = bobot * penilaian / 100
  double _kondisiTotal(Map<String, dynamic> k) {
    final bobot = _toDouble(k['bobot']);
    return bobot * _penilaianOf(k) / 100;
  }

  // Overall health = Σ(bobot * penilaian) / Σbobot
  double _overallHealth() {
    double totalWeighted = 0;
    double totalBobot = 0;
    for (final k in _komponen) {
      final bobot = _toDouble(k['bobot']);
      totalWeighted += bobot * _penilaianOf(k);
      totalBobot += bobot;
    }
    return totalBobot > 0 ? totalWeighted / totalBobot : 0;
  }

  String _statusLabel(double penilaian) {
    if (penilaian >= 100) return 'Good';
    if (penilaian >= 60) return 'Alert';
    if (penilaian > 0) return 'Danger';
    return '-';
  }

  Color _statusColor(double penilaian) {
    if (penilaian >= 100) return Colors.green;
    if (penilaian >= 60) return Colors.orange;
    if (penilaian > 0) return Colors.red;
    return Colors.grey;
  }

  Color _healthColor(double h) {
    if (h >= 85) return Colors.green;
    if (h >= 60) return Colors.orange;
    return Colors.red;
  }

  String _healthStatus(double h) {
    if (h >= 95) return 'Excellent';
    if (h >= 85) return 'Good';
    if (h >= 60) return 'Satisfactory';
    return 'Poor';
  }

  Future<void> _submit() async {
    final conditions = <Map<String, dynamic>>[];
    for (final k in _komponen) {
      final id = k['id_komponen'];
      final nilai = _toDouble(_nilaiControllers[id]?.text);
      if (nilai > 0) {
        conditions.add({
          'id_komponen': id,
          'kondisi': _penilaianOf(k),
        });
      }
    }
    if (conditions.isEmpty) {
      AppNotify.error(context, 'Isi minimal 1 nilai komponen');
      return;
    }
    if (_picController.text.trim().isEmpty) {
      AppNotify.error(context, 'PIC wajib diisi');
      return;
    }

    setState(() => _saving = true);
    try {
      final overall = _overallHealth();
      await ApiServices.submitInspection(
        machineId: widget.machineId,
        tanggalInspeksi: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        pic: _picController.text.trim(),
        keterangan: _keteranganController.text.trim().isEmpty ? null : _keteranganController.text.trim(),
        komponenConditions: conditions,
        healthOverall: overall,
        hm: _toDouble(_hmController.text),
        rpm: _toDouble(_rpmController.text),
      );
      if (mounted) AppNotify.success(context, 'Monitoring vibration disimpan');
      setState(() => _loading = true);
      for (final c in _nilaiControllers.values) c.dispose();
      _nilaiControllers.clear();
      await _loadKomponen();
    } catch (e) {
      if (mounted) AppNotify.error(context, 'Gagal simpan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in _nilaiControllers.values) c.dispose();
    _hmController.dispose();
    _rpmController.dispose();
    _picController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overall = _overallHealth();
    final overallColor = _healthColor(overall);

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
            Text(widget.machineName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Text('Monitoring Vibration - per Komponen',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overall health card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Overall Health',
                                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                                  Text('${overall.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: overallColor)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: overallColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(_healthStatus(overall),
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: overallColor)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 80,
                              width: 80,
                              child: Stack(
                                children: [
                                  CircularProgressIndicator(
                                    value: overall / 100,
                                    strokeWidth: 9,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(overallColor),
                                  ),
                                  Center(
                                    child: Icon(Icons.check_circle, color: overallColor, size: 32),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // HM & RPM (input per mesin, sesuai tabel)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _hmController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'HM',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _rpmController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'RPM',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      const Text('TABEL KOMPONEN',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 10),

                      // Header tabel
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a2332),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 1, child: Text('No', style: TextStyle(color: Colors.white, fontSize: 12))),
                            Expanded(flex: 4, child: Text('Uraian', style: TextStyle(color: Colors.white, fontSize: 12))),
                            Expanded(flex: 2, child: Text('Bobot', style: TextStyle(color: Colors.white, fontSize: 12))),
                            Expanded(flex: 3, child: Text('Nilai', style: TextStyle(color: Colors.white, fontSize: 12))),
                            Expanded(flex: 3, child: Text('Kond. Tot', style: TextStyle(color: Colors.white, fontSize: 12))),
                          ],
                        ),
                      ),

                      // Baris komponen
                      ..._komponen.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final k = entry.value;
                        final id = k['id_komponen'];
                        final bobot = _toDouble(k['bobot']);
                        final satuan = k['satuan'] ?? '';
                        final kondisi = _kondisiTotal(k);
                        final penilaian = _penilaianOf(k);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              left: BorderSide(color: Colors.grey.shade200),
                              right: BorderSide(color: Colors.grey.shade200),
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 1, child: Text('${idx + 1}', style: const TextStyle(fontSize: 13))),
                              Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(k['nama_komponen'] ?? '-',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text('Penilaian: ${penilaian.toStringAsFixed(0)} (${_statusLabel(penilaian)})',
                                          style: TextStyle(fontSize: 10, color: _statusColor(penilaian))),
                                    ],
                                  )),
                              Expanded(flex: 2, child: Text(bobot.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: _nilaiControllers[id],
                                    onChanged: (_) => setState(() {}),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      suffixText: satuan,
                                      hintText: '0',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                  flex: 3,
                                  child: Text(kondisi.toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 20),

                      // PIC & Keterangan
                      TextField(
                        controller: _picController,
                        decoration: InputDecoration(
                          labelText: 'PIC',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _keteranganController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Keterangan',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Simpan Monitoring Vibration'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
