// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import '../constants/route_names.dart';
// import '../../presentation/common/providers/auth_provider.dart';
// import '../../presentation/features/auth/login_screen.dart';
// import '../../presentation/features/auth/profile_screen.dart';
// import '../../presentation/features/home/home_screen.dart';
// import '../../presentation/features/academic/screens/classes_screen.dart';
// import '../../presentation/features/academic/screens/students_screen.dart';
// import '../../presentation/features/academic/screens/teachers_screen.dart';
// import '../../presentation/features/academic/screens/announcements_screen.dart';
// import '../../presentation/features/academic/screens/announcement_detail_screen.dart';
// import '../../presentation/features/academic/screens/schedules_screen.dart';
// import '../../presentation/features/academic/screens/letters_screen.dart';
// import '../../presentation/features/student/screens/attendance_recap_screen.dart';
// import '../../presentation/features/student/screens/grades_recap_screen.dart';
// import '../../presentation/features/student/screens/cleanliness_recap_screen.dart';
// import '../../presentation/features/student/screens/parenting_notes_screen.dart';
// import '../../presentation/features/student/screens/homeroom_reflection_screen.dart';
// import '../../presentation/features/student/screens/summons_letter_screen.dart';
// import '../../presentation/features/academic/screens/subjects_screen.dart';
//
// // ─── LEARNING SCREENS ─────────────────────────────────────
// import '../../presentation/features/learning/screens/Teacher_Attendance_Screen.dart';
// import '../../presentation/features/learning/screens/teaching_notes_screen.dart';
// import '../../presentation/features/learning/screens/teacher_evaluation_screen.dart';
// import '../../presentation/features/learning/screens/learning_device_screen.dart';
// import '../../presentation/features/learning/screens/principal_review_screen.dart';
// import '../../presentation/features/learning/screens/vice_principal_review_screen.dart';
//
// import '../../presentation/common/layout/main_shell.dart';
//
// // ─── VOCATIONAL & ASSET (tidak berubah) ───────────────────
// import '../../presentation/features/vocational/screens/scout_classes_screen.dart';
// import '../../presentation/features/vocational/screens/scout_attendance_screen.dart';
// import '../../presentation/features/vocational/screens/scout_report_screen.dart';
// import '../../presentation/features/vocational/screens/pkl_location_report_screen.dart';
// import '../../presentation/features/vocational/screens/pkl_progress_report_screen.dart';
// import '../../presentation/features/asset/screens/submission_info_screen.dart';
// import '../../presentation/features/asset/screens/item_loan_screen.dart';
// import '../../presentation/features/asset/screens/equipment_submission_screen.dart';
// import '../../presentation/features/asset/screens/loan_response_screen.dart';
// import '../../presentation/features/asset/screens/treasurer_response_screen.dart';
// import '../../presentation/features/asset/screens/principal_response_screen.dart';
//
// class AppRouter {
//   static final _rootNavigatorKey = GlobalKey<NavigatorState>();
//
//   static final router = GoRouter(
//     navigatorKey: _rootNavigatorKey,
//     initialLocation: RouteNames.login,
//     redirect: (context, state) {
//       final auth = context.read<AuthProvider>();
//       final isLoggedIn = auth.isAuthenticated;
//       final isLoginRoute = state.matchedLocation == RouteNames.login;
//
//       if (!isLoggedIn && !isLoginRoute) return RouteNames.login;
//       if (isLoggedIn && isLoginRoute) return RouteNames.home;
//       return null;
//     },
//     routes: [
//       // ─── Auth tanpa Shell ────────────────────────────────
//       // Login tidak perlu sidebar, appbar global, dan user icon.
//       GoRoute(
//         path: RouteNames.login,
//         builder: (_, __) => const LoginScreen(),
//       ),
//
//       // ─── Main App Shell ──────────────────────────────────
//       // Semua halaman setelah login masuk ke sini supaya sidebar
//       // dan user icon menjadi global seperti website.
//       ShellRoute(
//         builder: (context, state, child) {
//           return MainShell(
//             currentRoute: state.matchedLocation,
//             child: child,
//           );
//         },
//         routes: [
//           // ─── Auth setelah login ──────────────────────────
//           GoRoute(
//             path: RouteNames.profile,
//             builder: (_, __) => const ProfileScreen(),
//           ),
//
//       // ─── Academic ────────────────────────────────────────
//       GoRoute(path: RouteNames.classes, builder: (_, __) => const ClassesScreen()),
//       GoRoute(path: RouteNames.students, builder: (_, __) => const StudentsScreen()),
//       GoRoute(path: RouteNames.teachers, builder: (_, __) => const TeachersScreen()),
//       GoRoute(path: RouteNames.announcements, builder: (_, __) => const AnnouncementsScreen()),
//       GoRoute(path: RouteNames.schedules, builder: (_, __) => const SchedulesScreen()),
//       GoRoute(path: RouteNames.letters, builder: (_, __) => const LettersScreen()),
//       GoRoute(
//         path: RouteNames.announcementDetail,
//         builder: (context, state) {
//           final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
//           return AnnouncementDetailScreen(announcementId: id);
//         },
//       ),
//
//       // ─── Student ─────────────────────────────────────────
//       GoRoute(path: RouteNames.cleanlinessRecap, builder: (_, __) => const CleanlinessRecapScreen()),
//       GoRoute(path: RouteNames.parentingNotes, builder: (_, __) => const ParentingNotesScreen()),
//       GoRoute(path: RouteNames.homeroomReflection, builder: (_, __) => const HomeroomReflectionScreen()),
//       GoRoute(path: RouteNames.summonsLetter, builder: (_, __) => const SummonsLetterScreen()),
//       GoRoute(path: RouteNames.attendanceRecap, builder: (_, __) => const AttendanceRecapScreen()),
//       GoRoute(path: RouteNames.gradesRecap, builder: (_, __) => const GradesRecapScreen()),
//
//       // ─── Learning ────────────────────────────────────────
//       // ⭐ ABSENSI GURU — pakai screen baru kita
//       GoRoute(
//         path: RouteNames.teacherAttendance,
//         builder: (_, __) => const AbsensiGuruScreen(),
//           // ─── Home ────────────────────────────────────────
//           GoRoute(
//             path: RouteNames.home,
//             builder: (_, __) => const HomeScreen(),
//           ),
//
//           // ─── Academic ────────────────────────────────────
//           GoRoute(
//             path: RouteNames.classes,
//             builder: (_, __) => const ClassesScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.students,
//             builder: (_, __) => const StudentsScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.teachers,
//             builder: (_, __) => const TeachersScreen(),
//           ),
//
//           // Halaman daftar/manajemen Pengumuman.
//           // Route mobile tetap memakai RouteNames.announcements agar tidak
//           // merusak drawer dan screen lama.
//           GoRoute(
//             path: RouteNames.announcements,
//             builder: (_, __) => const AnnouncementsScreen(),
//           ),
//
//           // Halaman detail Pengumuman full screen.
//           // Path-nya memakai /academic/pengumuman/:id agar dekat dengan
//           // istilah web dan backend academic-service.
//           GoRoute(
//             path: RouteNames.announcementDetail,
//             builder: (_, state) {
//               final id = state.pathParameters['id'] ?? '';
//
//               return AnnouncementDetailScreen(
//                 announcementId: id,
//               );
//             },
//           ),
//
//           GoRoute(
//             path: RouteNames.schedules,
//             builder: (_, __) => const SchedulesScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.letters,
//             builder: (_, __) => const LettersScreen(),
//           ),
//
//           // ─── Student ─────────────────────────────────────
//           GoRoute(
//             path: RouteNames.cleanlinessRecap,
//             builder: (_, __) => const CleanlinessRecapScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.parentingNotes,
//             builder: (_, __) => const ParentingNotesScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.homeroomReflection,
//             builder: (_, __) => const HomeroomReflectionScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.summonsLetter,
//             builder: (_, __) => const SummonsLetterScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.attendanceRecap,
//             builder: (_, __) => const AttendanceRecapScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.gradesRecap,
//             builder: (_, __) => const GradesRecapScreen(),
//           ),
//
//           // ─── Learning ────────────────────────────────────
//           GoRoute(
//             path: RouteNames.teacherAttendance,
//             builder: (_, __) => const AbsensiGuruScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.teachingNotes,
//             builder: (_, __) => const TeachingNotesScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.teacherEvaluation,
//             builder: (_, __) => const TeacherEvaluationScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.learningDevice,
//             builder: (_, __) => const LearningDeviceScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.principalReview,
//             builder: (_, __) => const PrincipalReviewScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.vicePrincipalReview,
//             builder: (_, __) => const VicePrincipalReviewScreen(),
//           ),
//
//           // ─── Vocational ──────────────────────────────────
//           GoRoute(
//             path: RouteNames.scoutClasses,
//             builder: (_, __) => const ScoutClassesScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.scoutAttendance,
//             builder: (_, __) => const ScoutAttendanceScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.scoutReport,
//             builder: (_, __) => const ScoutReportScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.pklLocationReport,
//             builder: (_, __) => const PklLocationReportScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.pklProgressReport,
//             builder: (_, __) => const PklProgressReportScreen(),
//           ),
//
//           // ─── Asset ───────────────────────────────────────
//           GoRoute(
//             path: RouteNames.submissionInfo,
//             builder: (_, __) => const SubmissionInfoScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.subjects,
//             builder: (_, __) => const SubjectsScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.itemLoan,
//             builder: (_, __) => const ItemLoanScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.equipmentSubmission,
//             builder: (_, __) => const EquipmentSubmissionScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.loanResponse,
//             builder: (_, __) => const LoanResponseScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.treasurerResponse,
//             builder: (_, __) => const TreasurerResponseScreen(),
//           ),
//           GoRoute(
//             path: RouteNames.principalResponse,
//             builder: (_, __) => const PrincipalResponseScreen(),
//           ),
//       ],
//       ),
//     ],
//     errorBuilder: (_, state) => Scaffold(
//       body: Center(
//         child: Text('Halaman tidak ditemukan: ${state.error}'),
//       ),
//     ),
//   );
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/route_names.dart';
import '../../presentation/common/providers/auth_provider.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/auth/profile_screen.dart';
import '../../presentation/features/home/home_screen.dart';
import '../../presentation/common/layout/main_shell.dart';

