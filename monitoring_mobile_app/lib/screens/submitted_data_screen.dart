import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data_store.dart';
import 'lori_detail_screen.dart';

class SubmittedDataScreen extends StatefulWidget {
  const SubmittedDataScreen({super.key});

  @override
  State<SubmittedDataScreen> createState() => _SubmittedDataScreenState();
}

class _SubmittedDataScreenState extends State<SubmittedDataScreen> {
  final DataStore _dataStore = DataStore();
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    // Ambil semua data lori yang sudah di-submit
    List<Map<String, dynamic>> submittedData = [];

    _dataStore.loriData.forEach((name, data) {
      if (data['submitted'] == true) {
        submittedData.add({'name': name, 'data': data});
      }
    });

    // Urutkan berdasarkan tanggal submit terbaru
    submittedData.sort((a, b) {
      DateTime dateA = a['data']['submittedAt'] ?? DateTime(2000);
      DateTime dateB = b['data']['submittedAt'] ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Submitted Data',
          style: TextStyle(
            color: Color(0xFF1a2332),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: submittedData.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    'Belum ada data yang di-submit',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: submittedData.length,
              itemBuilder: (context, index) {
                final item = submittedData[index];
                String loriName = item['name'];
                Map<String, dynamic> data = item['data'];

                return _buildSubmittedCard(loriName, data);
              },
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSubmittedCard(String loriName, Map<String, dynamic> data) {
    int health = (data['overallHealth'] ?? 0).toInt();
    Color healthColor = health >= 90
        ? Colors.green
        : (health >= 70 ? Colors.orange : Colors.red);
    String status = health >= 90
        ? 'Baik'
        : (health >= 70 ? 'Perlu Perhatian' : 'Perlu Perbaikan');

    DateTime? submittedAt;
    if (data['submittedAt'] is DateTime) {
      submittedAt = data['submittedAt'];
    } else if (data['submittedAt'] is String) {
      try {
        submittedAt = DateTime.parse(data['submittedAt']);
      } catch (e) {}
    }

    String dateDisplay = submittedAt != null
        ? DateFormat('dd MMM yyyy HH:mm').format(submittedAt)
        : '-';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoriDetailScreen(
              loriName: loriName,
              loriCode: data['code'] ?? '',
              initialData: data,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loriName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a2332),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inspector: ${data['inspector'] ?? '-'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$health%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: healthColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
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
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      'Submitted: $dateDisplay',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
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
      // ✅ Tab Station → Submitted Data
      Navigator.pushNamed(context, '/submitted_data');
    }
  }
}
