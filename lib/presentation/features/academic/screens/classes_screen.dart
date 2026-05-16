import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/role_helper.dart';
import '../../../../data/models/user_search_model.dart';
import '../../../../data/repositories/academic_repository.dart';
import '../../../../data/repositories/kelola_akun_repository.dart';
import '../../../common/providers/auth_provider.dart';
import '../../../common/widgets/error_widget.dart';
import '../../../common/widgets/loading_widget.dart';
import '../providers/academic_provider.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(
        repository: sl<AcademicRepository>(),
        kelolaAkunRepository: sl<KelolaAkunRepository>(),
      )..fetchClasses(refresh: true),
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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

  bool _canManageClass(BuildContext context) {
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

    if (!provider.hasMoreClasses) return;
    if (provider.classState == AcademicLoadState.loading) return;

    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 200) {
      provider.fetchClasses(
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

      context.read<AcademicProvider>().fetchClasses(
        refresh: true,
        search: value.trim().isEmpty ? null : value.trim(),
      );
    });

    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();

    context.read<AcademicProvider>().fetchClasses(
      refresh: true,
    );

    setState(() {});
  }

  Future<void> _refreshClasses() {
    return context.read<AcademicProvider>().fetchClasses(
      refresh: true,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );
  }

  void _openAddClassSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: context.read<AcademicProvider>(),
          child: const _AddClassSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();
    final canManageClass = _canManageClass(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Manajemen Kelas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (canManageClass)
                FilledButton.icon(
                  onPressed: _openAddClassSheet,
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Kelas'),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: AppStrings.search,
              hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
              prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.grey.shade600),
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: _clearSearch,
                icon: Icon(Icons.clear_rounded, color: isDark ? Colors.white54 : Colors.grey.shade600),
              )
                  : null,
            ),
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              context.read<AcademicProvider>().fetchClasses(
                refresh: true,
                search: value.trim().isEmpty ? null : value.trim(),
              );
            },
          ),
        ),
        Expanded(
          child: _buildClassContent(provider, isDark),
        ),
      ],
    );
  }

  Widget _buildClassContent(AcademicProvider provider, bool isDark) {
    if ((provider.classState == AcademicLoadState.initial ||
        provider.classState == AcademicLoadState.loading) &&
        provider.classes.isEmpty) {
      return const LoadingWidget();
    }

    if (provider.classState == AcademicLoadState.error &&
        provider.classes.isEmpty) {
      return AppErrorWidget(
        message: provider.classError,
        onRetry: () {
          context.read<AcademicProvider>().fetchClasses(
            refresh: true,
          );
        },
      );
    }

    if (provider.classes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshClasses,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 160),
            Center(
              child: Text(
                AppStrings.noData,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshClasses,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: provider.classes.length + (provider.hasMoreClasses ? 1 : 0),
        separatorBuilder: (_, __) {
          return const SizedBox(height: 8);
        },
        itemBuilder: (context, index) {
          if (index == provider.classes.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final kelas = provider.classes[index];

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
                  color: isDark ? const Color(0xFF2563EB).withOpacity(0.15) : AppColors.academic.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.class_outlined,
                  color: isDark ? const Color(0xFF60A5FA) : AppColors.academic,
                ),
              ),
              title: Text(
                kelas.namaKelas,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    if (kelas.tingkat.isNotEmpty) 'Kelas ${kelas.tingkat}',
                    if ((kelas.waliKelasNama ?? '').isNotEmpty)
                      'Wali: ${kelas.waliKelasNama}',
                  ].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white70 : AppColors.grey500,
                  ),
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white30 : AppColors.grey400,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddClassSheet extends StatefulWidget {
  const _AddClassSheet();

  @override
  State<_AddClassSheet> createState() => _AddClassSheetState();
}

class _AddClassSheetState extends State<_AddClassSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _namaKelasController = TextEditingController();
  final TextEditingController _waliKelasController = TextEditingController();

  final List<String> _tingkatOptions = const [
    'X',
    'XI',
    'XII',
  ];

  String? _selectedTingkat;
  UserSearchModel? _selectedWaliKelas;

  Timer? _debounce;
  bool _isSearching = false;
  bool _isSubmitting = false;

  List<UserSearchModel> _suggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _namaKelasController.dispose();
    _waliKelasController.dispose();
    super.dispose();
  }

  void _onSearchWaliKelasChanged(String value) {
    _selectedWaliKelas = null;
    _debounce?.cancel();

    final keyword = value.trim();

    if (keyword.isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;

      setState(() {
        _isSearching = true;
      });

      final result = await context.read<AcademicProvider>().searchWaliKelas(keyword);

      if (!mounted) return;

      setState(() {
        _suggestions = result;
        _isSearching = false;
      });
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedWaliKelas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih wali kelas dari hasil rekomendasi.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await context.read<AcademicProvider>().createClass(
      namaKelas: _namaKelasController.text.trim(),
      tingkat: _selectedTingkat!,
      waliKelasId: _selectedWaliKelas!.id,
      waliKelasNama: _selectedWaliKelas!.fullName,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kelas berhasil ditambahkan.'),
        ),
      );
    } else {
      final error = context.read<AcademicProvider>().classError;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal menambahkan kelas.'),
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
                // Drag handle bar
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
                // Judul
                Text(
                  'Tambah Kelas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _namaKelasController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Nama Kelas',
                    hintText: 'Contoh: X RPL 1',
                    prefixIcon: const Icon(Icons.class_outlined),
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama kelas wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedTingkat,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Tingkat',
                    prefixIcon: const Icon(Icons.school_outlined),
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                  ),
                  items: _tingkatOptions.map((tingkat) {
                    return DropdownMenuItem<String>(
                      value: tingkat,
                      child: Text('Kelas $tingkat'),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                    setState(() {
                      _selectedTingkat = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tingkat wajib dipilih';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _waliKelasController,
                  enabled: !_isSubmitting,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Wali Kelas',
                    hintText: 'Ketik nama wali kelas',
                    prefixIcon: const Icon(Icons.person_search_outlined),
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                    suffixIcon: _isSearching
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                        : _waliKelasController.text.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        setState(() {
                          _waliKelasController.clear();
                          _selectedWaliKelas = null;
                          _suggestions = [];
                        });
                      },
                      icon: Icon(
                        Icons.clear_rounded,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    )
                        : null,
                  ),
                  onChanged: _onSearchWaliKelasChanged,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Wali kelas wajib dipilih';
                    }
                    if (_selectedWaliKelas == null) {
                      return 'Pilih wali kelas dari rekomendasi';
                    }
                    return null;
                  },
                ),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 220,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) {
                        return Divider(
                          height: 1,
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        );
                      },
                      itemBuilder: (context, index) {
                        final user = _suggestions[index];

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
                            user.fullName.isNotEmpty ? user.fullName : user.username,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          ),
                          subtitle: Text(
                            user.email?.isNotEmpty == true ? user.email! : '@${user.username}',
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedWaliKelas = user;
                              _waliKelasController.text =
                              user.fullName.isNotEmpty ? user.fullName : user.username;
                              _suggestions = [];
                              _isSearching = false;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
                if (_selectedWaliKelas != null) ...[
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
                          'Wali kelas terpilih: ${_selectedWaliKelas!.fullName.isNotEmpty ? _selectedWaliKelas!.fullName : _selectedWaliKelas!.username}',
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
                      _isSubmitting ? 'Menyimpan...' : 'Tambah Kelas',
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