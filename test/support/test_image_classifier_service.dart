import 'dart:async';

import 'package:lightshot_parser_mobile/features/gallery/domain/models/gallery_item.dart';
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';

ImageClassifierService buildTestImageClassifierService() {
  return ImageClassifierService(
    imagePreprocessor: ImagePreprocessor(),
    inferenceBackend: MockInferenceBackend(),
    cascadeClassifier: const CascadeClassifier(),
  );
}

class DelayedTestImageClassifierService extends ImageClassifierService {
  DelayedTestImageClassifierService({
    required this.delay,
    required this.onClassify,
  }) : super(
          imagePreprocessor: ImagePreprocessor(),
          inferenceBackend: MockInferenceBackend(),
          cascadeClassifier: const CascadeClassifier(),
        );

  final Duration delay;
  final GalleryItem Function(GalleryItem item) onClassify;

  @override
  Future<GalleryItem> classifyPendingGalleryItem({
    required GalleryItem item,
  }) async {
    await Future<void>.delayed(delay);
    return onClassify(item);
  }
}
