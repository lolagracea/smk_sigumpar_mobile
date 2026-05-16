import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/utils/role_helper.dart';
import '../../../data/repositories/academic_repository.dart';
import '../../../data/repositories/kelola_akun_repository.dart';
import '../../common/providers/auth_provider.dart';
import '../academic/providers/academic_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(
        repository: sl<AcademicRepository>(),
        kelolaAkunRepository: sl<KelolaAkunRepository>(),
      )..fetchAnnouncements(refresh: true),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    // ✅ IKUTI TEAM LEAD: isDark untuk dark mode support
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: const Color(0xFF2563EB),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      onRefresh: () {
        return context.read<AcademicProvider>().fetchAnnouncements(
          refresh: true,
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ IKUTI TEAM LEAD: pass isDark ke kedua widget
            _buildWelcomeCard(context, user, isDark),
            const SizedBox(height: 24),
            _buildAnnouncementCard(context, context.watch<AcademicProvider>(), isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, dynamic user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selamat Datang,',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user?.name ?? 'Memuat data...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2563EB).withOpacity(0.2)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              RoleHelper.getRolesLabel(
                role: user?.role,
                roles: user?.roles,
              ),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sistem informasi sekolah untuk mengelola data akademik dan administrasi pendidikan dengan mudah dan efisien.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ IKUTI TEAM LEAD: terima academicProvider & isDark sebagai parameter
  Widget _buildAnnouncementCard(
      BuildContext context,
      AcademicProvider provider,
      bool isDark,
      ) {
    final announcements = provider.announcements;

    return Container(
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : Colors.grey.shade100,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Pengumuman Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (announcements.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${announcements.length} Baru',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (provider.announcementState == AcademicLoadState.loading &&
              announcements.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2563EB),
                  strokeWidth: 3,
                ),
              ),
            )
          else if (announcements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 56,
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada pengumuman',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: announcements.take(5).map((item) {
                final judul = item['judul']?.toString() ?? '-';
                final isi = item['isi']?.toString() ?? '-';

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final id = item['id']?.toString();
                      if (id == null || id.isEmpty) return;
                      context.go(RouteNames.announcementDetailPath(id));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey.shade50,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2563EB).withOpacity(0.15)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.campaign_rounded,
                              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  judul,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isi,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}