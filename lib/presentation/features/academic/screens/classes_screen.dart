import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/academic_provider.dart';
import 'package:smk_sigumpar/data/repositories/academic_repository.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../common/widgets/loading_widget.dart';
import '../../../common/widgets/error_widget.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AcademicProvider(repository: sl<AcademicRepository>())
        ..fetchClasses(),
      child: const _ClassesView(),
    );
  }
}

class _ClassesView extends StatefulWidget {
  const _ClassesView();

  @override
  State<_ClassesView> createState() => _ClassesViewState();
}

class _ClassesViewState extends State<_ClassesView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AcademicProvider>().fetchClasses(
            search: _searchController.text.isEmpty
                ? null
                : _searchController.text,
          );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.classes)),
      body: Column(
        children: [
          // ─── Search bar ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.search,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<AcademicProvider>()
                              .fetchClasses(refresh: true);
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) => context
                  .read<AcademicProvider>()
                  .fetchClasses(refresh: true, search: value.isEmpty ? null : value),
            ),
          ),

          // ─── Content ─────────────────────────────────────
          Expanded(
            child: switch (provider.classState) {
              AcademicLoadState.initial ||
              AcademicLoadState.loading
                  when provider.classes.isEmpty =>
                const LoadingWidget(),
              AcademicLoadState.error when provider.classes.isEmpty =>
                AppErrorWidget(
                  message: provider.classError,
                  onRetry: () =>
                      context.read<AcademicProvider>().fetchClasses(refresh: true),
                ),
              _ => RefreshIndicator(
                  onRefresh: () => context
                      .read<AcademicProvider>()
                      .fetchClasses(refresh: true),
                  child: provider.classes.isEmpty
                      ? const Center(child: Text(AppStrings.noData))
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.classes.length +
                              (provider.hasMoreClasses ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            if (index == provider.classes.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final cls = provider.classes[index];
                            return Card(
                              child: ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.academic.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.class_outlined,
                                    color: AppColors.academic,
                                  ),
                                ),
                                title: Text(cls.name,
                                    style: Theme.of(context).textTheme.titleSmall),
                                subtitle: Text(
                                  '${cls.major} • ${cls.studentCount} Siswa',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.grey500),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.grey400,
                                ),
                              ),
                            );
                          },
                        ),
                ),
            },
          ),
        ],
      ),
    );
  }
}
