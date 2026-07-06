import 'package:flutter/material.dart';
import 'machine_detail_screen.dart'; // Navigasi ke detail Lori

class MachineListScreen extends StatefulWidget {
  final String stationName;

  const MachineListScreen({super.key, required this.stationName});

  @override
  State<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen> {
  int _selectedIndex = 1;

  // Data Sub-Unit (Mesin) di dalam Station
  final List<Map<String, dynamic>> subUnits = [
    {'name': 'Lori', 'health': 89, 'icon': Icons.directions_railway},
    {'name': 'Capstand', 'health': 94, 'icon': Icons.rotate_right},
    {
      'name': 'Hydraulic Power Unit (HPU)',
      'health': 91,
      'icon': Icons.settings_suggest,
    },
    {'name': 'Transfer Carriage', 'health': 88, 'icon': Icons.swap_horiz},
    {'name': 'Belt Track', 'health': 95, 'icon': Icons.view_stream},
  ];

  @override
  Widget build(BuildContext context) {
    // Hitung Overall Health (Rata-rata)
    int totalHealth =
        subUnits.fold(0, (sum, item) => sum + (item['health'] as int)) ~/
        subUnits.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF1a2332,
        ), // Dark blue header sesuai gambar
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.stationName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Card (Overall Health)
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
                    const Text(
                      'Overall Health',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Text(
                      '${totalHealth.toInt()}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _getColor(totalHealth.toInt()),
                      ),
                    ),
                    Text(
                      '${subUnits.length} Unit Mesin',
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
                          _getColor(totalHealth.toInt()),
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.check_circle,
                          color: _getColor(totalHealth.toInt()),
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

          // List Sub-Unit
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: subUnits.length,
              itemBuilder: (context, index) {
                final unit = subUnits[index];
                return _buildSubUnitCard(
                  index + 1,
                  unit['name'],
                  unit['health'],
                  unit['icon'],
                );
              },
            ),
          ),

          // Footer Last Updated
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Terakhir Diperbarui: 02 Jul 2026 10:30',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubUnitCard(int number, String name, int health, IconData icon) {
    Color color = _getColor(health);
    return GestureDetector(
      onTap: () {
        // Navigasi ke Machine Detail (Lori Overall)
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
          borderRadius: BorderRadius.circular(12),
          border: name == 'Lori'
              ? Border.all(color: Colors.blue, width: 2)
              : null, // Highlight Lori
        ),
        child: Row(
          children: [
            Text(
              '$number.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 15),
            Icon(icon, color: const Color(0xFF1a2332)),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$health%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(int health) {
    if (health >= 90) return Colors.green;
    if (health >= 70) return Colors.orange;
    return Colors.red;
  }
}
