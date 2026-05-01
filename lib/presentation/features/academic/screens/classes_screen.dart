import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/academic_provider.dart';
import 'package:smk_sigumpar/data/models/class_model.dart';
import 'package:smk_sigumpar/data/repositories/academic_repository.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../common/widgets/loading_widget.dart';
import '../../../common/widgets/error_widget.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(repository: sl<AcademicRepository>())
        ..fetchClasses(),
      child: const _ClassesView(),
    );
  }
}

class _ClassesView extends StatefulWidget {
  const _ClassesView();

  @override
  State<_ClassesView> createState() => _ClassesViewState();
}

class _ClassesViewState extends State<_ClassesView> {
  final _searchController = TextEditingController();

  String _getUserId(Map<String, dynamic> user) {
    return user['id']?.toString() ??
        user['user_id']?.toString() ??
        user['keycloak_id']?.toString() ??
        user['sub']?.toString() ??
        '';
  }

  String _getUserName(Map<String, dynamic> user) {
    return user['name']?.toString() ??
        user['nama']?.toString() ??
        user['nama_lengkap']?.toString() ??
        user['full_name']?.toString() ??
        user['username']?.toString() ??
        user['preferred_username']?.toString() ??
        '-';
  }

  Future<void> _showClassForm({
    ClassModel? initialData,
  }) async {
    final provider = context.read<AcademicProvider>();
    final isEdit = initialData != null;

    await provider.fetchWaliKelasUsers();

    final namaController = TextEditingController(
      text: initialData?.namaKelas ?? '',
    );

    String tingkat = initialData?.tingkat.isNotEmpty == true
        ? initialData!.tingkat
        : 'X';

    String? waliKelasId =
    initialData?.waliKelasId != null && initialData!.waliKelasId!.isNotEmpty
        ? initialData.waliKelasId
        : null;

    final waliKelasUsers = provider.waliKelasUsers;

    String getUserId(Map<String, dynamic> user) {
      return user['id']?.toString() ??
          user['user_id']?.toString() ??
          user['keycloak_id']?.toString() ??
          user['sub']?.toString() ??
          '';
    }

    String getUserName(Map<String, dynamic> user) {
      return user['name']?.toString() ??
          user['nama']?.toString() ??
          user['nama_lengkap']?.toString() ??
          user['full_name']?.toString() ??
          user['username']?.toString() ??
          user['preferred_username']?.toString() ??
          '-';
    }

    final dropdownItems = waliKelasUsers
        .map((user) {
      final id = getUserId(user);
      final name = getUserName(user);

      if (id.isEmpty) return null;

      return DropdownMenuItem<String>(
        value: id,
        child: Text(
          name,
          overflow: TextOverflow.ellipsis,
        ),
      );
    })
        .whereType<DropdownMenuItem<String>>()
        .toList();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            final selectedWaliStillExists = waliKelasId != null &&
                dropdownItems.any((item) => item.value == waliKelasId);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: bottomInset + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),

