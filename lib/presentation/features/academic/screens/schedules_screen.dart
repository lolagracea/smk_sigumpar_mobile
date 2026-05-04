import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/role_helper.dart';
import '../../../../data/models/mapel_assignment_model.dart';
import '../../../../data/models/schedule_model.dart';
import '../../../../data/models/user_search_model.dart';
import '../../../../data/repositories/academic_repository.dart';
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

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            final isMatch = controller.text.trim().toUpperCase() == 'HAPUS';

            return AlertDialog(
              title: const Text('Hapus Jadwal Mengajar'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anda yakin ingin menghapus jadwal ${item.mataPelajaran} untuk kelas ${item.namaKelas ?? '-'}?',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ketik HAPUS untuk konfirmasi.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi',
                      hintText: 'HAPUS',
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Jadwal Mengajar',
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
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.schedule_outlined,
              size: 56,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Center(
              child: Text('Belum ada jadwal mengajar.'),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
              Card(
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.schedule_outlined,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  title: Text(
                    item.mataPelajaran.isNotEmpty
                        ? item.mataPelajaran
                        : item.namaMapel ?? '-',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
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
                    ),
                  ),
                  trailing: canManage
                      ? PopupMenuButton<String>(
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
                            ? 'Edit Jadwal Mengajar'
                            : 'Tambah Jadwal Mengajar',
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
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih guru mapel, lalu pilih mapel dan kelas yang sudah di-assign.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _guruController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Guru Pengajar',
                    hintText: 'Ketik nama guru mapel...',
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
                          _assignments = [];
                          _selectedAssignment = null;
                          _selectedAssignmentMapelId = null;
                        });
                      },
                      icon: const Icon(Icons.clear_rounded),
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
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedAssignmentMapelId,
                  decoration: const InputDecoration(
                    labelText: 'Mata Pelajaran & Kelas',
                    prefixIcon: Icon(Icons.menu_book_outlined),
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Memuat assignment guru mapel...',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                if (!_isLoadingAssignments &&
                    _selectedGuru != null &&
                    _assignments.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Guru ini belum memiliki assignment mapel dan kelas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedHari,
                  decoration: const InputDecoration(
                    labelText: 'Hari',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
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
                          decoration: const InputDecoration(
                            labelText: 'Waktu Mulai',
                            prefixIcon: Icon(Icons.access_time_outlined),
                          ),
                          child: Text(
                            _formatTime(_waktuMulai).isEmpty
                                ? 'Pilih jam'
                                : _formatTime(_waktuMulai),
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
                          decoration: const InputDecoration(
                            labelText: 'Waktu Berakhir',
                            prefixIcon: Icon(Icons.access_time_filled_outlined),
                          ),
                          child: Text(
                            _formatTime(_waktuBerakhir).isEmpty
                                ? 'Pilih jam'
                                : _formatTime(_waktuBerakhir),
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
                    icon: _isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
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