import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../../../common/providers/auth_provider.dart';
import '../providers/absensi_guru_provider.dart';
import '../../home/widgets/guru_mapel_drawer.dart';
import '../../../../data/models/absensi_guru_model.dart';
import '../../../../core/utils/absensi_time_validator.dart';
import '../../../../core/constants/route_names.dart';

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

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil dari Kamera'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await provider.pickPhotoFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64,
        ),
        title: const Text(
          'Absensi Berhasil!',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Absensi Anda hari ini sudah tercatat.',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: const GuruMapelDrawer(currentRoute: RouteNames.absensiGuru),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 24),
            SizedBox(width: 8),
            Text(
              'SMK Negeri 1 Sigumpar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserCard(),
            const SizedBox(height: 16),
            _buildTimeStatusBanner(),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildStatusDropdown(),
            const SizedBox(height: 16),
            _buildKeteranganField(),
            const SizedBox(height: 16),
            _buildPhotoUpload(),
            const SizedBox(height: 16),
            _buildPhotoInfo(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── User Info Card ─────────────────────────────────────
  Widget _buildUserCard() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(
              Icons.person,
              size: 32,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Loading...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Guru Mata Pelajaran',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$_currentTime WIB',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Time Status Banner ─────────────────────────────────
  Widget _buildTimeStatusBanner() {
    final provider = context.watch<AbsensiGuruProvider>();

    if (provider.isWithinWindow) {
      // Window terbuka — show countdown ke deadline
      final countdown = AbsensiTimeValidator.getCountdownToDeadline();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Absensi tersedia. Batas waktu: $countdown',
                style: TextStyle(
                  color: Colors.green.shade900,
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
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.timeValidationMessage ?? 'Di luar waktu absensi',
                style: TextStyle(
                  color: Colors.red.shade900,
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
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Tanggal Absensi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                AbsensiTimeValidator.getCurrentDateFormatted(),
                style: const TextStyle(fontSize: 14, color: Colors.black87),  // ← explicit hitam
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Status Dropdown ────────────────────────────────────
  Widget _buildStatusDropdown() {
    final provider = context.watch<AbsensiGuruProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Kehadiran',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<StatusKehadiran>(
              value: provider.selectedStatus,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
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
  Widget _buildKeteranganField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keterangan/Catatan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _keteranganController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Tulis alasan jika sakit / izin',
              hintStyle: TextStyle(color: Colors.grey.shade400),
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
  Widget _buildPhotoUpload() {
    final provider = context.watch<AbsensiGuruProvider>();
    final photo = provider.selectedPhoto;

    return GestureDetector(
      onTap: () => _showPhotoPickerSheet(context),
      child: Container(
        height: photo == null ? 180 : 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade300,
            style: photo == null ? BorderStyle.solid : BorderStyle.solid,
            width: photo == null ? 1.5 : 1,
          ),
        ),
        child: photo == null
            ? _buildEmptyPhotoPlaceholder()
            : _buildPhotoPreview(photo.path, provider),
      ),
    );
  }

  Widget _buildEmptyPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: 48,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 12),
        Text(
          'Klik untuk ambil foto / upload',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
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
  Widget _buildPhotoInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Pastikan foto jelas dan sesuai dengan lokasi kerja.\nFormat yang didukung: JPG, PNG (maks 5MB)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Submit Button ──────────────────────────────────────
  Widget _buildSubmitButton() {
    final provider = context.watch<AbsensiGuruProvider>();

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        disabledBackgroundColor: Colors.grey.shade300,
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