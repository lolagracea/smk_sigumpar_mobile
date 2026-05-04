// lib/features/vokasi/pkl_nilai/presentation/screens/pkl_input_nilai_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smk_sigumpar/core/constants/app_colors.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/models/pkl_input_nilai_model.dart';
import '../providers/pkl_nilai_provider.dart';

class PklInputNilaiScreen extends StatefulWidget {
  const PklInputNilaiScreen({super.key});

  @override
  State<PklInputNilaiScreen> createState() => _PklInputNilaiScreenState();
}

class _PklInputNilaiScreenState extends State<PklInputNilaiScreen> {
  @override
  void initState() {
    super.initState();
    // Load daftar kelas saat screen pertama dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PklNilaiProvider>().loadKelas();
    });
  }

  // ── Warna predikat ─────────────────────────────────────────
  Color _predikatColor(String predikat) {
    switch (predikat) {
      case 'Sangat Baik':
        return AppColors.success;
      case 'Baik':
        return AppColors.info;
      case 'Cukup':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }

  Color _predikatBgColor(String predikat) {
    switch (predikat) {
      case 'Sangat Baik':
        return AppColors.successLight;
      case 'Baik':
        return AppColors.infoLight;
      case 'Cukup':
        return AppColors.warningLight;
      default:
        return AppColors.errorLight;
    }
  }

  // ── Snackbar helper ────────────────────────────────────────
  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<PklNilaiProvider>(
      builder: (context, provider, _) {
        // Tampilkan snackbar saat ada pesan
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (provider.successMessage != null) {
            _showSnackBar(provider.successMessage!);
            provider.clearMessages();
          } else if (provider.error != null && provider.sudahCari) {
            _showSnackBar(provider.error!, isError: true);
            provider.clearMessages();
          }
        });

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Input Nilai PKL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Data siswa dari Tata Usaha — nilai disimpan di database',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: AppColors.border, height: 1),
            ),
          ),
          body: Column(
            children: [
              // ── Panel filter kelas ───────────────────────────
              _buildFilterPanel(provider),

              // ── Konten utama ─────────────────────────────────
              Expanded(
                child: _buildBody(provider),
              ),
            ],
          ),

          // ── Tombol simpan (FAB) ──────────────────────────────
          floatingActionButton: provider.sudahCari && provider.rows.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: provider.isSaving
                      ? null
                      : () => _konfirmasiSimpan(provider),
                  backgroundColor: AppColors.vocational,
                  foregroundColor: Colors.white,
                  icon: provider.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label:
                      Text(provider.isSaving ? 'Menyimpan...' : 'Simpan Nilai'),
                )
              : null,
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────
  // WIDGET: Panel filter (pilih kelas + tombol tampilkan)
  // ──────────────────────────────────────────────────────────
  Widget _buildFilterPanel(PklNilaiProvider provider) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label ──────────────────────────────────────────
          const Text(
            'PILIH KELAS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          // ── Dropdown + tombol ───────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildKelasDropdown(provider),
              ),
              const SizedBox(width: 10),
              _buildTampilkanButton(provider),
            ],
          ),
          const SizedBox(height: 10),

          // ── Info box ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 15, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daftar siswa diambil dari data Tata Usaha. '
                    'Nilai PKL yang sudah diinput sebelumnya akan tampil otomatis.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.warning,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dropdown Kelas ─────────────────────────────────────────
  Widget _buildKelasDropdown(PklNilaiProvider provider) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClassModel>(
          value: provider.selectedKelas,
          isExpanded: true,
          hint: const Text(
            '-- Pilih Kelas --',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textPrimary,
          ),
          items: provider.kelasList
              .map(
                (k) => DropdownMenuItem<ClassModel>(
                  value: k,
                  child: Text(k.namaKelas),
                ),
              )
              .toList(),
          onChanged:
              provider.isLoading ? null : (val) => provider.selectKelas(val),
        ),
      ),
    );
  }

  // ── Tombol Tampilkan Siswa ─────────────────────────────────
  Widget _buildTampilkanButton(PklNilaiProvider provider) {
    return ElevatedButton.icon(
      onPressed: provider.isLoading || provider.selectedKelas == null
          ? null
          : () => provider.fetchSiswaWithNilai(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        disabledBackgroundColor: AppColors.grey300,
      ),
      icon: provider.isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.play_arrow_rounded, size: 18),
      label: const Text(
        'Tampilkan Siswa',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // WIDGET: Body utama
  // ──────────────────────────────────────────────────────────
  Widget _buildBody(PklNilaiProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.vocational),
            SizedBox(height: 12),
            Text('Memuat data...',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (!provider.sudahCari) {
      return _buildEmptyState();
    }

    if (provider.rows.isEmpty) {
      return _buildNoDataState();
    }

    return _buildSiswaList(provider);
  }

  // ── Empty state (belum pilih kelas) ───────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.vocational.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              size: 48,
              color: AppColors.vocational.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pilih kelas dan klik\n"Tampilkan Siswa"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── No data state ─────────────────────────────────────────
  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 48, color: AppColors.grey400),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada siswa di kelas ini',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // WIDGET: Daftar siswa dengan input nilai
  // ──────────────────────────────────────────────────────────
  Widget _buildSiswaList(PklNilaiProvider provider) {
    return Column(
      children: [
        // ── Header info kelas ────────────────────────────────
        _buildKelasHeader(provider),

        // ── List siswa ───────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: provider.rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final row = provider.rows[index];
              return _buildSiswaCard(
                row: row,
                nomor: index + 1,
                provider: provider,
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Header kelas (ringkasan) ───────────────────────────────
  Widget _buildKelasHeader(PklNilaiProvider provider) {
    final jumlah = provider.rows.length;
    final kelas = provider.selectedKelas;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.class_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kelas: ${kelas?.namaKelas ?? '-'}  •  $jumlah siswa',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // WIDGET: Card satu siswa
  // ──────────────────────────────────────────────────────────
  Widget _buildSiswaCard({
    required PklNilaiSiswaModel row,
    required int nomor,
    required PklNilaiProvider provider,
  }) {
    final nilaiAkhir = row.nilaiAkhir ?? 0;
    final predikat = row.predikat;
    final predColor = _predikatColor(predikat);
    final predBg = _predikatBgColor(predikat);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header card: avatar + nama + predikat ───────────
          _buildCardHeader(
            row: row,
            nomor: nomor,
            predikat: predikat,
            predColor: predColor,
            predBg: predBg,
          ),

          Divider(height: 1, color: AppColors.border),

          // ── Body card: input nilai ───────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // ── Tempat PKL ────────────────────────────────
                if (row.tempatPkl != null && row.tempatPkl!.isNotEmpty)
                  _buildTempatPkl(row.tempatPkl!),

                // ── Input nilai + nilai akhir ──────────────────
                Row(
                  children: [
                    // Nilai Industri
                    Expanded(
                      child: _buildNilaiInput(
                        label: 'Nilai Industri',
                        initialValue: row.nilaiIndustri,
                        icon: Icons.factory_outlined,
                        color: AppColors.vocational,
                        onChanged: (val) {
                          provider.updateNilai(
                            siswaId: row.siswaId,
                            field: 'industri',
                            value: val,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Nilai Sekolah
                    Expanded(
                      child: _buildNilaiInput(
                        label: 'Nilai Sekolah',
                        initialValue: row.nilaiSekolah,
                        icon: Icons.school_outlined,
                        color: AppColors.primary,
                        onChanged: (val) {
                          provider.updateNilai(
                            siswaId: row.siswaId,
                            field: 'sekolah',
                            value: val,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Nilai Akhir (read-only)
                    _buildNilaiAkhir(
                      nilai: nilaiAkhir,
                      predikat: predikat,
                      predColor: predColor,
                      predBg: predBg,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header card ───────────────────────────────────────────
  Widget _buildCardHeader({
    required PklNilaiSiswaModel row,
    required int nomor,
    required String predikat,
    required Color predColor,
    required Color predBg,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          // Nomor urut
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$nomor',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar inisial
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.vocational.withOpacity(0.12),
            child: Text(
              row.inisial,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.vocational,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nama & NIS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.namaSiswa,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (row.nis != null && row.nis!.isNotEmpty)
                  Text(
                    'NIS: ${row.nis}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),

          // Predikat badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: predBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: predColor.withOpacity(0.3)),
            ),
            child: Text(
              predikat,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: predColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tempat PKL chip ───────────────────────────────────────
  Widget _buildTempatPkl(String tempat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              tempat,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Input nilai ───────────────────────────────────────────
  Widget _buildNilaiInput({
    required String label,
    required double? initialValue,
    required IconData icon,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue?.toStringAsFixed(0) ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?')),
          ],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(
                color: AppColors.grey400, fontWeight: FontWeight.normal),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            filled: true,
            fillColor: color.withOpacity(0.03),
          ),
          onChanged: (val) {
            final parsed = double.tryParse(val) ?? 0;
            final clamped = parsed.clamp(0.0, 100.0);
            onChanged(clamped);
          },
        ),
      ],
    );
  }

  // ── Nilai akhir (read-only display) ───────────────────────
  Widget _buildNilaiAkhir({
    required double nilai,
    required String predikat,
    required Color predColor,
    required Color predBg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Nilai Akhir',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: predBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: predColor.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              nilai.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: predColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // Dialog konfirmasi simpan
  // ──────────────────────────────────────────────────────────
  Future<void> _konfirmasiSimpan(PklNilaiProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(Icons.save_rounded, color: AppColors.vocational, size: 22),
            const SizedBox(width: 8),
            const Text('Simpan Nilai PKL'),
          ],
        ),
        content: Text(
          'Nilai PKL untuk kelas '
          '${provider.selectedKelas?.namaKelas ?? '-'} '
          '(${provider.rows.length} siswa) akan disimpan ke database.\n\n'
          'Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vocational,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await provider.saveNilai();
    }
  }
}
