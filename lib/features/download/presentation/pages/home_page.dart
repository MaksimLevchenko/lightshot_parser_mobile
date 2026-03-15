import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/core/widgets/app_snack_bar.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_bloc.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_event.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_state.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/utils/download_source_texts.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/utils/home_page_texts.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_state.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/pages/gallery_page.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/data/repositories/photo_actions_repository.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/presentation/cubit/photo_viewer_cubit.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/presentation/pages/photo_viewer_page.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/domain/models/app_settings.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsRepository>().currentSettings;

    return BlocListener<DownloadBloc, DownloadState>(
      listener: (context, state) {
        if (state.status == DownloadStatus.completed) {
          ScaffoldMessenger.of(context).showSnackBar(
            buildAppSnackBar(message: S.of(context).downloadingComplete),
          );
          context.read<DownloadBloc>().add(const DownloadFeedbackCleared());
        } else if (state.status == DownloadStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            buildAppSnackBar(
              message: _failureMessage(context, state),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<DownloadBloc>().add(const DownloadFeedbackCleared());
        } else if (state.status == DownloadStatus.cancelled) {
          context.read<DownloadBloc>().add(const DownloadFeedbackCleared());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).mainTitle),
          actions: [
            IconButton(
              tooltip: HomePageTexts.openGalleryHint(context),
              onPressed: () => _openGallery(context),
              icon: const Icon(Icons.photo_library_outlined),
            ),
            IconButton(
              tooltip: S.of(context).settings,
              onPressed: () => _openSettings(context),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: SafeArea(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 1080;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeroSection(settings: settings),
                          const SizedBox(height: AppSpacing.xl),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _QuickActionsCard(
                                        onOpenGallery: () =>
                                            _openGallery(context),
                                        onOpenSettings: () =>
                                            _openSettings(context),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      _DownloadStatusCard(settings: settings),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xl),
                                Expanded(
                                  flex: 7,
                                  child: _RecentGallerySection(
                                    layoutKey:
                                        const ValueKey('home-wide-layout'),
                                    onOpenGallery: () => _openGallery(context),
                                    onOpenSettings: () =>
                                        _openSettings(context),
                                    onOpenPhotoViewer: (items, index) =>
                                        _openPhotoViewer(context, items, index),
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _QuickActionsCard(
                              onOpenGallery: () => _openGallery(context),
                              onOpenSettings: () => _openSettings(context),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _DownloadStatusCard(settings: settings),
                            const SizedBox(height: AppSpacing.lg),
                            _RecentGallerySection(
                              layoutKey: const ValueKey('home-narrow-layout'),
                              onOpenGallery: () => _openGallery(context),
                              onOpenSettings: () => _openSettings(context),
                              onOpenPhotoViewer: (items, index) =>
                                  _openPhotoViewer(context, items, index),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _failureMessage(BuildContext context, DownloadState state) {
    return switch (state.failureCode) {
      'proxy' => S.of(context).downloadErrorMakeSureYouUseHttpProxy,
      'vpn' => S.of(context).downloadErrorTryToChangeVpn,
      _ => S.of(context).unknownErrorEPleaseContactToTheDev(
            state.errorDetails ?? 'unknown',
          ),
    };
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<GalleryCubit>()),
            BlocProvider(
              create: (_) => SettingsCubit(context.read<SettingsRepository>()),
            ),
          ],
          child: const SettingsPage(),
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _openGallery(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<GalleryCubit>(),
          child: const GalleryPage(),
        ),
      ),
    );
  }

  void _openPhotoViewer(
    BuildContext context,
    List<GalleryItem> items,
    int index,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => PhotoViewerCubit(
            photoActionsRepository: context.read<PhotoActionsRepository>(),
            galleryRepository: context.read<GalleryRepository>(),
            initialItems: items,
            initialIndex: index,
          ),
          child: const PhotoViewerPage(),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = [
      (
        DownloadSourceTexts.currentSourceLabel(context),
        DownloadSourceTexts.sourceName(context, settings.selectedSource),
        Icons.link_rounded,
      ),
      (
        HomePageTexts.targetCountLabel(context),
        '${settings.wantedNumOfImages}',
        Icons.download_rounded,
      ),
      (
        HomePageTexts.proxyStatusLabel(context),
        settings.proxySettings.enabled
            ? HomePageTexts.proxyEnabled(context)
            : HomePageTexts.proxyDisabled(context),
        Icons.shield_outlined,
      ),
    ];

    return Container(
      key: const ValueKey('home-hero'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF9F3), Color(0xFFF2D7C9), Color(0xFFE3BDAF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.lg,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).mainTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    HomePageTexts.subtitle(context),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: chips
                  .map(
                    (chip) => Container(
                      constraints: const BoxConstraints(minWidth: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(chip.$3, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(chip.$1, style: theme.textTheme.bodySmall),
                              Text(chip.$2, style: theme.textTheme.titleMedium),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onOpenGallery,
    required this.onOpenSettings,
  });

  final VoidCallback onOpenGallery;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      sectionKey: const ValueKey('quick-actions-card'),
      child: BlocBuilder<DownloadBloc, DownloadState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                HomePageTexts.quickActionsTitle(context),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                HomePageTexts.quickActionsBody(context),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                key: const ValueKey('home-primary-action'),
                onPressed: () {
                  context.read<DownloadBloc>().add(
                        state.isDownloading
                            ? const DownloadCancelled()
                            : const DownloadRequested(),
                      );
                },
                icon: Icon(
                  state.isDownloading ? Icons.stop_rounded : Icons.play_arrow,
                ),
                label: Text(
                  state.isDownloading
                      ? S.of(context).cancel
                      : S.of(context).download,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                key: const ValueKey('open-settings-button'),
                onPressed: onOpenSettings,
                icon: const Icon(Icons.tune),
                label: Text(S.of(context).settings),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                key: const ValueKey('open-gallery-button'),
                onPressed: onOpenGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(S.of(context).galleryAppBar),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DownloadStatusCard extends StatelessWidget {
  const _DownloadStatusCard({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      sectionKey: const ValueKey('download-status-card'),
      child: BlocBuilder<DownloadBloc, DownloadState>(
        builder: (context, state) {
          final total = state.progress.totalCount == 0
              ? settings.wantedNumOfImages
              : state.progress.totalCount;
          final status = _statusData(context, state.status);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: status.$2.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(status.$3, color: status.$2),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          HomePageTexts.downloadStatusTitle(context),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          status.$1,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: status.$2,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: LinearProgressIndicator(
                  key: const ValueKey('download-progress-indicator'),
                  minHeight: 10,
                  value: state.isDownloading ? state.progress.fraction : 0,
                  backgroundColor: AppColors.panelStrong,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                S.of(context).downloadedImagesOfWantednumofimages(
                      state.progress.downloadedCount,
                      total,
                    ),
                key: const ValueKey('download-progress-text'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                HomePageTexts.currentSetupTitle(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _SummaryRow(
                label: DownloadSourceTexts.currentSourceLabel(context),
                value: DownloadSourceTexts.sourceName(
                  context,
                  settings.selectedSource,
                ),
              ),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(
                label: HomePageTexts.targetCountLabel(context),
                value: '${settings.wantedNumOfImages}',
              ),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(
                label: HomePageTexts.startPointLabel(context),
                value: _startValue(context, settings),
              ),
              const Divider(height: AppSpacing.lg),
              _SummaryRow(
                label: HomePageTexts.proxyStatusLabel(context),
                value: settings.proxySettings.enabled
                    ? HomePageTexts.proxyEnabled(context)
                    : HomePageTexts.proxyDisabled(context),
              ),
            ],
          );
        },
      ),
    );
  }

  (String, Color, IconData) _statusData(
    BuildContext context,
    DownloadStatus status,
  ) {
    return switch (status) {
      DownloadStatus.idle => (
          HomePageTexts.statusReady(context),
          AppColors.accent,
          Icons.dashboard_customize_outlined,
        ),
      DownloadStatus.inProgress => (
          HomePageTexts.statusDownloading(context),
          AppColors.seed,
          Icons.downloading_rounded,
        ),
      DownloadStatus.completed => (
          HomePageTexts.statusCompleted(context),
          AppColors.success,
          Icons.check_circle_outline,
        ),
      DownloadStatus.cancelled => (
          HomePageTexts.statusCancelled(context),
          AppColors.warning,
          Icons.pause_circle_outline,
        ),
      DownloadStatus.failure => (
          HomePageTexts.statusFailed(context),
          AppColors.error,
          Icons.error_outline,
        ),
    };
  }

  String _startValue(BuildContext context, AppSettings settings) {
    switch (settings.selectedSource) {
      case DownloadSource.lightshot:
        return settings.lightshot.useRandomAddress
            ? HomePageTexts.randomStart(context)
            : settings.lightshot.startingId;
      case DownloadSource.imgur:
        return settings.imgur.useRandomAddress
            ? HomePageTexts.randomStart(context)
            : settings.imgur.startingId;
    }
  }
}

class _RecentGallerySection extends StatelessWidget {
  const _RecentGallerySection({
    required this.layoutKey,
    required this.onOpenGallery,
    required this.onOpenSettings,
    required this.onOpenPhotoViewer,
  });

  final Key layoutKey;
  final VoidCallback onOpenGallery;
  final VoidCallback onOpenSettings;
  final void Function(List<GalleryItem> items, int index) onOpenPhotoViewer;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      sectionKey: layoutKey,
      child: BlocBuilder<GalleryCubit, GalleryState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final items = state.items.take(6).toList();
              return Column(
                key: const ValueKey('recent-gallery-section'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              HomePageTexts.recentGalleryTitle(context),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              HomePageTexts.recentGalleryBody(context),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onOpenGallery,
                        icon: const Icon(Icons.arrow_outward_rounded),
                        label: Text(S.of(context).seeAll),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.isLoading && state.items.isEmpty)
                    _GalleryStateCard(
                      icon: Icons.photo_library_outlined,
                      title: HomePageTexts.loadingGallery(context),
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    )
                  else if (state.errorMessage != null && state.items.isEmpty)
                    _GalleryStateCard(
                      icon: Icons.error_outline,
                      title: HomePageTexts.statusFailed(context),
                      body: state.errorMessage!,
                    )
                  else if (items.isEmpty)
                    _GalleryStateCard(
                      icon: Icons.photo_library_outlined,
                      title: HomePageTexts.emptyGalleryTitle(context),
                      body: HomePageTexts.emptyGalleryBody(context),
                      child: OutlinedButton.icon(
                        key: const ValueKey('empty-gallery-cta'),
                        onPressed: onOpenSettings,
                        icon: const Icon(Icons.tune),
                        label: Text(HomePageTexts.configureDownload(context)),
                      ),
                    )
                  else
                    GridView.builder(
                      key: const ValueKey('recent-gallery-grid'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _columns(constraints.maxWidth),
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio:
                            constraints.maxWidth >= 860 ? 0.95 : 1.05,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _GalleryPreviewCard(
                          key: ValueKey('gallery-preview-$index'),
                          item: item,
                          onTap: () => onOpenPhotoViewer(
                              state.items, state.items.indexOf(item)),
                        );
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  int _columns(double width) {
    if (width >= 860) {
      return 3;
    }
    if (width >= 520) {
      return 2;
    }
    return 1;
  }
}

class _GalleryStateCard extends StatelessWidget {
  const _GalleryStateCard({
    required this.icon,
    required this.title,
    this.body = '',
    this.child,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.panelStrong,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.accent),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: AppSpacing.md),
            child!,
          ],
        ],
      ),
    );
  }
}

class _GalleryPreviewCard extends StatelessWidget {
  const _GalleryPreviewCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final GalleryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: AppColors.panel),
                    child: Image.file(
                      item.file,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image_outlined, size: 40),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                item.sourceId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                DownloadSourceTexts.sourceName(context, item.source),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(HomePageTexts.openImage(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.sectionKey,
  });

  final Widget child;
  final Key? sectionKey;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: sectionKey,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
