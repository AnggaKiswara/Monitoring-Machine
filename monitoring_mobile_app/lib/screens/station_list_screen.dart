import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../app_notify.dart';
import 'machine_list_screen.dart';
import '../providers/auth_providers.dart';

class StationListScreen extends StatefulWidget {
  final String factoryName;
  final int factoryId;

  const StationListScreen({
    super.key,
    required this.factoryName,
    required this.factoryId,
  });

  @override
  State<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  int _selectedIndex = 1;
  List<dynamic> _stations = [];
  bool _loading = true;
  String? _error;
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    _initRole();
    _loadStations();
  }

  Future<void> _initRole() async {
    _canManage = await AuthHelper.canManageFactoryStation();
    if (mounted) setState(() {});
  }

  Future<void> _loadStations() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      print('=== LOADING STATIONS FOR FACTORY ${widget.factoryId} ===');
      // ✅ GANTI: Pakai getStationsByFactory()
      final data = await ApiServices.getStationsByFactory(
        factoryId: widget.factoryId,
      );

      print('Stations loaded: ${data.length}');

      setState(() {
        _stations = data;
        _loading = false;
      });
    } catch (e) {
      print('Error loading stations: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int total = _stations.length;
    int excellent = _stations.where((s) {
      final h = (s['health_station'] ?? 0).toDouble();
      return h >= 95;
    }).length;
    int good = _stations.where((s) {
      final h = (s['health_station'] ?? 0).toDouble();
      return h > 85 && h < 95;
    }).length;
    int satisfactory = _stations.where((s) {
      final h = (s['health_station'] ?? 0).toDouble();
      return h > 60 && h <= 85;
    }).length;
    int poor = _stations
        .where((s) => (s['health_station'] ?? 0).toDouble() <= 60)
        .length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1a2332)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.factoryName,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Text(
              'Station List',
              style: TextStyle(
                color: Color(0xFF1a2332),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
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
                  const Icon(Icons.error, size: 60, color: Colors.red),
                  const SizedBox(height: 20),
                  Text('Error: $_error'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadStations,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search station...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a2332),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Total Station',
                              '$total',
                              Colors.white,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white24,
                            ),
                            _buildStatItem(
                              'Excellent Condition',
                              '$excellent',
                              Colors.green[300]!,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white24, thickness: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Good Condition',
                              '$good',
                              Colors.teal[200]!,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white24,
                            ),
                            _buildStatItem(
                              'Satisfactory Condition',
                              '$satisfactory',
                              Colors.orange[300]!,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white24, thickness: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Poor Condition',
                              '$poor',
                              Colors.red[300]!,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _stations.length,
                    itemBuilder: (context, index) {
                      final station = _stations[index];
                      return _buildStationCard(
                        station['nama_station'] ?? 'Unknown Station',
                        (station['health_station'] ?? 0).toDouble(),
                        _getStationIcon(station['nama_station'] ?? ''),
                        _toInt(station['id_station']),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.white70),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getStationIcon(String stationName) {
    String name = stationName.toLowerCase();
    if (name.contains('loading') || name.contains('ramp'))
      return Icons.local_shipping;
    if (name.contains('sterilizer')) return Icons.eco;
    if (name.contains('digester') || name.contains('press'))
      return Icons.precision_manufacturing;
    if (name.contains('clarification')) return Icons.filter_list;
    if (name.contains('boiler')) return Icons.local_fire_department;
    return Icons.settings;
  }

  Widget _buildStationCard(String name, double health, IconData icon, int stationId) {
    int healthInt = health.toInt();
    Color healthColor = healthInt >= 90
        ? Colors.green
        : (healthInt >= 70 ? Colors.orange : Colors.red);
    String status = healthInt >= 90
        ? 'Excellent'
        : (healthInt >= 70 ? 'Good' : 'Attention');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MachineListScreen(stationName: name, stationId: stationId),
          ),
        );
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1a2332), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a2332),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: healthColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$healthInt%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: healthColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: healthColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: healthColor,
                ),
              ),
            ),
            if (_canManage)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Hapus station',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: () => _confirmDeleteStation(stationId, name),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        _onItemTapped(index);
      },
      selectedItemColor: const Color(0xFF2196F3),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_outlined),
          activeIcon: Icon(Icons.list),
          label: 'Station',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: 'Mill',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          activeIcon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushNamed(context, '/dashboard');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/submitted_data');
    }
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // ✅ Konfirmasi & hapus station (lori di dalamnya ikut terhapus)
  void _confirmDeleteStation(int stationId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Station'),
        content: Text(
          'Yakin hapus "$name"? Semua lori di station ini juga ikut terhapus.',
        ),
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
                await ApiServices.deleteStation(stationId: stationId);
                if (mounted) {
                  AppNotify.success(context, 'Station "$name" dihapus');
                  _loadStations();
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
