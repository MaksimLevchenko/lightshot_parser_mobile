import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/core/widgets/app_snack_bar.dart';
import 'package:lightshot_parser_mobile/core/widgets/status_view.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/presentation/cubit/photo_viewer_cubit.dart';
import 'package:lightshot_parser_mobile/features/photo_viewer/presentation/cubit/photo_viewer_state.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';

class PhotoViewerPage extends StatelessWidget {
  const PhotoViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PhotoViewerCubit, PhotoViewerState>(
      listener: (context, state) {
        if (state.feedback == PhotoViewerFeedback.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            buildAppSnackBar(message: S.of(context).imageDeleted),
          );
          context.read<PhotoViewerCubit>().clearFeedback();
          if (state.items.isEmpty && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } else if (state.feedback == PhotoViewerFeedback.saved &&
            state.savedPath != null &&
            state.savedPath!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            buildAppSnackBar(
              message: S.of(context).imageSavedToPath(state.savedPath!),
            ),
          );
          context.read<PhotoViewerCubit>().clearFeedback();
        } else if (state.errorMessage != null) {
          final errorMessage = switch (state.errorMessage) {
            'Storage operation failed' => S.of(context).permissionDenied,
            'permission-denied' => S.of(context).permissionDenied,
            'download-dir-missing' => S.of(context).noDownloadFolderFound,
            _ => S
                .of(context)
                .unknownErrorEPleaseContactToTheDev(state.errorMessage!),
          };
          ScaffoldMessenger.of(context).showSnackBar(
            buildAppSnackBar(
              message: errorMessage,
              backgroundColor: AppColors.error,
            ),
          );
          context.read<PhotoViewerCubit>().clearFeedback();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).photoViewer),
          actions: [
            IconButton(
              onPressed: () => context.read<PhotoViewerCubit>().saveCurrent(),
              icon: const Icon(Icons.download),
            ),
            IconButton(
              onPressed: () => context
                  .read<PhotoViewerCubit>()
                  .shareCurrent(S.of(context).shareImage),
              icon: const Icon(Icons.share),
            ),
            IconButton(
              onPressed: () => _confirmDeletion(context),
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
        body: BlocBuilder<PhotoViewerCubit, PhotoViewerState>(
          builder: (context, state) {
            if (state.items.isEmpty) {
              return StatusView(message: S.of(context).noPhotos);
            }
            return Stack(
              children: [
                PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  pageController:
                      PageController(initialPage: state.currentIndex),
                  itemCount: state.items.length,
                  onPageChanged: context.read<PhotoViewerCubit>().pageChanged,
                  builder: (context, index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: FileImage(state.items[index].file),
                      initialScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.contained * 4,
                      minScale: PhotoViewComputedScale.contained,
                    );
                  },
                  loadingBuilder: (context, event) => Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: event == null
                            ? null
                            : event.cumulativeBytesLoaded /
                                (event.expectedTotalBytes ?? 1),
                      ),
                    ),
                  ),
                  backgroundDecoration:
                      const BoxDecoration(color: AppColors.imageCard),
                ),
                if (state.isBusy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x66000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeletion(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(S.of(context).confirmDeletion),
              content: Text(S.of(context).areYouSureYouWantToDeleteThisImage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(S.of(context).cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(S.of(context).delete),
                ),
              ],
            );
          },
        ) ??
        false;
    if (shouldDelete && context.mounted) {
      await context.read<PhotoViewerCubit>().deleteCurrent();
    }
  }
}
