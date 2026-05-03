// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/auth_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user   = state is AuthAuthenticated ? state.user : null;
        final isWide = MediaQuery.of(context).size.width >= 700;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: isWide
              ? _buildWideLayout(context, user)
              : _buildNarrowLayout(context, user),
        );
      },
    );
  }

  // ── Lebar: 2 kolom sejajar seperti referensi ───────────────────────────────
  Widget _buildWideLayout(BuildContext context, UserModel? user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _WelcomeCard(user: user)),
        const SizedBox(width: 20),
        Expanded(child: _AnnouncementsCard()),
      ],
    );
  }

  // ── Sempit: 1 kolom ────────────────────────────────────────────────────────
  Widget _buildNarrowLayout(BuildContext context, UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeCard(user: user),
        const SizedBox(height: 20),
        _AnnouncementsCard(),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Welcome Card ──────────────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final UserModel? user;
  const _WelcomeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final initial = user?.inisial ?? 'G';
    final name    = user?.name ?? 'Guru';
    final role    = user?.displayRole ?? 'Guru Mata Pelajaran';

    return Container(
      width      : double.infinity,
      padding    : const EdgeInsets.all(20),
      decoration : BoxDecoration(
        color       : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border      : Border.all(color: const Color(0xFFE0E6F0)),
        boxShadow   : [
          BoxShadow(
            color  : Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul
          const Text(
            'Selamat Datang',
            style: TextStyle(
              color     : Color(0xFF1A3A6B),
              fontSize  : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Avatar + nama + role
          Row(
            children: [
              Container(
                width : 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color     : AppColors.primary,
                      fontSize  : 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color     : AppColors.textPrimary,
                        fontSize  : 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: const TextStyle(
                        color  : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEEF2F8), height: 1),
          const SizedBox(height: 14),

          // Keterangan login
          Text(
            'Anda login sebagai ${role.toLowerCase()} pada sistem informasi SMK N 1 Sigumpar.',
            style: const TextStyle(
              color   : AppColors.textSecondary,
              fontSize: 13,
              height  : 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Announcements Card ────────────────────────────────────────────────────────
class _AnnouncementsCard extends StatelessWidget {
  // Data dummy — bisa diganti dengan data dari API/bloc
  static const _announcements = <_AnnouncementData>[];

  @override
  Widget build(BuildContext context) {
    return Container(
      width      : double.infinity,
      decoration : BoxDecoration(
        color       : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border      : Border.all(color: const Color(0xFFE0E6F0)),
        boxShadow   : [
          BoxShadow(
            color  : Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 14),
            child  : Text(
              'Pengumuman Terbaru',
              style: TextStyle(
                color     : Color(0xFF1A3A6B),
                fontSize  : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEF2F8)),

          if (_announcements.isEmpty)
            const SizedBox(
              height: 160,
              child : Center(
                child: Text(
                  'Belum ada pengumuman aktif saat ini.',
                  style: TextStyle(
                    color  : AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics   : const NeverScrollableScrollPhysics(),
              padding   : const EdgeInsets.symmetric(vertical: 8),
              itemCount : _announcements.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFEEF2F8)),
              itemBuilder: (_, i) => _AnnouncementTile(data: _announcements[i]),
            ),
        ],
      ),
    );
  }
}

class _AnnouncementData {
  final String title;
  final String date;
  final String snippet;
  const _AnnouncementData(this.title, this.date, this.snippet);
}

class _AnnouncementTile extends StatelessWidget {
  final _AnnouncementData data;
  const _AnnouncementTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(data.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize  : 13,
                        color     : AppColors.textPrimary)),
              ),
              Text(data.date,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(data.snippet,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}