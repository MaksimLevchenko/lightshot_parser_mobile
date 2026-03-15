import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_package;
import 'package:lightshot_parser_mobile/features/image_classification/image_classification.dart';

void main() {
  late Directory tempDirectory;
  late ImagePreprocessor imagePreprocessor;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('preprocessor_test_');
    imagePreprocessor = ImagePreprocessor();
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('decode and preprocess resize image to tensor-ready data', () async {
    final image = image_package.Image(width: 2, height: 2)
      ..setPixelRgb(0, 0, 255, 0, 0)
      ..setPixelRgb(1, 0, 0, 255, 0)
      ..setPixelRgb(0, 1, 0, 0, 255)
      ..setPixelRgb(1, 1, 255, 255, 255);
    final file = File('${tempDirectory.path}/sample.png');
    await file.writeAsBytes(image_package.encodePng(image), flush: true);

    final decoded = await imagePreprocessor.decodeFile(imagePath: file.path);
    const modelSpec = ModelSpec(
      key: 'documents',
      category: ClassificationCategory.documents,
      assetPath: 'assets/ml/models/documents.onnx',
      inputName: 'input',
      outputName: 'output',
      inputWidth: 4,
      inputHeight: 4,
    );

    final preprocessed = imagePreprocessor.preprocessDecodedImage(
      decodedImage: decoded,
      modelSpec: modelSpec,
    );

    expect(preprocessed.width, 4);
    expect(preprocessed.height, 4);
    expect(preprocessed.channels, 3);
    expect(preprocessed.tensor.length, 4 * 4 * 3);
    expect(preprocessed.shape, const <int>[1, 3, 4, 4]);
    expect(preprocessed.tensor.first, 1.0);
  });

  test('nsfw preprocessing uses configured normalization and target size',
      () async {
    final image = image_package.Image(width: 1, height: 1)
      ..setPixelRgb(0, 0, 255, 128, 0);
    final file = File('${tempDirectory.path}/nsfw_sample.png');
    await file.writeAsBytes(image_package.encodePng(image), flush: true);

    final decoded = await imagePreprocessor.decodeFile(imagePath: file.path);
    const modelSpec = ModelSpec(
      key: 'nsfw',
      category: ClassificationCategory.nsfw,
      assetPath: 'assets/ml/models/nsfw.onnx',
      inputName: 'input',
      outputName: 'logits',
      inputWidth: 384,
      inputHeight: 384,
      normalizationMean: <double>[0.5, 0.5, 0.5],
      normalizationStd: <double>[0.5, 0.5, 0.5],
    );

    final preprocessed = imagePreprocessor.preprocessDecodedImage(
      decodedImage: decoded,
      modelSpec: modelSpec,
    );

    expect(preprocessed.shape, const <int>[1, 3, 384, 384]);
    expect(preprocessed.tensor[0], closeTo(1.0, 0.0001));
    expect(preprocessed.tensor[384 * 384], closeTo(0.0039, 0.001));
    expect(preprocessed.tensor[2 * 384 * 384], closeTo(-1.0, 0.0001));
  });

  test('decode throws for invalid image file', () async {
    final file = File('${tempDirectory.path}/invalid.bin');
    await file.writeAsString('not-an-image', flush: true);

    expect(
      () => imagePreprocessor.decodeFile(imagePath: file.path),
      throwsA(isA<FileSystemException>()),
    );
  });
}
