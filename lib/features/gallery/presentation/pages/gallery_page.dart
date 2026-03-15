import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/core/widgets/status_view.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_state.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/widgets/classification_badge.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/data/repositories/photo_actions_repository.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/presentation/cubit/photo_viewer_cubit.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/presentation/pages/photo_viewer_page.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).galleryAppBar),
      ),
      body: BlocBuilder<GalleryCubit, GalleryState>(
        builder: (context, state) {
          if (state.isLoading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty) {
            return StatusView(message: S.of(context).noPhotos);
          }
          final visibleItems = state.visibleItems;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: GalleryFilter.values.map((filter) {
                      return ChoiceChip(
                        key: ValueKey('gallery-filter-${filter.name}'),
                        label: Text(_filterLabel(context, filter)),
                        selected: state.selectedFilter == filter,
                        onSelected: (_) =>
                            context.read<GalleryCubit>().setFilter(filter),
                      );
                    }).toList(growable: false),
                  ),
                ),
              ),
              Expanded(
                child: visibleItems.isEmpty
                    ? StatusView(
                        message: S.of(context).noPhotosForSelectedFilter,
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                        ),
                        itemCount: visibleItems.length,
                        itemBuilder: (context, index) {
                          final item = visibleItems[index];
                          return InkWell(
                            key: ValueKey('gallery-grid-item-$index'),
                            onTap: () =>
                                _openPhotoViewer(context, visibleItems, index),
                            child: Container(
                              color: AppColors.imageCard,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.file(
                                      item.file,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    left: AppSpacing.sm,
                                    top: AppSpacing.sm,
                                    child: ClassificationBadge(
                                      classificationResult:
                                          item.classificationResult,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
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

  String _filterLabel(BuildContext context, GalleryFilter filter) {
    return switch (filter) {
      GalleryFilter.all => S.of(context).galleryFilterAll,
      GalleryFilter.nsfw => S.of(context).classificationCategoryNsfw,
      GalleryFilter.people => S.of(context).classificationCategoryPeople,
      GalleryFilter.documents => S.of(context).classificationCategoryDocuments,
      GalleryFilter.notClassified =>
        S.of(context).classificationCategoryNotClassified,
      GalleryFilter.unrecognized =>
        S.of(context).classificationCategoryUnrecognized,
    };
  }
}
