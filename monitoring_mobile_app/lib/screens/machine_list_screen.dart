import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../app_notify.dart';
import 'machine_detail_screen.dart';
import 'add_machine_screen.dart';
import '../providers/auth_providers.dart';

class MachineListScreen extends StatefulWidget {
  final String stationName;
  final int stationId;

  const MachineListScreen({
    super.key,
    required this.stationName,
    required this.stationId,
  });

  @override
  State<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen> {
  List<dynamic> _loriList = [];
  bool _loading = true;
  String? _error;

  // ✅ HELPER FUNCTION - Konversi aman ke double
  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  // ✅ HELPER FUNCTION - Konversi aman ke int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  bool _canManageLori = false;

  @override
  void initState() {
    super.initState();
    _initRole();
    _loadLoriList();
  }

  Future<void> _initRole() async {
    _canManageLori = await AuthHelper.canManageLori();
    if (mounted) setState(() {});
  }

  Future<void> _loadLoriList() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      print('=== LOADING LORI FOR STATION ${widget.stationId} ===');
      final data = await ApiServices.getMachines(stationId: widget.stationId);

      print('Lori loaded: ${data.length}');

      setState(() {
        _loriList = data;
        _loading = false;
      });
    } catch (e) {
      print('Error loading lori: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Pakai helper function untuk konversi
    int totalHealth = 0;
    if (_loriList.isNotEmpty) {
      double sum = 0;
      for (var item in _loriList) {
        sum += _toDouble(item['health_mesin']);
      }
      totalHealth = (sum / _loriList.length).round();
    }

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
          widget.stationName,
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
                    onPressed: _loadLoriList,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : Column(
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
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 5),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overall Health',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          Text(
                            '$totalHealth%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _getColor(totalHealth),
                            ),
                          ),
                          Text(
                            '${_loriList.length} Unit Lori',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 80,
                        width: 80,
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: totalHealth / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getColor(totalHealth),
                              ),
                            ),
                            Center(
                              child: Icon(
                                Icons.check_circle,
                                color: _getColor(totalHealth),
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
                  child: _loriList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.train,
                                size: 80,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Belum ada Lori di Station ini',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _loriList.length,
                          itemBuilder: (context, index) {
                            final lori = _loriList[index];
                            return _buildLoriCard(
                              index + 1,
                              lori['nama_mesin'] ?? 'Lori Unknown',
                              _toDouble(lori['health_mesin']),
                              _toInt(lori['id_mesin']),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
              ],
            ),
      floatingActionButton: _canManageLori
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMachineScreen(
                      stationId: widget.stationId,
                      stationName: widget.stationName,
                    ),
                  ),
                );

                if (result == true) {
                  _loadLoriList();
                }
              },
              backgroundColor: const Color(0xFF2196F3),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tambah Lori',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildLoriCard(int number, String name, double health, int machineId) {
    int healthInt = health.toInt();
    Color color = _getColor(healthInt);

    final lori = _loriList.firstWhere(
      (l) => _toInt(l['id_mesin']) == machineId,
      orElse: () => {},
    );

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MachineDetailScreen(
              machineName: name,
              machineId: machineId,
              kodeMesin: lori.isNotEmpty
                  ? (lori['kode_mesin']?.toString() ?? '')
                  : '',
              currentHM: lori.isNotEmpty ? _toDouble(lori['hm_current']) : 0,
            ),
          ),
        );
        _loadLoriList();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Nomor urut
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1a2332).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2332),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Icon lori (truk)
            Icon(Icons.local_shipping, color: const Color(0xFF1a2332), size: 22),
            const SizedBox(width: 12),
            // Nama + kode
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (lori.isNotEmpty &&
                      lori['kode_mesin'] != null &&
                      lori['kode_mesin'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Kode: ${lori['kode_mesin']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
            // Health badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$healthInt%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Tombol hapus (admin & staff)
            if (_canManageLori)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Hapus lori',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: () => _confirmDeleteLori(machineId, name),
              ),
          ],
        ),
      ),
    );
  }

  Color _getColor(int health) {
    if (health >= 90) return Colors.green;
    if (health >= 70) return Colors.orange;
    return Colors.red;
  }

  // ✅ Konfirmasi & hapus lori
  void _confirmDeleteLori(int machineId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Lori'),
        content: Text('Yakin hapus "$name"? Data inspeksi lori ini juga ikut terhapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiServices.deleteMachine(machineId: machineId);
                if (mounted) {
                  AppNotify.success(context, 'Lori "$name" dihapus');
                  _loadLoriList();
                }
              } catch (e) {
                if (mounted) {
                  AppNotify.error(context, 'Gagal: $e');
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
