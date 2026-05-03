// lib/features/guru_mapel/input_nilai/presentation/pages/input_nilai_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/models/shared_models.dart';
import '../../../../../shared/widgets/app_widgets.dart';
import '../../data/models/nilai_model.dart';
import '../../data/repositories/nilai_repository.dart';
import '../bloc/nilai_bloc.dart';

class InputNilaiPage extends StatefulWidget {
  const InputNilaiPage({super.key});
  @override State<InputNilaiPage> createState() => _InputNilaiPageState();
}

class _InputNilaiPageState extends State<InputNilaiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    context.read<NilaiBloc>().add(NilaiLoadMaster());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NilaiBloc, NilaiState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          AppWidgets.showSuccess(context, state.successMessage!);
        }
        if (state.error != null) {
          AppWidgets.showError(context, state.error!);
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            _buildHeader(context, state),
            const Divider(height: 1),

            // ── Filter Panel ─────────────────────────────────────────────
            _buildFilterPanel(context, state),
            const Divider(height: 1),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildInputTab(context, state),
                  _buildRiwayatTab(context, state),
                  _buildRekapTab(context, state),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, NilaiState state) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Title with left border accent
          Row(
            children: [
              Container(
                width: 4, height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text('Input & Kelola Nilai',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
            ],
          ),
          const Spacer(),
          // Atur Bobot button
          OutlinedButton.icon(
            onPressed: () => _showAturBobot(context),
            icon: const Icon(Icons.tune_rounded,
                size: 16, color: Color(0xFFE65100)),
            label: Row(
              children: [
                const Text('Atur Bobot',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('100%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      )),
                ),
              ],
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 0),
        ],
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w400),
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: EdgeInsets.zero,
        tabs: [
          _buildTab(Icons.edit_rounded, 'Input Nilai'),
          _buildTab(Icons.history_rounded, 'Riwayat'),
          _buildTab(Icons.bar_chart_rounded, 'Rekap'),
        ],
      ),
    );
  }

  Tab _buildTab(IconData icon, String label) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }

  // ── Filter Panel ─────────────────────────────────────────────────────────────
  Widget _buildFilterPanel(BuildContext context, NilaiState state) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          // Tab bar
          _buildTabBar(),
          const SizedBox(height: 12),
          // Filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: LayoutBuilder(builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              if (isNarrow) {
                return Column(
                  children: [
                    Row(children: [
                      Expanded(child: _buildMapelDropdown(context, state)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildKelasDropdown(context, state)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _buildTahunDropdown(context, state)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSearchField()),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _buildCariButton(context, state)),
                      const SizedBox(width: 8),
                      _buildResetButton(context),
                    ]),
                  ],
                );
              }
              return Row(
                children: [
                  _buildFilterLabel('MAPEL'),
                  const SizedBox(width: 6),
                  SizedBox(width: 160,
                      child: _buildMapelDropdown(context, state)),
                  const SizedBox(width: 12),
                  _buildFilterLabel('KELAS'),
                  const SizedBox(width: 6),
                  SizedBox(width: 150,
                      child: _buildKelasDropdown(context, state)),
                  const SizedBox(width: 12),
                  _buildFilterLabel('TAHUN AJAR'),
                  const SizedBox(width: 6),
                  SizedBox(width: 130,
                      child: _buildTahunDropdown(context, state)),
                  const SizedBox(width: 12),
                  _buildFilterLabel('CARI NAMA'),
                  const SizedBox(width: 6),
                  SizedBox(width: 160, child: _buildSearchField()),
                  const SizedBox(width: 8),
                  _buildCariButton(context, state),
                  const SizedBox(width: 6),
                  _buildResetButton(context),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterLabel(String text) {
    return Text(text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ));
  }

  Widget _buildMapelDropdown(BuildContext context, NilaiState state) {
    return _FilterDropdown<MapelModel>(
      hint: '-- Pilih Mapel --',
      value: state.selectedMapel,
      items: state.mapelList,
      label: (e) => e.namaMapel,
      onChanged: (v) =>
          context.read<NilaiBloc>().add(NilaiMapelChanged(v)),
      allowNull: true,
    );
  }

  Widget _buildKelasDropdown(BuildContext context, NilaiState state) {
    return _FilterDropdown<KelasModel>(
      hint: '-- Pilih Kelas --',
      value: state.selectedKelas,
      items: state.kelasList,
      label: (e) => e.namaKelas,
      onChanged: (v) {
        if (v != null) {
          context.read<NilaiBloc>().add(NilaiKelasChanged(v));
        }
      },
    );
  }

  Widget _buildTahunDropdown(BuildContext context, NilaiState state) {
    return _FilterDropdown<String>(
      hint: 'Tahun Ajar',
      value: state.tahunAjar,
      items: AppConstants.tahunAjarOptions,
      label: (e) => e,
      onChanged: (v) {
        if (v != null) {
          context.read<NilaiBloc>().add(NilaiTahunChanged(v));
        }
      },
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Ketik nama...',
          hintStyle: const TextStyle(
              fontSize: 13, color: AppColors.textTertiary),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 1.5),
          ),
          fillColor: AppColors.surface,
          filled: true,
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13),
        onChanged: (v) => setState(() => _search = v),
      ),
    );
  }

  Widget _buildCariButton(BuildContext context, NilaiState state) {
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: state.selectedKelas == null
            ? null
            : () => context.read<NilaiBloc>().add(NilaiFetch()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: const Text('CARI',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.white,
            )),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: () {
          _searchCtrl.clear();
          setState(() => _search = '');
          context.read<NilaiBloc>().add(NilaiLoadMaster());
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text('RESET',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            )),
      ),
    );
  }

  // ── Tab 1: Input Nilai ───────────────────────────────────────────────────────
  Widget _buildInputTab(BuildContext context, NilaiState state) {
    if (state.isLoading || state.isLoadingMaster) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!state.sudahCari) {
      return AppWidgets.emptyState(
        icon: Icons.search_rounded,
        title: 'Pilih filter dan tekan CARI',
        subtitle: 'Pilih Mapel, Kelas, dan Tahun Ajar\nlalu tekan tombol CARI',
      );
    }
    if (state.rows.isEmpty) {
      return AppWidgets.emptyState(
        icon: Icons.inbox_rounded,
        title: 'Tidak ada data siswa',
        subtitle: 'Tidak ditemukan siswa untuk filter ini',
      );
    }

    final filtered = state.rows.where((r) {
      if (_search.isEmpty) return true;
      return r.namaSiswa.toLowerCase().contains(_search.toLowerCase()) ||
          (r.nis ?? '').toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Bobot info bar
        _BobotBar(),
        // Table header
        _TableHeader(),
        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, i) => _NilaiRow(
              model: filtered[i],
              index: i,
              onUpdate: (field, val) => context
                  .read<NilaiBloc>()
                  .add(NilaiUpdate(filtered[i].siswaId, field, val)),
            ),
          ),
        ),
        // Save button
        if (state.sudahCari && state.rows.isNotEmpty)
          _SaveBar(state: state),
      ],
    );
  }

  // ── Tab 2: Riwayat ───────────────────────────────────────────────────────────
  Widget _buildRiwayatTab(BuildContext context, NilaiState state) {
    return AppWidgets.emptyState(
      icon: Icons.history_rounded,
      title: 'Riwayat Nilai',
      subtitle: 'Pilih filter dan tekan CARI\nuntuk melihat riwayat nilai',
    );
  }

  // ── Tab 3: Rekap ─────────────────────────────────────────────────────────────
  Widget _buildRekapTab(BuildContext context, NilaiState state) {
    return AppWidgets.emptyState(
      icon: Icons.bar_chart_rounded,
      title: 'Rekap Nilai',
      subtitle: 'Pilih filter dan tekan CARI\nuntuk melihat rekap nilai',
    );
  }

  // ── Atur Bobot Dialog ────────────────────────────────────────────────────────
  void _showAturBobot(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AturBobotDialog(),
    );
  }
}

