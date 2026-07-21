import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_services.dart';
import '../app_notify.dart';
import '../data_store.dart';
import 'lori_detail_screen.dart';
import 'inspection_history_detail_screen.dart';
import 'inspection_edit_screen.dart';
import '../providers/auth_providers.dart';

class MachineDetailScreen extends StatefulWidget {
  final String machineName;
  final int machineId;
  final String kodeMesin;
  final double currentHM;

  const MachineDetailScreen({
    super.key,
    required this.machineName,
    required this.machineId,
    this.kodeMesin = '',
    this.currentHM = 0,
  });

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _komponenList = [];
  bool _loading = true;
  String? _error;
  String _kodeMesin = '';
  double _currentHM = 0;

  // Inspection data
  DateTime? _lastPMDate;
  DateTime? _nextPMDate;
  String? _picName;
  int _komponenCount = 0;

  // ✅ FOTO INSPEKSI
  List<File> _photos = [];
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Ini menggunakan DataStore untuk bobot komponen
  final DataStore _dataStore = DataStore();

  // Komponen inspection state
  Map<int, String> _komponenConditions = {};
  bool _isSaving = false;

  // History data
  List<Map<String, dynamic>> _inspectionHistory = [];
  bool _loadingHistory = false;
  bool _canEdit = false;

  // ✅ TAMBAHAN: Controller dan State untuk Form Inspeksi
  final _inspectionPicController = TextEditingController();
  final _inspectionKeteranganController = TextEditingController();
  DateTime _inspectionDate = DateTime.now();

  // Nilai persentase
  final Map<String, double> _nilaiPersentase = {
    'Sangat Baik': 100.0,
    'Baik': 85.0,
    'Perlu Maintenance': 70.0,
    'Rusak': 30.0,
    'Tidak Ada': 0.0,
  };

  // ✅ Bobot default sesuai spreadsheet, dipakai jika DataStore belum menyimpan bobot.
  static const Map<String, double> _defaultKomponenWeights = {
    'Body': 25.0,
    'Siku': 5.0,
    'Steam Spreader': 7.0,
    'Chasis': 25.0,
    'Hock': 3.0,
    'Cover Roda': 2.0,
    'Roda': 13.0,
    'Lantai': 20.0,
  };

  final List<String> _kondisiOptions = [
    'Sangat Baik',
    'Baik',
    'Perlu Maintenance',
    'Rusak',
    'Tidak Ada',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _loadDraft(); // Load auto-save draft
    AuthHelper.canEditInspection().then((v) {
      if (mounted) setState(() => _canEdit = v);
    });
  }

  Future<void> _loadData() async {
    // Load komponen dulu agar _komponenCount tersedia untuk history
    await _loadKomponen();
    await Future.wait([
      _loadMachineDetail(),
      _loadInspectionData(),
      _loadHistory(),
    ]);
  }

  Future<void> _loadMachineDetail() async {
    try {
      final machines = await ApiServices.getMachines(stationId: null);
      if (machines.isEmpty) return;

      dynamic machine;
      for (var m in machines) {
        if (_toInt(m['id_mesin']) == widget.machineId) {
          machine = m;
          break;
        }
      }

      if (machine != null) {
        setState(() {
          _kodeMesin = machine['kode_mesin']?.toString() ?? '';
          _currentHM = _toDouble(machine['hm_current']);
        });
      }
    } catch (e) {
      print('Error loading machine detail: $e');
    }
  }

  Future<void> _loadInspectionData() async {
    try {
      final history = await ApiServices.getServiceHistory(
        machineId: widget.machineId,
        limit: 1,
      );

      if (history.isNotEmpty) {
        final lastInspection = history[0];
        setState(() {
          _lastPMDate = lastInspection['service_date'] != null
              ? DateTime.parse(lastInspection['service_date'])
              : null;
          _nextPMDate = lastInspection['next_service_date'] != null
              ? DateTime.parse(lastInspection['next_service_date'])
              : null;
          _picName = lastInspection['description'];
        });
      }
    } catch (e) {
      print('Error loading inspection data: $e');
    }
  }

  Future<void> _loadKomponen() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final data = await ApiServices.getKomponen(mesinId: widget.machineId);

