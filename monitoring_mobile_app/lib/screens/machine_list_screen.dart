import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'machine_detail_screen.dart';
import 'add_machine_screen.dart'; // ✅ TAMBAHKAN IMPORT INI

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

  @override
  void initState() {
    super.initState();
    _loadLoriList();
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
    // ✅ FIXED: Calculation dengan type casting yang benar
    int totalHealth = 0;
    if (_loriList.isNotEmpty) {
      num sum = 0;
      for (var item in _loriList) {
        num healthValue = (item['health_mesin'] ?? 0) as num;
        sum += healthValue;
      }
      totalHealth = (sum ~/ _loriList.length).toInt();
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
                              (lori['health_mesin'] ?? 0).toDouble(),
                              lori['id_mesin'] ?? 0,
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Terakhir Diperbarui: ${DateTime.now().toString().substring(0, 16)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ],
            ),
      // ✅ TAMBAHKAN FLOATING ACTION BUTTON INI
      floatingActionButton: FloatingActionButton.extended(
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

          // Refresh list jika ada data baru
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
      ),
    );
  }

  Widget _buildLoriCard(int number, String name, double health, int machineId) {
    int healthInt = health.toInt();
    Color color = _getColor(healthInt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MachineDetailScreen(machineName: name, machineId: machineId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue, width: 2),
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
            Text(
              '$number.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 15),
            const Icon(Icons.directions_railway, color: Color(0xFF1a2332)),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$healthInt%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
}
