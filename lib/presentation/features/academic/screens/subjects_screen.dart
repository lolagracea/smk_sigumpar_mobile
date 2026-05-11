import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/role_helper.dart';
import '../../../../data/models/class_model.dart';
import '../../../../data/models/subject_model.dart';
import '../../../../data/models/user_search_model.dart';
import '../../../../data/repositories/academic_repository.dart';
import '../../../common/providers/auth_provider.dart';
import '../../../common/widgets/error_widget.dart';
import '../../../common/widgets/loading_widget.dart';
import '../providers/academic_provider.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(
        repository: sl<AcademicRepository>(),
      )
        ..fetchSubjects(refresh: true)
        ..fetchClasses(refresh: true),
      child: const _SubjectsView(),
    );
  }
}

class _SubjectsView extends StatefulWidget {
  const _SubjectsView();

  @override
  State<_SubjectsView> createState() => _SubjectsViewState();
}

class _SubjectsViewState extends State<_SubjectsView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String? _selectedClassId;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _canManageSubject(BuildContext context) {
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

    if (!provider.hasMoreSubjects) return;
    if (provider.subjectState == AcademicLoadState.loading) return;

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 200) {
      provider.fetchSubjects(
        classId: _selectedClassId,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      context.read<AcademicProvider>().fetchSubjects(
        refresh: true,
        classId: _selectedClassId,
        search: value.trim().isEmpty ? null : value.trim(),
      );
    });

    setState(() {});
  }

  Future<void> _refresh() {
    return context.read<AcademicProvider>().fetchSubjects(
      refresh: true,
      classId: _selectedClassId,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );
  }

  void _openFormSheet({
    SubjectModel? subject,
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
          child: _SubjectFormSheet(
            parentContext: parentContext,
            subject: subject,
          ),
        );
      },
    );
  }

  void _openDeleteDialog(SubjectModel subject) {
    final parentContext = context;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            final isMatch = controller.text.trim() == subject.namaMapel;

            return AlertDialog(
              title: const Text('Hapus Mata Pelajaran'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tindakan ini akan menghapus assignment mapel ke guru dan kelas.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subject.namaMapel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Ketik nama mata pelajaran',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: isMatch
                      ? () async {
                    final provider =
                    parentContext.read<AcademicProvider>();

                    final success = await provider.deleteSubject(
                      id: subject.id,
                    );

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    if (!parentContext.mounted) return;

                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Mata pelajaran berhasil dihapus.'
                              : provider.subjectError ??
                              'Gagal menghapus mata pelajaran.',
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
    final canManage = _canManageSubject(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Mata Pelajaran',
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
                  label: const Text('Tambah Mapel'),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari mapel, kelas, atau guru...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();

                  context.read<AcademicProvider>().fetchSubjects(
                    refresh: true,
                    classId: _selectedClassId,
                  );

                  setState(() {});
                },
                icon: const Icon(Icons.clear_rounded),
              )
                  : null,
            ),
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
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
                  child: Text('${kelas.tingkat} - ${kelas.namaKelas}'),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedClassId = value;
              });

              context.read<AcademicProvider>().fetchSubjects(
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
    if ((provider.subjectState == AcademicLoadState.initial ||
        provider.subjectState == AcademicLoadState.loading) &&
        provider.subjects.isEmpty) {
      return const LoadingWidget();
    }

    if (provider.subjectState == AcademicLoadState.error &&
        provider.subjects.isEmpty) {
      return AppErrorWidget(
        message: provider.subjectError,
        onRetry: () {
          context.read<AcademicProvider>().fetchSubjects(refresh: true);
        },
      );
    }

    if (provider.subjects.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Icon(Icons.menu_book_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Center(child: Text('Belum ada data mata pelajaran.')),
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
        itemCount:
        provider.subjects.length + (provider.hasMoreSubjects ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == provider.subjects.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final subject = provider.subjects[index];

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
                  Icons.menu_book_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              title: Text(
                subject.namaMapel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    if (subject.kelasLabel.isNotEmpty) subject.kelasLabel,
                    if (subject.guruMapelNama.isNotEmpty)
                      subject.guruMapelNama,
                  ].join(' • '),
                ),
              ),
              trailing: canManage
                  ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openFormSheet(subject: subject);
                  } else if (value == 'delete') {
                    _openDeleteDialog(subject);
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

class _SubjectFormSheet extends StatefulWidget {
  final BuildContext parentContext;
  final SubjectModel? subject;

  const _SubjectFormSheet({
    required this.parentContext,
    this.subject,
  });

  @override
  State<_SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends State<_SubjectFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _namaMapelController = TextEditingController();
  final _guruController = TextEditingController();

  String? _selectedKelasId;
  UserSearchModel? _selectedGuru;

  Timer? _debounce;
  bool _isSearchingGuru = false;
  bool _isSubmitting = false;

  List<UserSearchModel> _guruSuggestions = [];

  bool get _isEdit => widget.subject != null;

  @override
  void initState() {
    super.initState();

    final subject = widget.subject;

    if (subject != null) {
      _namaMapelController.text = subject.namaMapel;
      _selectedKelasId = subject.kelasId;

      _selectedGuru = UserSearchModel(
        id: subject.guruMapelId,
        username: subject.guruMapelNama,
        fullName: subject.guruMapelNama,
        roles: const ['guru-mapel'],
      );

      _guruController.text = subject.guruMapelNama;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _namaMapelController.dispose();
    _guruController.dispose();
    super.dispose();
  }

  void _onGuruChanged(String value) {
    _selectedGuru = null;
    _debounce?.cancel();

    final keyword = value.trim();

    if (keyword.isEmpty) {
      setState(() {
        _guruSuggestions = [];
        _isSearchingGuru = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;

      setState(() {
        _isSearchingGuru = true;
      });

      final result = await context
          .read<AcademicProvider>()
          .searchGuruMapel(keyword);

      if (!mounted) return;

      setState(() {
        _guruSuggestions = result;
        _isSearchingGuru = false;
      });
    });

    setState(() {});
  }

  void _selectGuru(UserSearchModel guru) {
    setState(() {
      _selectedGuru = guru;
      _guruController.text =
      guru.fullName.isNotEmpty ? guru.fullName : guru.username;
      _guruSuggestions = [];
      _isSearchingGuru = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGuru == null) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('Pilih guru mapel dari hasil rekomendasi.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<AcademicProvider>();

    final success = _isEdit
        ? await provider.updateSubject(
      id: widget.subject!.id,
      namaMapel: _namaMapelController.text.trim(),
      kelasId: _selectedKelasId!,
      guruMapelId: _selectedGuru!.id,
      guruMapelNama: _guruController.text.trim(),
    )
        : await provider.createSubject(
      namaMapel: _namaMapelController.text.trim(),
      kelasId: _selectedKelasId!,
      guruMapelId: _selectedGuru!.id,
      guruMapelNama: _guruController.text.trim(),
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
                ? 'Mata pelajaran berhasil diperbarui.'
                : 'Mata pelajaran berhasil ditambahkan.',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.subjectError ?? 'Gagal menyimpan mata pelajaran.',
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                            ? 'Edit Mata Pelajaran'
                            : 'Tambah Mata Pelajaran',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _namaMapelController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Nama Mata Pelajaran',
                    hintText: 'Contoh: Matematika',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama mata pelajaran wajib diisi';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value:
                  _selectedKelasId?.isEmpty == true ? null : _selectedKelasId,
                  decoration: const InputDecoration(
                    labelText: 'Kelas',
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
                const SizedBox(height: 14),
                TextFormField(
                  controller: _guruController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Guru Mapel',
                    hintText: 'Ketik nama guru mapel',
                    prefixIcon: const Icon(Icons.person_search_outlined),
                    suffixIcon: _isSearchingGuru
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                        : _guruController.text.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        setState(() {
                          _guruController.clear();
                          _selectedGuru = null;
                          _guruSuggestions = [];
                        });
                      },
                      icon: const Icon(Icons.clear_rounded),
                    )
                        : null,
                  ),
                  onChanged: _onGuruChanged,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Guru mapel wajib dipilih';
                    }

                    if (_selectedGuru == null) {
                      return 'Pilih guru dari rekomendasi';
                    }

                    return null;
                  },
                ),
                if (_guruSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _guruSuggestions.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final guru = _guruSuggestions[index];

                        return ListTile(
                          dense: true,
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(
                            guru.fullName.isNotEmpty
                                ? guru.fullName
                                : guru.username,
                          ),
                          subtitle: Text(
                            guru.email?.isNotEmpty == true
                                ? guru.email!
                                : '@${guru.username}',
                          ),
                          onTap: () => _selectGuru(guru),
                        );
                      },
                    ),
                  ),
                ],
                if (_selectedGuru != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Guru terpilih: ${_guruController.text}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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
                      _isSubmitting ? 'Menyimpan...' : 'Simpan Mapel',
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