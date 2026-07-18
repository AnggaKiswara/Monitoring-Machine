import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';
import '../app_notify.dart';
import '../providers/auth_providers.dart';

class InspectionEditScreen extends StatefulWidget {
  final int machineId;
  final int serviceId;
  final String machineName;

  const InspectionEditScreen({
    super.key,
    required this.machineId,
    required this.serviceId,
    required this.machineName,
  });

  @override
  State<InspectionEditScreen> createState() => _InspectionEditScreenState();
}

class _InspectionEditScreenState extends State<InspectionEditScreen> {
  final _picController = TextEditingController();
  final _keteranganController = TextEditingController();
  DateTime _tanggal = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  // Daftar komponen dari detail (prefill kondisi)
  List<dynamic> _komponenReadings = [];
  final Map<int, String> _kondisi = {}; // id_komponen -> kondisi

  final Map<String, int> _nilaiPersentase = {
    'Baik': 100,
    'Perlu Perhatian': 50,
    'Rusak': 0,
  };
  final List<String> _kondisiOptions = ['Baik', 'Perlu Perhatian', 'Rusak'];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await ApiServices.getInspectionDetail(
        machineId: widget.machineId,
        serviceId: widget.serviceId,
      );
      final readings = detail['komponen_readings'] as List<dynamic>? ?? [];
      for (var r in readings) {
        final id = r['id_komponen'] is int
            ? r['id_komponen']
            : int.tryParse(r['id_komponen'].toString()) ?? 0;
        _kondisi[id] = (r['kondisi'] ?? 'Baik').toString();
      }
      _picController.text = (detail['pic'] ?? detail['pic_name'] ?? '').toString();
      _keteranganController.text = (detail['keterangan'] ?? '').toString();
      if (detail['tanggal_inspeksi'] != null) {
        _tanggal = DateTime.tryParse(detail['tanggal_inspeksi'].toString()) ?? DateTime.now();
      } else if (detail['tanggal'] != null) {
        _tanggal = DateTime.tryParse(detail['tanggal'].toString()) ?? DateTime.now();
      }
      setState(() {
        _komponenReadings = readings;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_picController.text.trim().isEmpty) {
      AppNotify.warning(context, 'PIC wajib diisi');
      return;
    }
    if (_kondisi.isEmpty) {
      AppNotify.warning(context, 'Pilih kondisi untuk minimal 1 komponen');
      return;
    }
    setState(() => _saving = true);
    try {
      final List<Map<String, dynamic>> komponenConditions = [];
      for (var r in _komponenReadings) {
        final id = r['id_komponen'] is int
            ? r['id_komponen']
            : int.tryParse(r['id_komponen'].toString()) ?? 0;
        final kondisi = _kondisi[id] ?? 'Baik';
        komponenConditions.add({
          'id_komponen': id,
          'kondisi': kondisi,
          'nilai': _nilaiPersentase[kondisi] ?? 0,
        });
      }
      await ApiServices.updateInspection(
        machineId: widget.machineId,
        serviceId: widget.serviceId,
        tanggalInspeksi: DateFormat('yyyy-MM-dd').format(_tanggal),
        pic: _picController.text.trim(),
        keterangan: _keteranganController.text.trim().isNotEmpty
            ? _keteranganController.text.trim()
            : null,
        komponenConditions: komponenConditions,
      );
      if (mounted) {
        AppNotify.success(context, 'Inspeksi berhasil diupdate');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) AppNotify.error(context, 'Gagal update: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a2332),
      appBar: AppBar(
        title: const Text('Edit Inspeksi'),
        backgroundColor: const Color(0xFF1a2332),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lori: ${widget.machineName}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 16),
                      // Tanggal
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _tanggal,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _tanggal = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd MMM yyyy').format(_tanggal)),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // PIC
                      TextField(
                        controller: _picController,
                        decoration: const InputDecoration(
                          labelText: 'PIC',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Keterangan
                      TextField(
                        controller: _keteranganController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Komponen',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._komponenReadings.map((r) {
                        final id = r['id_komponen'] is int
                            ? r['id_komponen']
                            : int.tryParse(r['id_komponen'].toString()) ?? 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(r['nama_komponen']?.toString() ?? 'Komponen $id'),
                              ),
                              DropdownButton<String>(
                                value: _kondisi[id] ?? 'Baik',
                                items: _kondisiOptions
                                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                                    .toList(),
                                onChanged: (v) => setState(() => _kondisi[id] = v!),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _saving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Simpan Perubahan',
                                  style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
