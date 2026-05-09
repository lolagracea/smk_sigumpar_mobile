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
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(item['judul']?.toString() ?? 'Detail Pengumuman'),
          content: SingleChildScrollView(
            child: Text(
              item['isi']?.toString() ?? '-',
              style: const TextStyle(height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Tutup'),
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

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            final isMatch = controller.text.trim() == title;

            return AlertDialog(
              title: const Text('Hapus Pengumuman'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ketik ulang judul "$title" untuk menghapus pengumuman ini.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      labelText: 'Judul Pengumuman',
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Manajemen Pengumuman',
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
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.campaign_outlined,
              size: 56,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Center(
              child: Text('Belum ada pengumuman.'),
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
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              title: Text(
                judul,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                  return const [
                    PopupMenuItem(
                      value: 'detail',
                      child: Text('Detail'),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus'),
                    ),
                  ];
                },
              )
                  : const Icon(Icons.chevron_right_rounded),
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
                        _isEdit
                            ? 'Edit Pengumuman'
                            : 'Tambah Pengumuman',
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
                  controller: _judulController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Judul Pengumuman',
                    hintText: 'Contoh: Libur Semester Ganjil',
                    prefixIcon: Icon(Icons.title_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul pengumuman wajib diisi';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _isiController,
                  enabled: !_isSubmitting,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Isi Pengumuman',
                    hintText: 'Tuliskan isi pengumuman secara lengkap...',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
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
                    icon: _isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
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