import 'package:flutter/material.dart';
import 'lori_detail_screen.dart';
import '../data_store.dart';

class LoriNotificationScreen extends StatefulWidget {
  const LoriNotificationScreen({super.key});

  @override
  State<LoriNotificationScreen> createState() => _LoriNotificationScreenState();
}

class _LoriNotificationScreenState extends State<LoriNotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allLoris = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLoris();
  }

  Future<void> _loadLoris() async {
    final list = DataStore().getLoriList() ?? [];
    final loris = list.map((e) {
      final name = (e['nama_lori'] ?? e['nama_mesin'] ?? e['nama'] ?? 'Lori')
          .toString();
      final code = (e['kode_lori'] ?? e['kode_mesin'] ?? e['kode'] ?? '')
          .toString();
      return {
        'name': name,
        'code': code,
        'data': e,
      };
    }).toList();

    setState(() {
      _allLoris = loris;
      _loading = false;
    });
  }

  double _getHealth(Map<String, dynamic> lori) {
    final name = lori['name'];
    final data = lori['data'];
    final saved = DataStore().getLoriOverallHealth(name);
    if (saved > 0) return saved;

    final fromData = data['health_lori'] ?? data['health_mesin'];
    if (fromData != null) return (fromData is num) ? fromData.toDouble() : 0.0;
    return 0;
  }

  Color _getHealthColor(double health) {
    final h = health.toInt();
    if (h >= 90) return Colors.green;
    if (h >= 60) return Colors.orange;
    return Colors.red;
  }

  List<Map<String, dynamic>> get _goodLoris {
    return _allLoris
        .where((lori) => _getHealth(lori) >= 60)
        .toList()
      ..sort((a, b) => _getHealth(b).compareTo(_getHealth(a)));
  }

  List<Map<String, dynamic>> get _serviceLoris {
    return _allLoris
        .where((lori) => _getHealth(lori) < 60)
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
          'Notifikasi Lori',
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
            Tab(text: 'Bagus'),
            Tab(text: 'Perlu Service'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allLoris.isEmpty
          ? Center(
              child: Text(
                'Belum ada data lori',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_goodLoris, emptyMsg: 'Tidak ada lori dalam kondisi bagus'),
                _buildList(_serviceLoris, emptyMsg: 'Tidak ada lori yang perlu diservice'),
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
        final lori = list[index];
        final name = lori['name'] as String;
        final code = lori['code'] as String;
        final health = _getHealth(lori);
        final color = _getHealthColor(health);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoriDetailScreen(
                  loriName: name,
                  loriCode: code.isEmpty ? name : code,
                  initialData: Map<String, dynamic>.from(lori['data'] ?? {}),
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
                    horizontal: 10,
                    vertical: 4,
                  ),
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
}
