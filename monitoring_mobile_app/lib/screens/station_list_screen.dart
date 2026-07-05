import 'package:flutter/material.dart';
import 'machine_list_screen.dart';

class StationListScreen extends StatefulWidget {
  final String factoryName; // <-- Parameter factoryName

  const StationListScreen({
    super.key,
    required this.factoryName, // <-- Wajib diisi
  });

  @override
  State<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  int _selectedIndex = 1;

  // Data Dummy untuk Station
  final List<Map<String, dynamic>> stations = [
    {'name': 'Loading Ramp', 'health': 97, 'icon': Icons.local_shipping},
    {'name': 'Press', 'health': 87, 'icon': Icons.settings},
    {'name': 'Clarification', 'health': 81, 'icon': Icons.filter_list},
    {'name': 'Turbine', 'health': 87, 'icon': Icons.wind_power},
    {'name': 'Kernel', 'health': 92, 'icon': Icons.grain},
    {'name': 'Boiler', 'health': 90, 'icon': Icons.local_fire_department},
    {'name': 'Sterilizer', 'health': 95, 'icon': Icons.water_drop},
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
              widget.factoryName, // <-- Gunakan widget.factoryName
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

          // Overall Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1a2332),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', '7', Colors.white),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _buildStatItem('Good', '5', Colors.green[300]!),
                  Container(width: 1, height: 30, color: Colors.white24),
                  _buildStatItem('Alert', '2', Colors.orange[300]!),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // List Station
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: stations.length,
              itemBuilder: (context, index) {
                final station = stations[index];
                return _buildStationCard(
                  station['name'],
                  station['health'],
                  station['icon'],
                );
              },
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildStationCard(String name, int health, IconData icon) {
    Color healthColor;
    String status;

    if (health >= 90) {
      healthColor = Colors.green;
      status = 'Excellent';
    } else if (health >= 70) {
      healthColor = Colors.orange;
      status = 'Good';
    } else {
      healthColor = Colors.red;
      status = 'Attention';
    }
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MachineListScreen(stationName: name),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1a2332), size: 24),
            ),
            const SizedBox(width: 15),

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
                const SizedBox(height: 4),
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
      Navigator.pushNamed(context, '/factory_list');
    }
  }
}