// ─── Academic ─────────────────────────────────────────────────
import '../../presentation/features/academic/screens/classes_screen.dart';
import '../../presentation/features/academic/screens/students_screen.dart';
import '../../presentation/features/academic/screens/teachers_screen.dart';
import '../../presentation/features/academic/screens/announcements_screen.dart';
import '../../presentation/features/academic/screens/announcement_detail_screen.dart';
import '../../presentation/features/academic/screens/schedules_screen.dart';
import '../../presentation/features/academic/screens/letters_screen.dart';
import '../../presentation/features/academic/screens/subjects_screen.dart';
import '../../presentation/features/academic/screens/monitoring_jadwal_screen.dart';

// ─── Student ──────────────────────────────────────────────────
import '../../presentation/features/student/screens/attendance_recap_screen.dart';
import '../../presentation/features/student/screens/grades_recap_screen.dart';
import '../../presentation/features/student/screens/cleanliness_recap_screen.dart';
import '../../presentation/features/student/screens/parenting_notes_screen.dart';
import '../../presentation/features/student/screens/homeroom_reflection_screen.dart';
import '../../presentation/features/student/screens/summons_letter_screen.dart';
import '../../presentation/features/academic/screens/subjects_screen.dart';
import '../../presentation/features/learning/screens/Teacher_Attendance_Screen.dart';
import '../../presentation/features/student/screens/parenting_wakil_screen.dart';

