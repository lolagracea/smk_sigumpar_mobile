import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/role_helper.dart';
import '../../../../data/repositories/academic_repository.dart';
import '../../../common/providers/auth_provider.dart';
import '../../../common/widgets/error_widget.dart';
import '../../../common/widgets/loading_widget.dart';
import '../providers/academic_provider.dart';
import '../../../../core/constants/route_names.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(
        repository: sl<AcademicRepository>(),
      )..fetchAnnouncements(refresh: true),
      child: const _AnnouncementsView(),
    );
  }
}

class _AnnouncementsView extends StatelessWidget {
  const _AnnouncementsView();

  bool _canManageAnnouncement(BuildContext context) {
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
        Map<String, dynamic>? initialData,
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
          child: _AnnouncementFormSheet(
            parentContext: parentContext,
            initialData: initialData,
          ),
        );
      },
    );
  }

  void _openDetailDialog(
      BuildContext context,
      Map<String, dynamic> item,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(
            item['judul']?.toString() ?? 'Detail Pengumuman',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: SingleChildScrollView(
            child: Text(
              item['isi']?.toString() ?? '-',
              style: TextStyle(
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Tutup',
                style: TextStyle(
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openDeleteDialog(
      BuildContext context,
      Map<String, dynamic> item,
      ) {
    final parentContext = context;
    final controller = TextEditingController();
    final title = item['judul']?.toString() ?? '';
    final id = item['id']?.toString() ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            final isMatch = controller.text.trim() == title;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text(
                'Hapus Pengumuman',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ketik ulang judul "$title" untuk menghapus pengumuman ini.',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Judul Pengumuman',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                  onPressed: isMatch
                      ? () async {
                    final provider =
                    parentContext.read<AcademicProvider>();

                    final success = await provider.deleteAnnouncement(
                      id: id,
                    );

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    if (!parentContext.mounted) return;

                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Pengumuman berhasil dihapus.'
                              : provider.announcementError ??
                              'Gagal menghapus pengumuman.',
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

  Future<void> _refresh(BuildContext context) {
    return context.read<AcademicProvider>().fetchAnnouncements(
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();
    final canManage = _canManageAnnouncement(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Manajemen Pengumuman',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (canManage)
                FilledButton.icon(
                  onPressed: () {
                    _openFormSheet(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Pengumuman'),
                ),
            ],
          ),
        ),
        Expanded(
          child: _buildContent(
            context,
            provider,
            canManage,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context,
      AcademicProvider provider,
      bool canManage,
      bool isDark,
      ) {
    if ((provider.announcementState == AcademicLoadState.initial ||
        provider.announcementState == AcademicLoadState.loading) &&
        provider.announcements.isEmpty) {
      return const LoadingWidget();
    }

    if (provider.announcementState == AcademicLoadState.error &&
        provider.announcements.isEmpty) {
      return AppErrorWidget(
        message: provider.announcementError,
        onRetry: () {
          context.read<AcademicProvider>().fetchAnnouncements(
            refresh: true,
          );
        },
      );
    }

    if (provider.announcements.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 140),
            Icon(
              Icons.campaign_outlined,
              size: 56,
              color: isDark ? Colors.white24 : Colors.grey,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Belum ada pengumuman.',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: provider.announcements.length,
        separatorBuilder: (_, __) {
          return const SizedBox(height: 8);
        },
        itemBuilder: (context, index) {
          final item = provider.announcements[index];
          final judul = item['judul']?.toString() ?? '-';
          final isi = item['isi']?.toString() ?? '-';

          return Card(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2563EB).withOpacity(0.15) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.campaign_outlined,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                ),
              ),
              title: Text(
                judul,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
                ),
              ),
              onTap: () {
                final id = item['id']?.toString();

                if (id == null || id.isEmpty) {
                  return;
                }

                context.go(RouteNames.announcementDetailPath(id));
              },
              trailing: canManage
                  ? PopupMenuButton<String>(
                iconColor: isDark ? Colors.white70 : Colors.grey.shade600,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                onSelected: (value) {
                  if (value == 'detail') {
                    final id = item['id']?.toString();

                    if (id == null || id.isEmpty) {
                      return;
                    }

                    context.go(RouteNames.announcementDetailPath(id));
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
                    PopupMenuItem(
                      value: 'detail',
                      child: Text('Detail', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus', style: TextStyle(color: Colors.red.shade400)),
                    ),
                  ];
                },
              )
                  : Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : Colors.grey.shade400),
            ),
          );
        },
      ),
    );
  }
}

class _AnnouncementFormSheet extends StatefulWidget {
  final BuildContext parentContext;
  final Map<String, dynamic>? initialData;

  const _AnnouncementFormSheet({
    required this.parentContext,
    this.initialData,
  });

  @override
  State<_AnnouncementFormSheet> createState() => _AnnouncementFormSheetState();
}

class _AnnouncementFormSheetState extends State<_AnnouncementFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _isiController = TextEditingController();

  bool _isSubmitting = false;

  bool get _isEdit => widget.initialData != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      _judulController.text =
          widget.initialData?['judul']?.toString() ?? '';
      _isiController.text = widget.initialData?['isi']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<AcademicProvider>();

    final success = _isEdit
        ? await provider.updateAnnouncement(
      id: widget.initialData?['id']?.toString() ?? '',
      judul: _judulController.text.trim(),
      isi: _isiController.text.trim(),
    )
        : await provider.createAnnouncement(
      judul: _judulController.text.trim(),
      isi: _isiController.text.trim(),
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
                ? 'Pengumuman berhasil diperbarui.'
                : 'Pengumuman berhasil ditambahkan.',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.announcementError ?? 'Gagal menyimpan pengumuman.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Indikator "Drag Handle" di bagian atas untuk digeser
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Judul Form
                Text(
                  _isEdit ? 'Edit Pengumuman' : 'Tambah Pengumuman',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _judulController,
                  enabled: !_isSubmitting,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Judul Pengumuman',
                    hintText: 'Contoh: Libur Semester Ganjil',
                    prefixIcon: const Icon(Icons.title_outlined),
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul pengumuman wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _isiController,
                  enabled: !_isSubmitting,
                  maxLines: 7,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Isi Pengumuman',
                    hintText: 'Tuliskan isi pengumuman secara lengkap...',
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.notes_outlined),
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Isi pengumuman wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
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