import 'package:flutter/material.dart';
import '../services/api_services.dart';

class InformasiServiceHistoryScreen extends StatefulWidget {
  final int machineId;
  final String machineName;

  const InformasiServiceHistoryScreen({
    super.key,
    required this.machineId,
    required this.machineName,
  });

  @override
  State<InformasiServiceHistoryScreen> createState() =>
      _InformasiServiceHistoryScreenState();
}

class _InformasiServiceHistoryScreenState
    extends State<InformasiServiceHistoryScreen> {
  List<dynamic> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await ApiServices.getServiceHistory(machineId: widget.machineId);
      setState(() {
        _history = data;
        _loading = false;
      });
    } catch (e) {
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
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Gagal memuat history: $_error'),
                    ],
                  ),
                )
              : _history.isEmpty
                  ? Center(
                      child: Text(
                        'Belum ada history service',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final date =
                            (item['service_date'] ?? '-').toString();
                        final type =
                            (item['service_type'] ?? '-').toString();
                        final before = item['health_mesin_before'] != null
                            ? '${(item['health_mesin_before'] as num).toInt()}%'
                            : '-';
                        final after = item['health_mesin_after'] != null
                            ? '${(item['health_mesin_after'] as num).toInt()}%'
                            : '-';
                        final desc =
                            (item['description'] ?? '').toString();
                        final pic =
                            (item['teknisi_name'] ?? '').toString();
                        final next =
                            (item['next_service_date'] ?? '').toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.06),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '#${item['id_service'] ?? index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1a2332),
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      type,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2196F3),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Tanggal: $date'),
                              if (next.isNotEmpty)
                                Text('Next service: $next'),
                              Text('Before: $before | After: $after'),
                              if (pic.isNotEmpty) Text('Teknisi: $pic'),
                              if (desc.isNotEmpty)
                                Text('Catatan: $desc'),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
