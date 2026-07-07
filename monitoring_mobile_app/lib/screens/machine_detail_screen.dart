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
  List<Map<String, dynamic>> loriList = [];

  @override
  void initState() {
    super.initState();
    _loadLoriList();
  }

  void _loadLoriList() {
    List<Map<String, dynamic>>? savedList = _dataStore.getLoriList();

    if (savedList != null && savedList.isNotEmpty) {
      loriList = savedList;
      print('[MachineDetail] Loaded ${loriList.length} lori from store');
    } else {
      loriList = [
        {'name': 'Lori No. 1', 'code': 'LORI-001'},
        {'name': 'Lori No. 2', 'code': 'LORI-002'},
        {'name': 'Lori No. 3', 'code': 'LORI-003'},
      ];
      _dataStore.setLoriList(loriList);
      print('[MachineDetail] Initialized with 3 default lori');
    }
  }

  void _saveLoriList() {
    _dataStore.setLoriList(loriList);
    print('[MachineDetail] Saved ${loriList.length} lori to store');
  }

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
    Map<String, dynamic>? loriData = _dataStore.getLoriData(name);
    bool isSubmitted = loriData != null && loriData['submitted'] == true;

    int realHealth = _dataStore.getLoriOverallHealth(name).toInt();
    Color displayColor = realHealth > 0 ? _getColor(realHealth) : Colors.grey;

    return GestureDetector(
      onTap: () {
        if (loriData != null) {
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
    TextEditingController inspectorController = TextEditingController();

    DateTime today = DateTime.now();
    String todayFormatted = DateFormat('dd MMM yyyy').format(today);

    DateTime lastCheckDate = today;
    String lastCheckFormatted = todayFormatted;

    DateTime nextPMDate = lastCheckDate.add(const Duration(days: 7));
    String nextPMFormatted = DateFormat('dd MMM yyyy').format(nextPMDate);

    int sisaHari = nextPMDate.difference(today).inDays;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Input Data Inspeksi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Tanggal Inspeksi (Read-only)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Inspeksi (Hari Ini)',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            todayFormatted,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Terakhir PM (Date Picker)
                GestureDetector(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: lastCheckDate,
                      firstDate: DateTime(2020),
                      lastDate: today,
                    );
                    if (picked != null) {
                      setDialogState(() {
                        lastCheckDate = picked;
                        lastCheckFormatted = DateFormat(
                          'dd MMM yyyy',
                        ).format(picked);

                        nextPMDate = picked.add(const Duration(days: 7));
                        nextPMFormatted = DateFormat(
                          'dd MMM yyyy',
                        ).format(nextPMDate);

                        sisaHari = nextPMDate.difference(today).inDays;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terakhir PM',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.history,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lastCheckFormatted,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Next PM (Read-only)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Next PM (+7 Hari)',
                        style: TextStyle(fontSize: 11, color: Colors.blue),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.event, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            nextPMFormatted,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Sisa Hari (Countdown)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sisaHari <= 3
                        ? Colors.red[50]
                        : (sisaHari <= 7
                              ? Colors.orange[50]
                              : Colors.green[50]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: sisaHari <= 3
                          ? Colors.red[300]!
                          : (sisaHari <= 7
                                ? Colors.orange[300]!
                                : Colors.green[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: sisaHari <= 3
                            ? Colors.red
                            : (sisaHari <= 7 ? Colors.orange : Colors.green),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sisa ${sisaHari} hari',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: sisaHari <= 3
                              ? Colors.red[900]
                              : (sisaHari <= 7
                                    ? Colors.orange[900]
                                    : Colors.green[900]),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        sisaHari <= 3
                            ? '⚠️ Segera'
                            : (sisaHari <= 7 ? '⚡ Segera' : '✅ Aman'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sisaHari <= 3
                              ? Colors.red[900]
                              : (sisaHari <= 7
                                    ? Colors.orange[900]
                                    : Colors.green[900]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 5. Inspector (Manual Input)
                TextField(
                  controller: inspectorController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Inspector',
                    hintText: 'Masukkan nama inspector',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
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
                if (inspectorController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inspector wajib diisi!')),
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
                        'tanggalInspeksi': today.toIso8601String(),
                        'tanggalInspeksiDisplay': todayFormatted,
                        'lastCheckPM': lastCheckDate.toIso8601String(),
                        'lastCheckPMDisplay': lastCheckFormatted,
                        'nextPM': nextPMDate.toIso8601String(),
                        'nextPMDisplay': nextPMFormatted,
                        'sisaHari': sisaHari,
                        'inspector': inspectorController.text,
                      },
                    ),
                  ),
                );
              },
              child: const Text(
                'Lanjut',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
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

                loriList.add({'name': newName, 'code': newCode});
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
