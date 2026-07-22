import 'package:flutter/material.dart';
import 'station_list_screen.dart';
import 'module_select_screen.dart';
import '../services/api_services.dart';
import '../app_notify.dart';
import '../providers/auth_providers.dart';

class FactoryListScreen extends StatefulWidget {
  const FactoryListScreen({super.key});

  @override
  State<FactoryListScreen> createState() => _FactoryListScreenState();
}

class _FactoryListScreenState extends State<FactoryListScreen> {
  int _selectedIndex = 1; // Tab "Station/List"
  List<dynamic> _factories = [];
  bool _loading = true;
  String? _error;
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    _initRole();
    _loadFactories();
  }

  Future<void> _initRole() async {
    _canManage = await AuthHelper.canManageFactoryStation();
    if (mounted) setState(() {});
  }

  Future<void> _loadFactories() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final data = await ApiServices.getFactories();
      setState(() {
        _factories = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1a2332)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Factory List',
          style: TextStyle(
            color: Color(0xFF1a2332),
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Gagal: $_error'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadFactories,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                            const Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search factory...',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // List Pabrik
                    Expanded(
                      child: _factories.isEmpty
                          ? const Center(
                              child: Text('Belum ada factory',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _factories.length,
                              itemBuilder: (context, index) {
                                final f = _factories[index];
                                final name = f['nama_factory']?.toString() ?? 'Unknown';
                                final loc = f['lokasi_factory']?.toString() ?? '-';
                                final health = _toInt(f['health_factory']);
                                return _buildFactoryCard(
                                  name,
                                  loc,
                                  health,
                                  _toInt(f['id_factory']),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: _showAddFactoryDialog,
              backgroundColor: const Color(0xFF2196F3),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Factory',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFactoryCard(String name, String location, int health, int factoryId) {
    Color healthColor = health >= 90
        ? Colors.green
        : (health >= 70 ? Colors.orange : Colors.red);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModuleSelectScreen(
              factoryName: name,
              factoryId: factoryId,
            ),
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
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.factory,
                color: Color(0xFF2196F3),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a2332),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    location,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: healthColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Health $health%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: healthColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_canManage)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Hapus factory',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
                onPressed: () => _confirmDeleteFactory(factoryId, name),
              ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ✅ Dialog tambah factory → auto-buat station + machine "Loading Ramp"
  void _showAddFactoryDialog() {
    final nameCtl = TextEditingController();
    final locCtl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Tambah Factory'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Factory',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locCtl,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setSt(() => isSaving = true);
                      try {
                        // 1️⃣ Factory
                        final factory = await ApiServices.createFactory(
                          namaFactory: nameCtl.text.trim(),
                          lokasiFactory: locCtl.text.trim(),
                        );
                        final factoryId = _toInt(factory['id_factory']);
                        // 2️⃣ Station default
                        final station = await ApiServices.createStation(
                          factoryId: factoryId,
                          namaStation: 'Main Station',
                        );
                        final stationId = _toInt(station['id_station']);
                        // 3️⃣ Machine "Loading Ramp" (kosong, komponen auto)
                        await ApiServices.createMachine(
                          stationId: stationId,
                          kodeMesin: 'LR-001',
                          namaMesin: 'Loading Ramp',
                        );
                        if (mounted) Navigator.pop(ctx);
                        _loadFactories();
                        AppNotify.success(context,
                            'Factory + Loading Ramp berhasil dibuat');
                      } catch (e) {
                        setSt(() => isSaving = false);
                        AppNotify.error(context, 'Gagal: $e');
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan'),
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
        setState(() {
          _selectedIndex = index;
        });
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

  // ✅ Konfirmasi & hapus factory (cascade: station + lori ikut terhapus)
  void _confirmDeleteFactory(int factoryId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Factory'),
        content: Text(
          'Yakin hapus "$name"? Semua station & lori di dalamnya juga ikut terhapus.',
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
                await ApiServices.deleteFactory(factoryId: factoryId);
                  if (mounted) {
                    AppNotify.success(context, 'Factory "$name" dihapus');
                    _loadFactories();
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
