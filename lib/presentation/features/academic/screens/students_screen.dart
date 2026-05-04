import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/role_helper.dart';
import '../../../../data/models/class_model.dart';
import '../../../../data/models/student_model.dart';
import '../../../../data/repositories/academic_repository.dart';
import '../../../common/providers/auth_provider.dart';
import '../../../common/widgets/error_widget.dart';
import '../../../common/widgets/loading_widget.dart';
import '../providers/academic_provider.dart';

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(
        repository: sl<AcademicRepository>(),
      )
        ..fetchStudents(refresh: true)
        ..fetchClasses(refresh: true),
      child: const _StudentsView(),
    );
  }
}

class _StudentsView extends StatefulWidget {
  const _StudentsView();

  @override
  State<_StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<_StudentsView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _canManageStudent(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    return RoleHelper.hasRole(
      targetRole: AppRoles.staff,
      role: user?.role,
      roles: user?.roles,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final provider = context.read<AcademicProvider>();

    if (!provider.hasMoreStudents) return;
    if (provider.studentState == AcademicLoadState.loading) return;

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 200) {
      provider.fetchStudents(
        classId: _selectedClassId,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
    }
  }

  Future<void> _refresh() {
    return context.read<AcademicProvider>().fetchStudents(
      refresh: true,
      classId: _selectedClassId,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );
  }

  void _onSearchSubmitted(String value) {
    context.read<AcademicProvider>().fetchStudents(
      refresh: true,
      classId: _selectedClassId,
      search: value.trim().isEmpty ? null : value.trim(),
    );
  }

  void _openFormSheet({
    StudentModel? student,
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
          child: _StudentFormSheet(
            parentContext: parentContext,
            student: student,
          ),
        );
      },
    );
  }

  void _openDeleteDialog(StudentModel student) {
    final parentContext = context;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            final isMatch = controller.text.trim() == student.namaLengkap;

            return AlertDialog(
              title: const Text('Hapus Data Siswa'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tindakan ini bersifat permanen. Ketik ulang nama lengkap siswa untuk konfirmasi.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    student.namaLengkap,
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
                      labelText: 'Nama lengkap siswa',
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

                    final success = await provider.deleteStudent(
                      id: student.id,
                    );

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    if (!parentContext.mounted) return;

                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Siswa berhasil dihapus.'
                              : provider.studentError ??
                              'Gagal menghapus siswa.',
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();
    final canManage = _canManageStudent(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Manajemen Siswa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (canManage)
                FilledButton.icon(
                  onPressed: () => _openFormSheet(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Siswa'),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari NISN, nama siswa, atau kelas...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();

                  context.read<AcademicProvider>().fetchStudents(
                    refresh: true,
                    classId: _selectedClassId,
                  );

                  setState(() {});
                },
                icon: const Icon(Icons.clear_rounded),
              )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: _onSearchSubmitted,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: DropdownButtonFormField<String>(
            value: _selectedClassId,
            decoration: const InputDecoration(
              labelText: 'Filter Kelas',
              prefixIcon: Icon(Icons.class_outlined),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Semua Kelas'),
              ),
              ...provider.classes.map((kelas) {
                return DropdownMenuItem<String>(
                  value: kelas.id,
                  child: Text(
                    '${kelas.tingkat} - ${kelas.namaKelas}',
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedClassId = value;
              });

              context.read<AcademicProvider>().fetchStudents(
                refresh: true,
                classId: value,
                search: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
              );
            },
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
    if ((provider.studentState == AcademicLoadState.initial ||
        provider.studentState == AcademicLoadState.loading) &&
        provider.students.isEmpty) {
      return const LoadingWidget();
    }

    if (provider.studentState == AcademicLoadState.error &&
        provider.students.isEmpty) {
      return AppErrorWidget(
        message: provider.studentError,
        onRetry: () {
          context.read<AcademicProvider>().fetchStudents(refresh: true);
        },
      );
    }

    if (provider.students.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.groups_outlined,
              size: 56,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Center(
              child: Text('Belum ada data siswa.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: provider.students.length +
            (provider.hasMoreStudents ? 1 : 0),
        separatorBuilder: (_, __) {
          return const SizedBox(height: 8);
        },
        itemBuilder: (context, index) {
          if (index == provider.students.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final siswa = provider.students[index];

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
                  Icons.person_outline,
                  color: Color(0xFF2563EB),
                ),
              ),
              title: Text(
                siswa.namaLengkap,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    if (siswa.nisn.isNotEmpty) 'NISN: ${siswa.nisn}',
                    if (siswa.namaKelas.isNotEmpty) siswa.namaKelas,
                  ].join(' • '),
                ),
              ),
              trailing: canManage
                  ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openFormSheet(student: siswa);
                  } else if (value == 'delete') {
                    _openDeleteDialog(siswa);
                  }
                },
                itemBuilder: (_) {
                  return const [
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
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _StudentFormSheet extends StatefulWidget {
  final BuildContext parentContext;
  final StudentModel? student;

  const _StudentFormSheet({
    required this.parentContext,
    this.student,
  });

  @override
  State<_StudentFormSheet> createState() => _StudentFormSheetState();
}

class _StudentFormSheetState extends State<_StudentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nisnController = TextEditingController();
  final _namaLengkapController = TextEditingController();

  String? _selectedKelasId;
  bool _isSubmitting = false;

  bool get _isEdit => widget.student != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      _nisnController.text = widget.student?.nisn ?? '';
      _namaLengkapController.text = widget.student?.namaLengkap ?? '';
      _selectedKelasId = widget.student?.kelasId;
    }
  }

  @override
  void dispose() {
    _nisnController.dispose();
    _namaLengkapController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<AcademicProvider>();

    final success = _isEdit
        ? await provider.updateStudent(
      id: widget.student!.id,
      nisn: _nisnController.text.trim(),
      namaLengkap: _namaLengkapController.text.trim(),
      kelasId: _selectedKelasId!,
    )
        : await provider.createStudent(
      nisn: _nisnController.text.trim(),
      namaLengkap: _namaLengkapController.text.trim(),
      kelasId: _selectedKelasId!,
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
                ? 'Data siswa berhasil diperbarui.'
                : 'Siswa berhasil ditambahkan.',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.studentError ?? 'Gagal menyimpan data siswa.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();
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
                        _isEdit ? 'Edit Data Siswa' : 'Tambah Siswa Baru',
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
                  controller: _nisnController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'NISN',
                    hintText: 'Masukkan NISN',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'NISN wajib diisi';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _namaLengkapController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'Nama lengkap sesuai ijazah',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap wajib diisi';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedKelasId?.isEmpty == true
                      ? null
                      : _selectedKelasId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Kelas',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  items: provider.classes.map((kelas) {
                    return DropdownMenuItem<String>(
                      value: kelas.id,
                      child: Text('${kelas.tingkat} - ${kelas.namaKelas}'),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                    setState(() {
                      _selectedKelasId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kelas wajib dipilih';
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSubmitting ? 'Menyimpan...' : 'Simpan Data'),
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