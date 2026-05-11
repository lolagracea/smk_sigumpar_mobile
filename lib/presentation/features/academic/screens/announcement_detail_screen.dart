import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../data/repositories/academic_repository.dart';
import '../../../common/widgets/error_widget.dart';
import '../../../common/widgets/loading_widget.dart';
import '../providers/academic_provider.dart';
import '../providers/announcement_provider.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final String announcementId;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(
        repository: sl<AcademicRepository>(),
      )..fetchAnnouncements(refresh: true),
      child: _AnnouncementDetailView(
        announcementId: announcementId,
      ),
    );
  }
}

class _AnnouncementDetailView extends StatelessWidget {
  final String announcementId;

  const _AnnouncementDetailView({
    required this.announcementId,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();

    if ((provider.announcementState == AcademicLoadState.initial ||
            provider.announcementState == AcademicLoadState.loading) &&
        provider.announcements.isEmpty) {
      return const Scaffold(
        body: LoadingWidget(),
      );
    }

    if (provider.announcementState == AcademicLoadState.error &&
        provider.announcements.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pengumuman')),
        body: AppErrorWidget(
          message: provider.announcementError,
          onRetry: () {
            context.read<AcademicProvider>().fetchAnnouncements(
                  refresh: true,
                );
          },
        ),
      );
    }

    final item = _findAnnouncement(provider.announcements);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pengumuman')),
        body: RefreshIndicator(
          onRefresh: () {
            return context.read<AcademicProvider>().fetchAnnouncements(
                  refresh: true,
                );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: const [
              SizedBox(height: 120),
              Icon(
                Icons.campaign_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'Pengumuman tidak ditemukan.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final judul = item['judul']?.toString() ?? 'Pengumuman';
    final isi = item['isi']?.toString() ?? '-';
    final createdAt = item['created_at']?.toString() ??
        item['tanggal']?.toString() ??
        item['updated_at']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return context.read<AcademicProvider>().fetchAnnouncements(
                refresh: true,
              );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 36,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    judul,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (createdAt != null && createdAt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            createdAt,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 18),
                  Text(
                    isi,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          fontSize: 15,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic>? _findAnnouncement(
    List<Map<String, dynamic>> announcements,
  ) {
    for (final item in announcements) {
      final id = item['id']?.toString();

      if (id == announcementId) {
        return item;
      }
    }

    return null;
  }
}