// ── Bobot Bar ─────────────────────────────────────────────────────────────────
class _BobotBar extends StatelessWidget {
  final _items = const [
    _BobotItem('Tugas',   '15%', AppColors.primary),
    _BobotItem('Kuis',    '15%', AppColors.secondary),
    _BobotItem('UTS',     '20%', AppColors.warning),
    _BobotItem('UAS',     '30%', AppColors.error),
    _BobotItem('Praktik', '20%', AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Bobot: ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: _items.map((e) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: e.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: e.color.withOpacity(0.3)),
                ),
                child: Text('${e.label} ${e.bobot}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: e.color,
                    )),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BobotItem {
  final String label;
  final String bobot;
  final Color  color;
  const _BobotItem(this.label, this.bobot, this.color);
}

// ── Table Header ──────────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: const [
          SizedBox(width: 30,
              child: Text('No', style: _headerStyle)),
          SizedBox(width: 80,
              child: Text('NIS', style: _headerStyle)),
          Expanded(
              child: Text('Nama Siswa', style: _headerStyle)),
          SizedBox(width: 70,
              child: Text('Tugas', style: _headerStyle,
                  textAlign: TextAlign.center)),
          SizedBox(width: 70,
              child: Text('Kuis', style: _headerStyle,
                  textAlign: TextAlign.center)),
          SizedBox(width: 70,
              child: Text('UTS', style: _headerStyle,
                  textAlign: TextAlign.center)),
          SizedBox(width: 70,
              child: Text('UAS', style: _headerStyle,
                  textAlign: TextAlign.center)),
          SizedBox(width: 70,
              child: Text('Praktik', style: _headerStyle,
                  textAlign: TextAlign.center)),
          SizedBox(width: 70,
              child: Text('Nilai Akhir', style: _headerStyle,
                  textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );
}

// ── Nilai Row ─────────────────────────────────────────────────────────────────
class _NilaiRow extends StatefulWidget {
  final NilaiSiswaModel model;
  final int             index;
  final void Function(String field, double val) onUpdate;

