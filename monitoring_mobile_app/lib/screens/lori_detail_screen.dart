import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'component_detail_screen.dart';
import '../data_store.dart';

class LoriDetailScreen extends StatefulWidget {
  final String loriName;
  final String loriCode;
  final Map<String, dynamic> initialData;

  const LoriDetailScreen({
    super.key,
    required this.loriName,
    required this.loriCode,
    required this.initialData,
  });

  @override
  State<LoriDetailScreen> createState() => _LoriDetailScreenState();
}

class _LoriDetailScreenState extends State<LoriDetailScreen> {
  late Map<String, dynamic> loriData;
  final DataStore _dataStore = DataStore();

  final List<Map<String, dynamic>> komponenList = [
    {'name': 'Roda', 'icon': Icons.circle},
    {'name': 'Bushing', 'icon': Icons.circle},
    {'name': 'Bearing', 'icon': Icons.circle},
    {'name': 'Siku', 'icon': Icons.circle},
    {'name': 'Body samping', 'icon': Icons.circle},
    {'name': 'Body depan belakang', 'icon': Icons.circle},
    {'name': 'Hook', 'icon': Icons.circle},
    {'name': 'Steam Spreader', 'icon': Icons.circle},
    {'name': 'Frame', 'icon': Icons.circle},
  ];

  @override
  void initState() {
    super.initState();
    loriData = Map<String, dynamic>.from(widget.initialData);

    // Parse tanggal-tanggal dari string ke DateTime jika perlu
    _parseDateField('tanggalInspeksi');
    _parseDateField('lastCheckPM');
    _parseDateField('nextPM');
    _parseDateField('submittedAt');

    // Fallback: jika masih pakai format lama (key 'tanggal')
    if (loriData['tanggal'] != null && loriData['tanggalInspeksi'] == null) {
      loriData['tanggalInspeksi'] = loriData['tanggal'];
      loriData['tanggalInspeksiDisplay'] = DateFormat(
        'dd MMM yyyy',
      ).format(loriData['tanggalInspeksi']);
    }

    _saveDataToStore();
    print('=== LORI DETAIL INIT ===');
    print('Lori Name: ${widget.loriName}');
    print('Initial Data: $loriData');
    print('========================');
  }

  void _parseDateField(String key) {
    if (loriData[key] is String) {
      try {
        loriData[key] = DateTime.parse(loriData[key]);
      } catch (e) {
        // ignore
      }
    }
  }

  void _saveDataToStore() {
    _dataStore.setLoriData(widget.loriName, loriData);
    print('Data saved to store: $loriData');
  }

  double _calculateOverallHealth() {
    return _dataStore.getLoriOverallHealth(widget.loriName);
  }

