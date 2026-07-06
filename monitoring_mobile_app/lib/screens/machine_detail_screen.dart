import 'package:flutter/material.dart';
import 'lori_detail_screen.dart';
import 'package:intl/intl.dart';
import '../data_store.dart';

class MachineDetailScreen extends StatefulWidget {
  final String machineName;

  const MachineDetailScreen({super.key, required this.machineName});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  final DataStore _dataStore = DataStore();

  // Data Lori (akan di-load dari DataStore)
  List<Map<String, dynamic>> loriList = [];

  @override
  void initState() {
    super.initState();
    _loadLoriList();
  }

  // Load daftar lori dari DataStore
  void _loadLoriList() {
    List<Map<String, dynamic>>? savedList = _dataStore.getLoriList();

    if (savedList != null && savedList.isNotEmpty) {
      // Jika ada data tersimpan, gunakan itu
      loriList = savedList;
      print('[MachineDetail] Loaded ${loriList.length} lori from store');
    } else {
      // Jika belum ada, gunakan default 3 lori
      loriList = [
        {'name': 'Lori No. 1', 'code': 'LORI-001'},
        {'name': 'Lori No. 2', 'code': 'LORI-002'},
        {'name': 'Lori No. 3', 'code': 'LORI-003'},
      ];
      // Simpan ke DataStore
      _dataStore.setLoriList(loriList);
      print('[MachineDetail] Initialized with 3 default lori');
    }
  }

  // Simpan daftar lori ke DataStore
  void _saveLoriList() {
    _dataStore.setLoriList(loriList);
    print('[MachineDetail] Saved ${loriList.length} lori to store');
  }

  // Hitung total Overall Health dari semua Lori (REAL)
  int _calculateTotalOverallHealth() {
    double total = 0;
    int count = 0;

    for (var lori in loriList) {
      String name = lori['name'];
      double loriHealth = _dataStore.getLoriOverallHealth(name);

      if (loriHealth > 0) {
        total += loriHealth;
        count++;
      }
    }

    if (count == 0) return 0;
    return (total / count).toInt();
  }

  @override
  Widget build(BuildContext context) {
    int totalHealth = _calculateTotalOverallHealth();

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
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Health ${widget.machineName}',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Text(
                      '$totalHealth%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: totalHealth > 0
                            ? _getColor(totalHealth)
                            : Colors.grey,
                      ),
                    ),
                    Text(
                      'Total ${loriList.length} Unit ${widget.machineName}',
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
                          totalHealth > 0
                              ? _getColor(totalHealth)
                              : Colors.grey,
                        ),
                      ),
                      Center(
                        child: Icon(
                          totalHealth > 0 ? Icons.check_circle : Icons.info,
                          color: totalHealth > 0
                              ? _getColor(totalHealth)
                              : Colors.grey,
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

          // List Lori
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: loriList.length,
              itemBuilder: (context, index) {
                final lori = loriList[index];
                return _buildLoriCard(lori['name'], lori['code']);
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Terakhir Diperbarui: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1a2332),
        onPressed: _showAddLoriDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLoriCard(String name, String code) {
    // Ambil data dari DataStore
    Map<String, dynamic>? loriData = _dataStore.getLoriData(name);
    bool isSubmitted = loriData != null && loriData['submitted'] == true;

    // Hitung real health dari komponen
    int realHealth = _dataStore.getLoriOverallHealth(name).toInt();
    Color displayColor = realHealth > 0 ? _getColor(realHealth) : Colors.grey;

    return GestureDetector(
      onTap: () {
        if (isSubmitted && loriData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoriDetailScreen(
                loriName: name,
                loriCode: code,
                initialData: loriData,
              ),
            ),
          ).then((_) {
            setState(() {});
          });
        } else if (loriData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoriDetailScreen(
                loriName: name,
                loriCode: code,
                initialData: loriData,
              ),
            ),
          ).then((_) {
            setState(() {});
          });
        } else {
          _showInitialInputDialog(name, code);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSubmitted ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSubmitted
              ? Border.all(color: Colors.green, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSubmitted
                                ? Colors.green[800]
                                : Colors.black,
                          ),
                        ),
                      ),
                      if (isSubmitted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Submitted',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    code,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              '$realHealth%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: displayColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInitialInputDialog(String name, String code) {
    TextEditingController hmSaatIni = TextEditingController();
    TextEditingController hmTerakhirPM = TextEditingController();
    TextEditingController nextPM = TextEditingController();
    TextEditingController sisaHM = TextEditingController();
    TextEditingController inspector = TextEditingController();

    String currentDateTime = DateFormat(
      'dd MMM yyyy HH:mm',
    ).format(DateTime.now());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Input Data Awal - $name'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hmSaatIni,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'HM Saat Ini',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: hmTerakhirPM,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'HM Terakhir PM',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nextPM,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Next PM',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sisaHM,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sisa HM',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: inspector,
                decoration: const InputDecoration(
                  labelText: 'Nama Inspector',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tanggal Inspeksi',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            currentDateTime,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a2332),
            ),
            onPressed: () {
              if (hmSaatIni.text.isEmpty || inspector.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('HM Saat Ini dan Inspector wajib diisi!'),
                  ),
                );
                return;
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoriDetailScreen(
                    loriName: name,
                    loriCode: code,
                    initialData: {
                      'hmSaatIni': hmSaatIni.text,
                      'hmTerakhirPM': hmTerakhirPM.text,
                      'nextPM': nextPM.text,
                      'sisaHM': sisaHM.text,
                      'inspector': inspector.text,
                      'tanggal': currentDateTime,
                    },
                  ),
                ),
              );
            },
            child: const Text('Lanjut', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddLoriDialog() {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Lori Baru'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nama Lori (Opsional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                int nextNum = loriList.length + 1;
                String newName = nameController.text.isNotEmpty
                    ? nameController.text
                    : 'Lori No. $nextNum';
                String newCode = 'LORI-${nextNum.toString().padLeft(3, '0')}';

                // Tambah ke list
                loriList.add({'name': newName, 'code': newCode});

                // ✅ SIMPAN KE DATASTORE
                _saveLoriList();
              });
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Color _getColor(int health) {
    if (health >= 90) return Colors.green;
    if (health >= 70) return Colors.orange;
    return Colors.red;
  }
}
