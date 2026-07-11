import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final _hmController = TextEditingController();
  final _keteranganController = TextEditingController();

  DateTime _tanggalInspeksi = DateTime.now();
  DateTime? _tanggalPM;
  bool _isLoading = false;
  bool _isPMMode = false;
  Map<String, dynamic>? _pmStatus;

  @override
  void initState() {
    super.initState();
    _loadPMStatus();
    _hmController.text = widget.currentHM.toString();
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
      initialDate: _tanggalPM ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _tanggalPM = picked);
    }
  }

  Future<void> _submitInspection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isPMMode) {
        // Record PM
        await ApiServices.recordPM(
          machineId: widget.machineId,
          tanggalService: _tanggalPM,
          keterangan: _keteranganController.text,
        );
      } else {
        // Update HM
        final hmValue = double.parse(_hmController.text);
        await ApiServices.updateHM(
          machineId: widget.machineId,
          hmCurrent: hmValue,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isPMMode ? 'PM berhasil dicatat' : 'HM berhasil diupdate',
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
        title: const Text(
          'Input Data Inspeksi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                    // Info Machine Card
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

                    // Toggle HM/PM Mode
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isPMMode = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isPMMode
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: !_isPMMode
                                      ? [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Update HM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !_isPMMode
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isPMMode = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _isPMMode
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _isPMMode
                                      ? [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            blurRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Record PM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isPMMode
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // PM Status Alert (jika mode PM)
                    if (_isPMMode && _pmStatus != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (_pmStatus!['need_pm'] as bool ?? false)
                              ? Colors.orange[50]
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_pmStatus!['need_pm'] as bool ?? false)
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (_pmStatus!['need_pm'] as bool ?? false)
                                  ? Icons.warning
                                  : Icons.check_circle,
                              color: (_pmStatus!['need_pm'] as bool ?? false)
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (_pmStatus!['need_pm'] as bool ?? false)
                                        ? 'Perlu PM!'
                                        : 'Masih Baik',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          (_pmStatus!['need_pm'] as bool ??
                                              false)
                                          ? Colors.orange[900]
                                          : Colors.green[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sisa ${_pmStatus!['hours_until_pm']?.toStringAsFixed(0)} jam / ${_pmStatus!['days_until_pm']} hari',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isPMMode) const SizedBox(height: 20),

                    // Form Fields
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
                          // Tanggal Inspeksi
                          const Text(
                            'Tanggal Inspeksi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _selectTanggalInspeksi,
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
                                      dateFormat.format(_tanggalInspeksi),
                                      style: const TextStyle(fontSize: 14),
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
                          const SizedBox(height: 20),

                          // HM Value (jika mode HM)
                          if (!_isPMMode) ...[
                            const Text(
                              'Nilai HM Saat Ini',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _hmController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                hintText: 'Masukkan nilai HM',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                suffixText: 'Jam',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'HM wajib diisi';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Harus berupa angka';
                                }
                                if (double.parse(value) < widget.currentHM) {
                                  return 'HM harus lebih besar dari saat ini';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Tanggal PM (jika mode PM)
                          if (_isPMMode) ...[
                            const Text(
                              'Tanggal PM',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _selectTanggalPM,
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
                                        _tanggalPM != null
                                            ? dateFormat.format(_tanggalPM!)
                                            : 'Pilih tanggal PM',
                                        style: TextStyle(
                                          fontSize: 14,
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
                            const SizedBox(height: 20),
                          ],

                          // Keterangan
                          const Text(
                            'Keterangan (Opsional)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _keteranganController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Catatan tambahan...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitInspection,
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
                              _isPMMode ? 'SIMPAN PM' : 'UPDATE HM',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),

                    // Cancel Button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
    _hmController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }
}