// ─── Learning ─────────────────────────────────────────────────
import '../../presentation/features/learning/screens/absensi_guru_screen.dart';
import '../../presentation/features/learning/screens/teaching_notes_screen.dart';
import '../../presentation/features/learning/screens/teacher_evaluation_screen.dart';
import '../../presentation/features/learning/screens/learning_device_screen.dart';
import '../../presentation/features/learning/screens/principal_review_screen.dart';
import '../../presentation/features/learning/screens/vice_principal_review_screen.dart';
import '../../presentation/common/layout/main_shell.dart';
import '../../presentation/features/learning/screens/absensi_guru_wakil_screen.dart';
import '../../presentation/features/learning/screens/kurikulum_screen.dart';
import '../../presentation/features/learning/screens/laporan_wakil_screen.dart';

// ─── Vocational / Pramuka ─────────────────────────────────────
import '../../presentation/features/vocational/screens/scout_classes_screen.dart';
import '../../presentation/features/vocational/screens/scout_attendance_screen.dart';
import '../../presentation/features/vocational/screens/scout_report_screen.dart';

// ─── Vocational / PKL ─────────────────────────────────────────
import '../../presentation/features/vocational/screens/pkl_location_report_screen.dart';
import '../../presentation/features/vocational/screens/pkl_progress_report_screen.dart';
import '../../presentation/features/vocational/screens/nilai_pkl_screen.dart';