  const _NilaiRow({
    required this.model,
    required this.index,
    required this.onUpdate,
  });

  @override
  State<_NilaiRow> createState() => _NilaiRowState();
}

class _NilaiRowState extends State<_NilaiRow> {
  late Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      'tugas'  : TextEditingController(
          text: widget.model.nilaiTugas?.toStringAsFixed(0) ?? ''),
      'kuis'   : TextEditingController(
          text: widget.model.nilaiKuis?.toStringAsFixed(0) ?? ''),
      'uts'    : TextEditingController(
          text: widget.model.nilaiUts?.toStringAsFixed(0) ?? ''),
      'uas'    : TextEditingController(
          text: widget.model.nilaiUas?.toStringAsFixed(0) ?? ''),
      'praktik': TextEditingController(
          text: widget.model.nilaiPraktik?.toStringAsFixed(0) ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  Color get _predikatColor {
    switch (widget.model.predikat) {
      case 'A': return AppColors.success;
      case 'B': return AppColors.primary;
      case 'C': return AppColors.warning;
      case 'D': return AppColors.sakit;
      default : return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEven = widget.index % 2 == 0;
    return Container(
      color: isEven ? AppColors.surface : AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 30,
              child: Text('${widget.index + 1}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary))),
          SizedBox(width: 80,
              child: Text(widget.model.nis ?? '-',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary))),
          Expanded(
              child: Text(widget.model.namaSiswa,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis)),
          SizedBox(width: 70,
              child: _NilaiInput(
                  ctrl: _ctrls['tugas']!,
                  onChanged: (v) => widget.onUpdate('tugas', v))),
          SizedBox(width: 70,
              child: _NilaiInput(
                  ctrl: _ctrls['kuis']!,
                  onChanged: (v) => widget.onUpdate('kuis', v))),
          SizedBox(width: 70,
              child: _NilaiInput(
                  ctrl: _ctrls['uts']!,
                  onChanged: (v) => widget.onUpdate('uts', v))),
          SizedBox(width: 70,
              child: _NilaiInput(
                  ctrl: _ctrls['uas']!,
                  onChanged: (v) => widget.onUpdate('uas', v))),
          SizedBox(width: 70,
              child: _NilaiInput(
                  ctrl: _ctrls['praktik']!,
                  onChanged: (v) => widget.onUpdate('praktik', v))),
          SizedBox(
            width: 70,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _predikatColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(widget.model.nilaiAkhir ?? 0).toStringAsFixed(1)} '
                      '(${widget.model.predikat})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _predikatColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nilai Input Field ─────────────────────────────────────────────────────────
class _NilaiInput extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<double>  onChanged;

  const _NilaiInput({required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 32,
        child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(r'^\d{0,3}\.?\d{0,2}')),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            isDense  : true,
            filled   : true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                  color: AppColors.primary, width: 1.5),
            ),
          ),
          onChanged: (v) {
            final val = double.tryParse(v);
            if (val != null && val >= 0 && val <= 100) onChanged(val);
          },
        ),
      ),
    );
  }
}

