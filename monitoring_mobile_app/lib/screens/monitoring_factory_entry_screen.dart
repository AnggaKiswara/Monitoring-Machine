import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'monitoring_screen.dart';

class MonitoringFactoryEntryScreen extends StatefulWidget {
  final String factoryName;
  final int factoryId;

  const MonitoringFactoryEntryScreen({
    super.key,
    required this.factoryName,
    required this.factoryId,
  });

  @override
  State<MonitoringFactoryEntryScreen> createState() => _MonitoringFactoryEntryScreenState();
}

class _MonitoringFactoryEntryScreenState extends State<MonitoringFactoryEntryScreen> {
  bool _loading = true;
  Map<int, List<dynamic>> _stationMachines = {};
  List<dynamic> _stations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stations = await ApiServices.getStationsByFactory(factoryId: widget.factoryId);
      final Map<int, List<dynamic>> grouped = {};
      for (final s in stations) {
        final stationId = s['id_station'];
        final machines = await ApiServices.getMachines(stationId: stationId);
        grouped[stationId] = machines;
      }

      if (mounted) {
        setState(() {
          _stations = stations;
          _stationMachines = grouped;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.factoryName,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
            const Text(
              'Pilih Mesin Monitoring',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Gagal memuat data: $_error'),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _stations.length,
                  itemBuilder: (context, index) {
                    final station = _stations[index];
                    final stationId = station['id_station'];
                    final stationName = station['nama_station'] ?? 'Station';
                    final machines = _stationMachines[stationId] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            stationName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[700],
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (machines.isEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text('Belum ada mesin', style: TextStyle(color: Colors.grey[500])),
                          )
                        else
                          ...machines.map((m) {
                            final machineId = m['id_mesin'];
                            final name = m['nama_mesin'] ?? 'Mesin';
                            final health = (m['health_mesin'] ?? 0).toDouble();
                            final healthInt = health.round();
                            final color = healthInt >= 90
                                ? Colors.green
                                : healthInt >= 70
                                    ? Colors.orange
                                    : Colors.red;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MonitoringSessionScreen(
                                      machineName: name,
                                      machineId: machineId,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.precision_manufacturing, color: Color(0xFF2196F3)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$healthInt%',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
    );
  }
}
