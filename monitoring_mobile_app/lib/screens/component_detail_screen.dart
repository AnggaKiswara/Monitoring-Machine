import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'component_review_screen.dart';
import '../data_store.dart';

class ComponentDetailScreen extends StatefulWidget {
  final String componentName;
  final String loriName;
  final String loriCode;

  const ComponentDetailScreen({
    super.key,
    required this.componentName,
    required this.loriName,
    required this.loriCode,
  });

  @override
  State<ComponentDetailScreen> createState() => _ComponentDetailScreenState();
}

class _ComponentDetailScreenState extends State<ComponentDetailScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _catatanController = TextEditingController();
  final DataStore _dataStore = DataStore();
  late List<Map<String, dynamic>> _parameters;
  DateTime _tanggalInspeksi = DateTime.now();
  String _inspectorName = '';
  double _komponenWeight = 0.0;
  final TextEditingController _weightController = TextEditingController();
  bool _weightInitialized = false;

  // ✅ Mapping nama komponen -> bobot default sesuai spreadsheet
  // Catatan: nama baru sesuai spreadsheet, sedangkan nama lama tetap dipertahankan
  // dengan bobot 0 agar data tersimpan lama tidak rusak saat migrasi nama komponen.
  static const Map<String, double> _defaultWeights = {
    'Body': 25.0,
    'Siku': 5.0,
    'Steam Spreader': 7.0,
    'Chasis': 25.0,
    'Hook': 10.0,
    'Cover Roda': 8.0,
    'Roda': 15.0,
    'Lantai': 5.0,
  };

  @override
  void initState() {
    super.initState();
    _initializeParameters();
    _loadSavedData();
  }

  void _initializeParameters() {
    final Map<String, List<Map<String, dynamic>>> componentParameters = {
      'Body': [
        {'name': 'Visual Condition', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Karat', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Penyok', 'value': '', 'maxValue': 100, 'unit': '%'},
      ],
      'Siku': [
        {'name': 'Visual Condition', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Retak', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Kekakuan', 'value': '', 'maxValue': 100, 'unit': '%'},
      ],
      'Steam Spreader': [
        {'name': 'Visual Condition', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Tekanan', 'value': '', 'maxValue': 100, 'unit': 'bar'},
        {'name': 'Suhu', 'value': '', 'maxValue': 100, 'unit': '°C'},
      ],
      'Chasis': [
        {'name': 'Visual Condition', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Kelurusan', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Aus', 'value': '', 'maxValue': 100, 'unit': '%'},
      ],
      'Hook': [
        {'name': 'Visual Condition', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Aus', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Deformasi', 'value': '', 'maxValue': 100, 'unit': '%'},
      ],
      'Cover Roda': [
        {'name': 'Visual Condition', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Kebulatan', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Retakan', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Celungan', 'value': '', 'maxValue': 100, 'unit': '%'},
      ],
      'Roda': [
        {'name': 'Visual Condition', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Kebulatan', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Retakan', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Celungan', 'value': '', 'maxValue': 100, 'unit': '%'},
      ],
      'Lantai': [
        {'name': 'Visual Condition', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Karat', 'value': '', 'maxValue': 100, 'unit': '%'},
        {'name': 'Penyok', 'value': '', 'maxValue': 100, 'unit': '%'},
      ],
    };

    _parameters =
        componentParameters[widget.componentName] ??
            [
              {
                'name': 'Visual Condition',
                'value': '',
                'maxValue': 100,
                'unit': '%',
              },
            ];

    for (var param in _parameters) {
      _controllers[param['name']] = TextEditingController();
    }

    // Inisialisasi bobot komponen
    final defaultWeight = _defaultWeights[widget.componentName] ?? 0.0;
    final savedWeight = _dataStore.getKomponenWeight(
      widget.loriName,
      widget.componentName,
    );
    _komponenWeight = savedWeight > 0 ? savedWeight : defaultWeight;
    _weightController.text = _komponenWeight.toStringAsFixed(1);
    _weightInitialized = true;
  }

  // ✅ METHOD YANG DIPERBAIKI - sekarang utuh dan tidak terputus
  void _loadSavedData() {
    // Ambil data Lori (termasuk inspector)
    Map<String, dynamic>? loriData = _dataStore.getLoriData(widget.loriName);
    if (loriData != null) {
      _inspectorName = loriData['inspector'] ?? '';
      if (loriData['tanggal'] != null) {
        if (loriData['tanggal'] is DateTime) {
          _tanggalInspeksi = loriData['tanggal'];
        } else if (loriData['tanggal'] is String) {
          try {
            _tanggalInspeksi = DateTime.parse(loriData['tanggal']);
          } catch (e) {
            _tanggalInspeksi = DateTime.now();
          }
        }
      }
    }

    // Ambil data parameter yang sudah tersimpan untuk komponen ini
    String componentKey = '${widget.loriName}_${widget.componentName}';
    Map<String, dynamic>? savedData = _dataStore.getComponentData(componentKey);

    if (savedData != null) {
      // Isi controller dengan data yang tersimpan
      Map<String, dynamic>? savedParams = savedData['parameters'];
      if (savedParams != null) {
        for (var param in _parameters) {
          String paramName = param['name'];
          if (savedParams.containsKey(paramName)) {
            _controllers[paramName]!.text = savedParams[paramName].toString();
          }
        }
      }

      // Isi catatan jika ada
      if (savedData.containsKey('catatan')) {
        _catatanController.text = savedData['catatan'] ?? '';
      }
    }
  }

  // Simpan data ke session
  void _saveToSession() {
    String componentKey = '${widget.loriName}_${widget.componentName}';

    Map<String, dynamic> parametersMap = {};
    for (var param in _parameters) {
      parametersMap[param['name']] = _controllers[param['name']]!.text;
    }

    Map<String, dynamic> componentData = {
      'parameters': parametersMap,
      'catatan': _catatanController.text,
      'inspector': _inspectorName,
      'tanggal': _tanggalInspeksi,
    };

    _dataStore.setComponentData(componentKey, componentData);

    // ✅ Simpan bobot komponen jika sudah diubah
    if (_weightInitialized) {
      _dataStore.setKomponenWeight(
        widget.loriName,
        widget.componentName,
        _komponenWeight,
      );
    }
  }

  double _calculateHealth() {
    double total = 0;
    int count = 0;

    for (var param in _parameters) {
      String value = _controllers[param['name']]!.text;
      if (value.isNotEmpty) {
        double? numValue = double.tryParse(value);
        if (numValue != null) {
          total += numValue;
          count++;
        }
      }
    }

    if (count == 0) return 0;
    return total / count;
  }

  Widget _buildWeightSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bobot Komponen'),
                const SizedBox(height: 6),
                TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    suffixText: '%',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    setState(() {
                      _komponenWeight = parsed ?? 0.0;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.scale, color: Colors.grey[600]),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _catatanController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double health = _calculateHealth();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2332),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            _saveToSession();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.componentName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Health',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Text(
                      '${health.toInt()}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: health > 0
                            ? _getColor(health.toInt())
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lori: ${widget.loriName}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(
                  height: 80,
                  width: 80,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: health / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          health > 0 ? _getColor(health.toInt()) : Colors.grey,
                        ),
                      ),
                      Center(
                        child: Icon(
                          health > 0 ? Icons.check_circle : Icons.info,
                          color: health > 0
                              ? _getColor(health.toInt())
                              : Colors.grey,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TANGGAL INSPEKSI',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat(
                                  'dd MMM yyyy HH:mm',
                                ).format(_tanggalInspeksi),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Inspector: $_inspectorName',
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
                  const SizedBox(height: 20),

                  const Text(
                    'PARAMETER',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ..._parameters.map(
                    (param) =>
                        _buildParameterInput(param['name'], param['unit']),
                  ),
                  const SizedBox(height: 20),

                  _buildWeightSection(),
                  const SizedBox(height: 20),

                  const Text(
                    'CATATAN',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _catatanController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Tidak ada catatan...',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => _saveToSession(),
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: health > 0
                          ? () {
                              _saveToSession();
                              _navigateToReview(health);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: health > 0
                            ? const Color(0xFF1a2332)
                            : Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lihat Riwayat & Dokumen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterInput(String paramName, String unit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              paramName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 1,
            child: TextField(
              controller: _controllers[paramName],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0-$unit',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: unit,
              ),
              onChanged: (value) {
                setState(() {});
                _saveToSession();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToReview(double health) {
    Map<String, dynamic> parameterData = {};
    for (var param in _parameters) {
      parameterData[param['name']] = _controllers[param['name']]!.text;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComponentReviewScreen(
          componentName: widget.componentName,
          loriName: widget.loriName,
          loriCode: widget.loriCode,
          health: health.toInt(),
          parameters: parameterData,
          catatan: _catatanController.text,
          inspector: _inspectorName,
          tanggal: _tanggalInspeksi,
        ),
      ),
    );
  }

  Color _getColor(int health) {
    if (health >= 90) return Colors.green;
    if (health >= 70) return Colors.orange;
    return Colors.red;
  }
}
