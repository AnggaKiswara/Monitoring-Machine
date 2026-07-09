import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'lori_detail_screen.dart';

class MachineDetailScreen extends StatefulWidget {
  final String machineName;
  final int machineId;

  const MachineDetailScreen({
    super.key,
    required this.machineName,
    required this.machineId,
  });

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  List<dynamic> _komponenList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKomponen();
  }

  Future<void> _loadKomponen() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      print('=== LOADING KOMPONEN FOR LORI ${widget.machineId} ===');
      // ✅ FIXED: ApiServices (dengan 's')
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
          : _komponenList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  Text(
                    'Belum ada Komponen untuk Lori ini',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tambahkan via Database',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
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
