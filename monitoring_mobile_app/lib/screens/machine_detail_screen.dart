import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'lori_detail_screen.dart';
import 'input_inspection_screen.dart'; // ✅ TAMBAHKAN IMPORT

class MachineDetailScreen extends StatefulWidget {
  final String machineName;
  final int machineId;
  final String kodeMesin; // ✅ TAMBAHKAN
  final double currentHM; // ✅ TAMBAHKAN

  const MachineDetailScreen({
    super.key,
    required this.machineName,
    required this.machineId,
    this.kodeMesin = '', // ✅ Default empty
    this.currentHM = 0, // ✅ Default 0
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

  @override
  void initState() {
    super.initState();
    _kodeMesin = widget.kodeMesin;
    _currentHM = widget.currentHM;
    _loadKomponen();
    _loadMachineDetail(); // ✅ Load detail machine
  }

  Future<void> _loadMachineDetail() async {
    try {
      // Ambil detail machine untuk dapat kode_mesin dan hm_current
      final machines = await ApiServices.getMachines(stationId: null);
      final machine = machines.firstWhere(
        (m) => m['id_mesin'] == widget.machineId,
        orElse: () => null,
      );

      if (machine != null) {
        setState(() {
          _kodeMesin = machine['kode_mesin'] ?? '';
          _currentHM = (machine['hm_current'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      print('Error loading machine detail: $e');
    }
  }

  Future<void> _loadKomponen() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      print('=== LOADING KOMPONEN FOR LORI ${widget.machineId} ===');
      final data = await ApiServices.getKomponen(mesinId: widget.machineId);

      print('Komponen loaded: ${data.length}');

      setState(() {
        _komponenList = data;
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
          : Column(
              children: [
                // ✅ MACHINE INFO CARD
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current HM',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_currentHM.toStringAsFixed(0)} Jam',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Komponen',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_komponenList.length} Unit',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ✅ KOMPONEN LIST
                Expanded(
                  child: _komponenList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _komponenList.length,
                          itemBuilder: (context, index) {
                            final komponen = _komponenList[index];
                            return _buildKomponenCard(
                              komponen['nama_komponen'] ?? 'Komponen Unknown',
                              komponen['id_komponen'] ?? 0,
                              komponen['jenis_komponen'] ?? '',
                            );
                          },
                        ),
                ),
              ],
            ),
      // ✅ FLOATING ACTION BUTTON - INPUT INSPEKSI
      floatingActionButton: FloatingActionButton.extended(
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

          // Refresh data jika ada update
          if (result == true) {
            _loadMachineDetail();
            _loadKomponen();
          }
        },
        backgroundColor: const Color(0xFF2196F3),
        icon: const Icon(Icons.add_circle, color: Colors.white),
        label: const Text(
          'Input Inspeksi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
