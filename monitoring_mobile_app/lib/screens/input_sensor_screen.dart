import 'package:flutter/material.dart';
import '../services/api_services.dart';

class InputSensorScreen extends StatefulWidget {
  final String machineName;
  final String componentName;
  final int komponenId;

  const InputSensorScreen({
    super.key,
    required this.machineName,
    required this.componentName,
    required this.komponenId,
  });

  @override
  State<InputSensorScreen> createState() => _InputSensorScreenState();
}

class _InputSensorScreenState extends State<InputSensorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nilaiController = TextEditingController();

  List<dynamic> _parameters = [];
  int? _selectedParameterId;
  double? _minValue;
  double? _maxValue;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadParameters();
  }

  Future<void> _loadParameters() async {
    try {
      print('=== LOADING PARAMETERS FOR KOMPONEN ${widget.komponenId} ===');
      final data = await ApiServices.getParametersByKomponen(widget.komponenId);

      print('Parameters loaded: ${data.length}');
      print('Data: $data');

      setState(() {
        _parameters = data;
        _isLoading = false;
        if (_parameters.isNotEmpty) {
          _selectedParameterId = _parameters.first['id_parameter'];
          _minValue =
              (_parameters.first['nilai_min_override'] ??
                      _parameters.first['nilai_min'])
                  ?.toDouble();
          _maxValue =
              (_parameters.first['nilai_max_override'] ??
                      _parameters.first['nilai_max'])
                  ?.toDouble();
        }
      });
    } catch (e) {
      print('Error loading parameters: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat parameter: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onParameterChanged(int? value) {
    setState(() {
      _selectedParameterId = value;
      if (value != null) {
        final selectedParam = _parameters.firstWhere(
          (p) => p['id_parameter'] == value,
        );
        _minValue =
            (selectedParam['nilai_min_override'] ?? selectedParam['nilai_min'])
                ?.toDouble();
        _maxValue =
            (selectedParam['nilai_max_override'] ?? selectedParam['nilai_max'])
                ?.toDouble();
      }
    });
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParameterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih parameter terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      print('=== SUBMITTING SENSOR READING ===');
      print('id_komponen: ${widget.komponenId}');
      print('id_parameter: $_selectedParameterId');
      print('nilai: ${double.parse(_nilaiController.text)}');

      await ApiServices.submitSensorReading(
        idKomponen: widget.komponenId,
        idParameter: _selectedParameterId!,
        nilai: double.parse(_nilaiController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error submitting data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2332),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.machineName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Text(
              'Input ${widget.componentName}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parameters.isEmpty
          ? Center(child: Text('Tidak ada parameter untuk komponen ini'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Komponen
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Komponen: ${widget.componentName}',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dropdown Parameter
                    const Text(
                      'Pilih Parameter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedParameterId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: _parameters.map((param) {
                        return DropdownMenuItem(
                          value: param['id_parameter'],
                          child: Text(
                            '${param['nama_parameter']} (${param['satuan']})',
                          ),
                        );
                      }).toList(),
                      onChanged: _onParameterChanged,
                    ),
                    const SizedBox(height: 8),
                    if (_minValue != null && _maxValue != null)
                      Text(
                        'Range normal: $_minValue - $_maxValue',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 24),

                    // Input Nilai
                    const Text(
                      'Nilai Pengukuran',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nilaiController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Masukkan angka (misal: 85.5)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Nilai wajib diisi';
                        double? parsed = double.tryParse(value);
                        if (parsed == null) return 'Harus berupa angka';
                        if (_minValue != null && parsed < _minValue!)
                          return 'Nilai di bawah minimum ($_minValue)';
                        if (_maxValue != null && parsed > _maxValue!)
                          return 'Nilai di atas maksimum ($_maxValue)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Tombol Simpan
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SIMPAN DATA',
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
    _nilaiController.dispose();
    super.dispose();
  }
}
