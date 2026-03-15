import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/core/widgets/app_snack_bar.dart';
import 'package:lightshot_parser_mobile/core/widgets/status_view.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/utils/download_source_texts.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_bloc.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_event.dart';
import 'package:lightshot_parser_mobile/features/download/presentation/bloc/download_state.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_state.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/pages/gallery_page.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/data/repositories/photo_actions_repository.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/presentation/cubit/photo_viewer_cubit.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/presentation/pages/photo_viewer_page.dart';
import 'package:lightshot_parser_mobile/features/settings/data/repositories/settings_repository.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:lightshot_parser_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final selectedSource =
        context.read<SettingsRepository>().currentSettings.selectedSource;
    return BlocListener<DownloadBloc, DownloadState>(
      listener: (context, state) {
        if (state.status == DownloadStatus.completed) {
          ScaffoldMessenger.of(context).showSnackBar(
            buildAppSnackBar(message: S.of(context).downloadingComplete),
          );
          context.read<DownloadBloc>().add(const DownloadFeedbackCleared());
        } else if (state.status == DownloadStatus.failure) {
          final message = switch (state.failureCode) {
            'proxy' => S.of(context).downloadErrorMakeSureYouUseHttpProxy,
            'vpn' => S.of(context).downloadErrorTryToChangeVpn,
            _ => S.of(context).unknownErrorEPleaseContactToTheDev(
                  state.errorDetails ?? 'unknown',
                ),
          };
          ScaffoldMessenger.of(context).showSnackBar(
            buildAppSnackBar(
              message: message,
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
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(
                          value: context.read<GalleryCubit>(),
                        ),
                        BlocProvider(
                          create: (_) => SettingsCubit(
                            context.read<SettingsRepository>(),
                          ),
                        ),
                      ],
                      child: const SettingsPage(),
                    ),
                  ),
                );
                if (mounted) {
                  setState(() {});
                }
              },
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
        body: SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.md),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      S.of(context).galleryAppBar,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BlocProvider.value(
                              value: context.read<GalleryCubit>(),
                              child: const GalleryPage(),
                            ),
                          ),
                        );
                      },
                      child: Text(S.of(context).seeAll),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 300,
                  child: BlocBuilder<GalleryCubit, GalleryState>(
                    builder: (context, galleryState) {
                      if (galleryState.isLoading &&
                          galleryState.items.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (galleryState.items.isEmpty) {
                        return StatusView(message: S.of(context).noPhotos);
                      }
                      final recentItems = galleryState.items.take(15).toList();
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentItems.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = recentItems[index];
                          return _GalleryCard(
                            item: item,
                            onTap: () => _openPhotoViewer(
                              context,
                              galleryState.items,
                              galleryState.items.indexOf(item),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                BlocBuilder<DownloadBloc, DownloadState>(
                  builder: (context, state) {
                    final total = state.progress.totalCount == 0
                        ? context
                            .read<SettingsRepository>()
                            .currentSettings
                            .wantedNumOfImages
                        : state.progress.totalCount;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(DownloadSourceTexts.currentSourceLabel(
                                context)),
                            Chip(
                              label: Text(
                                DownloadSourceTexts.sourceName(
                                  context,
                                  selectedSource,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: state.isDownloading
                              ? Column(
                                  key: const ValueKey('progress'),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    LinearProgressIndicator(
                                      value: state.progress.fraction,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      S
                                          .of(context)
                                          .downloadedImagesOfWantednumofimages(
                                            state.progress.downloadedCount,
                                            total,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                )
                              : const SizedBox(
                                  key: ValueKey('idle-spacing'),
                                  height: 50,
                                ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            context.read<DownloadBloc>().add(
                                  state.isDownloading
                                      ? const DownloadCancelled()
                                      : const DownloadRequested(),
                                );
                          },
                          child: Text(
                            state.isDownloading
                                ? S.of(context).cancel
                                : S.of(context).download,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
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

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({
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
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Image.file(
            item.file,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}