  void _submitAllData() {
    print('=== SUBMITTING DATA ===');

    loriData['submitted'] = true;
    loriData['submittedAt'] = DateTime.now();
    loriData['overallHealth'] = _calculateOverallHealth();

    _saveDataToStore();

    print('Final Data: $loriData');
    print('======================');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Berhasil Disimpan'),
        content: const Text(
          'Semua data inspeksi untuk Lori ini telah disimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double overallHealth = _calculateOverallHealth();
    int healthInt = overallHealth.toInt();
    String status = healthInt >= 90
        ? 'Baik'
        : (healthInt >= 70 ? 'Perlu Perhatian' : 'Perlu Perbaikan');
    Color statusColor = healthInt >= 90
        ? Colors.green
        : (healthInt >= 70 ? Colors.orange : Colors.red);

    // Format tanggal untuk ditampilkan
    String tanggalInspeksiDisplay = '-';
    if (loriData['tanggalInspeksiDisplay'] != null) {
      tanggalInspeksiDisplay = loriData['tanggalInspeksiDisplay'];
    } else if (loriData['tanggalInspeksi'] is DateTime) {
      tanggalInspeksiDisplay = DateFormat(
        'dd MMM yyyy',
      ).format(loriData['tanggalInspeksi']);
    } else if (loriData['tanggalInspeksi'] is String) {
      tanggalInspeksiDisplay = loriData['tanggalInspeksi'];
    }

    String lastCheckDisplay = loriData['lastCheckPMDisplay'] ?? '-';
    String nextPMDisplay = loriData['nextPMDisplay'] ?? '-';
    int sisaHari = (loriData['sisaHari'] ?? 0) is int
        ? loriData['sisaHari']
        : int.tryParse(loriData['sisaHari'].toString()) ?? 0;

    return WillPopScope(
      onWillPop: () async {
        _saveDataToStore();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFF1a2332),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              _saveDataToStore();
              Navigator.pop(context);
            },
          ),
          title: Text(
            widget.loriName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Health Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                          ),
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
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '$healthInt%',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: healthInt > 0
                                      ? statusColor
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (healthInt > 0
                                              ? statusColor
                                              : Colors.grey)
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Status: ${healthInt > 0 ? status : "Belum Diinspeksi"}',
                                  style: TextStyle(
                                    color: healthInt > 0
                                        ? statusColor
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 100,
                            width: 100,
                            child: Stack(
                              children: [
                                CircularProgressIndicator(
                                  value: overallHealth / 100,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    healthInt > 0 ? statusColor : Colors.grey,
                                  ),
                                ),
                                Center(
                                  child: Icon(
                                    healthInt > 0
                                        ? Icons.check_circle
                                        : Icons.info,
                                    color: healthInt > 0
                                        ? statusColor
                                        : Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ✅ INFO CARDS (SISTEM TANGGAL)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildInfoCard(
                          'Tanggal Inspeksi',
                          tanggalInspeksiDisplay,
                          Icons.calendar_today,
                          Colors.blue,
                        ),
                        _buildInfoCard(
                          'Terakhir PM',
                          lastCheckDisplay,
                          Icons.history,
                          Colors.orange,
                        ),
                        _buildInfoCard(
                          'Next PM',
                          nextPMDisplay,
                          Icons.event,
                          Colors.green,
                        ),
                        _buildSisaHariCard(sisaHari),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Inspector Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.purple,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Inspector',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  loriData['inspector'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1a2332),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Komponen List
                    Text(
                      'KOMPONEN (${komponenList.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...komponenList.map((k) {
                      String componentName = k['name'] as String;
                      int health = _dataStore.getComponentHealth(
                        widget.loriName,
                        componentName,
                      );
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComponentDetailScreen(
                                componentName: componentName,
                                loriName: widget.loriName,
                                loriCode: widget.loriCode,
                              ),
                            ),
                          ).then((_) {
                            setState(() {});
                          });
                        },
                        child: _buildKomponenItem(componentName, health),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _submitAllData,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text(
                    'Kirim Data Lori',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a2332),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Info Card dengan warna dinamis
  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2332),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Card Sisa Hari dengan countdown color
  Widget _buildSisaHariCard(int sisaHari) {
    Color bgColor;
    Color textColor;
    String status;
    IconData icon;

    if (sisaHari <= 0) {
      bgColor = Colors.red[50]!;
      textColor = Colors.red[900]!;
      status = 'Overdue!';
      icon = Icons.error;
    } else if (sisaHari <= 3) {
      bgColor = Colors.red[50]!;
      textColor = Colors.red[900]!;
      status = 'Segera';
      icon = Icons.warning;
    } else if (sisaHari <= 7) {
      bgColor = Colors.orange[50]!;
      textColor = Colors.orange[900]!;
      status = 'Segera';
      icon = Icons.timer;
    } else {
      bgColor = Colors.green[50]!;
      textColor = Colors.green[900]!;
      status = 'Aman';
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: textColor, size: 20),
              Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$sisaHari hari',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const Text(
            'Sisa Hari',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildKomponenItem(String name, int health) {
    Color color = health >= 90
        ? Colors.green
        : (health >= 70
              ? Colors.orange
              : (health > 0 ? Colors.red : Colors.grey));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '$health%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ],
      ),
    );
  }
}
