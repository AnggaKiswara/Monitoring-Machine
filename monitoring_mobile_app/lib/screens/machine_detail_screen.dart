import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';
import 'lori_detail_screen.dart';
import 'input_inspection_screen.dart';

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

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  List<dynamic> _komponenList = [];
  bool _loading = true;
  String? _error;
  String _kodeMesin = '';
  double _currentHM = 0;

  // ✅ Inspection data
  DateTime? _lastPMDate;
  DateTime? _nextPMDate;
  String? _picName;
  int _komponenCount = 0;

  // ✅ Helper function
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

  @override
  void initState() {
    super.initState();
    _kodeMesin = widget.kodeMesin;
    _currentHM = widget.currentHM;
    _loadKomponen();
    _loadMachineDetail();
    _loadInspectionData(); // ✅ Load inspection data
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
      // Get service history
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
          _picName =
              lastInspection['description']; // PIC name stored in description
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
          widget.machineName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 60, color: Colors.red),
                  const SizedBox(height: 20),
                  Text('Error: $_error'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadKomponen,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ✅ UPDATED CARD WITH INSPECTION DATA & BUTTON
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
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
                        // Header: Machine Info
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
                                    _kodeMesin.isNotEmpty
                                        ? _kodeMesin
                                        : 'No Code',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
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
                        const SizedBox(height: 20),

                        // ✅ Inspection Info
                        if (_lastPMDate != null || _picName != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Inspeksi Terakhir',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.event,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'PM: ${_formatDate(_lastPMDate)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_nextPMDate != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Next PM: ${_formatDate(_nextPMDate)} (${_calculateDaysRemaining(_nextPMDate)} hari)',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (_picName != null &&
                                    _picName!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'PIC: $_picName',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        if (_lastPMDate != null || _picName != null)
                          const SizedBox(height: 16),

                        // ✅ BUTTON INSIDE CARD
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InputInspectionScreen(
                                    machineId: widget.machineId,
                                    machineName: widget.machineName,
                                    kodeMesin: _kodeMesin,
                                    currentHM: _currentHM,
                                  ),
                                ),
                              );

                              if (result == true) {
                                _loadMachineDetail();
                                _loadKomponen();
                                _loadInspectionData();
                              }
                            },
                            icon: Icon(
                              _lastPMDate != null
                                  ? Icons.edit_note
                                  : Icons.add_circle,
                              color: _lastPMDate != null
                                  ? Colors.white
                                  : const Color(0xFF1976D2),
                              size: 20,
                            ),
                            label: Text(
                              _lastPMDate != null
                                  ? 'Update Keterangan'
                                  : 'Input Keterangan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _lastPMDate != null
                                    ? Colors.white
                                    : const Color(0xFF1976D2),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _lastPMDate != null
                                  ? const Color(
                                      0xFFFF9800,
                                    ) // Orange jika sudah ada data
                                  : Colors.white, // Putih jika belum ada data
                              foregroundColor: _lastPMDate != null
                                  ? Colors.white
                                  : const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Komponen List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text(
                          'Daftar Komponen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1a2332),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_komponenCount item',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _komponenList.isEmpty
                      ? Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.settings,
                                size: 80,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Belum ada Komponen untuk Lori ini',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Tambahkan via Database',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _komponenList.length,
                          itemBuilder: (context, index) {
                            final komponen = _komponenList[index];
                            return _buildKomponenCard(
                              komponen['nama_komponen'] ?? 'Komponen Unknown',
                              _toInt(komponen['id_komponen']),
                              komponen['jenis_komponen'] ?? '',
                            );
                          },
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildKomponenCard(String name, int komponenId, String jenis) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoriDetailScreen(
              loriName: widget.machineName,
              loriCode: 'KOMP-$komponenId',
              initialData: {
                'id_komponen': komponenId,
                'nama_komponen': name,
                'jenis_komponen': jenis,
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.build_circle,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a2332),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      jenis,
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
