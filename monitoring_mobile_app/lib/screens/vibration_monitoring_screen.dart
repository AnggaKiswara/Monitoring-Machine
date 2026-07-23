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

  final Map<int, TextEditingController> _penilaianControllers = {};
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
            final id = k['id_komponen'];
            _penilaianControllers[id] = TextEditingController();
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

  // Kondisi total per komponen = bobot * penilaian / 100
  double _kondisiTotal(Map<String, dynamic> k) {
    final id = k['id_komponen'];
    final bobot = _toDouble(k['bobot']);
    final penilaian = _toDouble(_penilaianControllers[id]?.text);
    return bobot * penilaian / 100;
  }

  // Overall health = Σ(bobot * penilaian) / Σbobot
  double _overallHealth() {
    double totalWeighted = 0;
    double totalBobot = 0;
    for (final k in _komponen) {
      final bobot = _toDouble(k['bobot']);
      final penilaian = _toDouble(_penilaianControllers[k['id_komponen']]?.text);
      totalWeighted += bobot * penilaian;
      totalBobot += bobot;
    }
    return totalBobot > 0 ? totalWeighted / totalBobot : 0;
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
    // validasi: minimal 1 penilaian diisi
    final conditions = <Map<String, dynamic>>[];
    for (final k in _komponen) {
      final id = k['id_komponen'];
      final penilaian = _toDouble(_penilaianControllers[id]?.text);
      if (penilaian > 0) {
        conditions.add({
          'id_komponen': id,
          'kondisi': penilaian,
        });
      }
    }
    if (conditions.isEmpty) {
      AppNotify.error(context, 'Isi minimal 1 penilaian komponen');
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
      );
      if (mounted) AppNotify.success(context, 'Monitoring vibration disimpan');
      // reload untuk refresh health per komponen
      setState(() => _loading = true);
      _penilaianControllers.clear();
      await _loadKomponen();
    } catch (e) {
      if (mounted) AppNotify.error(context, 'Gagal simpan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in _penilaianControllers.values) c.dispose();
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
                            Expanded(flex: 3, child: Text('Penilaian', style: TextStyle(color: Colors.white, fontSize: 12))),
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
                        final kondisi = _kondisiTotal(k);
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
                                  child: Text(k['nama_komponen'] ?? '-',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                              Expanded(flex: 2, child: Text(bobot.toStringAsFixed(0), style: const TextStyle(fontSize: 13))),
                              Expanded(
                                flex: 3,
                                child: SizedBox(
                                  height: 36,
                                  child: TextField(
                                    controller: _penilaianControllers[id],
                                    onChanged: (_) => setState(() {}),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      hintText: '0-100',
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
