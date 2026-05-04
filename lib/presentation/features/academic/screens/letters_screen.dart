import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/role_helper.dart';
import '../../../../data/models/arsip_surat_model.dart';
import '../../../../data/repositories/academic_repository.dart';
import '../../../common/providers/auth_provider.dart';
import '../../../common/widgets/error_widget.dart';
import '../../../common/widgets/loading_widget.dart';
import '../providers/academic_provider.dart';

class LettersScreen extends StatelessWidget {
  const LettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(
        repository: sl<AcademicRepository>(),
      )..fetchLetters(refresh: true),
      child: const _LettersView(),
    );
  }
}

class _LettersView extends StatelessWidget {
  const _LettersView();

  bool _canManageLetter(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    return RoleHelper.hasRole(
      targetRole: AppRoles.staff,
      role: user?.role,
      roles: user?.roles,
    );
  }

  void _openFormSheet(
      BuildContext context, {
        ArsipSuratModel? initialData,
      }) {
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: parentContext.read<AcademicProvider>(),
          child: _LetterFormSheet(
            parentContext: parentContext,
            initialData: initialData,
          ),
        );
      },
    );
  }

  void _openDeleteDialog(
      BuildContext context,
      ArsipSuratModel item,
      ) {
    final parentContext = context;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            final isMatch = controller.text.trim() == item.nomorSurat;

            return AlertDialog(
              title: const Text('Hapus Arsip Surat'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tindakan ini akan menghapus data arsip dan file surat. Ketik ulang nomor surat untuk konfirmasi.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.nomorSurat,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      labelText: 'Nomor surat',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: isMatch
                      ? () async {
                    final provider =
                    parentContext.read<AcademicProvider>();

                    final success = await provider.deleteLetter(
                      id: item.id,
                    );

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    if (!parentContext.mounted) return;

                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Arsip surat berhasil dihapus.'
                              : provider.letterError ??
                              'Gagal menghapus arsip surat.',
                        ),
                      ),
                    );
                  }
                      : null,
                  child: const Text('Tetap Hapus'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      controller.dispose();
    });
  }

  Future<void> _openFile(
      BuildContext context,
      ArsipSuratModel item,
      ) async {
    final url = _buildPublicFileUrl(item);

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File surat tidak tersedia.'),
        ),
      );
      return;
    }

    final uri = Uri.parse(url);

    final success = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka file surat.'),
        ),
      );
    }
  }

  String _buildPublicFileUrl(ArsipSuratModel item) {
    if (item.fileUrl.isEmpty) return '';

    final filename = item.fileUrl.split('/').last;

    if (filename.isEmpty) return '';

    return '${ApiEndpoints.baseUrl}/uploads/$filename';
  }

  Future<void> _refresh(BuildContext context) {
    return context.read<AcademicProvider>().fetchLetters(
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();
    final canManage = _canManageLetter(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Arsip Surat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (canManage)
                FilledButton.icon(
                  onPressed: () {
                    _openFormSheet(context);
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Arsip'),
                ),
            ],
          ),
        ),
        Expanded(
          child: _buildContent(
            context,
            provider,
            canManage,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context,
      AcademicProvider provider,
      bool canManage,
      ) {
    if ((provider.letterState == AcademicLoadState.initial ||
        provider.letterState == AcademicLoadState.loading) &&
        provider.letters.isEmpty) {
      return const LoadingWidget();
    }

    if (provider.letterState == AcademicLoadState.error &&
        provider.letters.isEmpty) {
      return AppErrorWidget(
        message: provider.letterError,
        onRetry: () {
          context.read<AcademicProvider>().fetchLetters(
            refresh: true,
          );
        },
      );
    }

    if (provider.letters.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.archive_outlined,
              size: 56,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Center(
              child: Text('Belum ada arsip surat.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: provider.letters.length,
        separatorBuilder: (_, __) {
          return const SizedBox(height: 8);
        },
        itemBuilder: (context, index) {
          final item = provider.letters[index];

          return Card(
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              title: Text(
                item.nomorSurat,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              onTap: () {
                _openFile(context, item);
              },
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'view') {
                    _openFile(context, item);
                  } else if (value == 'download') {
                    _openFile(context, item);
                  } else if (value == 'edit') {
                    _openFormSheet(
                      context,
                      initialData: item,
                    );
                  } else if (value == 'delete') {
                    _openDeleteDialog(context, item);
                  }
                },
                itemBuilder: (_) {
                  return [
                    const PopupMenuItem(
                      value: 'view',
                      child: Text('Lihat'),
                    ),
                    const PopupMenuItem(
                      value: 'download',
                      child: Text('Unduh'),
                    ),
                    if (canManage)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                    if (canManage)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                  ];
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LetterFormSheet extends StatefulWidget {
  final BuildContext parentContext;
  final ArsipSuratModel? initialData;

  const _LetterFormSheet({
    required this.parentContext,
    this.initialData,
  });

  @override
  State<_LetterFormSheet> createState() => _LetterFormSheetState();
}

class _LetterFormSheetState extends State<_LetterFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomorSuratController = TextEditingController();

  PlatformFile? _selectedFile;
  bool _isSubmitting = false;

  bool get _isEdit => widget.initialData != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      _nomorSuratController.text = widget.initialData?.nomorSurat ?? '';
    }
  }

  @override
  void dispose() {
    _nomorSuratController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'jpg',
        'jpeg',
        'png',
      ],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      _selectedFile = result.files.first;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEdit && _selectedFile == null) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('File surat wajib diunggah.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<AcademicProvider>();

    final success = _isEdit
        ? await provider.updateLetter(
      id: widget.initialData!.id,
      nomorSurat: _nomorSuratController.text.trim(),
      file: _selectedFile,
    )
        : await provider.createLetter(
      nomorSurat: _nomorSuratController.text.trim(),
      file: _selectedFile!,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    final messenger = ScaffoldMessenger.of(widget.parentContext);

    if (success) {
      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Arsip surat berhasil diperbarui.'
                : 'Arsip surat berhasil ditambahkan.',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.letterError ?? 'Gagal menyimpan arsip surat.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEdit ? 'Edit Arsip Surat' : 'Tambah Arsip Surat',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomorSuratController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Surat',
                    hintText: 'Contoh: 123/SMKN1/2026',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nomor surat wajib diisi';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _isSubmitting ? null : _pickFile,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: _isEdit
                          ? 'File Surat Baru Opsional'
                          : 'File Surat',
                      prefixIcon: const Icon(Icons.upload_file_outlined),
                      suffixIcon: const Icon(Icons.folder_open_outlined),
                    ),
                    child: Text(
                      _selectedFile?.name ??
                          (_isEdit
                              ? 'Biarkan kosong jika tidak ingin mengganti file'
                              : 'Pilih file PDF/DOCX/JPG/PNG'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _selectedFile == null
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
                if (_isEdit && widget.initialData!.fileName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'File saat ini: ${widget.initialData!.fileName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSubmitting ? 'Menyimpan...' : 'Simpan',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}