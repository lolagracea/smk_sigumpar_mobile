import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Penting untuk cek Web

import '../../../common/providers/auth_provider.dart';
import '../providers/learning_provider.dart';
import '../../../../data/models/absensi_guru_model.dart';
import '../../../../core/utils/absensi_time_validator.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final TextEditingController _remarksController = TextEditingController();
  Timer? _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());

    // Auto-refresh window every 10s
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) { timer.cancel(); return; }
      context.read<LearningProvider>().refreshTimeStatus();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _remarksController.dispose();
    super.dispose();
  }

  void _updateClock() {
    if (mounted) {
      setState(() => _currentTime = AbsensiTimeValidator.getCurrentTimeFormatted());
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Attendance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current User Info
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(auth.user?.name ?? 'Teacher'),
                trailing: Text('$_currentTime WIB'),
              ),
            ),
            const SizedBox(height: 16),

            // Status Window Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: provider.isWithinTimeWindow ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(provider.isWithinTimeWindow
                  ? 'Window Open. Deadline: ${AbsensiTimeValidator.getCountdownToDeadline()}'
                  : provider.timeValidationMessage ?? 'Attendance Closed'),
            ),
            const SizedBox(height: 16),

            // Attendance Status Dropdown
            DropdownButtonFormField<StatusKehadiran>(
              value: provider.selectedStatus,
              decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder()
              ),
              items: StatusKehadiran.selectableStatuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => v != null ? provider.setAttendanceStatus(v) : null,
            ),
            const SizedBox(height: 16),

            // Remarks
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Remarks (Optional)',
                  border: OutlineInputBorder()
              ),
              onChanged: (v) => provider.setRemarks(v),
            ),
            const SizedBox(height: 16),

            // Photo Preview with Web Support
            GestureDetector(
              onTap: () => _showPicker(context, provider),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8)
                ),
                child: provider.selectedPhoto == null
                    ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                    : kIsWeb
                    ? Image.memory(provider.webImageBytes!, fit: BoxFit.cover)
                    : Image.file(File(provider.selectedPhoto!.path), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: provider.canSubmitAttendance ? () async {
                final success = await provider.submitAttendance(
                    teacherName: auth.user?.name ?? ''
                );
                if (success && mounted) {
                  _remarksController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Attendance submitted successfully!'))
                  );
                }
              } : null,
              child: provider.isSubmitting
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)
              )
                  : const Text('Submit Attendance'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, LearningProvider provider) {
    showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Wrap(children: [
            ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  provider.pickPhoto(ImageSource.camera);
                  Navigator.pop(context);
                }
            ),
            ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  provider.pickPhoto(ImageSource.gallery);
                  Navigator.pop(context);
                }
            ),
          ]),
        )
    );
  }
}