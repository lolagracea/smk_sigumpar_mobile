// lib/features/guru_mapel/perangkat/presentation/pages/perangkat_page.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/app_widgets.dart';
import '../../data/perangkat_model.dart';
import '../bloc/perangkat_bloc.dart';

class PerangkatPage extends StatefulWidget {
  const PerangkatPage({super.key});
  @override State<PerangkatPage> createState() => _PerangkatPageState();
}

class _PerangkatPageState extends State<PerangkatPage> {
  @override
  void initState() {
    super.initState();
    // Gunakan addPostFrameCallback agar context sudah siap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerangkatBloc>().add(PerangkatLoad());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PerangkatBloc, PerangkatState>(
      listener: (context, state) {
        if (state is PerangkatActionSuccess) {
          AppWidgets.showSuccess(context, state.message);
        } else if (state is PerangkatError) {
          AppWidgets.showError(context, state.message);
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Page Title ──────────────────────────────────────────
              const Text('Perangkat Pembelajaran',
                  style: TextStyle(
                    fontSize  : 22,
                    fontWeight: FontWeight.w700,
                    color     : AppColors.textPrimary,
                  )),
              const SizedBox(height: 4),
              const Text(
                'Upload, lihat, dan kelola dokumen perangkat pembelajaran · Guru',
                style: TextStyle(
                  fontSize: 13,
                  color   : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // ── Upload Card ─────────────────────────────────────────
              const _UploadCard(),
              const SizedBox(height: 16),

              // ── Daftar Card ─────────────────────────────────────────
              _DaftarCard(state: state),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

// ── Upload Card ───────────────────────────────────────────────────────────────
class _UploadCard extends StatefulWidget {
  const _UploadCard();
  @override State<_UploadCard> createState() => _UploadCardState();
}

class _UploadCardState extends State<_UploadCard> {
  final _namaCtrl  = TextEditingController();
  String       _jenis     = 'RPP';
  PlatformFile? _file;
  bool          _uploading = false;

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type             : FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx',
        'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.first);
    }
  }

  void _submit() {
    if (_namaCtrl.text.trim().isEmpty) {
      AppWidgets.showError(context, 'Nama dokumen tidak boleh kosong');
      return;
    }
    if (_file == null) {
      AppWidgets.showError(context, 'Pilih file terlebih dahulu');
      return;
    }
    if (_file!.path == null) return;

    setState(() => _uploading = true);
    context.read<PerangkatBloc>().add(PerangkatUploadRequested(
      namaDokumen : _namaCtrl.text.trim(),
      jenisDokumen: _jenis,
      filePath    : _file!.path!,
      fileName    : _file!.name,
    ));

    // Reset form
    setState(() {
      _namaCtrl.clear();
      _jenis     = 'RPP';
      _file      = null;
      _uploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width     : double.infinity,
      constraints: const BoxConstraints(maxWidth: 700),
      padding   : const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color       : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border      : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: const [
              Text('📤', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('Upload Dokumen Baru',
                  style: TextStyle(
                    fontSize  : 15,
                    fontWeight: FontWeight.w700,
                    color     : AppColors.textPrimary,
                  )),
            ],
          ),
          const SizedBox(height: 16),

          // Form row
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 500;
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NamaField(ctrl: _namaCtrl),
                  const SizedBox(height: 12),
                  _JenisDropdown(
                    value    : _jenis,
                    onChanged: (v) =>
                        setState(() => _jenis = v ?? 'RPP'),
                  ),
                  const SizedBox(height: 12),
                  _FileField(
                    file   : _file,
                    onPick : _pickFile,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 3,
                    child: _NamaField(ctrl: _namaCtrl)),
                const SizedBox(width: 12),
                Expanded(flex: 2,
                    child: _JenisDropdown(
                      value    : _jenis,
                      onChanged: (v) =>
                          setState(() => _jenis = v ?? 'RPP'),
                    )),
                const SizedBox(width: 12),
                Expanded(flex: 4,
                    child: _FileField(
                      file  : _file,
                      onPick: _pickFile,
                    )),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Upload button (right-aligned)
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 42,
              child : ElevatedButton.icon(
                onPressed: _uploading ? null : _submit,
                icon : _uploading
                    ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload_rounded, size: 18),
                label: Text(
                  _uploading ? 'Mengupload...' : 'Upload Dokumen',
                  style: const TextStyle(
                    fontSize  : 13,
                    fontWeight: FontWeight.w600,
                    color     : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation      : 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nama Field ────────────────────────────────────────────────────────────────
class _NamaField extends StatelessWidget {
  final TextEditingController ctrl;
  const _NamaField({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('NAMA DOKUMEN'),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText      : 'Contoh: RPP Matematika Bab 1',
            hintStyle     : TextStyle(
                fontSize: 13, color: AppColors.textTertiary),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 12, vertical: 11),
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
            isDense  : true,
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

// ── Jenis Dropdown ────────────────────────────────────────────────────────────
class _JenisDropdown extends StatelessWidget {
  final String           value;
  final ValueChanged<String?> onChanged;
  const _JenisDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('JENIS DOKUMEN'),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value    : value,
          isDense  : true,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(
                horizontal: 12, vertical: 11),
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
          items: AppConstants.jenisDokumen
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e,
                style: const TextStyle(fontSize: 13)),
          ))
              .toList(),
          onChanged  : onChanged,
          style      : const TextStyle(
              fontSize: 13, color: AppColors.textPrimary),
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── File Field ────────────────────────────────────────────────────────────────
class _FileField extends StatelessWidget {
  final PlatformFile? file;
  final VoidCallback  onPick;
  const _FileField({required this.file, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('FILE (PDF/DOCX/GAMBAR)'),
        const SizedBox(height: 5),
        Row(
          children: [
            // Choose File button
            OutlinedButton(
              onPressed: onPick,
              style    : OutlinedButton.styleFrom(
                side   : const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                shape  : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                backgroundColor: AppColors.surfaceVariant,
              ),
              child: const Text('Choose File',
                  style: TextStyle(
                    fontSize: 13,
                    color   : AppColors.textPrimary,
                  )),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file?.name ?? 'No file chosen',
                style: TextStyle(
                  fontSize: 13,
                  color   : file != null
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Daftar Card ───────────────────────────────────────────────────────────────
class _DaftarCard extends StatefulWidget {
  final PerangkatState state;
  const _DaftarCard({required this.state});

  @override
  State<_DaftarCard> createState() => _DaftarCardState();
}

class _DaftarCardState extends State<_DaftarCard> {
  String? _filterJenis;
  String? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    List<PerangkatModel> items = [];
    if (state is PerangkatLoaded) {
      items = state.filtered;
    }

    // Apply status filter locally
    if (_filterStatus != null && _filterStatus != 'Semua Status') {
      items = items.where((e) =>
      e.statusReview == _filterStatus!.toLowerCase()).toList();
    }

    return Container(
      width     : double.infinity,
      constraints: const BoxConstraints(maxWidth: 700),
      decoration: BoxDecoration(
        color       : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border      : Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Text('📁', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text('Daftar Dokumen Terupload',
                    style: TextStyle(
                      fontSize  : 15,
                      fontWeight: FontWeight.w700,
                      color     : AppColors.textPrimary,
                    )),
                const Spacer(),
                // Semua Jenis dropdown
                _SmallDropdown(
                  value  : _filterJenis ?? 'Semua Jenis',
                  options: [
                    'Semua Jenis',
                    ...AppConstants.jenisDokumen,
                  ],
                  onChanged: (v) {
                    setState(() => _filterJenis = v);
                    context.read<PerangkatBloc>().add(
                      PerangkatFilterChanged(
                          v == 'Semua Jenis' ? null : v),
                    );
                  },
                ),
                const SizedBox(width: 8),
                // Semua Status dropdown
                _SmallDropdown(
                  value  : _filterStatus ?? 'Semua Status',
                  options: const [
                    'Semua Status',
                    'menunggu',
                    'disetujui',
                    'revisi',
                    'ditolak',
                  ],
                  onChanged: (v) =>
                      setState(() => _filterStatus = v),
                ),
                const SizedBox(width: 8),
                // File count
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color       : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                    border      : Border.all(color: AppColors.border),
                  ),
                  child: Text('${items.length} FILE',
                      style: const TextStyle(
                        fontSize  : 11,
                        fontWeight: FontWeight.w700,
                        color     : AppColors.textSecondary,
                      )),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          if (state is PerangkatLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child  : Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            _EmptyState()
          else
            ...items.map((doc) => _DokumenItem(
              doc     : doc,
              onDelete: () {
                if (doc.id != null) {
                  context.read<PerangkatBloc>().add(
                      PerangkatDeleteRequested(doc.id!));
                }
              },
            )).toList(),
        ],
      ),
    );
  }
}

// ── Dokumen Item ──────────────────────────────────────────────────────────────
class _DokumenItem extends StatelessWidget {
  final PerangkatModel doc;
  final VoidCallback   onDelete;
  const _DokumenItem({required this.doc, required this.onDelete});

  static const _jenisColors = {
    'RPP'    : AppColors.primary,
    'Silabus': AppColors.success,
    'Modul'  : AppColors.accent,
  };

  static const _statusMeta = {
    'menunggu' : ('Menunggu Review', AppColors.warning),
    'disetujui': ('Disetujui',       AppColors.hadir),
    'revisi'   : ('Perlu Revisi',    AppColors.info),
    'ditolak'  : ('Ditolak',         AppColors.error),
  };

  @override
  Widget build(BuildContext context) {
    final jenisColor =
        _jenisColors[doc.jenisDokumen] ?? AppColors.primary;
    final meta = _statusMeta[doc.statusReview] ??
        ('Menunggu Review', AppColors.warning);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Jenis badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color       : jenisColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border      : Border.all(
                  color: jenisColor.withOpacity(0.3)),
            ),
            child: Text(doc.jenisDokumen,
                style: TextStyle(
                  fontSize  : 11,
                  fontWeight: FontWeight.w700,
                  color     : jenisColor,
                )),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(doc.namaDokumen,
                          style: const TextStyle(
                            fontSize  : 14,
                            fontWeight: FontWeight.w600,
                            color     : AppColors.textPrimary,
                          )),
                    ),
                    if (doc.versi > 1)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color       : AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('v${doc.versi}',
                            style: const TextStyle(
                              fontSize  : 11,
                              fontWeight: FontWeight.w700,
                              color     : AppColors.primary,
                            )),
                      ),
                  ],
                ),
                if (doc.fileName != null)
                  Text(doc.fileName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color   : AppColors.textSecondary,
                      )),
                const SizedBox(height: 6),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color       : meta.$2.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border      : Border.all(
                        color: meta.$2.withOpacity(0.3)),
                  ),
                  child: Text(meta.$1,
                      style: TextStyle(
                        fontSize  : 11,
                        fontWeight: FontWeight.w600,
                        color     : meta.$2,
                      )),
                ),
                if (doc.catatanReview != null &&
                    doc.catatanReview!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(doc.catatanReview!,
                        style: const TextStyle(
                          fontSize: 12,
                          color   : AppColors.textSecondary,
                        )),
                  ),
              ],
            ),
          ),

          // Delete button
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon     : const Icon(
                Icons.delete_outline_rounded,
                size: 18, color: AppColors.error),
            tooltip  : 'Hapus',
            padding  : EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text('Hapus Dokumen'),
        content: Text(
            'Yakin ingin menghapus "${doc.namaDokumen}"?'),
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

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: const [
          Text('📁', style: TextStyle(fontSize: 48)),
          SizedBox(height: 10),
          Text('Belum ada dokumen yang sesuai filter',
              style: TextStyle(
                fontSize: 13,
                color   : AppColors.textTertiary,
              )),
        ],
      ),
    );
  }
}

// ── Small Dropdown ────────────────────────────────────────────────────────────
class _SmallDropdown extends StatelessWidget {
  final String         value;
  final List<String>   options;
  final ValueChanged<String?> onChanged;
  const _SmallDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color       : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border      : Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value    : value,
          isDense  : true,
          style    : const TextStyle(
              fontSize: 12, color: AppColors.textPrimary),
          icon     : const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: AppColors.textSecondary),
          dropdownColor: AppColors.surface,
          items: options
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e,
                style: const TextStyle(fontSize: 12)),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
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