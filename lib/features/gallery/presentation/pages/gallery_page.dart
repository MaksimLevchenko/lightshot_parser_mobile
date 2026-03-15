import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/core/widgets/status_view.dart';
import 'package:lightshot_parser_mobile/features/gallery/data/repositories/gallery_repository.dart';
import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_cubit.dart';
import 'package:lightshot_parser_mobile/features/gallery/presentation/cubit/gallery_state.dart';
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
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
            ),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return InkWell(
                onTap: () => _openPhotoViewer(context, state.items, index),
                child: Container(
                  color: AppColors.imageCard,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Image.file(item.file),
                ),
              );
            },
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
}
