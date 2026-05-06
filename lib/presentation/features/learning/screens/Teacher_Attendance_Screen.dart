import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../common/providers/auth_provider.dart';
import '../providers/learning_provider.dart';
import '../../../../data/models/absensi_guru_model.dart';
import '../../../../core/utils/absensi_time_validator.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final TextEditingController _remarksController = TextEditingController();
  Timer? _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());

    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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
      setState(
              () => _currentTime = AbsensiTimeValidator.getCurrentTimeFormatted());
    }
  }

  void _showPicker(BuildContext context, LearningProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt,
                  color: isDark ? Colors.white70 : Colors.black87),
              title: Text('Ambil dari Kamera',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                provider.pickPhoto(ImageSource.camera);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library,
                  color: isDark ? Colors.white70 : Colors.black87),
              title: Text('Pilih dari Galeri',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                provider.pickPhoto(ImageSource.gallery);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit(LearningProvider provider, String teacherName) async {
    final success = await provider.submitAttendance(teacherName: teacherName);
    if (!mounted) return;

    if (success) {
      _remarksController.clear();
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(Icons.check_circle,
              color: isDark ? Colors.green.shade400 : Colors.green, size: 64),
          title: Text('Absensi Berhasil!',
              textAlign: TextAlign.center,
              style:
              TextStyle(color: isDark ? Colors.white : Colors.black87)),
          content: Text('Absensi Anda hari ini sudah tercatat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87)),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.errorMessage ?? 'Terjadi kesalahan'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<LearningProvider>();
    final auth = context.watch<AuthProvider>();

    // ✅ Tidak ada Scaffold/AppBar — MainShell yang handle
    return Container(
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── User Card ──────────────────────────────────────
            _buildCard(
              isDark: isDark,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                    isDark ? Colors.white12 : Colors.grey.shade200,
                    child: Icon(Icons.person,
                        size: 32,
                        color: isDark ? Colors.white70 : Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.name ?? 'Loading...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Guru Mata Pelajaran',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$_currentTime WIB',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Time Status Banner ─────────────────────────────
            _buildTimeStatusBanner(isDark, provider),

            const SizedBox(height: 16),

            // ─── Tanggal (read-only) ────────────────────────────
            _buildLabel('Pilih Tanggal Absensi', isDark),
            const SizedBox(height: 8),
            _buildCard(
              isDark: isDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 18,
                      color: isDark ? Colors.white54 : Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    AbsensiTimeValidator.getCurrentDateFormatted(),
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Status Dropdown ────────────────────────────────
            _buildLabel('Status Kehadiran', isDark),
            const SizedBox(height: 8),
            _buildCard(
              isDark: isDark,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<StatusKehadiran>(
                  value: provider.selectedStatus,
                  isExpanded: true,
                  dropdownColor:
                  isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14),
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: isDark ? Colors.white54 : Colors.black87),
                  items: StatusKehadiran.selectableStatuses
                      .map((s) => DropdownMenuItem(
                      value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: provider.isSubmitting
                      ? null
                      : (v) {
                    if (v != null) provider.setAttendanceStatus(v);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Keterangan ─────────────────────────────────────
            _buildLabel('Keterangan/Catatan', isDark),
            const SizedBox(height: 8),
            _buildCard(
              isDark: isDark,
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _remarksController,
                maxLines: 4,
                maxLength: 500,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Tulis alasan jika sakit / izin',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  counterText: '',
                ),
                onChanged: (v) => provider.setRemarks(v),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Photo Upload ───────────────────────────────────
            GestureDetector(
              onTap: () => _showPicker(context, provider),
              child: Container(
                height: provider.selectedPhoto == null ? 180 : 240,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    width: provider.selectedPhoto == null ? 1.5 : 1,
                  ),
                ),
                child: provider.selectedPhoto == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        size: 48,
                        color: isDark
                            ? Colors.white30
                            : Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Klik untuk ambil foto / upload',
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white54
                              : Colors.grey.shade600),
                    ),
                  ],
                )
                    : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: kIsWeb
                            ? (provider.webImageBytes != null
                            ? Image.memory(provider.webImageBytes!,
                            fit: BoxFit.cover)
                            : const SizedBox())
                            : Image.file(
                            File(provider.selectedPhoto!.path),
                            fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: provider.removePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Photo Info ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2563EB).withOpacity(0.15)
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16,
                      color: isDark
                          ? const Color(0xFF60A5FA)
                          : Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pastikan foto jelas dan sesuai dengan lokasi kerja.\nFormat yang didukung: JPG, PNG (maks 5MB)',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Submit Button ──────────────────────────────────
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                disabledBackgroundColor:
                isDark ? Colors.white12 : Colors.grey.shade300,
              ),
              onPressed: provider.canSubmitAttendance
                  ? () => _handleSubmit(provider, auth.user?.name ?? '')
                  : null,
              child: provider.isSubmitting
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Kirim Absensi',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────
  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _buildTimeStatusBanner(bool isDark, LearningProvider provider) {
    final isOpen = provider.isWithinTimeWindow;
    final bgColor = isOpen
        ? (isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50)
        : (isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50);
    final borderColor = isOpen
        ? (isDark ? Colors.green.shade800 : Colors.green.shade200)
        : (isDark ? Colors.red.shade800 : Colors.red.shade200);
    final iconColor = isOpen
        ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
        : (isDark ? Colors.red.shade400 : Colors.red.shade700);
    final textColor = isOpen
        ? (isDark ? Colors.green.shade200 : Colors.green.shade900)
        : (isDark ? Colors.red.shade200 : Colors.red.shade900);
    final message = isOpen
        ? 'Absensi tersedia. Batas waktu: ${AbsensiTimeValidator.getCountdownToDeadline()}'
        : (provider.timeValidationMessage ?? 'Di luar waktu absensi');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(isOpen ? Icons.check_circle : Icons.warning,
              color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: textColor, fontSize: 13))),
        ],
      ),
    );
  }
}