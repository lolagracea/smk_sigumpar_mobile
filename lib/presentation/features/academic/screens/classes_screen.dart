import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/role_helper.dart';
import '../../../../data/models/user_search_model.dart';
import '../../../../data/repositories/academic_repository.dart';
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Manajemen Kelas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (canManageClass)
                FilledButton.icon(
                  onPressed: _openAddClassSheet,
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
            decoration: InputDecoration(
              hintText: AppStrings.search,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear_rounded),
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
          child: _buildClassContent(provider),
        ),
      ],
    );
  }

  Widget _buildClassContent(AcademicProvider provider) {
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
          children: const [
            SizedBox(height: 160),
            Center(
              child: Text(AppStrings.noData),
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
        itemCount:
        provider.classes.length + (provider.hasMoreClasses ? 1 : 0),
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
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.academic.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.class_outlined,
                  color: AppColors.academic,
                ),
              ),
              title: Text(
                kelas.namaKelas,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
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
                    color: AppColors.grey500,
                  ),
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey400,
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

      final result = await context
          .read<AcademicProvider>()
          .searchWaliKelas(keyword);

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
                    const Expanded(
                      child: Text(
                        'Tambah Kelas',
                        style: TextStyle(
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
                  controller: _namaKelasController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Kelas',
                    hintText: 'Contoh: X RPL 1',
                    prefixIcon: Icon(Icons.class_outlined),
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
                  decoration: const InputDecoration(
                    labelText: 'Tingkat',
                    prefixIcon: Icon(Icons.school_outlined),
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
                  decoration: InputDecoration(
                    labelText: 'Wali Kelas',
                    hintText: 'Ketik nama wali kelas',
                    prefixIcon: const Icon(Icons.person_search_outlined),
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
                      icon: const Icon(Icons.clear_rounded),
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
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) {
                        return Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        );
                      },
                      itemBuilder: (context, index) {
                        final user = _suggestions[index];

                        return ListTile(
                          dense: true,
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName
                                : user.username,
                          ),
                          subtitle: Text(
                            user.email?.isNotEmpty == true
                                ? user.email!
                                : '@${user.username}',
                          ),
                          onTap: () {
                            setState(() {
                              _selectedWaliKelas = user;
                              _waliKelasController.text =
                              user.fullName.isNotEmpty
                                  ? user.fullName
                                  : user.username;
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
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Wali kelas terpilih: ${_selectedWaliKelas!.fullName.isNotEmpty ? _selectedWaliKelas!.fullName : _selectedWaliKelas!.username}',
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
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