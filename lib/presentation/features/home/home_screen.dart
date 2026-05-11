import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/utils/role_helper.dart';
import '../../../data/repositories/academic_repository.dart';
import '../../common/providers/auth_provider.dart';
import '../academic/providers/announcement_provider.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/announcement_model.dart';
import 'widgets/guru_mapel_drawer.dart';
import '../academic/providers/academic_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementProvider>().loadAnnouncements(limit: 5);
    });
  }

  Future<void> _refreshData() async {
    await context.read<AnnouncementProvider>().refresh(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(
        repository: sl<AcademicRepository>(),
      )..fetchAnnouncements(refresh: true),
      child: _HomeView(onRefresh: _refreshData),
    );
  }
}

class _HomeView extends StatelessWidget {
  final VoidCallback onRefresh;

  const _HomeView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: _buildDrawerByRole(user?.role),
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
              'SMK NEGERI 1 SIGUMPAR',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeCard(context, user),
              const SizedBox(height: 16),
              _buildAnnouncementCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildDrawerByRole(String? role) {
    if (role == null) return null;

    if (role == AppRoles.teacher) {
      return const GuruMapelDrawer(currentRoute: RouteNames.home);
    }

    return null;
  }

  Widget _buildWelcomeCard(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat Datang',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.name ?? 'Loading...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            RoleHelper.getRolesLabel(
              role: user?.role,
              roles: user?.roles,
            ),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sistem informasi sekolah untuk mengelola data akademik dan administrasi pendidikan dengan mudah dan efisien.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();
    final announcements = provider.announcements;

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pengumuman Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (announcements.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${announcements.length} pengumuman',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (provider.isLoading && announcements.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (announcements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada pengumuman aktif saat ini.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: announcements.take(5).map((announcement) {
                return InkWell(
                  onTap: () {
                    context.go(RouteNames.announcementDetailPath(
                        announcement.id.toString()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.campaign_outlined,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.judul,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                announcement.preview,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                              if (announcement.createdAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _formatRelativeDate(announcement.createdAt!),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';

    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
