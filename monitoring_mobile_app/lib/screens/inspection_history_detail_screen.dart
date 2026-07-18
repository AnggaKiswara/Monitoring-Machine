import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';

class InspectionHistoryDetailScreen extends StatefulWidget {
  final int machineId;
  final int serviceId;
  final String machineName;

  const InspectionHistoryDetailScreen({
    super.key,
    required this.machineId,
    required this.serviceId,
    required this.machineName,
  });

  @override
  State<InspectionHistoryDetailScreen> createState() =>
      _InspectionHistoryDetailScreenState();
}

class _InspectionHistoryDetailScreenState
    extends State<InspectionHistoryDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final data = await ApiServices.getInspectionDetail(
        machineId: widget.machineId,
        serviceId: widget.serviceId,
      );

      setState(() {
        _detail = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  Color _getHealthColor(double health) {
    if (health >= 90) return Colors.green;
    if (health >= 70) return Colors.lightGreen;
    if (health >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getKondisiColor(String kondisi) {
    switch (kondisi) {
      case 'Sangat Baik':
        return Colors.green;
      case 'Baik':
        return Colors.lightGreen;
      case 'Perlu Maintenance':
        return Colors.orange;
      case 'Rusak':
        return Colors.red;
      case 'Tidak Ada':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getKondisiIcon(String kondisi) {
    switch (kondisi) {
      case 'Sangat Baik':
        return Icons.check_circle;
      case 'Baik':
        return Icons.thumb_up;
      case 'Perlu Maintenance':
        return Icons.warning;
      case 'Rusak':
        return Icons.error;
      case 'Tidak Ada':
        return Icons.remove_circle;
      default:
        return Icons.help;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return date.toString();
    }
  }

  // Parse description untuk ambil PIC dan Keterangan
  Map<String, String> _parseDescription(String? description) {
    if (description == null || description.isEmpty) {
      return {'pic': '-', 'keterangan': '-'};
    }

    String pic = description;
    String keterangan = '-';

    // Format: "PIC: nama - keterangan"
    if (description.startsWith('PIC: ')) {
      final content = description.substring(5); // Remove "PIC: "
      final parts = content.split(' - ');
      pic = parts[0];
      if (parts.length > 1) {
        keterangan = parts.sublist(1).join(' - ');
      }
    }

    return {'pic': pic, 'keterangan': keterangan};
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
        title: const Text(
          'Detail Inspeksi',
          style: TextStyle(
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
                      Icon(Icons.error_outline,
                          size: 60, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memuat data',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadDetail,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_detail == null) return const SizedBox.shrink();

    final healthBefore = _toDouble(_detail!['health_mesin_before']);
    final healthAfter = _toDouble(_detail!['health_mesin_after']);
    final parsed = _parseDescription(_detail!['description']);
    final komponenList = _detail!['komponen'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card - Machine & Date
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.machineName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(_detail!['service_date']),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (_detail!['service_type'] ?? 'inspection')
                            .toString()
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Health Before → After Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perubahan Health',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a2332),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Before
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Sebelum',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${healthBefore.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _getHealthColor(healthBefore),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                    ),
                    // After
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Sesudah',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${healthAfter.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _getHealthColor(healthAfter),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Health change indicator
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (healthAfter >= healthBefore
                              ? Colors.green
                              : Colors.red)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          healthAfter >= healthBefore
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 18,
                          color: healthAfter >= healthBefore
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(healthAfter - healthBefore) >= 0 ? '+' : ''}${(healthAfter - healthBefore).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: healthAfter >= healthBefore
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Info Inspeksi Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informasi Inspeksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1a2332),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Tanggal',
                  _formatDate(_detail!['service_date']),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.event,
                  'Inspeksi Selanjutnya',
                  _formatDate(_detail!['next_service_date']),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.person,
                  'PIC',
                  parsed['pic'] ?? '-',
                ),
                if (parsed['keterangan'] != '-') ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.note,
                    'Keterangan',
                    parsed['keterangan'] ?? '-',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Component List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Penilaian Komponen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2332),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a2332).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${komponenList.length} komponen',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1a2332),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Component List
          ...komponenList.map((komponen) {
            final namaKomponen =
                komponen['nama_komponen'] ?? 'Unknown';
            final jenisKomponen = komponen['jenis_komponen'] ?? '';
            final nilai = _toDouble(komponen['nilai']);
            final kondisi = komponen['kondisi'] ?? '-';
            final hasData = komponen['nilai'] != null;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
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
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasData
                          ? _getKondisiColor(kondisi).withOpacity(0.15)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      hasData
                          ? _getKondisiIcon(kondisi)
                          : Icons.help_outline,
                      color: hasData
                          ? _getKondisiColor(kondisi)
                          : Colors.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name & Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaKomponen,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1a2332),
                          ),
                        ),
                        if (jenisKomponen.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            jenisKomponen,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Kondisi Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasData
                              ? _getKondisiColor(kondisi)
                                  .withOpacity(0.15)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hasData ? kondisi : 'Tidak Dinilai',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: hasData
                                ? _getKondisiColor(kondisi)
                                : Colors.grey,
                          ),
                        ),
                      ),
                      if (hasData) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${nilai.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getHealthColor(nilai),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          // ✅ FOTO INSPEKSI (dari upload saat inspeksi)
          _buildPhotoSection(),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    final photos = _detail!['photos'] as List<dynamic>? ?? [];
    if (photos.isEmpty) return const SizedBox.shrink();

    // Base host: baseUrl = http://host:port/api → origin = http://host:port
    final origin = Uri.parse(ApiServices.baseUrl).origin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Foto Inspeksi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a2332),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1a2332).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${photos.length} foto',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a2332),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photos.length,
          itemBuilder: (ctx, i) {
            final photo = photos[i];
            final path = photo['photo_path']?.toString() ?? '';
            final url = path.isNotEmpty ? '$origin/$path' : '';
            final caption = photo['caption']?.toString() ?? '';
            return GestureDetector(
              onTap: () => _showPhotoFullscreen(url, caption),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (c, child, prog) =>
                            prog == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : Container(color: Colors.grey[200]),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showPhotoFullscreen(String url, String caption) {
    if (url.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url, fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Padding(
                padding: EdgeInsets.all(20),
                child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
              ),
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(caption, style: const TextStyle(fontSize: 13)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1a2332),
            ),
          ),
        ),
      ],
    );
  }
}
