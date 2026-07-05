import 'package:flutter/material.dart';

class PartDetailScreen extends StatefulWidget {
  final String partName;

  const PartDetailScreen({super.key, required this.partName});

  @override
  State<PartDetailScreen> createState() => _PartDetailScreenState();
}

class _PartDetailScreenState extends State<PartDetailScreen> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1a2332)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.partName,
            style: const TextStyle(
              color: Color(0xFF1a2332),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF2196F3),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF2196F3),
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Trend'),
              Tab(text: 'History'),
              Tab(text: 'Document'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab Overview
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar Part
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.circle,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Health Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Health',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a2332),
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            '92%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Excellent',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.92,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Statistik Waktu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatBox('Running Hour', '12,450 hr'),
                      _buildStatBox('Lifetime', '15,000 hr'),
                      _buildStatBox('Remaining', '2,570 hr'),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Spesifikasi Part
                  const Text(
                    'Specifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a2332),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildSpecRow('Type', 'Ball Bearing'),
                  _buildSpecRow('Lubrication', 'Grease'),
                  _buildSpecRow('Condition', 'Normal'),
                  _buildSpecRow('Location', 'DE Side'),
                ],
              ),
            ),
            // Tab Trend (Placeholder)
            const Center(child: Text('Grafik Trend akan ditampilkan di sini')),
            // Tab History (Placeholder)
            const Center(
              child: Text('Riwayat Maintenance akan ditampilkan di sini'),
            ),
            // Tab Document (Placeholder)
            const Center(
              child: Text('Dokumen Manual Book akan ditampilkan di sini'),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(12),
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
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a2332),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1a2332)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1a2332),
            ),
          ),
        ],
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
    if (index == 0)
      Navigator.pushNamed(context, '/dashboard');
    else if (index == 1)
      Navigator.pushNamed(context, '/factory_list');
  }
}
