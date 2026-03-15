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
      key: 'games',
      category: ClassificationCategory.games,
      assetPath: 'assets/ml/models/games.onnx',
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
