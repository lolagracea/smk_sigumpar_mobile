import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../common/providers/auth_provider.dart';
import '../providers/absensi_guru_provider.dart';
import '../../../../data/models/absensi_guru_model.dart';
import '../../../../core/utils/absensi_time_validator.dart';
// import '../../home/widgets/guru_mapel_drawer.dart'; // Dihapus karena tidak dipakai lagi
// import '../../../../core/constants/route_names.dart'; // Dihapus karena tidak dipakai lagi

class AbsensiGuruScreen extends StatefulWidget {
  const AbsensiGuruScreen({super.key});

  @override
  State<AbsensiGuruScreen> createState() => _AbsensiGuruScreenState();
}

class _AbsensiGuruScreenState extends State<AbsensiGuruScreen> {
  final TextEditingController _keteranganController = TextEditingController();
  Timer? _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateClock();

    // Update jam realtime tiap 1 detik
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateClock();
    });

    // Refresh status window tiap 10 detik (efisien)
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      context.read<AbsensiGuruProvider>().refreshTimeStatus();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _keteranganController.dispose();
    super.dispose();
  }

  void _updateClock() {
    if (mounted) {
      setState(() {
        _currentTime = AbsensiTimeValidator.getCurrentTimeFormatted();
      });
    }
  }

  // ─── Show Photo Picker Bottom Sheet ─────────────────────
  void _showPhotoPickerSheet(BuildContext context) {
    final provider = context.read<AbsensiGuruProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: isDark ? Colors.white70 : Colors.black87),
              title: Text('Ambil dari Kamera', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () async {
                Navigator.pop(sheetContext);
                await provider.pickPhotoFromCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: isDark ? Colors.white70 : Colors.black87),
              title: Text('Pilih dari Galeri', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () async {
                Navigator.pop(sheetContext);
                await provider.pickPhotoFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Submit Absensi ─────────────────────────────────────
  Future<void> _handleSubmit() async {
    final authProvider = context.read<AuthProvider>();
    final absensiProvider = context.read<AbsensiGuruProvider>();

    final namaGuru = authProvider.user?.name ?? '';

    final success = await absensiProvider.submit(namaGuru: namaGuru);

    if (!mounted) return;

    if (success) {
      _keteranganController.clear();
      _showSuccessDialog();
    } else {
      _showErrorSnackBar(absensiProvider.errorMessage ?? 'Terjadi kesalahan');
    }
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        icon: Icon(
          Icons.check_circle,
          color: isDark ? Colors.green.shade400 : Colors.green,
          size: 64,
        ),
        title: Text(
          'Absensi Berhasil!',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Absensi Anda hari ini sudah tercatat.',
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ LANGSUNG KEMBALIKAN KONTEN UTAMA (Tanpa Scaffold & AppBar)
    return Container(
      color: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserCard(isDark),
            const SizedBox(height: 16),
            _buildTimeStatusBanner(isDark),
            const SizedBox(height: 16),
            _buildDateField(isDark),
            const SizedBox(height: 16),
            _buildStatusDropdown(isDark),
            const SizedBox(height: 16),
            _buildKeteranganField(isDark),
            const SizedBox(height: 16),
            _buildPhotoUpload(isDark),
            const SizedBox(height: 16),
            _buildPhotoInfo(isDark),
            const SizedBox(height: 24),
            _buildSubmitButton(isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── User Info Card ─────────────────────────────────────
  Widget _buildUserCard(bool isDark) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
            child: Icon(
              Icons.person,
              size: 32,
              color: isDark ? Colors.white70 : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Loading...',
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
    );
  }

  // ─── Time Status Banner ─────────────────────────────────
  Widget _buildTimeStatusBanner(bool isDark) {
    final provider = context.watch<AbsensiGuruProvider>();

    if (provider.isWithinWindow) {
      // Window terbuka — show countdown ke deadline
      final countdown = AbsensiTimeValidator.getCountdownToDeadline();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.green.withOpacity(0.1) : Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.green.shade800 : Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: isDark ? Colors.green.shade400 : Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Absensi tersedia. Batas waktu: $countdown',
                style: TextStyle(
                  color: isDark ? Colors.green.shade200 : Colors.green.shade900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Di luar window
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.red.shade800 : Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: isDark ? Colors.red.shade400 : Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.timeValidationMessage ?? 'Di luar waktu absensi',
                style: TextStyle(
                  color: isDark ? Colors.red.shade200 : Colors.red.shade900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // ─── Date Field (Read Only) ─────────────────────────────
  Widget _buildDateField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Tanggal Absensi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: isDark ? Colors.white54 : Colors.grey),
              const SizedBox(width: 12),
              Text(
                AbsensiTimeValidator.getCurrentDateFormatted(),
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Status Dropdown ────────────────────────────────────
  Widget _buildStatusDropdown(bool isDark) {
    final provider = context.watch<AbsensiGuruProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Kehadiran',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<StatusKehadiran>(
              value: provider.selectedStatus,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              isExpanded: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
              icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white54 : Colors.black87),
              items: StatusKehadiran.selectableStatuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.label),
                );
              }).toList(),
              onChanged: provider.isSubmitting
                  ? null
                  : (newValue) {
                if (newValue != null) {
                  provider.setStatus(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Keterangan Field ───────────────────────────────────
  Widget _buildKeteranganField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keterangan/Catatan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
          ),
          child: TextField(
            controller: _keteranganController,
            maxLines: 4,
            maxLength: 500,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Tulis alasan jika sakit / izin',
              hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
            ),
            onChanged: (value) {
              context.read<AbsensiGuruProvider>().setKeterangan(value);
            },
          ),
        ),
      ],
    );
  }

  // ─── Photo Upload ───────────────────────────────────────
  Widget _buildPhotoUpload(bool isDark) {
    final provider = context.watch<AbsensiGuruProvider>();
    final photo = provider.selectedPhoto;

    return GestureDetector(
      onTap: () => _showPhotoPickerSheet(context),
      child: Container(
        height: photo == null ? 180 : 240,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
            style: BorderStyle.solid,
            width: photo == null ? 1.5 : 1,
          ),
        ),
        child: photo == null
            ? _buildEmptyPhotoPlaceholder(isDark)
            : _buildPhotoPreview(photo.path, provider),
      ),
    );
  }

  Widget _buildEmptyPhotoPlaceholder(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: 48,
          color: isDark ? Colors.white30 : Colors.grey.shade400,
        ),
        const SizedBox(height: 12),
        Text(
          'Klik untuk ambil foto / upload',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPreview(String photoPath, AbsensiGuruProvider provider) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: kIsWeb
                ? Image.network(photoPath, fit: BoxFit.cover)
                : Image.file(File(photoPath), fit: BoxFit.cover),
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
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Photo Info ─────────────────────────────────────────
  Widget _buildPhotoInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2563EB).withOpacity(0.15) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: isDark ? const Color(0xFF60A5FA) : Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pastikan foto jelas dan sesuai dengan lokasi kerja.\nFormat yang didukung: JPG, PNG (maks 5MB)',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Submit Button ──────────────────────────────────────
  Widget _buildSubmitButton(bool isDark) {
    final provider = context.watch<AbsensiGuruProvider>();

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        disabledBackgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
      ),
      onPressed: provider.canSubmit ? _handleSubmit : null,
      child: provider.isSubmitting
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : const Text(
        'Kirim Absensi',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}