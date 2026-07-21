import 'package:flutter/material.dart';
import 'machine_detail_screen.dart';
import '../services/api_services.dart';

class ServiceNotificationScreen extends StatefulWidget {
  const ServiceNotificationScreen({super.key});

  @override
  State<ServiceNotificationScreen> createState() =>
      _ServiceNotificationScreenState();
}

class _ServiceNotificationScreenState extends State<ServiceNotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _machines = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final data = await ApiServices.getMachines();

      setState(() {
        _machines = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  double _getHealth(Map<String, dynamic> machine) {
    final health = machine['health_mesin'];
    if (health == null) return 0;
    if (health is num) return health.toDouble();
    return double.tryParse(health.toString()) ?? 0;
  }

  Color _getHealthColor(double health) {
    final h = health.toInt();
    if (h >= 90) return Colors.green;
    if (h >= 60) return Colors.orange;
    return Colors.red;
  }

  List<Map<String, dynamic>> get _goodMachines {
    return _machines
        .where((m) => _getHealth(m) >= 85)
        .toList()
      ..sort((a, b) => _getHealth(b).compareTo(_getHealth(a)));
  }

  List<Map<String, dynamic>> get _serviceMachines {
    return _machines
        .where((m) => _getHealth(m) < 85)
        .toList()
      ..sort((a, b) => _getHealth(a).compareTo(_getHealth(b)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2332),
        elevation: 0,
        title: const Text(
          'Service Notification',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF2196F3),
          tabs: const [
            Tab(text: 'Baik'),
            Tab(text: 'Perlu Service'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _machines.isEmpty
                  ? _buildEmptyState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_goodMachines,
                            emptyMsg: 'Tidak ada mesin dalam kondisi baik'),
                        _buildList(_serviceMachines,
                            emptyMsg: 'Tidak ada mesin yang perlu diservice'),
                      ],
                    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadMachines,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.precision_manufacturing,
              size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'Belum ada data mesin',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> list, {
    required String emptyMsg,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              emptyMsg,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final machine = list[index];
        final name = (machine['nama_mesin'] ?? 'Unknown Machine').toString();
        final code = (machine['kode_mesin'] ?? '').toString();
        final health = _getHealth(machine);
        final color = _getHealthColor(health);
        final machineId = (machine['id_mesin'] is num)
            ? (machine['id_mesin'] as num).toInt()
            : int.tryParse(machine['id_mesin'].toString()) ?? 0;

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MachineDetailScreen(
                  machineName: name,
                  machineId: machineId,
                  kodeMesin: code,
                  currentHM: _toDouble(machine['hm_current']),
                ),
              ),
            );
            _loadMachines();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.precision_manufacturing, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1a2332),
                        ),
                      ),
                      Text(
                        code.isEmpty ? '-' : code,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${health.toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
