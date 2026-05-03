// lib/features/guru_mapel/absensi_siswa/presentation/pages/absensi_siswa_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/models/shared_models.dart';
import '../../../../../shared/widgets/app_widgets.dart';
import '../bloc/absensi_siswa_bloc.dart';

class AbsensiSiswaPage extends StatefulWidget {
  const AbsensiSiswaPage({super.key});
  @override State<AbsensiSiswaPage> createState() =>
      _AbsensiSiswaPageState();
}

class _AbsensiSiswaPageState extends State<AbsensiSiswaPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _search    = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    context.read<AbsensiSiswaBloc>().add(AbsensiSiswaLoadMasterData());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AbsensiSiswaBloc, AbsensiSiswaState>(
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
            _buildHeader(context, state),
            const Divider(height: 1),
            _buildFilterPanel(context, state),
            const Divider(height: 1),
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

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AbsensiSiswaState state) {
    return Container(
      color  : AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child  : Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
              const Text('Absensi Siswa',
                  style: TextStyle(
                    fontSize  : 18,
                    fontWeight: FontWeight.w700,
                    color     : AppColors.textPrimary,
                  )),
            ],
          ),
          const Spacer(),
          // Stats chips
          if (state.sudahCari) ...[
            _StatChip('H', state.stats['hadir'] ?? 0, AppColors.hadir),
            const SizedBox(width: 4),
            _StatChip('T', state.stats['terlambat'] ?? 0,
                AppColors.terlambat),
            const SizedBox(width: 4),
            _StatChip('I', state.stats['izin'] ?? 0, AppColors.izin),
            const SizedBox(width: 4),
            _StatChip('S', state.stats['sakit'] ?? 0, AppColors.sakit),
            const SizedBox(width: 4),
            _StatChip('A', state.stats['alpa'] ?? 0, AppColors.alpa),
          ],
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color  : AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child  : TabBar(
        controller     : _tabCtrl,
        isScrollable   : true,
        tabAlignment   : TabAlignment.start,
        labelColor     : Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle     : const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w400),
        indicator      : BoxDecoration(
          color        : AppColors.primary,
          borderRadius : BorderRadius.circular(6),
        ),
        indicatorSize  : TabBarIndicatorSize.tab,
        dividerColor   : Colors.transparent,
        padding        : EdgeInsets.zero,
        tabs: [
          _buildTab(Icons.edit_rounded,     'Input Absensi'),
          _buildTab(Icons.history_rounded,  'Riwayat'),
          _buildTab(Icons.bar_chart_rounded,'Rekap'),
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

  // ── Filter Panel ──────────────────────────────────────────────────────────
  Widget _buildFilterPanel(
      BuildContext context, AbsensiSiswaState state) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _buildTabBar(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: LayoutBuilder(builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: _buildKelasDropdown(context, state)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _buildMapelDropdown(context, state)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: _buildTanggalPicker(context, state)),
                      const SizedBox(width: 8),
                      _buildSemuaHadirBtn(context, state),
                      const SizedBox(width: 6),
                      _buildSemuaIzinBtn(context, state),
                    ]),
                  ],
                );
              }
              return Row(
                children: [
                  _FilterLabel('KELAS'),
                  const SizedBox(width: 6),
                  SizedBox(width: 180,
                      child: _buildKelasDropdown(context, state)),
                  const SizedBox(width: 12),
                  _FilterLabel('MATA PELAJARAN'),
                  const SizedBox(width: 6),
                  SizedBox(width: 180,
                      child: _buildMapelDropdown(context, state)),
                  const SizedBox(width: 12),
                  _FilterLabel('TANGGAL'),
                  const SizedBox(width: 6),
                  SizedBox(width: 160,
                      child: _buildTanggalPicker(context, state)),
                  const SizedBox(width: 10),
                  _buildSemuaHadirBtn(context, state),
                  const SizedBox(width: 6),
                  _buildSemuaIzinBtn(context, state),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildKelasDropdown(
      BuildContext context, AbsensiSiswaState state) {
    return _FilterDropdown<KelasModel>(
      hint    : '-- Pilih Kelas --',
      value   : state.selectedKelas,
      items   : state.kelasList,
      label   : (e) => e.namaKelas,
      onChanged: (v) {
        if (v != null) {
          context
              .read<AbsensiSiswaBloc>()
              .add(AbsensiSiswaKelasChanged(v));
        }
      },
    );
  }

  Widget _buildMapelDropdown(
      BuildContext context, AbsensiSiswaState state) {
    return _FilterDropdown<MapelModel>(
      hint    : '-- Pilih Mapel --',
      value   : state.selectedMapel,
      items   : state.mapelList,
      label   : (e) => e.namaMapel,
      onChanged: (v) => context
          .read<AbsensiSiswaBloc>()
          .add(AbsensiSiswaMapelChanged(v)),
      allowNull: true,
    );
  }

  Widget _buildTanggalPicker(
      BuildContext context, AbsensiSiswaState state) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context    : context,
          initialDate: state.tanggal.isNotEmpty
              ? DateTime.parse(state.tanggal)
              : DateTime.now(),
          firstDate  : DateTime(2020),
          lastDate   : DateTime.now(),
          builder    : (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                  primary: AppColors.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null && context.mounted) {
          context.read<AbsensiSiswaBloc>().add(
            AbsensiSiswaTanggalChanged(
                picked.toIso8601String().substring(0, 10)),
          );
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height    : 38,
        padding   : const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color       : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border      : Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                state.tanggal.isNotEmpty
                    ? DateFormat('dd/MM/yyyy').format(
                    DateTime.parse(state.tanggal))
                    : DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.calendar_month_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSemuaHadirBtn(
      BuildContext context, AbsensiSiswaState state) {
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: state.siswaList.isEmpty
            ? null
            : () {
          for (final s in state.siswaList) {
            context.read<AbsensiSiswaBloc>().add(
                AbsensiSiswaStatusChanged(s.id, 'hadir'));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.hadir,
          elevation      : 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('Semua hadir',
            style: TextStyle(
                fontSize: 13, color: Colors.white,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildSemuaIzinBtn(
      BuildContext context, AbsensiSiswaState state) {
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: state.siswaList.isEmpty
            ? null
            : () {
          for (final s in state.siswaList) {
            context.read<AbsensiSiswaBloc>().add(
                AbsensiSiswaStatusChanged(s.id, 'izin'));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107),
          elevation      : 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('Semua izin',
            style: TextStyle(
                fontSize: 13, color: Colors.white,
                fontWeight: FontWeight.w500)),
      ),
    );
  }

  // ── Tab 1: Input Absensi ──────────────────────────────────────────────────
  Widget _buildInputTab(
      BuildContext context, AbsensiSiswaState state) {
    if (state.isLoadingMaster || state.isLoadingSiswa) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.selectedKelas == null) {
      return AppWidgets.emptyState(
        icon    : Icons.touch_app_rounded,
        title   : 'Pilih Kelas & Tanggal',
        subtitle: 'Pilih kelas dan tanggal untuk\nmenampilkan daftar siswa',
      );
    }

    if (state.siswaList.isEmpty) {
      return AppWidgets.emptyState(
        icon    : Icons.group_off_rounded,
        title   : 'Tidak ada siswa',
        subtitle: 'Tidak ada siswa pada kelas ini',
      );
    }

    final filtered = state.siswaList.where((s) {
      if (_search.isEmpty) return true;
      return s.namaSiswa.toLowerCase().contains(_search.toLowerCase()) ||
          s.nis.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search bar
        _buildSearchBar(),
        // Table header
        _buildTableHeader(),
        // Siswa list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, i) {
              final siswa = filtered[i];
              final status =
                  state.attendance[siswa.id] ?? 'hadir';
              return _AbsensiRow(
                siswa   : siswa,
                status  : status,
                index   : i,
                onStatus: (s) => context
                    .read<AbsensiSiswaBloc>()
                    .add(AbsensiSiswaStatusChanged(siswa.id, s)),
              );
            },
          ),
        ),
        // Save bar
        _buildSaveBar(context, state),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color  : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child  : Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child : TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText  : 'Cari nama atau NIS...',
                  hintStyle : const TextStyle(
                      fontSize: 13, color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide:
                    const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide:
                    const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  fillColor: AppColors.surface,
                  filled   : true,
                  isDense  : true,
                ),
                style    : const TextStyle(fontSize: 13),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Fetch button
          SizedBox(
            height: 36,
            child : ElevatedButton(
              onPressed: () => context
                  .read<AbsensiSiswaBloc>()
                  .add(AbsensiSiswaFetch()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation      : 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Tampilkan',
                  style: TextStyle(
                    fontSize  : 13,
                    fontWeight: FontWeight.w600,
                    color     : Colors.white,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color  : AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child  : Row(
        children: const [
          SizedBox(width: 36,
              child: Text('No', style: _hStyle)),
          SizedBox(width: 80,
              child: Text('NIS', style: _hStyle)),
          Expanded(
              child: Text('Nama Siswa', style: _hStyle)),
          SizedBox(width: 220,
              child: Text('Status Kehadiran', style: _hStyle,
                  textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  static const _hStyle = TextStyle(
    fontSize  : 11,
    fontWeight: FontWeight.w700,
    color     : AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  Widget _buildSaveBar(
      BuildContext context, AbsensiSiswaState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color : AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text('Total ${state.siswaList.length} siswa',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          SizedBox(
            height: 38,
            child : ElevatedButton.icon(
              onPressed: state.isSaving
                  ? null
                  : () => context
                  .read<AbsensiSiswaBloc>()
                  .add(AbsensiSiswaSaveRequested()),
              icon : state.isSaving
                  ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                  state.isSaving ? 'Menyimpan...' : 'Simpan Absensi',
                  style: const TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation      : 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Riwayat ────────────────────────────────────────────────────────
  Widget _buildRiwayatTab(
      BuildContext context, AbsensiSiswaState state) {
    return AppWidgets.emptyState(
      icon    : Icons.history_rounded,
      title   : 'Riwayat Absensi',
      subtitle: 'Pilih kelas dan tanggal untuk\nmelihat riwayat absensi',
    );
  }

  // ── Tab 3: Rekap ──────────────────────────────────────────────────────────
  Widget _buildRekapTab(
      BuildContext context, AbsensiSiswaState state) {
    return AppWidgets.emptyState(
      icon    : Icons.bar_chart_rounded,
      title   : 'Rekap Absensi',
      subtitle: 'Pilih kelas untuk melihat\nrekap absensi siswa',
    );
  }
}

// ── Absensi Row ───────────────────────────────────────────────────────────────
class _AbsensiRow extends StatelessWidget {
  final SiswaModel   siswa;
  final String       status;
  final int          index;
  final ValueChanged<String> onStatus;

  const _AbsensiRow({
    required this.siswa,
    required this.status,
    required this.index,
    required this.onStatus,
  });

  static const _statuses = [
    _StatusBtn('H', 'hadir',     AppColors.hadir),
    _StatusBtn('T', 'terlambat', AppColors.terlambat),
    _StatusBtn('I', 'izin',      AppColors.izin),
    _StatusBtn('S', 'sakit',     AppColors.sakit),
    _StatusBtn('A', 'alpa',      AppColors.alpa),
  ];

  @override
  Widget build(BuildContext context) {
    final isEven = index % 2 == 0;
    return Container(
      color  : isEven ? AppColors.surface : AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child  : Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('${index + 1}',
                style: const TextStyle(
                    fontSize: 12,
                    color   : AppColors.textSecondary)),
          ),
          SizedBox(
            width: 80,
            child: Text(siswa.nis,
                style: const TextStyle(
                    fontSize: 12,
                    color   : AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              siswa.namaSiswa,
              style: const TextStyle(
                fontSize  : 13,
                fontWeight: FontWeight.w500,
                color     : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Status buttons
          SizedBox(
            width: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _statuses.map((s) {
                final isSelected = status == s.value;
                return GestureDetector(
                  onTap: () => onStatus(s.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin  : const EdgeInsets.symmetric(horizontal: 3),
                    width   : 34, height: 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? s.color
                          : s.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? s.color
                            : s.color.withOpacity(0.3),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(s.label,
                          style: TextStyle(
                            fontSize  : 12,
                            fontWeight: FontWeight.w700,
                            color     : isSelected
                                ? Colors.white : s.color,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBtn {
  final String label;
  final String value;
  final Color  color;
  const _StatusBtn(this.label, this.value, this.color);
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int    count;
  final Color  color;
  const _StatChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color       : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border      : Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text('$label: $count',
          style: TextStyle(
            fontSize  : 11,
            fontWeight: FontWeight.w700,
            color     : color,
          )),
    );
  }
}

// ── Filter Dropdown ───────────────────────────────────────────────────────────
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
      child : DropdownButtonFormField<T>(
        value     : value,
        isDense   : true,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide  : const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide  : const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide  : const BorderSide(
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
                      fontSize: 13,
                      color   : AppColors.textTertiary)),
            ),
          ...items.map((e) => DropdownMenuItem<T>(
            value: e,
            child: Text(label(e),
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          )),
        ],
        onChanged  : onChanged,
        style      : const TextStyle(
            fontSize: 13, color: AppColors.textPrimary),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            size: 18, color: AppColors.textSecondary),
        dropdownColor: AppColors.surface,
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String text;
  const _FilterLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontSize    : 11,
          fontWeight  : FontWeight.w700,
          color       : AppColors.textSecondary,
          letterSpacing: 0.5,
        ));
  }
}