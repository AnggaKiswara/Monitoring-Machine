import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../app_notify.dart';
import 'machine_detail_screen.dart';

class InformasiServiceScreen extends StatefulWidget {
  const InformasiServiceScreen({super.key});

  @override
  State<InformasiServiceScreen> createState() => _InformasiServiceScreenState();
}

class _InformasiServiceScreenState extends State<InformasiServiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _machines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMachines();
  }

  Future<void> _loadMachines() async {
    try {
      final list = await ApiServices.getMachines();
      setState(() {
        _machines = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) AppNotify.error(context, 'Gagal memuat data machine: $e');
    }
  }

  double _getHealth(Map<String, dynamic> machine) {
    final h = machine['health_mesin'] ?? machine['health_overall'];
    if (h == null) return 0.0;
    if (h is num) return h.toDouble();
    return double.tryParse(h.toString()) ?? 0.0;
  }

  Color _getHealthColor(double health) {
    final h = health.toInt();
    if (h >= 95) return Colors.green;
    if (h > 85) return Colors.teal;
    if (h > 60) return Colors.orange;
    return Colors.red;
  }

  List<Map<String, dynamic>> get _goodMachines {
    final filtered = _machines
        .where((m) {
          if (m is! Map<String, dynamic>) return false;
          return _getHealth(m) >= 85;
        })
        .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
        .toList();
    filtered.sort((a, b) => _getHealth(b).compareTo(_getHealth(a)));
    return filtered;
  }

  List<Map<String, dynamic>> get _serviceMachines {
    final filtered = _machines
        .where((m) {
          if (m is! Map<String, dynamic>) return false;
          return _getHealth(m) < 85;
        })
        .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
        .toList();
    filtered.sort((a, b) => _getHealth(a).compareTo(_getHealth(b)));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a2332),
        elevation: 0,
        leading: BackButton(color: Colors.white),
        title: const Text(
          'Informasi Service',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFF2196F3),
          tabs: const [
            Tab(text: 'Perlu Service'),
            Tab(text: 'Baik'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _machines.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada data machine',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(
                      _serviceMachines,
                      emptyMsg: 'Tidak ada machine yang perlu diservice',
                    ),
                    _buildList(
                      _goodMachines,
                      emptyMsg: 'Tidak ada machine dalam kondisi baik',
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
        child: Text(
          emptyMsg,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final machine = list[index];
        final name = (machine['nama_mesin'] ?? machine['nama'] ?? 'Machine')
            .toString();
        final code = (machine['kode_mesin'] ?? machine['kode'] ?? '').toString();
        final health = _getHealth(machine);
        final color = _getHealthColor(health);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MachineDetailScreen(
                  machineId: _toInt(machine['id_mesin'] ?? machine['id']),
                  machineName: name,
                ),
              ),
            );
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
                      const SizedBox(height: 3),
                      Text(
                        code.isEmpty ? '-' : code,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
