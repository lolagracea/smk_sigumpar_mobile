import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

import '../../../../data/models/absensi_guru_model.dart';
import '../../../../data/repositories/learning_repository.dart';
import '../../../../core/utils/absensi_time_validator.dart';

enum AbsensiSubmitStatus { idle, submitting, success, error }

class AbsensiGuruProvider extends ChangeNotifier {
  final LearningRepository _repository;

  AbsensiGuruProvider({required LearningRepository repository})
      : _repository = repository {
    // Initial check apakah window absensi terbuka
    _refreshTimeStatus();
  }

  // ════════════════════════════════════════════════════════════════
  // === STATE ===
  // ════════════════════════════════════════════════════════════════

  AbsensiSubmitStatus _submitStatus = AbsensiSubmitStatus.idle;
  String? _errorMessage;
  String? _successMessage;

  // Form state
  XFile? _selectedPhoto;
  StatusKehadiran _selectedStatus = StatusKehadiran.hadir;
  String _keterangan = '';
  DateTime _selectedDate = DateTime.now();

  // Time window state
  bool _isWithinWindow = true;
  String? _timeValidationMessage;

  // ════════════════════════════════════════════════════════════════
  // === GETTERS ===
  // ════════════════════════════════════════════════════════════════

  AbsensiSubmitStatus get submitStatus => _submitStatus;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  XFile? get selectedPhoto => _selectedPhoto;
  StatusKehadiran get selectedStatus => _selectedStatus;
  String get keterangan => _keterangan;
  DateTime get selectedDate => _selectedDate;

  bool get isSubmitting => _submitStatus == AbsensiSubmitStatus.submitting;
  bool get hasPhoto => _selectedPhoto != null;
  bool get isWithinWindow => _isWithinWindow;
  String? get timeValidationMessage => _timeValidationMessage;

  /// Apakah form bisa di-submit
  bool get canSubmit {
    return _isWithinWindow && hasPhoto && !isSubmitting;
  }

  // ════════════════════════════════════════════════════════════════
  // === SETTERS ===
  // ════════════════════════════════════════════════════════════════

  void setStatus(StatusKehadiran status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setKeterangan(String value) {
    _keterangan = value;
    // Tidak panggil notifyListeners() karena di-bind via TextController
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _submitStatus = AbsensiSubmitStatus.idle;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    _submitStatus = AbsensiSubmitStatus.idle;
    notifyListeners();
  }

  /// Refresh status window (panggil periodic dari UI dengan Timer)
  void _refreshTimeStatus() {
    _isWithinWindow = AbsensiTimeValidator.isWithinWindow();
    _timeValidationMessage = AbsensiTimeValidator.getValidationMessage();
  }

  void refreshTimeStatus() {
    final wasInWindow = _isWithinWindow;
    _refreshTimeStatus();

    // Hanya notify kalau status berubah (efisien)
    if (wasInWindow != _isWithinWindow) {
      notifyListeners();
    }
  }

  // ════════════════════════════════════════════════════════════════
  // === PHOTO PICKER ===
  // ════════════════════════════════════════════════════════════════

  Future<bool> pickPhotoFromCamera() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.front,
      );

      if (picked != null) {
        _selectedPhoto = picked;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Gagal membuka kamera: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> pickPhotoFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (picked != null) {
        _selectedPhoto = picked;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Gagal membuka galeri: $e';
      notifyListeners();
      return false;
    }
  }

