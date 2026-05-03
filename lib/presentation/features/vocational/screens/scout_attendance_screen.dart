import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_names.dart';
import '../providers/vocational_provider.dart';
import '../widgets/pramuka_drawer.dart';

class ScoutAttendanceScreen extends StatefulWidget {
  const ScoutAttendanceScreen({super.key});

  @override
  State<ScoutAttendanceScreen> createState() => _ScoutAttendanceScreenState();
}

class _ScoutAttendanceScreenState extends State<ScoutAttendanceScreen> {
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VocationalProvider>();
      provider.fetchScoutClasses();
      provider.fetchScoutAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Absensi Pramuka'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tambah Absensi',
            onPressed: () => _showAbsensiForm(context),
          ),
        ],
      ),
      drawer: const PramukaDrawer(currentRoute: RouteNames.scoutAttendance),
      body: Consumer<VocationalProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Filter kelas
              _buildFilterBar(provider),
              // Daftar absensi
              Expanded(
                child: provider.scoutAttendance.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => provider.fetchScoutAttendance(
                          refresh: true,
                          classId: _selectedClassId,
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.scoutAttendance.length,
                          itemBuilder: (context, index) {
                            return _buildAttendanceCard(
                              provider.scoutAttendance[index],
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(VocationalProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedClassId,
                hint: const Text('Semua Kelas', style: TextStyle(fontSize: 14)),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Semua Kelas')),
                  ...provider.scoutClasses.map((k) {
                    final id = k['id']?.toString() ?? '';
                    final name = k['nama'] ?? k['name'] ?? 'Kelas';
                    return DropdownMenuItem(value: id, child: Text(name));
                  }),
                ],
                onChanged: (val) {
                  setState(() => _selectedClassId = val);
                  provider.fetchScoutAttendance(
                    refresh: true,
                    classId: val,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> item) {
    final hadir = item['hadir'] ?? item['present'] ?? 0;
    final total = item['total'] ?? 0;
    final tanggal = item['tanggal'] ?? item['date'] ?? '';
    final namaKelas = item['nama_kelas'] ?? item['class_name'] ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fact_check_rounded,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaKelas,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tanggal.isNotEmpty ? tanggal : '-',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$hadir/$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Belum ada data absensi',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showAbsensiForm(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Absensi'),
          ),
        ],
      ),
    );
  }

  void _showAbsensiForm(BuildContext context) {
    final provider = context.read<VocationalProvider>();
    String? selectedClass;
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Absensi Pramuka',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Kelas / Regu',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: provider.scoutClasses.map((k) {
                  return DropdownMenuItem(
                    value: k['id']?.toString() ?? '',
                    child: Text(k['nama'] ?? k['name'] ?? '-'),
                  );
                }).toList(),
                onChanged: (val) => setModalState(() => selectedClass = val),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: dateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: const Icon(Icons.calendar_today_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedClass == null
                      ? null
                      : () async {
                          final success = await provider.submitScoutAttendance({
                            'class_id': selectedClass,
                            'tanggal': dateController.text,
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Absensi berhasil disimpan'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            provider.fetchScoutAttendance(refresh: true);
                          }
                        },
                  child: const Text('Simpan Absensi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}