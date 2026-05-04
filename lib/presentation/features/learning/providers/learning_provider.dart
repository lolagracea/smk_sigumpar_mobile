//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../../../../data/models/absensi_guru_model.dart';
// import '../../../../data/repositories/learning_repository.dart';
// import '../../../../core/utils/absensi_time_validator.dart';
//
// enum LearningLoadState { initial, loading, loaded, error }
// enum SubmitState { idle, submitting, success, error }
//
// class LearningProvider extends ChangeNotifier {
//   final LearningRepository _repository;
//
//   LearningProvider({required LearningRepository repository})
//       : _repository = repository {
//     _refreshTimeStatus();
//   }
//
//   // ─── List States (Fetch) ──────────────────────────────────
//   LearningLoadState _attendanceState = LearningLoadState.initial;
//   List<Map<String, dynamic>> _teacherAttendances = [];
//
//   LearningLoadState _notesState = LearningLoadState.initial;
//   List<Map<String, dynamic>> _teachingNotes = [];
//
//   LearningLoadState _deviceState = LearningLoadState.initial;
//   List<Map<String, dynamic>> _learningDevices = [];
//
//   // Getters for Lists
//   LearningLoadState get attendanceState => _attendanceState;
//   List<Map<String, dynamic>> get teacherAttendances => _teacherAttendances;
//   LearningLoadState get notesState => _notesState;
//   List<Map<String, dynamic>> get teachingNotes => _teachingNotes;
//   LearningLoadState get deviceState => _deviceState;
//   List<Map<String, dynamic>> get learningDevices => _learningDevices;
//
//   // ─── Attendance Form States (Submit) ──────────────────────
//   SubmitState _attendanceSubmitState = SubmitState.idle;
//   String? _errorMessage;
//   XFile? _selectedPhoto;
//   StatusKehadiran _selectedStatus = StatusKehadiran.hadir;
//   String _remarks = '';
//   bool _isWithinTimeWindow = true;
//   String? _timeValidationMessage;
//
//   // Getters for Form
//   SubmitState get attendanceSubmitState => _attendanceSubmitState;
//   String? get errorMessage => _errorMessage;
//   XFile? get selectedPhoto => _selectedPhoto;
//   StatusKehadiran get selectedStatus => _selectedStatus;
//   bool get isSubmitting => _attendanceSubmitState == SubmitState.submitting;
//   bool get isWithinTimeWindow => _isWithinTimeWindow;
//   String? get timeValidationMessage => _timeValidationMessage;
//   bool get canSubmitAttendance => _isWithinTimeWindow && _selectedPhoto != null && !isSubmitting;
//
//   // ─── Fetch Methods ────────────────────────────────────────
//   Future<void> fetchTeacherAttendance({bool refresh = false, String? date}) async {
//     if (refresh) _teacherAttendances = [];
//     _attendanceState = LearningLoadState.loading;
//     notifyListeners();
//     try {
//       final result = await _repository.getTeacherAttendance(date: date);
//       _teacherAttendances = result.items;
//       _attendanceState = LearningLoadState.loaded;
//     } catch (e) {
//       _attendanceState = LearningLoadState.error;
//     }
//     notifyListeners();
//   }
//
//   Future<void> fetchTeachingNotes({bool refresh = false}) async {
//     if (refresh) _teachingNotes = [];
//     _notesState = LearningLoadState.loading;
//     notifyListeners();
//     try {
//       final result = await _repository.getTeachingNotes();
//       _teachingNotes = result.items;
//       _notesState = LearningLoadState.loaded;
//     } catch (e) {
//       _notesState = LearningLoadState.error;
//     }
//     notifyListeners();
//   }
//
//   // ─── Attendance Form Methods ──────────────────────────────
//   void setAttendanceStatus(StatusKehadiran status) {
//     _selectedStatus = status;
//     notifyListeners();
//   }
//
//   void setRemarks(String value) => _remarks = value;
//
//   void _refreshTimeStatus() {
//     _isWithinTimeWindow = AbsensiTimeValidator.isWithinWindow();
//     _timeValidationMessage = AbsensiTimeValidator.getValidationMessage();
//   }
//
//   void refreshTimeStatus() {
//     final wasInWindow = _isWithinTimeWindow;
//     _refreshTimeStatus();
//     if (wasInWindow != _isWithinTimeWindow) notifyListeners();
//   }
//
//   Future<void> pickPhoto(ImageSource source) async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: source, imageQuality: 70);
//     if (picked != null) {
//       _selectedPhoto = picked;
//       notifyListeners();
//     }
//   }
//
//   void removePhoto() {
//     _selectedPhoto = null;
//     notifyListeners();
//   }
//
//   Future<bool> submitAttendance({required String teacherName}) async {
//     _refreshTimeStatus();
//     if (!_isWithinTimeWindow || _selectedPhoto == null) return false;
//
//     _attendanceSubmitState = SubmitState.submitting;
//     notifyListeners();
//
//     try {
//       final bytes = await _selectedPhoto!.readAsBytes();
//       final base64Photo = 'data:image/jpeg;base64,${base64Encode(bytes)}';
//
//       await _repository.submitAbsensiGuru(
//         namaGuru: teacherName,
//         tanggal: DateTime.now(),
//         status: _selectedStatus.value,
//         fotoBase64: base64Photo,
//         keterangan: _remarks.isEmpty ? null : _remarks,
//       );
//
//       _resetAttendanceForm();
//       _attendanceSubmitState = SubmitState.success;
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString();
//       _attendanceSubmitState = SubmitState.error;
//       notifyListeners();
//       return false;
//     }
//   }
//
//   void _resetAttendanceForm() {
//     _selectedPhoto = null;
//     _remarks = '';
//     _selectedStatus = StatusKehadiran.hadir;
//   }
// }