// ─── Asset ────────────────────────────────────────────────────
import '../../presentation/features/asset/screens/submission_info_screen.dart';
import '../../presentation/features/asset/screens/item_loan_screen.dart';
import '../../presentation/features/asset/screens/equipment_submission_screen.dart';
import '../../presentation/features/asset/screens/loan_response_screen.dart';
import '../../presentation/features/asset/screens/treasurer_response_screen.dart';
import '../../presentation/features/asset/screens/principal_response_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: RouteNames.home, // Default ke home, biarkan redirect yang atur
      refreshListenable: authProvider, // KUNCI: Router mendengarkan AuthProvider
      redirect: (context, state) {
        final status = authProvider.status;
        final isLoggingIn = state.matchedLocation == RouteNames.login;

        // Jika masih loading baca token, jangan pindah halaman dulu
        if (status == AuthStatus.initial || status == AuthStatus.loading) {
          return null;
        }

        final bool authenticated = status == AuthStatus.authenticated;

        if (!authenticated) {
          // Jika tidak login, paksa ke halaman login
          return isLoggingIn ? null : RouteNames.login;
        }

        // Jika sudah login tapi malah buka halaman login, lempar ke home
        if (authenticated && isLoggingIn) {
          return RouteNames.home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RouteNames.login,
          builder: (_, __) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return MainShell(
              currentRoute: state.matchedLocation,
              child: child,
            );
          },
          routes: [
            GoRoute(path: RouteNames.profile, builder: (_, __) => const ProfileScreen()),
            GoRoute(path: RouteNames.home, builder: (_, __) => const HomeScreen()),
            GoRoute(path: RouteNames.classes, builder: (_, __) => const ClassesScreen()),
            GoRoute(path: RouteNames.students, builder: (_, __) => const StudentsScreen()),
            GoRoute(path: RouteNames.teachers, builder: (_, __) => const TeachersScreen()),
            GoRoute(path: RouteNames.announcements, builder: (_, __) => const AnnouncementsScreen()),
            GoRoute(
              path: RouteNames.announcementDetail,
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                return AnnouncementDetailScreen(announcementId: id);
              },
            ),
            GoRoute(path: RouteNames.schedules, builder: (_, __) => const SchedulesScreen()),
            GoRoute(path: RouteNames.letters, builder: (_, __) => const LettersScreen()),
            GoRoute(path: RouteNames.cleanlinessRecap, builder: (_, __) => const CleanlinessRecapScreen()),
            GoRoute(path: RouteNames.parentingNotes, builder: (_, __) => const ParentingNotesScreen()),
            GoRoute(path: RouteNames.homeroomReflection, builder: (_, __) => const HomeroomReflectionScreen()),
            GoRoute(path: RouteNames.summonsLetter, builder: (_, __) => const SummonsLetterScreen()),
            GoRoute(path: RouteNames.attendanceRecap, builder: (_, __) => const AttendanceRecapScreen()),
            GoRoute(path: RouteNames.gradesRecap, builder: (_, __) => const GradesRecapScreen()),
            GoRoute(path: RouteNames.teacherAttendance, builder: (_, __) => const TeacherAttendanceScreen()),
            GoRoute(path: RouteNames.teachingNotes, builder: (_, __) => const TeachingNotesScreen()),
            GoRoute(path: RouteNames.teacherEvaluation, builder: (_, __) => const TeacherEvaluationScreen()),
            GoRoute(path: RouteNames.learningDevice, builder: (_, __) => const LearningDeviceScreen()),
            GoRoute(path: RouteNames.principalReview, builder: (_, __) => const PrincipalReviewScreen()),
            GoRoute(path: RouteNames.vicePrincipalReview, builder: (_, __) => const VicePrincipalReviewScreen()),
            GoRoute(path: RouteNames.scoutClasses, builder: (_, __) => const ScoutClassesScreen()),
            GoRoute(path: RouteNames.scoutAttendance, builder: (_, __) => const ScoutAttendanceScreen()),
            GoRoute(path: RouteNames.scoutReport, builder: (_, __) => const ScoutReportScreen()),
            GoRoute(path: RouteNames.pklLocationReport, builder: (_, __) => const PklLocationReportScreen()),
            GoRoute(path: RouteNames.pklProgressReport, builder: (_, __) => const PklProgressReportScreen()),
            GoRoute(path: RouteNames.submissionInfo, builder: (_, __) => const SubmissionInfoScreen()),
            GoRoute(path: RouteNames.subjects, builder: (_, __) => const SubjectsScreen()),
            GoRoute(path: RouteNames.itemLoan, builder: (_, __) => const ItemLoanScreen()),
            GoRoute(path: RouteNames.equipmentSubmission, builder: (_, __) => const EquipmentSubmissionScreen()),
            GoRoute(path: RouteNames.loanResponse, builder: (_, __) => const LoanResponseScreen()),
            GoRoute(path: RouteNames.treasurerResponse, builder: (_, __) => const TreasurerResponseScreen()),
            GoRoute(path: RouteNames.principalResponse, builder: (_, __) => const PrincipalResponseScreen()),
          ],
        ),
      ],
      errorBuilder: (_, state) => Scaffold(
        body: Center(child: Text('Halaman tidak ditemukan: ${state.error}')),
      ),
    );
  }
}
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.login,
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final isLoggedIn = auth.isAuthenticated;
      final isLoginRoute = state.matchedLocation == RouteNames.login;
      if (!isLoggedIn && !isLoginRoute) return RouteNames.login;
      if (isLoggedIn && isLoginRoute) return RouteNames.home;
      return null;
    },
    routes: [
      GoRoute(path: RouteNames.login, builder: (_, __) => const LoginScreen()),

      ShellRoute(
        builder: (context, state, child) => MainShell(currentRoute: state.matchedLocation, child: child),
        routes: [
          // ─── Auth ──────────────────────────────────────────
          GoRoute(path: RouteNames.profile, builder: (_, __) => const ProfileScreen()),

          // ─── Home ──────────────────────────────────────────
          GoRoute(path: RouteNames.home, builder: (_, __) => const HomeScreen()),

          // ─── Academic ──────────────────────────────────────
          GoRoute(path: RouteNames.classes, builder: (_, __) => const ClassesScreen()),
          GoRoute(path: RouteNames.students, builder: (_, __) => const StudentsScreen()),
          GoRoute(path: RouteNames.teachers, builder: (_, __) => const TeachersScreen()),
          GoRoute(path: RouteNames.announcements, builder: (_, __) => const AnnouncementsScreen()),
          GoRoute(
            path: RouteNames.announcementDetail,
            builder: (_, state) => AnnouncementDetailScreen(announcementId: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(path: RouteNames.schedules, builder: (_, __) => const SchedulesScreen()),
          GoRoute(path: RouteNames.letters, builder: (_, __) => const LettersScreen()),
          GoRoute(path: RouteNames.subjects, builder: (_, __) => const SubjectsScreen()),
          // Wakil Kepsek → Academic Service
          GoRoute(path: RouteNames.wakilMonitoringJadwal, builder: (_, __) => const MonitoringJadwalScreen()),

          // ─── Student ───────────────────────────────────────
          GoRoute(path: RouteNames.cleanlinessRecap, builder: (_, __) => const CleanlinessRecapScreen()),
          GoRoute(path: RouteNames.parentingNotes, builder: (_, __) => const ParentingNotesScreen()),
          GoRoute(path: RouteNames.homeroomReflection, builder: (_, __) => const HomeroomReflectionScreen()),
          GoRoute(path: RouteNames.summonsLetter, builder: (_, __) => const SummonsLetterScreen()),
          GoRoute(path: RouteNames.attendanceRecap, builder: (_, __) => const AttendanceRecapScreen()),
          GoRoute(path: RouteNames.gradesRecap, builder: (_, __) => const GradesRecapScreen()),
          // Wakil Kepsek → Student Service
          GoRoute(path: RouteNames.wakilParenting, builder: (_, __) => const ParentingWakilScreen()),

          // ─── Learning ──────────────────────────────────────
          GoRoute(path: RouteNames.teacherAttendance, builder: (_, __) => const AbsensiGuruScreen()),
          GoRoute(path: RouteNames.teachingNotes, builder: (_, __) => const TeachingNotesScreen()),
          GoRoute(path: RouteNames.teacherEvaluation, builder: (_, __) => const TeacherEvaluationScreen()),
          GoRoute(path: RouteNames.learningDevice, builder: (_, __) => const LearningDeviceScreen()),
          GoRoute(path: RouteNames.principalReview, builder: (_, __) => const PrincipalReviewScreen()),
          GoRoute(path: RouteNames.vicePrincipalReview, builder: (_, __) => const VicePrincipalReviewScreen()),
          // Wakil Kepsek → Learning Service
          GoRoute(path: RouteNames.wakilAbsensiGuru, builder: (_, __) => const AbsensiGuruWakilScreen()),
          GoRoute(path: RouteNames.wakilKurikulum, builder: (_, __) => const KurikulumScreen()),
          GoRoute(path: RouteNames.wakilLaporan, builder: (_, __) => const LaporanWakilScreen()),

          // ─── Vocational / Pramuka ──────────────────────────
          GoRoute(path: RouteNames.scoutClasses, builder: (_, __) => const ScoutClassesScreen()),
          GoRoute(path: RouteNames.scoutAttendance, builder: (_, __) => const ScoutAttendanceScreen()),
          GoRoute(path: RouteNames.scoutReport, builder: (_, __) => const ScoutReportScreen()),

          // ─── Vocational / PKL ──────────────────────────────
          GoRoute(path: RouteNames.pklLocationReport, builder: (_, __) => const PklLocationReportScreen()),
          GoRoute(path: RouteNames.pklProgressReport, builder: (_, __) => const PklProgressReportScreen()),
          GoRoute(path: RouteNames.pklGrades, builder: (_, __) => const NilaiPKLScreen()),

          // ─── Asset ─────────────────────────────────────────
          GoRoute(path: RouteNames.submissionInfo, builder: (_, __) => const SubmissionInfoScreen()),
          GoRoute(path: RouteNames.itemLoan, builder: (_, __) => const ItemLoanScreen()),
          GoRoute(path: RouteNames.equipmentSubmission, builder: (_, __) => const EquipmentSubmissionScreen()),
          GoRoute(path: RouteNames.loanResponse, builder: (_, __) => const LoanResponseScreen()),
          GoRoute(path: RouteNames.treasurerResponse, builder: (_, __) => const TreasurerResponseScreen()),
          GoRoute(path: RouteNames.principalResponse, builder: (_, __) => const PrincipalResponseScreen()),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan: ${state.error}')),
    ),
  );
}