  void removePhoto() {
    _selectedPhoto = null;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════
  // === IMAGE COMPRESSION + BASE64 ENCODE ===
  // ════════════════════════════════════════════════════════════════

  Future<String?> _processPhotoToBase64(XFile photo) async {
    try {
      // Untuk web, langsung baca bytes (kIsWeb tidak punya File API)
      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        // Cek size (max 5MB)
        if (bytes.length > 5 * 1024 * 1024) {
          throw Exception('Ukuran foto melebihi 5MB');
        }
        return 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      // Untuk mobile (Android/iOS), compress dulu
      final originalFile = File(photo.path);
      final originalSize = await originalFile.length();

      // Kalau sudah < 1MB, skip compression
      if (originalSize < 1024 * 1024) {
        final bytes = await originalFile.readAsBytes();
        return 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      // Compress
      final dir = originalFile.parent.path;
      final ext = path.extension(originalFile.path);
      final targetPath = path.join(
        dir,
        'compressed_${DateTime.now().millisecondsSinceEpoch}$ext',
      );

      final compressed = await FlutterImageCompress.compressAndGetFile(
        originalFile.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) {
        throw Exception('Gagal kompres foto');
      }

      final compressedFile = File(compressed.path);
      final compressedBytes = await compressedFile.readAsBytes();

      // Final size check
      if (compressedBytes.length > 5 * 1024 * 1024) {
        throw Exception('Ukuran foto setelah kompresi masih > 5MB');
      }

      return 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
    } catch (e) {
      if (kDebugMode) print('Process photo error: $e');
      throw Exception('Gagal proses foto: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // === SUBMIT ABSENSI ===
  // ════════════════════════════════════════════════════════════════

  Future<bool> submit({required String namaGuru}) async {
    // 1. Validasi window waktu
    refreshTimeStatus();
    if (!_isWithinWindow) {
      _errorMessage = _timeValidationMessage ?? 'Di luar waktu absensi';
      _submitStatus = AbsensiSubmitStatus.error;
      notifyListeners();
      return false;
    }

    // 2. Validasi foto
    if (_selectedPhoto == null) {
      _errorMessage = 'Foto wajib diupload sebagai bukti absensi';
      _submitStatus = AbsensiSubmitStatus.error;
      notifyListeners();
      return false;
    }

    // 3. Validasi nama guru
    if (namaGuru.isEmpty) {
      _errorMessage = 'Nama guru tidak ditemukan. Silakan login ulang.';
      _submitStatus = AbsensiSubmitStatus.error;
      notifyListeners();
      return false;
    }

    // 4. Mulai submit
    _submitStatus = AbsensiSubmitStatus.submitting;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 5. Convert foto ke base64
      final fotoBase64 = await _processPhotoToBase64(_selectedPhoto!);
      if (fotoBase64 == null) {
        throw Exception('Foto tidak bisa diproses');
      }

      // 6. Submit ke backend
      await _repository.submitAbsensiGuru(
        namaGuru: namaGuru,
        tanggal: _selectedDate,
        status: _selectedStatus.value,
        fotoBase64: fotoBase64,
        keterangan: _keterangan.isEmpty ? null : _keterangan,
      );

      // 7. Success — reset form
      _resetForm();
      _submitStatus = AbsensiSubmitStatus.success;
      _successMessage = 'Absensi berhasil dikirim';
      notifyListeners();
      return true;
    } catch (e) {
      _submitStatus = AbsensiSubmitStatus.error;
      _errorMessage = _parseErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  String _parseErrorMessage(Object error) {
    final errorStr = error.toString();

    // Handle specific errors
    if (errorStr.contains('SequelizeUniqueConstraintError') ||
        errorStr.contains('unique constraint') ||
        errorStr.contains('duplicate')) {
      return 'Anda sudah absen hari ini. Tidak bisa absen 2x sehari.';
    }

    if (errorStr.contains('SocketException') ||
        errorStr.contains('Connection') ||
        errorStr.contains('Network')) {
      return 'Koneksi internet bermasalah. Coba lagi.';
    }

    if (errorStr.contains('TimeoutException')) {
      return 'Server tidak merespon. Coba lagi.';
    }

    // Default: clean up error message
    return errorStr
        .replaceAll('Exception: ', '')
        .replaceAll('NetworkExceptions: ', '')
        .replaceAll('DioException: ', '');
  }

  void _resetForm() {
    _selectedPhoto = null;
    _selectedStatus = StatusKehadiran.hadir;
    _keterangan = '';
    _selectedDate = DateTime.now();
  }
}