import 'dart:convert';
import 'package:flutter/foundation.dart'; // Penting untuk kIsWeb dan Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/absensi_guru_model.dart';
import '../../../../data/repositories/learning_repository.dart';
import '../../../../core/utils/absensi_time_validator.dart';

enum LearningLoadState { initial, loading, loaded, error }
enum SubmitState { idle, submitting, success, error }

class LearningProvider extends ChangeNotifier {
  final LearningRepository _repository;

  LearningProvider({required LearningRepository repository})
      : _repository = repository {
    _refreshTimeStatus();
  }

  // ─── List States (Fetch) ──────────────────────────────────
  LearningLoadState _attendanceState = LearningLoadState.initial;
  List<Map<String, dynamic>> _teacherAttendances = [];
  LearningLoadState _notesState = LearningLoadState.initial;
  List<Map<String, dynamic>> _teachingNotes = [];
  LearningLoadState _deviceState = LearningLoadState.initial;
  List<Map<String, dynamic>> _learningDevices = [];

  LearningLoadState get attendanceState => _attendanceState;
  List<Map<String, dynamic>> get teacherAttendances => _teacherAttendances;
  LearningLoadState get notesState => _notesState;

  // ─── Attendance Form States (Submit) ──────────────────────
  SubmitState _attendanceSubmitState = SubmitState.idle;
  String? _errorMessage;
  XFile? _selectedPhoto;
  Uint8List? _webImageBytes; // Tambahan untuk fix error Web
  StatusKehadiran _selectedStatus = StatusKehadiran.hadir;
  String _remarks = '';
  bool _isWithinTimeWindow = true;
  String? _timeValidationMessage;

  SubmitState get attendanceSubmitState => _attendanceSubmitState;
  String? get errorMessage => _errorMessage;
  XFile? get selectedPhoto => _selectedPhoto;
  Uint8List? get webImageBytes => _webImageBytes; // Getter baru
  StatusKehadiran get selectedStatus => _selectedStatus;
  bool get isSubmitting => _attendanceSubmitState == SubmitState.submitting;
  bool get isWithinTimeWindow => _isWithinTimeWindow;
  String? get timeValidationMessage => _timeValidationMessage;
  bool get canSubmitAttendance => _isWithinTimeWindow && _selectedPhoto != null && !isSubmitting;

  // ─── Fetch Methods ────────────────────────────────────────
  Future<void> fetchTeacherAttendance({bool refresh = false, String? date}) async {
    if (refresh) _teacherAttendances = [];
    _attendanceState = LearningLoadState.loading;
    notifyListeners();
    try {
      final result = await _repository.getTeacherAttendance(date: date);
      _teacherAttendances = result.items;
      _attendanceState = LearningLoadState.loaded;
    } catch (e) {
      _attendanceState = LearningLoadState.error;
    }
    notifyListeners();
  }

  // ─── Attendance Form Methods ──────────────────────────────
  void setAttendanceStatus(StatusKehadiran status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setRemarks(String value) => _remarks = value;

  void _refreshTimeStatus() {
    _isWithinTimeWindow = AbsensiTimeValidator.isWithinWindow();
    _timeValidationMessage = AbsensiTimeValidator.getValidationMessage();
  }

  void refreshTimeStatus() {
    final wasInWindow = _isWithinTimeWindow;
    _refreshTimeStatus();
    if (wasInWindow != _isWithinTimeWindow) notifyListeners();
  }

  Future<void> pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      _selectedPhoto = picked;
      // Jika di Web, kita baca bytes-nya agar bisa tampil
      if (kIsWeb) {
        _webImageBytes = await picked.readAsBytes();
      }
      notifyListeners();
    }
  }

  void removePhoto() {
    _selectedPhoto = null;
    _webImageBytes = null;
    notifyListeners();
  }

  Future<bool> submitAttendance({required String teacherName}) async {
    _refreshTimeStatus();
    if (!_isWithinTimeWindow || _selectedPhoto == null) return false;

    _attendanceSubmitState = SubmitState.submitting;
    notifyListeners();

    try {
      final bytes = await _selectedPhoto!.readAsBytes();
      final extension = _selectedPhoto!.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'png' : 'jpeg';
      final base64Photo = 'data:image/$mimeType;base64,${base64Encode(bytes)}';

      // Memanggil fungsi asli di repository kamu
      await _repository.submitAbsensiGuru(
        namaGuru: teacherName,
        tanggal: DateTime.now(),
        status: _selectedStatus.value,
        fotoBase64: base64Photo,
        keterangan: _remarks.isEmpty ? null : _remarks,
      );

      _resetAttendanceForm();
      _attendanceSubmitState = SubmitState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _attendanceSubmitState = SubmitState.error;
      notifyListeners();
      return false;
    }
  }

  void _resetAttendanceForm() {
    _selectedPhoto = null;
    _webImageBytes = null;
    _remarks = '';
    _selectedStatus = StatusKehadiran.hadir;
  }
}