      setState(() {
        _komponenList = data;
        _komponenCount = data.length;
        _loading = false;
      });
    } catch (e) {
      print('Error loading komponen: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      setState(() => _loadingHistory = true);

      final history = await ApiServices.getServiceHistory(
        machineId: widget.machineId,
        limit: 50,
      );

      setState(() {
        _inspectionHistory = history.map((item) {
          return {
            'id': item['id_service'],
            'tanggal': item['service_date'],
            'overall_health': _toDouble(item['health_mesin_after']),
            'description': item['description'] ?? '',
            'komponen_count': _komponenCount,
          };
        }).toList();
        _loadingHistory = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _loadingHistory = false);
    }
  }

  // Auto-save draft ke local storage
  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = 'inspection_draft_${widget.machineId}';

      final draftData = {
        'komponen_conditions': _komponenConditions.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        'pic': _inspectionPicController.text,
        'keterangan': _inspectionKeteranganController.text,
        'tanggal': _inspectionDate.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString(draftKey, json.encode(draftData));
    } catch (e) {
      print('Error saving draft: $e');
    }
  }

  // Load draft dari local storage
  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = 'inspection_draft_${widget.machineId}';
      final draftString = prefs.getString(draftKey);

      if (draftString != null) {
        final draftData = json.decode(draftString);
        final conditions = Map<String, dynamic>.from(
          draftData['komponen_conditions'],
        );

        setState(() {
          _komponenConditions = conditions.map(
            (key, value) => MapEntry(int.parse(key), value.toString()),
          );

          // Load text fields jika ada
          if (draftData['pic'] != null) {
            _inspectionPicController.text = draftData['pic'];
          }
          if (draftData['keterangan'] != null) {
            _inspectionKeteranganController.text = draftData['keterangan'];
          }
          if (draftData['tanggal'] != null) {
            _inspectionDate = DateTime.parse(draftData['tanggal']);
          }
        });

        // Show notification jika ada draft
        if (_komponenConditions.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNotify.warning(
              context,
              'Draft ditemukan dari ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(draftData['timestamp']))}',
            );
          });
        }
      }
    } catch (e) {
      print('Error loading draft: $e');
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftKey = 'inspection_draft_${widget.machineId}';
      await prefs.remove(draftKey);

      setState(() {
        _komponenConditions.clear();
        _inspectionPicController.clear();
        _inspectionKeteranganController.clear();
        _inspectionDate = DateTime.now();
      });
    } catch (e) {
      print('Error clearing draft: $e');
    }
  }

  // Hitung overall health berbobot sesuai spreadsheet
  // Rumus: sum(condition_i * weight_i) / sum(weight_i)
  double? get _overallHealth {
    if (_komponenConditions.isEmpty) return null;

    double weightedSum = 0;
    double totalWeight = 0;

    _komponenList.forEach((komponen) {
      final komponenId = komponen['id_komponen'];
      final kondisi = _komponenConditions[komponenId];
      if (kondisi == null) return;

      final conditionValue = _nilaiPersentase[kondisi] ?? 0;
      final komponenName = komponen['nama_komponen']?.toString() ?? '';

      // Gunakan bobot tersimpan di DataStore, fallback ke default spreadsheet
      double weight = _dataStore.getKomponenWeight(
        widget.machineName,
        komponenName,
      );
      if (weight <= 0) {
        weight = _defaultKomponenWeights[komponenName] ?? 0.0;
      }

      weightedSum += conditionValue * weight;
      totalWeight += weight;
    });

    return totalWeight > 0 ? weightedSum / 100 : null;
  }

  Color _getHealthColor(double health) {
    if (health >= 90) return Colors.green;
    if (health >= 70) return Colors.lightGreen;
    if (health >= 60) return Colors.orange;
    return Colors.red;
  }

  // Submit inspeksi
  Future<void> _submitInspection() async {
    // Validasi PIC
    if (_inspectionPicController.text.trim().isEmpty) {
      AppNotify.warning(context, 'PIC wajib diisi');
      return;
    }

    if (_komponenConditions.isEmpty) {
      AppNotify.warning(context, 'Pilih kondisi untuk minimal 1 komponen');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Build daftar kondisi komponen
      final List<Map<String, dynamic>> komponenConditions = [];

      for (var komponen in _komponenList) {
        final komponenId = komponen['id_komponen'];
        final kondisi = _komponenConditions[komponenId];

        if (kondisi != null) {
          final komponenName = komponen['nama_komponen']?.toString() ?? '';
          double weight = _dataStore.getKomponenWeight(
            widget.machineName,
            komponenName,
          );
          if (weight <= 0) {
            weight = _defaultKomponenWeights[komponenName] ?? 0.0;
          }

          komponenConditions.add({
            'id_komponen': komponenId,
            'kondisi': kondisi,
            'nilai': _nilaiPersentase[kondisi] ?? 0,
            'bobot': weight,
          });
        }
      }

      // Kirim semua data dalam 1 request
      final result = await ApiServices.submitInspection(
        machineId: widget.machineId,
        tanggalInspeksi: DateFormat('yyyy-MM-dd').format(_inspectionDate),
        pic: _inspectionPicController.text.trim(),
        keterangan: _inspectionKeteranganController.text.trim().isNotEmpty
            ? _inspectionKeteranganController.text.trim()
            : null,
        komponenConditions: komponenConditions,
        healthOverall: _overallHealth,
      );

      // ✅ Upload foto inspeksi (jika ada)
      final serviceId = result['id_service'];
      if (_photos.isNotEmpty && serviceId != null) {
        try {
          await ApiServices.uploadInspectionPhotos(
            machineId: widget.machineId,
            serviceId: serviceId is int ? serviceId : int.parse(serviceId.toString()),
            photos: _photos,
          );
          if (mounted) {
            AppNotify.success(
              context,
              '${_photos.length} foto berhasil diupload',
            );
          }
        } catch (photoErr) {
          // Foto gagal, tapi inspeksi sudah tersimpan → kasih tahu user
          if (mounted) {
            AppNotify.error(
              context,
              'Inspeksi tersimpan, tapi foto GAGAL: $photoErr',
            );
          }
        }
      }

      // Clear draft setelah berhasil simpan
      await _clearDraft();

      if (mounted) {
        final healthAfter = result['health_after'];
        AppNotify.success(
          context,
          'Inspeksi berhasil disimpan! Health: $healthAfter%',
        );

        // Reset form setelah sukses
        setState(() {
          _komponenConditions.clear();
          _photos.clear(); // bersihkan foto dari form (hindari "cache" tersisa)
          _inspectionPicController.clear();
          _inspectionKeteranganController.clear();
          _inspectionDate = DateTime.now();
        });

        // Refresh data
        await _loadHistory();
        await _loadInspectionData();
      }
    } catch (e) {
      if (mounted) {
        AppNotify.error(context, 'Gagal: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ✅ FOTO INSPEKSI — pilih dari kamera/galeri
  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1280,
    ).catchError((_) => null);
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
    ).catchError((_) => null);
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_camera, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              const Text(
                'Foto Inspeksi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2332),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showPhotoSourceSheet,
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: const Text('Tambah'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_photos.isEmpty)
            GestureDetector(
              onTap: _showPhotoSourceSheet,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, width: 1.5),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                      SizedBox(height: 6),
                      Text('Tap untuk tambah foto',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_photos[i], fit: BoxFit.cover,
                        width: double.infinity, height: double.infinity),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removePhoto(i),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date);
  }

  int _calculateDaysRemaining(DateTime? nextDate) {
    if (nextDate == null) return 0;
    final now = DateTime.now();
    final diff = nextDate.difference(now).inDays;
    return diff > 0 ? diff : 0;
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
        title: Text(
          widget.machineName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Inspeksi', icon: Icon(Icons.edit)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildInspectionTab(), _buildHistoryTab()],
            ),
    );
  }

  // TAB 1: INSPEKSI
  Widget _buildInspectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Machine Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_railway,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _kodeMesin.isNotEmpty ? _kodeMesin : 'No Code',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.machineName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Overall Health Card
          if (_overallHealth != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getHealthColor(_overallHealth!),
                    _getHealthColor(_overallHealth!).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getHealthColor(_overallHealth!).withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Overall Health',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  Text(
                    '${_overallHealth!.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          if (_overallHealth != null) const SizedBox(height: 20),

          // ✅ TAMBAHAN: Form Informasi Inspeksi (Tanggal, PIC, Keterangan)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Inspeksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a2332),
                  ),
                ),
                const SizedBox(height: 16),

                // Tanggal
                const Text(
                  'Tanggal Inspeksi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _inspectionDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _inspectionDate = picked);
                      _saveDraft();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat('dd MMM yyyy').format(_inspectionDate),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // PIC
                const Text(
                  'PIC (Person in Charge)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _inspectionPicController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama PIC',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  onChanged: (_) => _saveDraft(),
                ),
                const SizedBox(height: 16),

                // Keterangan
                const Text(
                  'Keterangan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _inspectionKeteranganController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Masukkan keterangan inspeksi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(Icons.note),
                  ),
                  onChanged: (_) => _saveDraft(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Component List Header
          const Text(
            'Penilaian Komponen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2332),
            ),
          ),
          const SizedBox(height: 12),

          // ✅ Component List (FIXED: Menggunakan Column agar dropdown tidak gepeng/vertikal)
          ..._komponenList.map((komponen) {
            final komponenId = komponen['id_komponen'];
            final komponenName = komponen['nama_komponen'] ?? 'Unknown';
            final selectedCondition = _komponenConditions[komponenId];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris atas: Icon + Nama + Jenis
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selectedCondition != null
                              ? _getHealthColor(
                                  _nilaiPersentase[selectedCondition]!,
                                ).withOpacity(0.2)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.build_circle,
                          color: selectedCondition != null
                              ? _getHealthColor(
                                  _nilaiPersentase[selectedCondition]!,
                                )
                              : Colors.grey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              komponenName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1a2332),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              komponen['jenis_komponen'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ✅ Dropdown dengan isExpanded: true agar tidak overflow/vertikal
                  DropdownButtonFormField<String>(
                    value: selectedCondition,
                    isExpanded: true, // <-- INI KUNCI PERBAIKANNYA
                    decoration: InputDecoration(
                      hintText: 'Pilih kondisi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: selectedCondition != null
                          ? _getHealthColor(
                              _nilaiPersentase[selectedCondition]!,
                            ).withOpacity(0.1)
                          : Colors.grey[50],
                    ),
                    items: _kondisiOptions.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _komponenConditions[komponenId] = value!;
                      });
                      _saveDraft(); // Auto-save setiap perubahan
                    },
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 20),

          // ✅ FOTO INSPEKSI
          _buildPhotoSection(),

          // Submit Button
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _submitInspection,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _isSaving ? 'Menyimpan...' : 'SIMPAN INSPEKSI',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: HISTORY
  Widget _buildHistoryTab() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_inspectionHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Belum ada riwayat inspeksi',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _inspectionHistory.length,
      itemBuilder: (context, index) {
        final item = _inspectionHistory[index];
        final tanggal = item['tanggal'] != null
            ? DateTime.parse(item['tanggal'])
            : null;
        final overallHealth = _toDouble(item['overall_health']);

        return GestureDetector(
          onTap: () {
            final serviceId = _toInt(item['id']);
            if (serviceId > 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InspectionHistoryDetailScreen(
                    machineId: widget.machineId,
                    serviceId: serviceId,
                    machineName: widget.machineName,
                  ),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: _getHealthColor(overallHealth), width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(tanggal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a2332),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getHealthColor(overallHealth).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${overallHealth.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getHealthColor(overallHealth),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.build_circle, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${_komponenList.length} komponen dinilai',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (item['description'] != null &&
                    item['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item['description']}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                // Indicator klik
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_canEdit)
                      TextButton.icon(
                        onPressed: () {
                          final serviceId = _toInt(item['id']);
                          if (serviceId > 0) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InspectionEditScreen(
                                  machineId: widget.machineId,
                                  serviceId: serviceId,
                                  machineName: widget.machineName,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2196F3),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (_canEdit) const SizedBox(width: 12),
                    Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue[600]),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    // ✅ Dispose controller baru agar tidak memory leak
    _inspectionPicController.dispose();
    _inspectionKeteranganController.dispose();
    super.dispose();
  }
}
