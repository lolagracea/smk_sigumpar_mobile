import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/route_names.dart';
import '../../presentation/common/providers/auth_provider.dart';
import '../../presentation/features/auth/login_screen.dart';
import '../../presentation/features/auth/profile_screen.dart';
import '../../presentation/features/home/home_screen.dart';
import '../../presentation/features/academic/screens/classes_screen.dart';
import '../../presentation/features/academic/screens/students_screen.dart';
import '../../presentation/features/academic/screens/teachers_screen.dart';
import '../../presentation/features/academic/screens/announcements_screen.dart';
import '../../presentation/features/academic/screens/schedules_screen.dart';
import '../../presentation/features/academic/screens/letters_screen.dart';
import '../../presentation/features/student/screens/attendance_recap_screen.dart';
import '../../presentation/features/student/screens/grades_recap_screen.dart';
import '../../presentation/features/student/screens/cleanliness_recap_screen.dart';
import '../../presentation/features/student/screens/parenting_notes_screen.dart';
import '../../presentation/features/student/screens/homeroom_reflection_screen.dart';
import '../../presentation/features/student/screens/summons_letter_screen.dart';
import '../../presentation/features/learning/screens/teacher_attendance_screen.dart';
import '../../presentation/features/learning/screens/teaching_notes_screen.dart';
import '../../presentation/features/learning/screens/teacher_evaluation_screen.dart';
import '../../presentation/features/learning/screens/learning_device_screen.dart';
import '../../presentation/features/learning/screens/principal_review_screen.dart';
import '../../presentation/features/learning/screens/vice_principal_review_screen.dart';
import '../../presentation/features/vocational/screens/scout_classes_screen.dart';
import '../../presentation/features/vocational/screens/scout_attendance_screen.dart';
import '../../presentation/features/vocational/screens/scout_report_screen.dart';
import '../../presentation/features/vocational/screens/pkl_location_report_screen.dart';
import '../../presentation/features/vocational/screens/pkl_progress_report_screen.dart';
import '../../presentation/features/asset/screens/submission_info_screen.dart';
import '../../presentation/features/asset/screens/item_loan_screen.dart';
import '../../presentation/features/asset/screens/equipment_submission_screen.dart';
import '../../presentation/features/asset/screens/loan_response_screen.dart';
import '../../presentation/features/asset/screens/treasurer_response_screen.dart';
import '../../presentation/features/asset/screens/principal_response_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

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
      // ─── Auth ────────────────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (_, __) => const ProfileScreen(),
      ),

      // ─── Home ────────────────────────────────────────────
      GoRoute(
        path: RouteNames.home,
        builder: (_, __) => const HomeScreen(),
      ),

      // ─── Academic ────────────────────────────────────────
      GoRoute(path: RouteNames.classes, builder: (_, __) => const ClassesScreen()),
      GoRoute(path: RouteNames.students, builder: (_, __) => const StudentsScreen()),
      GoRoute(path: RouteNames.teachers, builder: (_, __) => const TeachersScreen()),
      GoRoute(path: RouteNames.announcements, builder: (_, __) => const AnnouncementsScreen()),
      GoRoute(path: RouteNames.schedules, builder: (_, __) => const SchedulesScreen()),
      GoRoute(path: RouteNames.letters, builder: (_, __) => const LettersScreen()),

      // ─── Student ─────────────────────────────────────────
      GoRoute(path: RouteNames.cleanlinessRecap, builder: (_, __) => const CleanlinessRecapScreen()),
      GoRoute(path: RouteNames.parentingNotes, builder: (_, __) => const ParentingNotesScreen()),
      GoRoute(path: RouteNames.homeroomReflection, builder: (_, __) => const HomeroomReflectionScreen()),
      GoRoute(path: RouteNames.summonsLetter, builder: (_, __) => const SummonsLetterScreen()),
      GoRoute(path: RouteNames.attendanceRecap, builder: (_, __) => const AttendanceRecapScreen()),
      GoRoute(path: RouteNames.gradesRecap, builder: (_, __) => const GradesRecapScreen()),

      // ─── Learning ────────────────────────────────────────
      GoRoute(path: RouteNames.teacherAttendance, builder: (_, __) => const TeacherAttendanceScreen()),
      GoRoute(path: RouteNames.teachingNotes, builder: (_, __) => const TeachingNotesScreen()),
      GoRoute(path: RouteNames.teacherEvaluation, builder: (_, __) => const TeacherEvaluationScreen()),
      GoRoute(path: RouteNames.learningDevice, builder: (_, __) => const LearningDeviceScreen()),
      GoRoute(path: RouteNames.principalReview, builder: (_, __) => const PrincipalReviewScreen()),
      GoRoute(path: RouteNames.vicePrincipalReview, builder: (_, __) => const VicePrincipalReviewScreen()),

      // ─── Vocational ──────────────────────────────────────
      GoRoute(path: RouteNames.scoutClasses, builder: (_, __) => const ScoutClassesScreen()),
      GoRoute(path: RouteNames.scoutAttendance, builder: (_, __) => const ScoutAttendanceScreen()),
      GoRoute(path: RouteNames.scoutReport, builder: (_, __) => const ScoutReportScreen()),
      GoRoute(path: RouteNames.pklLocationReport, builder: (_, __) => const PklLocationReportScreen()),
      GoRoute(path: RouteNames.pklProgressReport, builder: (_, __) => const PklProgressReportScreen()),

      // ─── Asset ───────────────────────────────────────────
      GoRoute(path: RouteNames.submissionInfo, builder: (_, __) => const SubmissionInfoScreen()),
      GoRoute(path: RouteNames.itemLoan, builder: (_, __) => const ItemLoanScreen()),
      GoRoute(path: RouteNames.equipmentSubmission, builder: (_, __) => const EquipmentSubmissionScreen()),
      GoRoute(path: RouteNames.loanResponse, builder: (_, __) => const LoanResponseScreen()),
      GoRoute(path: RouteNames.treasurerResponse, builder: (_, __) => const TreasurerResponseScreen()),
      GoRoute(path: RouteNames.principalResponse, builder: (_, __) => const PrincipalResponseScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak ditemukan: ${state.error}'),
      ),
    ),
  );
}
