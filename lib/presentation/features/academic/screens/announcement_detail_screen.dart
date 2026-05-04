import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/academic_provider.dart';
import '../../../../data/repositories/academic_repository.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../common/widgets/loading_widget.dart';
import '../../../common/widgets/error_widget.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final String announcementId;

  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(repository: sl<AcademicRepository>())
        ..fetchAnnouncements(),
      child: _AnnouncementDetailView(announcementId: announcementId),
    );
  }
}

class _AnnouncementDetailView extends StatelessWidget {
  final String announcementId;

  const _AnnouncementDetailView({required this.announcementId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
      ),
      body: switch (provider.announcementState) {
        AcademicLoadState.initial ||
        AcademicLoadState.loading =>
          const LoadingWidget(),
        AcademicLoadState.error => AppErrorWidget(
            message: 'Gagal memuat pengumuman',
            onRetry: () => context
                .read<AcademicProvider>()
                .fetchAnnouncements(refresh: true),
          ),
        AcademicLoadState.loaded => _buildDetail(context, provider),
      },
    );
  }

  Widget _buildDetail(BuildContext context, AcademicProvider provider) {
    final announcement = provider.announcements
        .where((a) => a['id']?.toString() == announcementId)
        .firstOrNull;

    if (announcement == null) {
      return const Center(child: Text('Pengumuman tidak ditemukan'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            announcement['judul'] ?? announcement['title'] ?? 'Tanpa Judul',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(announcement['created_at']),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
          const Divider(height: 32),
          Text(
            announcement['isi'] ?? announcement['content'] ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    return date.toString();
  }
}