// ── Save Bar ──────────────────────────────────────────────────────────────────
class _SaveBar extends StatelessWidget {
  final NilaiState state;
  const _SaveBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text('Total ${state.rows.length} siswa',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: state.isSaving
                  ? null
                  : () => context.read<NilaiBloc>().add(NilaiSave()),
              icon: state.isSaving
                  ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                  state.isSaving ? 'Menyimpan...' : 'Simpan Nilai',
                  style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Atur Bobot Dialog ─────────────────────────────────────────────────────────
class _AturBobotDialog extends StatefulWidget {
  const _AturBobotDialog();

  @override
  State<_AturBobotDialog> createState() => _AturBobotDialogState();
}

class _AturBobotDialogState extends State<_AturBobotDialog> {
  late Map<String, int> _bobot;
  int get _total =>
      _bobot.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _bobot = Map.from(AppConstants.bobotNilai);
  }

  @override
  Widget build(BuildContext context) {
    final totalOk = _total == 100;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Atur Bobot Nilai',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._bobot.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      _capitalize(e.key),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: e.value.toDouble(),
                      min: 0, max: 50,
                      divisions: 50,
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          setState(() => _bobot[e.key] = v.toInt()),
                    ),
                  ),
                  Container(
                    width: 46,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${e.value}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        )),
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: totalOk
                        ? AppColors.successLight
                        : AppColors.errorLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('$_total%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: totalOk
                            ? AppColors.success
                            : AppColors.error,
                      )),
                ),
              ],
            ),
            if (!totalOk)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Total bobot harus 100%',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: totalOk
              ? () => Navigator.pop(context, _bobot)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            elevation: 0,
          ),
          child: const Text('Simpan'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Generic Filter Dropdown ───────────────────────────────────────────────────
class _FilterDropdown<T> extends StatelessWidget {
  final String           hint;
  final T?               value;
  final List<T>          items;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;
  final bool             allowNull;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    this.allowNull = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: DropdownButtonFormField<T>(
        value    : value,
        isDense  : true,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 1.5),
          ),
          fillColor: AppColors.surface,
          filled   : true,
        ),
        hint: Text(hint,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textTertiary)),
        items: [
          if (allowNull)
            DropdownMenuItem<T>(
              value: null,
              child: Text(hint,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textTertiary)),
            ),
          ...items.map((e) => DropdownMenuItem<T>(
            value: e,
            child: Text(label(e),
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          )),
        ],
        onChanged: onChanged,
        style: const TextStyle(
            fontSize: 13, color: AppColors.textPrimary),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            size: 18, color: AppColors.textSecondary),
        dropdownColor: AppColors.surface,
      ),
    );
  }
}