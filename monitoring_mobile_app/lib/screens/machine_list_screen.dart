import 'package:flutter/material.dart';
import 'machine_detail_screen.dart';
// Nanti kita akan import machine_detail_screen.dart di sini

class MachineListScreen extends StatefulWidget {
  final String stationName;

  const MachineListScreen({super.key, required this.stationName});

  @override
  State<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen> {
  int _selectedIndex = 1;

  // Data Dummy untuk Mesin
  final List<Map<String, dynamic>> machines = [
    {
      'name': 'Sterilizer 1',
      'status': 'Running',
      'health': 95,
      'icon': Icons.precision_manufacturing,
    },
    {
      'name': 'Sterilizer 2',
      'status': 'Running',
      'health': 92,
      'icon': Icons.precision_manufacturing,
    },
    {
      'name': 'Sterilizer 3',
      'status': 'Running',
      'health': 71,
      'icon': Icons.precision_manufacturing,
    },
    {
      'name': 'Sterilizer 4',
      'status': 'Breakdown',
      'health': 40,
      'icon': Icons.precision_manufacturing,
    },
  ];

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.stationName,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Text(
              'Machine List',
              style: TextStyle(
                color: Color(0xFF1a2332),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Column(
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
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search machine...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List Mesin
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: machines.length,
              itemBuilder: (context, index) {
                final machine = machines[index];
                return _buildMachineCard(
                  machine['name'],
                  machine['status'],
                  machine['health'],
                  machine['icon'],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildMachineCard(
    String name,
    String status,
    int health,
    IconData icon,
  ) {
    // Tentukan warna status
    bool isBreakdown = status == 'Breakdown';
    Color statusColor = isBreakdown ? Colors.red : Colors.green;
    Color healthColor = health >= 90
        ? Colors.green
        : (health >= 70 ? Colors.orange : Colors.red);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MachineDetailScreen(machineName: name),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Mesin
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1a2332), size: 24),
            ),
            const SizedBox(width: 15),

            // Nama & Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a2332),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Health Percentage
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Health $health%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: healthColor,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: health / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                    minHeight: 4,
                  ),
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
    if (index == 0)
      Navigator.pushNamed(context, '/dashboard');
    else if (index == 1)
      Navigator.pushNamed(context, '/factory_list');
  }
}
