import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smk_sigumpar/presentation/features/student/providers/student_provider.dart';
import 'package:smk_sigumpar/presentation/features/academic/providers/academic_provider.dart';
import 'package:smk_sigumpar/presentation/common/widgets/loading_widget.dart';
import 'package:smk_sigumpar/presentation/common/widgets/error_widget.dart';
import 'package:smk_sigumpar/data/models/grade_model.dart';

class RekapNilaiScreen extends StatefulWidget {
  const RekapNilaiScreen({super.key});

  @override
  State<RekapNilaiScreen> createState() => _RekapNilaiScreenState();
}

class _RekapNilaiScreenState extends State<RekapNilaiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String? _selectedKelasId;
  String? _selectedMapelId;
  String _selectedTahun = '2024/2025';
  String _selectedSemester = 'ganjil';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final academic = context.read<AcademicProvider>();
      academic.fetchClasses(refresh: true);
      academic.fetchSubjects(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _tampilkanRekap() {
    if (_selectedKelasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kelas terlebih dahulu')),
      );
      return;
    }

    context.read<StudentProvider>().fetchGrades(
      classId: _selectedKelasId!,
      semester: _selectedSemester,
      academicYear: _selectedTahun,
      mapelId: _selectedMapelId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E6091),
        elevation: 0,
        title: const Text('Rekap Nilai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Rekap Nilai'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRekapTab(),
          const Center(child: Text('Riwayat Rekap Nilai')),
        ],
      ),
    );
  }

  Widget _buildRekapTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rekap Nilai Siswa (Wali Kelas)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                ),
                const SizedBox(height: 16),
                _buildFiltersCard(),
              ],
            ),
          ),
        ),
        
        Consumer<StudentProvider>(
          builder: (context, provider, child) {
            if (provider.gradeState == StudentLoadState.loading) {
              return const SliverFillRemaining(child: Center(child: LoadingWidget()));
            }
            if (provider.gradeState == StudentLoadState.error) {
              return SliverFillRemaining(
                child: AppErrorWidget(
                  message: provider.gradeError ?? 'Gagal memuat rekap', 
                  onRetry: _tampilkanRekap
                )
              );
            }
            if (provider.gradeState == StudentLoadState.initial) {
              return SliverToBoxAdapter(child: _buildEmptyState());
            }

            final allGrades = provider.grades;
            if (allGrades.isEmpty) {
              return const SliverFillRemaining(child: Center(child: Text('Tidak ada data nilai')));
            }

            return ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, searchVal, _) {
                final filteredGrades = allGrades.where((g) {
                  if (searchVal.text.isEmpty) return true;
                  return g.studentName.toLowerCase().contains(searchVal.text.toLowerCase());
                }).toList();

                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _buildSummaryStats(filteredGrades),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: _buildGradesHeader(),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildGradeRow(filteredGrades[index], index),
                          childCount: filteredGrades.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 700;
                return isWide ? _buildWideFilters() : _buildNarrowFilters();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideFilters() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _buildKelasDropdown()),
        const SizedBox(width: 12),
        Expanded(child: _buildMapelDropdown()),
        const SizedBox(width: 12),
        Expanded(child: _buildTahunDropdown()),
        const SizedBox(width: 12),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildNarrowFilters() {
    return Column(
      children: [
        _buildKelasDropdown(),
        const SizedBox(height: 12),
        _buildMapelDropdown(),
        const SizedBox(height: 12),
        _buildTahunDropdown(),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: _buildSubmitButton()),
      ],
    );
  }

  Widget _buildKelasDropdown() {
    return Selector<AcademicProvider, List<dynamic>>(
      selector: (_, p) => p.classes,
      builder: (context, classes, _) {
        return _DropdownField(
          label: 'KELAS',
          hint: '-- Pilih Kelas --',
          initialValue: _selectedKelasId,
          items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.namaKelas))).toList(),
          onChanged: (val) => setState(() => _selectedKelasId = val),
        );
      },
    );
  }

  Widget _buildMapelDropdown() {
    return Selector<AcademicProvider, List<dynamic>>(
      selector: (_, p) => p.subjects,
      builder: (context, subjects, _) {
        return _DropdownField(
          label: 'MATA PELAJARAN',
          hint: 'Semua Mapel',
          initialValue: _selectedMapelId,
          items: [
            const DropdownMenuItem(value: null, child: Text('Semua Mapel')),
            ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.namaMapel, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (val) => setState(() => _selectedMapelId = val),
        );
      },
    );
  }

  Widget _buildTahunDropdown() {
    return _DropdownField(
      label: 'TAHUN AJAR',
      initialValue: _selectedTahun,
      items: const [
        DropdownMenuItem(value: '2024/2025', child: Text('2024/2025')),
        DropdownMenuItem(value: '2023/2024', child: Text('2023/2024')),
      ],
      onChanged: (val) => setState(() => _selectedTahun = val!),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _tampilkanRekap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3182CE),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.search, size: 20),
      label: const Text('Tampilkan Rekap', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSummaryStats(List<GradeModel> grades) {
    if (grades.isEmpty) return const SizedBox.shrink();
    
    double avg = grades.map((g) => g.nilaiAkhir).reduce((a, b) => a + b) / grades.length;
    double highest = grades.map((g) => g.nilaiAkhir).reduce((a, b) => a > b ? a : b);
    double lowest = grades.map((g) => g.nilaiAkhir).reduce((a, b) => a < b ? a : b);
    int passed = grades.where((g) => g.nilaiAkhir >= 70).length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatCard('Rata-rata', avg.toStringAsFixed(1), Icons.analytics, Colors.blue),
        _buildStatCard('Tertinggi', highest.toStringAsFixed(0), Icons.trending_up, Colors.orange),
        _buildStatCard('Terendah', lowest.toStringAsFixed(0), Icons.trending_down, Colors.pink),
        _buildStatCard('Lulus (≥70)', '$passed/${grades.length}', Icons.check_circle, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGradesHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Rekap Nilai Siswa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF2D3748),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(
            children: [
              SizedBox(width: 30, child: Text('NO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text('NAMA SISWA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(child: Text('TGS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(child: Text('UTS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(child: Text('UAS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(child: Text('AKHIR', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradeRow(GradeModel g, int index) {
    final bool isEven = index % 2 == 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFF7FAFC),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('${index + 1}', style: const TextStyle(fontSize: 11))),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.studentName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(g.nisn ?? '-', style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(child: Text(g.tugas.toStringAsFixed(0), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(g.uts.toStringAsFixed(0), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(g.uas.toStringAsFixed(0), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPredikatColor(g.letterGrade).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  g.nilaiAkhir.toStringAsFixed(1),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getPredikatColor(g.letterGrade)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPredikatColor(String grade) {
    switch (grade) {
      case 'A': return Colors.green;
      case 'B': return Colors.blue;
      case 'C': return Colors.orange;
      case 'D': return Colors.deepOrange;
      default: return Colors.red;
    }
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Pilih Filter Rekap Nilai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Klik Tampilkan Rekap untuk memuat data', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? hint;
  final dynamic initialValue;
  final List<DropdownMenuItem<dynamic>> items;
  final ValueChanged<dynamic> onChanged;

  const _DropdownField({required this.label, this.hint, this.initialValue, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF718096))),
        const SizedBox(height: 6),
        DropdownButtonFormField<dynamic>(
          initialValue: initialValue,
          hint: hint != null ? Text(hint!, style: const TextStyle(fontSize: 13)) : null,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            isDense: true,
            fillColor: Colors.white,
            filled: true,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
