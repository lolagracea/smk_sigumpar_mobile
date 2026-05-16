import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/role_helper.dart';
import '../../../../data/models/mapel_assignment_model.dart';
import '../../../../data/models/schedule_model.dart';
import '../../../../data/models/user_search_model.dart';
import '../../../../data/repositories/academic_repository.dart';
import '../../../../data/repositories/kelola_akun_repository.dart';
import '../../../common/providers/auth_provider.dart';
import '../../../common/widgets/error_widget.dart';
import '../../../common/widgets/loading_widget.dart';
import '../providers/academic_provider.dart';

class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(
        repository: sl<AcademicRepository>(),
        kelolaAkunRepository: sl<KelolaAkunRepository>(),
      )..fetchSchedules(),
      child: const _SchedulesView(),
    );
  }
}

class _SchedulesView extends StatelessWidget {
  const _SchedulesView();

  bool _canManageSchedule(BuildContext context) {
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
        ScheduleModel? initialData,
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
          child: _ScheduleFormSheet(
            parentContext: parentContext,
            initialData: initialData,
          ),
        );
      },
    );
  }

  void _openDeleteDialog(
      BuildContext context,
      ScheduleModel item,
      ) {
    final parentContext = context;
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            final isMatch = controller.text.trim().toUpperCase() == 'HAPUS';

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: Text(
                'Hapus Jadwal Mengajar',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anda yakin ingin menghapus jadwal ${item.mataPelajaran} untuk kelas ${item.namaKelas ?? '-'}?',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ketik HAPUS untuk konfirmasi.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi',
                      hintText: 'HAPUS',
                      labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                      hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
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

                    final success = await provider.deleteSchedule(
                      id: item.id,
                    );

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    if (!parentContext.mounted) return;

                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Jadwal mengajar berhasil dihapus.'
                              : provider.scheduleError ??
                              'Gagal menghapus jadwal mengajar.',
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
    return context.read<AcademicProvider>().fetchSchedules();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();
    final canManage = _canManageSchedule(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Jadwal Mengajar',
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
                  label: const Text('Tambah Jadwal'),
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
    if ((provider.scheduleState == AcademicLoadState.initial ||
        provider.scheduleState == AcademicLoadState.loading) &&
        provider.schedules.isEmpty) {
      return const LoadingWidget();
    }

    if (provider.scheduleState == AcademicLoadState.error &&
        provider.schedules.isEmpty) {
      return AppErrorWidget(
        message: provider.scheduleError,
        onRetry: () {
          context.read<AcademicProvider>().fetchSchedules();
        },
      );
    }

    if (provider.schedules.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 140),
            Icon(
              Icons.schedule_outlined,
              size: 56,
              color: isDark ? Colors.white24 : Colors.grey,
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Belum ada jadwal mengajar.',
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
        itemCount: provider.schedules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = provider.schedules[index];
          final isNewDay = index == 0 ||
              item.hari != provider.schedules[index - 1].hari;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNewDay) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                  child: Text(
                    item.hari.isEmpty ? 'Hari Tidak Diisi' : item.hari,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
              Card(
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
                      Icons.schedule_outlined,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    ),
                  ),
                  title: Text(
                    item.mataPelajaran.isNotEmpty
                        ? item.mataPelajaran
                        : item.namaMapel ?? '-',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        '${item.waktuMulai} - ${item.waktuBerakhir}',
                        if ((item.namaKelas ?? '').isNotEmpty)
                          item.namaKelas!,
                        if ((item.guruNama ?? '').isNotEmpty)
                          item.guruNama!,
                      ].where((e) => e.trim().isNotEmpty).join(' • '),
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
                    ),
                  ),
                  trailing: canManage
                      ? PopupMenuButton<String>(
                    iconColor: isDark ? Colors.white70 : Colors.grey.shade600,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    onSelected: (value) {
                      if (value == 'edit') {
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
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScheduleFormSheet extends StatefulWidget {
  final BuildContext parentContext;
  final ScheduleModel? initialData;

  const _ScheduleFormSheet({
    required this.parentContext,
    this.initialData,
  });

  @override
  State<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<_ScheduleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _guruController = TextEditingController();

  final List<String> _hariOptions = const [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  UserSearchModel? _selectedGuru;
  String? _selectedAssignmentMapelId;
  MapelAssignmentModel? _selectedAssignment;
  String? _selectedHari;

  TimeOfDay? _waktuMulai;
  TimeOfDay? _waktuBerakhir;

  Timer? _debounce;
  bool _isSearchingGuru = false;
  bool _isLoadingAssignments = false;
  bool _isSubmitting = false;

  List<UserSearchModel> _guruSuggestions = [];
  List<MapelAssignmentModel> _assignments = [];

  bool get _isEdit => widget.initialData != null;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;

    if (data != null) {
      _selectedGuru = UserSearchModel(
        id: data.guruId ?? '',
        username: data.guruNama ?? '',
        fullName: data.guruNama ?? '',
        roles: const ['guru-mapel'],
      );

      _guruController.text = data.guruNama ?? '';
      _selectedHari = data.hari;
      _waktuMulai = _parseTime(data.waktuMulai);
      _waktuBerakhir = _parseTime(data.waktuBerakhir);

      if ((data.guruId ?? '').isNotEmpty) {
        _loadAssignments(
          data.guruId!,
          selectedMapelId: data.mapelId,
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _guruController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String value) {
    if (value.isEmpty || !value.contains(':')) return null;

    final parts = value.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  void _onGuruChanged(String value) {
    _selectedGuru = null;
    _selectedAssignment = null;
    _selectedAssignmentMapelId = null;
    _assignments = [];

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

  Future<void> _selectGuru(UserSearchModel guru) async {
    setState(() {
      _selectedGuru = guru;
      _guruController.text =
      guru.fullName.isNotEmpty ? guru.fullName : guru.username;
      _guruSuggestions = [];
      _selectedAssignment = null;
      _selectedAssignmentMapelId = null;
      _assignments = [];
    });

    await _loadAssignments(guru.id);
  }

  Future<void> _loadAssignments(
      String guruId, {
        String? selectedMapelId,
      }) async {
    if (guruId.isEmpty) return;

    setState(() {
      _isLoadingAssignments = true;
    });

    final result = await context.read<AcademicProvider>().getMapelByGuru(
      guruId,
    );

    if (!mounted) return;

    MapelAssignmentModel? selected;

    if (selectedMapelId != null && selectedMapelId.isNotEmpty) {
      for (final item in result) {
        if (item.mapelId == selectedMapelId) {
          selected = item;
          break;
        }
      }
    }

    setState(() {
      _assignments = result;
      _selectedAssignment = selected;
      _selectedAssignmentMapelId = selected?.mapelId;
      _isLoadingAssignments = false;
    });
  }

  Future<void> _pickStartTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _waktuMulai ?? const TimeOfDay(hour: 7, minute: 30),
    );

    if (result == null) return;

    setState(() {
      _waktuMulai = result;
    });
  }

  Future<void> _pickEndTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _waktuBerakhir ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (result == null) return;

    setState(() {
      _waktuBerakhir = result;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGuru == null) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('Pilih guru dari hasil rekomendasi.'),
        ),
      );
      return;
    }

    if (_selectedAssignment == null) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('Pilih mapel dan kelas yang sudah di-assign.'),
        ),
      );
      return;
    }

    if (_waktuMulai == null || _waktuBerakhir == null) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('Waktu mulai dan berakhir wajib dipilih.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<AcademicProvider>();

    final success = _isEdit
        ? await provider.updateSchedule(
      id: widget.initialData!.id,
      guruId: _selectedGuru!.id,
      guruNama: _guruController.text.trim(),
      kelasId: _selectedAssignment!.kelasId,
      mapelId: _selectedAssignment!.mapelId,
      mataPelajaran: _selectedAssignment!.namaMapel,
      hari: _selectedHari!,
      waktuMulai: _formatTime(_waktuMulai),
      waktuBerakhir: _formatTime(_waktuBerakhir),
    )
        : await provider.createSchedule(
      guruId: _selectedGuru!.id,
      guruNama: _guruController.text.trim(),
      kelasId: _selectedAssignment!.kelasId,
      mapelId: _selectedAssignment!.mapelId,
      mataPelajaran: _selectedAssignment!.namaMapel,
      hari: _selectedHari!,
      waktuMulai: _formatTime(_waktuMulai),
      waktuBerakhir: _formatTime(_waktuBerakhir),
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
                ? 'Jadwal mengajar berhasil diperbarui.'
                : 'Jadwal mengajar berhasil ditambahkan.',
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.scheduleError ?? 'Gagal menyimpan jadwal mengajar.',
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
                  _isEdit ? 'Edit Jadwal Mengajar' : 'Tambah Jadwal Mengajar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pilih guru mapel, lalu pilih mapel dan kelas yang sudah di-assign.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _guruController,
                  enabled: !_isSubmitting,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Guru Pengajar',
                    hintText: 'Ketik nama guru mapel...',
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
                          _assignments = [];
                          _selectedAssignment = null;
                          _selectedAssignmentMapelId = null;
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
                      return 'Guru pengajar wajib dipilih';
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
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedAssignmentMapelId,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Mata Pelajaran & Kelas',
                    prefixIcon: const Icon(Icons.menu_book_outlined),
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                  ),
                  items: _assignments.map((assignment) {
                    return DropdownMenuItem<String>(
                      value: assignment.mapelId,
                      child: Text(assignment.label),
                    );
                  }).toList(),
                  onChanged: (!_isSubmitting &&
                      _selectedGuru != null &&
                      !_isLoadingAssignments)
                      ? (value) {
                    final selected = _assignments
                        .where((item) => item.mapelId == value)
                        .cast<MapelAssignmentModel?>()
                        .firstOrNull;

                    setState(() {
                      _selectedAssignmentMapelId = value;
                      _selectedAssignment = selected;
                    });
                  }
                      : null,
                  validator: (value) {
                    if (_selectedGuru == null) {
                      return 'Pilih guru terlebih dahulu';
                    }
                    if (value == null || value.isEmpty) {
                      return 'Mapel dan kelas wajib dipilih';
                    }
                    return null;
                  },
                ),
                if (_isLoadingAssignments) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Memuat assignment guru mapel...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
                if (!_isLoadingAssignments &&
                    _selectedGuru != null &&
                    _assignments.isEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Guru ini belum memiliki assignment mapel dan kelas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.red.shade300 : Colors.red,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedHari,
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Hari',
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                  ),
                  items: _hariOptions.map((hari) {
                    return DropdownMenuItem<String>(
                      value: hari,
                      child: Text(hari),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                    setState(() {
                      _selectedHari = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Hari wajib dipilih';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _isSubmitting ? null : _pickStartTime,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Waktu Mulai',
                            prefixIcon: const Icon(Icons.access_time_outlined),
                            labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                          ),
                          child: Text(
                            _formatTime(_waktuMulai).isEmpty ? 'Pilih jam' : _formatTime(_waktuMulai),
                            style: TextStyle(
                              color: _waktuMulai == null
                                  ? (isDark ? Colors.white54 : Colors.grey.shade600)
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _isSubmitting ? null : _pickEndTime,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Waktu Berakhir',
                            prefixIcon: const Icon(Icons.access_time_filled_outlined),
                            labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade700),
                          ),
                          child: Text(
                            _formatTime(_waktuBerakhir).isEmpty ? 'Pilih jam' : _formatTime(_waktuBerakhir),
                            style: TextStyle(
                              color: _waktuBerakhir == null
                                  ? (isDark ? Colors.white54 : Colors.grey.shade600)
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                      _isSubmitting ? 'Menyimpan...' : 'Simpan Jadwal',
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

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}