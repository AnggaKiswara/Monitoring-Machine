import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_services.dart';

class InputInspectionScreen extends StatefulWidget {
  final int machineId;
  final String machineName;
  final String kodeMesin;
  final double currentHM;

  const InputInspectionScreen({
    super.key,
    required this.machineId,
    required this.machineName,
    required this.kodeMesin,
    required this.currentHM,
  });

  @override
  State<InputInspectionScreen> createState() => _InputInspectionScreenState();
}

class _InputInspectionScreenState extends State<InputInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picController = TextEditingController();

  DateTime _tanggalInspeksi = DateTime.now();
  DateTime? _tanggalPM;
  bool _isLoading = false;
  bool _isUploading = false;
  List<File> _photos = []; // ✅ Foto inspeksi yang dipilih
  Map<String, dynamic>? _pmStatus;
  final ImagePicker _picker = ImagePicker();

  // ✅ Ambil foto dari kamera / galeri
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80, // kompres biar ringan
        maxWidth: 1280,
      );
      if (picked != null) {
        setState(() => _photos.add(File(picked.path)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ambil foto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto (Kamera)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Data inspection terakhir
  List<dynamic> _inspectionHistory = [];
  Map<String, dynamic>? _lastInspection;

  @override
  void initState() {
    super.initState();
    _loadPMStatus();
    _loadInspectionHistory(); // ✅ Load history saat init
  }

  Future<void> _loadPMStatus() async {
    try {
      final status = await ApiServices.getPMStatus(widget.machineId);
      setState(() {
        _pmStatus = status;
      });
    } catch (e) {
      print('Error loading PM status: $e');
    }
  }

  Future<void> _loadInspectionHistory() async {
    try {
      // Load history inspeksi terakhir
      final history = await ApiServices.getServiceHistory(
        machineId: widget.machineId,
        limit: 5, // Ambil 5 history terakhir
      );

      setState(() {
        _inspectionHistory = history;
        if (history.isNotEmpty) {
          _lastInspection = history[0];

          // ✅ Isi form dengan data terakhir
          if (_lastInspection != null) {
            // Parse tanggal service
            if (_lastInspection!['service_date'] != null) {
              _tanggalInspeksi = DateTime.parse(
                _lastInspection!['service_date'],
              );
            }

            // Parse next service date (untuk tanggal PM)
            if (_lastInspection!['next_service_date'] != null) {
              _tanggalPM = DateTime.parse(
                _lastInspection!['next_service_date'],
              );
            }

            // Parse PIC (dari description)
            if (_lastInspection!['description'] != null) {
              _picController.text = _lastInspection!['description'];
            }
          }
        }
      });
    } catch (e) {
      print('Error loading inspection history: $e');
    }
  }

  Future<void> _selectTanggalInspeksi() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalInspeksi,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _tanggalInspeksi = picked);
    }
  }

  Future<void> _selectTanggalPM() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalPM ?? _tanggalInspeksi,
      firstDate: _tanggalInspeksi,
      lastDate: _tanggalInspeksi.add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() => _tanggalPM = picked);
    }
  }

  // ✅ Hitung Next PM (7 hari setelah tanggal terakhir PM)
  DateTime get _nextPM {
    if (_tanggalPM == null)
      return _tanggalInspeksi.add(const Duration(days: 7));
    return _tanggalPM!.add(const Duration(days: 0));
  }

  // ✅ Hitung sisa hari
  int get _sisaHari {
    if (_tanggalPM == null) return 0;
    final now = DateTime.now();
    final diff = _tanggalPM!.difference(now).inDays;
    return diff > 0 ? diff : 0;
  }

  Future<void> _submitInspection() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tanggalPM == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal PM wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Record PM (tetap INSERT untuk menyimpan history)
      final pmResult = await ApiServices.recordPM(
        machineId: widget.machineId,
        tanggalService: _tanggalPM,
        keterangan: _picController.text.trim(),
      );
      final int? serviceId = pmResult['id_service'];

      // 2️⃣ Upload foto inspeksi (jika ada) — sekaligus saat simpan
      if (_photos.isNotEmpty && serviceId != null) {
        setState(() => _isUploading = true);
        try {
          await ApiServices.uploadInspectionPhotos(
            machineId: widget.machineId,
            serviceId: serviceId,
            photos: _photos,
            caption: _picController.text.trim(),
          );
        } catch (e) {
          // Foto gagal, tapi inspeksi tetap tercatat — info ke user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Inspeksi tersimpan, tapi upload foto gagal: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isUploading = false);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _lastInspection == null
                  ? 'Inspeksi berhasil dicatat${_photos.isNotEmpty ? ' + ${_photos.length} foto' : ''}'
                  : 'Inspeksi berhasil diupdate',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

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
          _lastInspection != null
              ? 'Update Data Inspeksi'
              : 'Input Data Inspeksi',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _pmStatus == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1️⃣ INFO MACHINE CARD
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_railway,
                              color: Color(0xFF2196F3),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.kodeMesin,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.machineName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1a2332),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2️⃣ TANGGAL INSPEKSI
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
                            'Tanggal Inspeksi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a2332),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _selectTanggalInspeksi,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
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
                                      dateFormat.format(_tanggalInspeksi),
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3️⃣ TANGGAL TERAKHIR PM
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
                            'Tanggal Terakhir PM',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a2332),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _selectTanggalPM,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _tanggalPM != null
                                          ? dateFormat.format(_tanggalPM!)
                                          : 'Pilih tanggal PM',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: _tanggalPM != null
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4️⃣ NEXT PM & COUNTDOWN
                    if (_tanggalPM != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF2196F3),
                              const Color(0xFF1976D2),
                            ],
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
                          children: [
                            // Next PM Date
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Next PM',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    dateFormat.format(_nextPM),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Countdown
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Countdown',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _sisaHari <= 3
                                        ? Colors.orange.withOpacity(0.3)
                                        : Colors.green.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _sisaHari <= 3
                                          ? Colors.orange
                                          : Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _sisaHari <= 3
                                            ? Icons.warning
                                            : Icons.timer,
                                        color: _sisaHari <= 3
                                            ? Colors.orange
                                            : Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_sisaHari} Hari',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _sisaHari <= 3
                                              ? Colors.orange
                                              : Colors.green,
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
                    if (_tanggalPM != null) const SizedBox(height: 16),

                    // 5️⃣ INPUT PIC
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
                            'PIC (Person in Charge)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a2332),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _picController,
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama PIC',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'PIC wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5️⃣ FOTO INSPEKSI
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
                          Row(
                            children: [
                              const Icon(Icons.photo_camera,
                                  color: Color(0xFF1a2332), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Foto Inspeksi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1a2332),
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _showPhotoSourceSheet,
                                icon: const Icon(Icons.add_a_photo, size: 18),
                                label: const Text('Tambah'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF2196F3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_photos.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: _showPhotoSourceSheet,
                                child: Column(
                                  children: [
                                    Icon(Icons.add_photo_alternate,
                                        size: 40, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap untuk tambah foto',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _photos.length,
                              itemBuilder: (ctx, i) => Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _photos[i],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removePhoto(i),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close,
                                            size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_isUploading)
                            const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2196F3),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Mengupload foto...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      )),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 6️⃣ TOMBOL SUBMIT (LEBAR PENUH)
                    ElevatedButton(
                      onPressed: _isLoading || _isUploading ? null : _submitInspection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _lastInspection != null
                                  ? 'UPDATE INSPEKSI'
                                  : 'SIMPAN INSPEKSI',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),

                    // TOMBOL BATAL
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),

                    // ✅ HISTORY INSPECTION (jika ada)
                    if (_inspectionHistory.length > 1) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Riwayat Inspeksi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a2332),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._inspectionHistory.skip(1).take(4).map((inspection) {
                        final date = inspection['service_date'] != null
                            ? DateTime.parse(inspection['service_date'])
                            : null;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      date != null
                                          ? dateFormat.format(date)
                                          : '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (inspection['description'] != null &&
                                        inspection['description']
                                            .toString()
                                            .isNotEmpty)
                                      Text(
                                        'PIC: ${inspection['description']}',
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
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _picController.dispose();
    super.dispose();
  }
}
