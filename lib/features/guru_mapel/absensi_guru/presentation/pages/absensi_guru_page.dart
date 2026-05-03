// lib/features/guru_mapel/absensi_guru/presentation/pages/absensi_guru_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/app_widgets.dart';
import '../../../../../features/auth/data/models/auth_model.dart';
import '../../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/absensi_guru_model.dart';
import '../bloc/absensi_guru_bloc.dart';

class AbsensiGuruPage extends StatefulWidget {
  const AbsensiGuruPage({super.key});
  @override State<AbsensiGuruPage> createState() =>
      _AbsensiGuruPageState();
}

class _AbsensiGuruPageState extends State<AbsensiGuruPage> {
  // Form state
  String  _tanggal      = _todayIso();
  String  _status       = 'hadir';
  String  _keterangan   = '';
  String? _fotoBase64;
  String  _filterTanggal = _todayIso();

  static String _todayIso() =>
      DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    context.read<AbsensiGuruBloc>()
        .add(AbsensiGuruLoadRequested(tanggal: _filterTanggal));
  }

  Future<void> _pickFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source      : ImageSource.camera,
      imageQuality: 70,
      maxWidth    : 800,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _fotoBase64 =
      'data:image/jpeg;base64,${base64Encode(bytes)}');
    }
  }

  void _submit() {
    final model = AbsensiGuruModel(
      tanggal    : _tanggal,
      status     : _status,
      keterangan : _keterangan.isEmpty ? null : _keterangan,
      fotoBase64 : _fotoBase64,
    );
    context.read<AbsensiGuruBloc>()
        .add(AbsensiGuruCreateRequested(model));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AbsensiGuruBloc, AbsensiGuruState>(
      listener: (context, state) {
        if (state is AbsensiGuruActionSuccess) {
          AppWidgets.showSuccess(context, state.message);
          setState(() {
            _status     = 'hadir';
            _keterangan = '';
            _fotoBase64 = null;
            _tanggal    = _todayIso();
          });
        } else if (state is AbsensiGuruError) {
          AppWidgets.showError(context, state.message);
        }
      },
      builder: (context, state) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            final user = authState is AuthAuthenticated
                ? authState.user : null;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Page Title ─────────────────────────────────────
                  _PageTitle(),
                  const SizedBox(height: 16),

                  // ── Form Card ──────────────────────────────────────
                  _FormCard(
                    user       : user,
                    tanggal    : _tanggal,
                    status     : _status,
                    keterangan : _keterangan,
                    fotoBase64 : _fotoBase64,
                    isLoading  : state is AbsensiGuruLoading,
                    onTanggal  : (v) => setState(() => _tanggal = v),
                    onStatus   : (v) => setState(() => _status = v),
                    onKeterangan: (v) => setState(() => _keterangan = v),
                    onPickFoto : _pickFoto,
                    onRemoveFoto: () =>
                        setState(() => _fotoBase64 = null),
                    onSubmit   : _submit,
                  ),
                  const SizedBox(height: 16),

                  // ── Stats Bar ──────────────────────────────────────
                  if (state is AbsensiGuruLoaded)
                    _StatsBar(summary: state.summary),

                  const SizedBox(height: 16),

                  // ── Daftar Tabel ───────────────────────────────────
                  _DaftarCard(
                    state         : state,
                    filterTanggal : _filterTanggal,
                    onFilterChange: (v) {
                      setState(() => _filterTanggal = v);
                      context.read<AbsensiGuruBloc>().add(
                          AbsensiGuruFilterChanged(v));
                    },
                    onRefresh: () => context.read<AbsensiGuruBloc>()
                        .add(AbsensiGuruLoadRequested(
                        tanggal: _filterTanggal)),
                    onDelete : (id) => context.read<AbsensiGuruBloc>()
                        .add(AbsensiGuruDeleteRequested(id)),
                    onUbahStatus: (id, model) =>
                        _showUbahStatus(context, id, model),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showUbahStatus(
      BuildContext context, int id, AbsensiGuruModel model) {
    String newStatus = model.status;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ubah Status Absensi',
              style: TextStyle(
                  fontSize  : 16,
                  fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _statusOptions.map((s) => RadioListTile<String>(
                value   : s['value']!,
                groupValue: newStatus,
                title   : Text(s['label']!,
                    style: const TextStyle(fontSize: 14)),
                activeColor: AppColors.primary,
                dense   : true,
                onChanged: (v) =>
                    setDialogState(() => newStatus = v!),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AbsensiGuruBloc>().add(
                  AbsensiGuruUpdateRequested(
                      id, model.copyWith(status: newStatus)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
              ),
              child: const Text('Simpan'),
            ),
          ],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static const _statusOptions = [
    {'value': 'hadir',     'label': 'Hadir'},
    {'value': 'terlambat', 'label': 'Terlambat'},
    {'value': 'izin',      'label': 'Izin'},
    {'value': 'sakit',     'label': 'Sakit'},
    {'value': 'alpa',      'label': 'Alpa'},
  ];
}

// ── Page Title ────────────────────────────────────────────────────────────────
class _PageTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width : 4, height: 22,
              decoration: BoxDecoration(
                color       : AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text('ABSENSI MANDIRI GURU',
                style: TextStyle(
                  fontSize  : 16,
                  fontWeight: FontWeight.w700,
                  color     : AppColors.textPrimary,
                  letterSpacing: 0.5,
                )),
          ],
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 14),
          child  : Text(
            'Batas waktu pengiriman absensi adalah pukul 07:30 WIB',
            style: TextStyle(
              fontSize: 12,
              color   : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Form Card ─────────────────────────────────────────────────────────────────
class _FormCard extends StatefulWidget {
  final UserModel?  user;
  final String      tanggal;
  final String      status;
  final String      keterangan;
  final String?     fotoBase64;
  final bool        isLoading;
  final ValueChanged<String> onTanggal;
  final ValueChanged<String> onStatus;
  final ValueChanged<String> onKeterangan;
  final VoidCallback onPickFoto;
  final VoidCallback onRemoveFoto;
  final VoidCallback onSubmit;

  const _FormCard({
    required this.user,
    required this.tanggal,
    required this.status,
    required this.keterangan,
    required this.fotoBase64,
    required this.isLoading,
    required this.onTanggal,
    required this.onStatus,
    required this.onKeterangan,
    required this.onPickFoto,
    required this.onRemoveFoto,
    required this.onSubmit,
  });

  @override
  State<_FormCard> createState() => _FormCardState();
}

class _FormCardState extends State<_FormCard> {
  late String _jamSekarang;

  @override
  void initState() {
    super.initState();
    _updateJam();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      setState(_updateJam);
      return true;
    });
  }

  void _updateJam() {
    final now = DateTime.now();
    _jamSekarang =
        DateFormat('HH.mm', 'id_ID').format(now) + ' WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color       : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border      : Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Profile + waktu
          _buildProfileBar(),
          const Divider(height: 1),
          // Form content
          Padding(
            padding: const EdgeInsets.all(16),
            child  : LayoutBuilder(builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeftForm(),
                    const SizedBox(height: 16),
                    _buildRightForm(),
                    const SizedBox(height: 16),
                    _buildSubmitBtn(),
                  ],
                );
              }
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildLeftForm()),
                      const SizedBox(width: 16),
                      SizedBox(
                          width: 200,
                          child: _buildRightForm()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSubmitBtn(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      color  : AppColors.surfaceVariant,
      child  : Row(
        children: [
          Container(
            width : 40, height: 40,
            decoration: BoxDecoration(
              color : AppColors.primary,
              shape : BoxShape.circle,
            ),
            child : Center(
              child: Text(
                widget.user?.inisial ?? 'G',
                style: const TextStyle(
                  color     : Colors.white,
                  fontSize  : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user?.name ?? 'Guru',
                style: const TextStyle(
                  fontSize  : 14,
                  fontWeight: FontWeight.w700,
                  color     : AppColors.textPrimary,
                ),
              ),
              Text(
                (widget.user?.displayRole ?? 'GURU MATA PELAJARAN')
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize  : 11,
                  color     : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('WAKTU SEKARANG',
                  style: TextStyle(
                    fontSize: 10,
                    color   : AppColors.textSecondary,
                    letterSpacing: 0.5,
                  )),
              Text(_jamSekarang,
                  style: const TextStyle(
                    fontSize  : 18,
                    fontWeight: FontWeight.w700,
                    color     : AppColors.textPrimary,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeftForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('PILIH TANGGAL ABSENSI'),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context    : context,
              initialDate: DateTime.parse(widget.tanggal),
              firstDate  : DateTime(2020),
              lastDate   : DateTime.now(),
              builder    : (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: AppColors.primary)),
                child: child!,
              ),
            );
            if (picked != null) {
              widget.onTanggal(
                  picked.toIso8601String().substring(0, 10));
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border      : Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
              color       : AppColors.surface,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(
                        DateTime.parse(widget.tanggal)),
                    style: const TextStyle(
                      fontSize: 14,
                      color   : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_month_rounded,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        _FieldLabel('STATUS KEHADIRAN'),
        const SizedBox(height: 6),
        _StatusDropdown(
          value    : widget.status,
          onChanged: widget.onStatus,
        ),
        const SizedBox(height: 14),

        _FieldLabel('KETERANGAN / CATATAN'),
        const SizedBox(height: 6),
        TextField(
          maxLines   : 3,
          decoration : const InputDecoration(
            hintText        : 'Tulis alasan jika Izin/Sakit...',
            hintStyle       : TextStyle(
                fontSize: 13, color: AppColors.textTertiary),
            contentPadding  : EdgeInsets.all(12),
            border          : OutlineInputBorder(
              borderRadius  : BorderRadius.all(Radius.circular(6)),
              borderSide    : BorderSide(color: AppColors.border),
            ),
            enabledBorder   : OutlineInputBorder(
              borderRadius  : BorderRadius.all(Radius.circular(6)),
              borderSide    : BorderSide(color: AppColors.border),
            ),
            focusedBorder   : OutlineInputBorder(
              borderRadius  : BorderRadius.all(Radius.circular(6)),
              borderSide    : BorderSide(
                  color: AppColors.primary, width: 1.5),
            ),
            fillColor: AppColors.surface,
            filled   : true,
          ),
          style    : const TextStyle(fontSize: 13),
          onChanged: widget.onKeterangan,
        ),
      ],
    );
  }

  Widget _buildRightForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('UNGGAH BUKTI FOTO (SELFIE)'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: widget.onPickFoto,
          child: Container(
            width : double.infinity,
            height: 160,
            decoration: BoxDecoration(
              border      : Border.all(
                color: AppColors.border,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(6),
              color       : AppColors.surfaceVariant,
            ),
            child: widget.fotoBase64 != null
                ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    base64Decode(
                        widget.fotoBase64!.split(',').last),
                    width : double.infinity,
                    height: double.infinity,
                    fit   : BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6, right: 6,
                  child: GestureDetector(
                    onTap: widget.onRemoveFoto,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color : Colors.black54,
                        shape : BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.camera_alt_outlined,
                    size: 32,
                    color: AppColors.textTertiary),
                SizedBox(height: 8),
                Text('Klik untuk ambil foto / upload',
                    style: TextStyle(
                      fontSize: 12,
                      color   : AppColors.textSecondary,
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Info box
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color       : const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(6),
            border      : Border.all(
                color: const Color(0xFFFFE082)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: Color(0xFFFF8F00)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pastikan foto yang diunggah adalah foto asli pada hari ini. '
                      'Sistem akan menolak absensi jika dikirim melewati pukul 07:30 WIB.',
                  style: TextStyle(
                    fontSize: 11,
                    color   : Color(0xFF795548),
                    height  : 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitBtn() {
    return SizedBox(
      width : double.infinity,
      height: 46,
      child : ElevatedButton(
        onPressed: widget.isLoading ? null : widget.onSubmit,
        style    : ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation      : 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
        child: widget.isLoading
            ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5))
            : const Text('KIRIM ABSENSI',
            style: TextStyle(
              fontSize     : 14,
              fontWeight   : FontWeight.w700,
              letterSpacing: 1.0,
              color        : Colors.white,
            )),
      ),
    );
  }
}

// ── Stats Bar ─────────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final AbsensiSummary summary;
  const _StatsBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard('Total',     '${summary.total}',
            AppColors.textPrimary, AppColors.surface),
        const SizedBox(width: 8),
        _StatCard('Hadir',     '${summary.hadir}',
            AppColors.hadir,    const Color(0xFFF1FFF4)),
        const SizedBox(width: 8),
        _StatCard('Terlambat', '${summary.terlambat}',
            AppColors.terlambat, const Color(0xFFFFFBF0)),
        const SizedBox(width: 8),
        _StatCard('Izin',      '${summary.izin}',
            AppColors.izin,     const Color(0xFFF0F8FF)),
        const SizedBox(width: 8),
        _StatCard('Sakit',     '${summary.sakit}',
            AppColors.sakit,    const Color(0xFFFFF5F0)),
        const SizedBox(width: 8),
        _StatCard('Alpa',      '${summary.alpa}',
            AppColors.alpa,     const Color(0xFFFFF0F0)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final Color  bg;
  const _StatCard(this.label, this.value, this.color, this.bg);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color       : bg,
          borderRadius: BorderRadius.circular(6),
          border      : Border.all(
              color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                  fontSize  : 11,
                  color     : color,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                  fontSize  : 22,
                  fontWeight: FontWeight.w700,
                  color     : color,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Daftar Card ───────────────────────────────────────────────────────────────
class _DaftarCard extends StatelessWidget {
  final AbsensiGuruState state;
  final String           filterTanggal;
  final ValueChanged<String> onFilterChange;
  final VoidCallback         onRefresh;
  final ValueChanged<int>    onDelete;
  final void Function(int, AbsensiGuruModel) onUbahStatus;

  const _DaftarCard({
    required this.state,
    required this.filterTanggal,
    required this.onFilterChange,
    required this.onRefresh,
    required this.onDelete,
    required this.onUbahStatus,
  });

  @override
  Widget build(BuildContext context) {
    final items = state is AbsensiGuruLoaded
        ? (state as AbsensiGuruLoaded).items
        : <AbsensiGuruModel>[];

    return Container(
      decoration: BoxDecoration(
        color       : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border      : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Text('Daftar Absensi Guru',
                    style: TextStyle(
                      fontSize  : 15,
                      fontWeight: FontWeight.w700,
                      color     : AppColors.textPrimary,
                    )),
                const Spacer(),
                // Filter tanggal
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context    : context,
                      initialDate: DateTime.parse(filterTanggal),
                      firstDate  : DateTime(2020),
                      lastDate   : DateTime.now(),
                      builder    : (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: AppColors.primary)),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      onFilterChange(
                          picked.toIso8601String().substring(0, 10));
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border      : Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(
                              DateTime.parse(filterTanggal)),
                          style: const TextStyle(
                            fontSize: 13,
                            color   : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.calendar_month_rounded,
                            size: 16,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Refresh
                InkWell(
                  onTap: onRefresh,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border      : Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh_rounded,
                            size: 15,
                            color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text('Refresh',
                            style: TextStyle(
                              fontSize: 12,
                              color   : AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table header
          _TableHeader(),

          // Table rows
          if (state is AbsensiGuruLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child  : Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            _EmptyTable()
          else
            ...items.asMap().entries.map((e) => _TableRow(
              index      : e.key,
              item       : e.value,
              onDelete   : () {
                if (e.value.id != null) onDelete(e.value.id!);
              },
              onUbahStatus: () {
                if (e.value.id != null) {
                  onUbahStatus(e.value.id!, e.value);
                }
              },
            )).toList(),
        ],
      ),
    );
  }
}

// ── Table Header ──────────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color  : AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      child: Row(
        children: const [
          SizedBox(width: 36,
              child: Text('NO', style: _hs)),
          SizedBox(width: 130,
              child: Text('NAMA GURU', style: _hs)),
          SizedBox(width: 100,
              child: Text('TANGGAL', style: _hs)),
          SizedBox(width: 90,
              child: Text('JAM MASUK', style: _hs)),
          SizedBox(width: 90,
              child: Text('STATUS', style: _hs)),
          Expanded(
              child: Text('KETERANGAN', style: _hs)),
          SizedBox(width: 60,
              child: Text('FOTO', style: _hs,
                  textAlign: TextAlign.center)),
          SizedBox(width: 100,
              child: Text('UBAH STATUS', style: _hs,
                  textAlign: TextAlign.center)),
          SizedBox(width: 60,
              child: Text('HAPUS', style: _hs,
                  textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  static const _hs = TextStyle(
    fontSize  : 11,
    fontWeight: FontWeight.w700,
    color     : AppColors.textSecondary,
    letterSpacing: 0.3,
  );
}

// ── Table Row ─────────────────────────────────────────────────────────────────
class _TableRow extends StatelessWidget {
  final int              index;
  final AbsensiGuruModel item;
  final VoidCallback     onDelete;
  final VoidCallback     onUbahStatus;

  const _TableRow({
    required this.index,
    required this.item,
    required this.onDelete,
    required this.onUbahStatus,
  });

  Color get _statusColor {
    switch (item.status) {
      case 'hadir'    : return AppColors.hadir;
      case 'terlambat': return AppColors.terlambat;
      case 'izin'     : return AppColors.izin;
      case 'sakit'    : return AppColors.sakit;
      case 'alpa'     : return AppColors.alpa;
      default         : return AppColors.textSecondary;
    }
  }

  String get _jamMasuk {
    if (item.createdAt == null) return '-';
    return DateFormat('HH:mm').format(item.createdAt!);
  }

  @override
  Widget build(BuildContext context) {
    final isEven = index % 2 == 0;
    return Container(
      color  : isEven ? AppColors.surface : AppColors.surfaceVariant,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      child  : Row(
        children: [
          // NO
          SizedBox(
            width: 36,
            child: Text('${index + 1}',
                style: const TextStyle(
                    fontSize: 13,
                    color   : AppColors.textSecondary)),
          ),
          // NAMA GURU
          SizedBox(
            width: 130,
            child: Text(
              item.namaGuru ?? 'Saya',
              style: const TextStyle(
                fontSize  : 13,
                fontWeight: FontWeight.w500,
                color     : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // TANGGAL
          SizedBox(
            width: 100,
            child: Text(
              _formatTanggal(item.tanggal),
              style: const TextStyle(
                fontSize: 13,
                color   : AppColors.textPrimary,
              ),
            ),
          ),
          // JAM MASUK
          SizedBox(
            width: 90,
            child: Text(_jamMasuk,
                style: const TextStyle(
                  fontSize: 13,
                  color   : AppColors.textPrimary,
                )),
          ),
          // STATUS
          SizedBox(
            width: 90,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color       : _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border      : Border.all(
                    color: _statusColor.withOpacity(0.3)),
              ),
              child: Text(
                _capitalize(item.status),
                style: TextStyle(
                  fontSize  : 11,
                  fontWeight: FontWeight.w700,
                  color     : _statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // KETERANGAN
          Expanded(
            child: Text(
              item.keterangan ?? '-',
              style: const TextStyle(
                fontSize: 12,
                color   : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // FOTO
          SizedBox(
            width: 60,
            child: Center(
              child: item.fotoBase64 != null
                  ? GestureDetector(
                onTap: () => _showFoto(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.memory(
                    base64Decode(
                        item.fotoBase64!.split(',').last),
                    width : 36, height: 36,
                    fit   : BoxFit.cover,
                  ),
                ),
              )
                  : const Icon(Icons.image_not_supported_outlined,
                  size: 20, color: AppColors.textTertiary),
            ),
          ),
          // UBAH STATUS
          SizedBox(
            width: 100,
            child: Center(
              child: TextButton(
                onPressed: onUbahStatus,
                style    : TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                ),
                child: const Text('Ubah',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
          // HAPUS
          SizedBox(
            width: 60,
            child: Center(
              child: IconButton(
                onPressed: () => _confirmDelete(context),
                icon     : const Icon(
                    Icons.delete_outline_rounded,
                    size : 18,
                    color: AppColors.error),
                padding  : EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip  : 'Hapus',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTanggal(String iso) {
    try {
      return DateFormat('dd/MM/yyyy')
          .format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _showFoto(BuildContext context) {
    if (item.fotoBase64 == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(item.fotoBase64!.split(',').last),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text('Hapus Absensi'),
        content: const Text('Yakin ingin menghapus data absensi ini?'),
        shape  : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation      : 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── Empty Table ───────────────────────────────────────────────────────────────
class _EmptyTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child  : Column(
        children: const [
          Icon(Icons.assignment_outlined,
              size: 40, color: AppColors.textTertiary),
          SizedBox(height: 10),
          Text('Belum ada data absensi untuk tanggal ini',
              style: TextStyle(
                fontSize: 13,
                color   : AppColors.textTertiary,
              )),
        ],
      ),
    );
  }
}

// ── Status Dropdown ───────────────────────────────────────────────────────────
class _StatusDropdown extends StatelessWidget {
  final String           value;
  final ValueChanged<String> onChanged;

  const _StatusDropdown({
    required this.value,
    required this.onChanged,
  });

  static const _options = [
    {'value': 'hadir',     'label': 'HADIR'},
    {'value': 'terlambat', 'label': 'TERLAMBAT'},
    {'value': 'izin',      'label': 'IZIN'},
    {'value': 'sakit',     'label': 'SAKIT'},
    {'value': 'alpa',      'label': 'ALPA'},
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value    : value,
      isDense  : true,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide  : BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide  : BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide  : BorderSide(
              color: AppColors.primary, width: 1.5),
        ),
        fillColor: AppColors.surface,
        filled   : true,
      ),
      items: _options.map((o) => DropdownMenuItem(
        value: o['value']!,
        child: Text(o['label']!,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textPrimary)),
      )).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          size: 20, color: AppColors.textSecondary),
      dropdownColor: AppColors.surface,
      style: const TextStyle(
          fontSize: 13, color: AppColors.textPrimary),
    );
  }
}

// ── Field Label ───────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
        fontSize    : 11,
        fontWeight  : FontWeight.w700,
        color       : AppColors.textSecondary,
        letterSpacing: 0.5,
      ));
}