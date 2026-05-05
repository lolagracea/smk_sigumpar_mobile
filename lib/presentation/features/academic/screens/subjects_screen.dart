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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            final isMatch = controller.text.trim() == subject.namaMapel;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text(
                'Hapus Mata Pelajaran',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tindakan ini akan menghapus assignment mapel ke guru dan kelas.',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subject.namaMapel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Ketik nama mata pelajaran',
                      labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Batal',
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Mata Pelajaran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (canManage)
                FilledButton.icon(
                  onPressed: () => _openFormSheet(),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
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
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Cari mapel, kelas, atau guru...',
              hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
              prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.grey.shade600),
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
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
                icon: Icon(Icons.clear_rounded, color: isDark ? Colors.white54 : Colors.grey.shade600),
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
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: 'Filter Kelas',
              prefixIcon: const Icon(Icons.class_outlined),
              labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
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
          children: [
            const SizedBox(height: 140),
            Icon(Icons.menu_book_outlined, size: 56, color: isDark ? Colors.white24 : Colors.grey),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Belum ada data mata pelajaran.',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
              ),
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
                  Icons.menu_book_outlined,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                ),
              ),
              title: Text(
                subject.namaMapel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
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
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
                ),
              ),
              trailing: canManage
                  ? PopupMenuButton<String>(
                iconColor: isDark ? Colors.white70 : Colors.grey.shade600,
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                onSelected: (value) {
                  if (value == 'edit') {
                    _openFormSheet(subject: subject);
                  } else if (value == 'delete') {
                    _openDeleteDialog(subject);
                  }
                },
                itemBuilder: (_) {
                  return [
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  _isEdit ? 'Edit Mata Pelajaran' : 'Tambah Mata Pelajaran',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _namaMapelController,
                  enabled: !_isSubmitting,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Nama Mata Pelajaran',
                    hintText: 'Contoh: Matematika',
                    prefixIcon: const Icon(Icons.menu_book_outlined),
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
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
                  value: _selectedKelasId?.isEmpty == true ? null : _selectedKelasId,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Kelas',
                    prefixIcon: const Icon(Icons.class_outlined),
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
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
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Guru Mapel',
                    hintText: 'Ketik nama guru mapel',
                    prefixIcon: const Icon(Icons.person_search_outlined),
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
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
                      icon: Icon(
                        Icons.clear_rounded,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
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
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _guruSuggestions.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final guru = _guruSuggestions[index];

                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                            child: Icon(
                              Icons.person_outline,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          title: Text(
                            guru.fullName.isNotEmpty ? guru.fullName : guru.username,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          ),
                          subtitle: Text(
                            guru.email?.isNotEmpty == true ? guru.email! : '@${guru.username}',
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600),
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
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: isDark ? Colors.green.shade400 : Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Guru terpilih: ${_guruController.text}',
                          style: TextStyle(
                            color: isDark ? Colors.green.shade400 : Colors.green,
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