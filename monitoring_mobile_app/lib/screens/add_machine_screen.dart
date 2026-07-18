import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../app_notify.dart';
import '../providers/auth_providers.dart';

class AddMachineScreen extends StatefulWidget {
  final int stationId;
  final String stationName;

  const AddMachineScreen({
    super.key,
    required this.stationId,
    required this.stationName,
  });

  @override
  State<AddMachineScreen> createState() => _AddMachineScreenState();
}

class _AddMachineScreenState extends State<AddMachineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _kodeController = TextEditingController(); // ✅ TAMBAHKAN INI
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Defense: hanya admin & staff yang boleh tambah lori
    AuthHelper.canManageLori().then((allowed) {
      if (!allowed && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppNotify.error(context, 'Hanya admin/staff yang boleh menambah lori');
          Navigator.pop(context);
        });
      }
    });
  }

  Future<void> _saveMachine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiServices.createMachine(
        stationId: widget.stationId,
        kodeMesin: _kodeController.text.trim(), // ✅ TAMBAHKAN INI
        namaMesin: _namaController.text.trim(),
      );

      if (mounted) {
        AppNotify.success(context, 'Lori berhasil ditambahkan');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppNotify.error(context, 'Gagal menambah Lori: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2332),
        title: Text('Tambah Lori - ${widget.stationName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ FIELD KODE LORI
              const Text(
                'Kode Lori',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _kodeController,
                decoration: InputDecoration(
                  hintText: 'Contoh: 17/2014',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: const Icon(Icons.code),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kode Lori wajib diisi';
                  }
                  // Validasi format: angka/angka (contoh: 17/2014)
                  if (!RegExp(r'^\d+/\d+$').hasMatch(value.trim())) {
                    return 'Format harus: Nomor/Tahun (contoh: 17/2014)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // FIELD NAMA LORI
              const Text(
                'Nama Lori/Mesin',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Lori No. 1',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: const Icon(Icons.directions_railway),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // TOMBOL SIMPAN
              ElevatedButton(
                onPressed: _isLoading ? null : _saveMachine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'SIMPAN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kodeController.dispose(); // ✅ Dispose controller
    super.dispose();
  }
}
