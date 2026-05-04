import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import 'app_drawer.dart';
import 'user_account_menu.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const MainShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  String get _title {
    if (currentRoute.startsWith('/academic/pengumuman/')) {
      return 'Detail Pengumuman';
    }
    switch (currentRoute) {
      case RouteNames.home:
        return 'Beranda';
      case RouteNames.classes:
        return 'Manajemen Kelas';
      case RouteNames.students:
        return 'Manajemen Siswa';
      case RouteNames.subjects:
        return 'Mata Pelajaran';
      case RouteNames.teachers:
        return 'Data Guru';
      case RouteNames.announcements:
        return 'Pengumuman';
      case RouteNames.schedules:
        return 'Jadwal Mengajar';
      case RouteNames.letters:
        return 'Arsip Surat';
      case RouteNames.teacherAttendance:
        return 'Absensi Guru';
      case RouteNames.attendanceRecap:
        return 'Rekap Kehadiran';
      case RouteNames.gradesRecap:
        return 'Rekap Nilai';
      case RouteNames.cleanlinessRecap:
        return 'Kebersihan Kelas';
      case RouteNames.parentingNotes:
        return 'Parenting';
      case RouteNames.homeroomReflection:
        return 'Refleksi Wali Kelas';
      case RouteNames.summonsLetter:
        return 'Surat Panggilan';
      case RouteNames.learningDevice:
        return 'Perangkat Ajar';
      case RouteNames.teacherEvaluation:
        return 'Evaluasi Guru';
      case RouteNames.principalReview:
        return 'Pemeriksaan Kepala Sekolah';
      case RouteNames.vicePrincipalReview:
        return 'Pemeriksaan Waka Sekolah';
      case RouteNames.scoutClasses:
        return 'Kelas Pramuka';
      case RouteNames.scoutAttendance:
        return 'Absensi Pramuka';
      case RouteNames.scoutReport:
        return 'Laporan Pramuka';
      case RouteNames.pklLocationReport:
        return 'Lokasi PKL';
      case RouteNames.pklProgressReport:
        return 'Progres PKL';
      case RouteNames.pklGradeInput:
        return 'Input Nilai PKL';
      case RouteNames.submissionInfo:
        return 'Informasi Pengajuan';
      case RouteNames.itemLoan:
        return 'Peminjaman Barang';
      case RouteNames.equipmentSubmission:
        return 'Pengajuan Barang';
      case RouteNames.loanResponse:
        return 'Respon Peminjaman';
      case RouteNames.treasurerResponse:
        return 'Respon Bendahara';
      case RouteNames.principalResponse:
        return 'Respon Kepala Sekolah';
      default:
        return 'SMK Negeri 1 Sigumpar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: AppDrawer(
        currentRoute: currentRoute,
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            if (currentRoute != RouteNames.home) {
              context.go(RouteNames.home);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: UserAccountMenu(),
          ),
        ],
      ),
      body: child,
    );
  }
}
