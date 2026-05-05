import 'package:intl/intl.dart';

/// Validator untuk window waktu absensi guru
///
/// Aturan:
/// - Submit absensi hanya BOLEH antara 05:00 - 07:20 WIB
/// - Sebelum 05:00 → ditolak (terlalu pagi)
/// - Setelah 07:20 → ditolak (sudah lewat batas)
class AbsensiTimeValidator {
  AbsensiTimeValidator._();

  /// Jam mulai window (05:00)
  static const int startHour = 5;
  static const int startMinute = 0;

  /// Jam akhir window (07:20)
  static const int endHour = 7;
  static const int endMinute = 20;

  /// Cek apakah waktu saat ini berada dalam window absensi
  static bool isWithinWindow([DateTime? now]) {
    final current = now ?? DateTime.now();
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  /// Cek apakah terlalu pagi (sebelum 05:00)
  static bool isTooEarly([DateTime? now]) {
    final current = now ?? DateTime.now();
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = startHour * 60 + startMinute;

    return currentMinutes < startMinutes;
  }

  /// Cek apakah sudah lewat batas (setelah 07:20)
  static bool isPastDeadline([DateTime? now]) {
    final current = now ?? DateTime.now();
    final currentMinutes = current.hour * 60 + current.minute;
    final endMinutes = endHour * 60 + endMinute;

    return currentMinutes > endMinutes;
  }

  /// Get error message yang sesuai untuk waktu saat ini
  /// Return null kalau dalam window (boleh submit)
  static String? getValidationMessage([DateTime? now]) {
    if (isWithinWindow(now)) return null;

    if (isTooEarly(now)) {
      return 'Belum waktunya absen. Absensi dibuka pukul 05:00 WIB.';
    }

    if (isPastDeadline(now)) {
      return 'Batas waktu absensi sudah lewat (07:20 WIB). Hubungi tata usaha untuk konfirmasi.';
    }

    return 'Waktu tidak valid untuk absensi.';
  }

  /// Get formatted countdown ke deadline (07:20)
  /// Contoh return: "1 jam 35 menit lagi"
  static String getCountdownToDeadline([DateTime? now]) {
    final current = now ?? DateTime.now();
    final deadline = DateTime(
      current.year,
      current.month,
      current.day,
      endHour,
      endMinute,
    );

    if (current.isAfter(deadline)) return 'Sudah lewat';

    final diff = deadline.difference(current);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours > 0) {
      return '$hours jam $minutes menit lagi';
    } else {
      return '$minutes menit lagi';
    }
  }

  /// Format current time (HH:mm) untuk display
  static String getCurrentTimeFormatted([DateTime? now]) {
    final current = now ?? DateTime.now();
    return DateFormat('HH:mm').format(current);
  }

  /// Format current date in Indonesian (Senin, 15 Januari 2025)
  static String getCurrentDateFormatted([DateTime? now]) {
    final current = now ?? DateTime.now();
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(current);
  }

  /// Format any date in Indonesian
  static String formatDateIndonesian(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }

  /// Format time HH:mm WIB
  static String formatTimeWIB(DateTime time) {
    return '${DateFormat('HH:mm').format(time)} WIB';
  }
}