                    Text(
                      isEdit ? 'Edit Kelas' : 'Tambah Kelas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      isEdit
                          ? 'Perbarui data kelas dan wali kelas.'
                          : 'Tambahkan kelas baru dan assign user wali kelas.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: namaController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kelas',
                        hintText: 'Contoh: X RPL 1',
                        prefixIcon: Icon(Icons.class_outlined),
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: tingkat,
                      decoration: const InputDecoration(
                        labelText: 'Tingkat',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'X', child: Text('X')),
                        DropdownMenuItem(value: 'XI', child: Text('XI')),
                        DropdownMenuItem(value: 'XII', child: Text('XII')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => tingkat = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: selectedWaliStillExists ? waliKelasId : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Wali Kelas',
                        hintText: 'Pilih user wali kelas',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: dropdownItems,
                      onChanged: (value) {
                        setModalState(() => waliKelasId = value);
                      },
                    ),

                    if (dropdownItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Belum ada user dengan role wali-kelas.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey600,
                          ),
                        ),
                      ),

                    if (provider.waliKelasError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          provider.waliKelasError!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(bottomSheetContext, false),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save_outlined),
                            label: Text(isEdit ? 'Update' : 'Simpan'),
                            onPressed: () async {
                              final namaKelas = namaController.text.trim();

                              if (namaKelas.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nama kelas wajib diisi'),
                                  ),
                                );
                                return;
                              }

                              if (waliKelasId == null ||
                                  waliKelasId!.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Wali kelas wajib dipilih'),
                                  ),
                                );
                                return;
                              }

                              final success = isEdit
                                  ? await provider.updateClass(
                                id: initialData.id,
                                namaKelas: namaKelas,
                                tingkat: tingkat,
                                waliKelasId: waliKelasId,
                              )
                                  : await provider.createClass(
                                namaKelas: namaKelas,
                                tingkat: tingkat,
                                waliKelasId: waliKelasId,
                              );

                              if (!context.mounted) return;

                              if (success) {
                                Navigator.pop(bottomSheetContext, true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      provider.classError ??
                                          'Gagal menyimpan kelas',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    namaController.dispose();

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? 'Kelas berhasil diperbarui' : 'Kelas berhasil ditambahkan',
          ),
        ),
      );
    }
  }

  Future<void> _deleteClass(ClassModel cls) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Kelas'),
          content: Text(
            'Apakah kamu yakin ingin menghapus kelas ${cls.namaKelas}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final provider = context.read<AcademicProvider>();
    final success = await provider.deleteClass(cls.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Kelas berhasil dihapus'
              : provider.classError ?? 'Gagal menghapus kelas',
        ),
      ),
    );
  }

  List<ClassModel> _filterClasses(List<ClassModel> classes) {
    final keyword = _searchController.text.trim().toLowerCase();

    if (keyword.isEmpty) return classes;

    return classes.where((item) {
      return item.namaKelas.toLowerCase().contains(keyword) ||
          item.tingkat.toLowerCase().contains(keyword) ||
          (item.waliKelasNama ?? '').toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();
    final classes = _filterClasses(provider.classes);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.classes),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              context.read<AcademicProvider>().fetchClasses(refresh: true);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClassForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Kelas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari kelas...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          Expanded(
            child: switch (provider.classState) {
            AcademicLoadState.initial ||
            AcademicLoadState.loading
            when provider.classes.isEmpty =>
            const LoadingWidget(message: 'Memuat data kelas...'),

            AcademicLoadState.error when provider.classes.isEmpty =>
            AppErrorWidget(
            message: provider.classError,
            onRetry: () => context
                .read<AcademicProvider>()
                .fetchClasses(refresh: true),
            ),

            _ => RefreshIndicator(
            onRefresh: () => context
                .read<AcademicProvider>()
                .fetchClasses(refresh: true),
            child: classes.isEmpty
            ? ListView(
            children: const [
            SizedBox(height: 160),
            Center(child: Text('Belum ada data kelas')),
            ],
            )
                : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            itemCount: classes.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 10),
            itemBuilder: (context, index) {
            final cls = classes[index];

            return Card(
            child: ListTile(
            leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
            color: AppColors.academic.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
            Icons.class_outlined,
            color: AppColors.academic,
            ),
            ),
            title: Text(
            cls.namaKelas,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
            'Tingkat ${cls.tingkat}'
            '${cls.waliKelasNama != null && cls.waliKelasNama!.isNotEmpty ? ' • Wali: ${cls.waliKelasNama}' : ''}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.grey600),
            ),
            ),
            trailing: PopupMenuButton<String>(
            onSelected: (value) {
            if (value == 'edit') {
            _showClassForm(initialData: cls);
            }

            if (value == 'delete') {
            _deleteClass(cls);
            }
            },
            itemBuilder: (_) => const [
            PopupMenuItem(
            value: 'edit',
            child: Row(
            children: [
            Icon(Icons.edit_outlined),
            SizedBox(width: 8),
            Text('Edit'),
            ],
            ),
            ),
            PopupMenuItem(
            value: 'delete',
            child: Row(
            children: [
            Icon(
            Icons.delete_outline,
            color: AppColors.error,
            ),
            SizedBox(width: 8),
            Text('Hapus'),
            ],
            ),
            ),
            ],
            ),
            ),
            );
            },
            ),
            ),
            },
          ),
        ],
      ),
    );
  }
}