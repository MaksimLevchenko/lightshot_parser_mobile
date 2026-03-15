import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image_package;

import 'package:lightshot_parser_mobile/features/image_classification/data/models/model_spec.dart';
import 'package:lightshot_parser_mobile/features/image_classification/data/models/preprocessed_image_data.dart';

class DecodedImageData {
  const DecodedImageData({
    required this.imagePath,
    required this.image,
    required this.signature,
  });

  final String imagePath;
  final image_package.Image image;
  final int signature;
}

class ImagePreprocessor {
  Future<DecodedImageData> decodeFile({
    required String imagePath,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    final decodedImage = image_package.decodeImage(bytes);
    if (decodedImage == null) {
      throw const FileSystemException(
        'Unable to decode image for classification',
      );
    }

    return DecodedImageData(
      imagePath: imagePath,
      image: decodedImage,
      signature: _buildSignature(bytes),
    );
  }

  PreprocessedImageData preprocessDecodedImage({
    required DecodedImageData decodedImage,
    required ModelSpec modelSpec,
  }) {
    final resizedImage = image_package.copyResize(
      decodedImage.image,
      width: modelSpec.inputWidth,
      height: modelSpec.inputHeight,
      interpolation: image_package.Interpolation.average,
    );

    final tensorLength = modelSpec.inputWidth * modelSpec.inputHeight * 3;
    final tensor = Float32List(tensorLength);
    var tensorIndex = 0;

    for (var channel = 0; channel < 3; channel += 1) {
      final mean = modelSpec.normalizationMean[channel];
      final std = modelSpec.normalizationStd[channel];
      for (var y = 0; y < modelSpec.inputHeight; y += 1) {
        for (var x = 0; x < modelSpec.inputWidth; x += 1) {
          final pixel = resizedImage.getPixel(x, y);
          final channelValue = switch (channel) {
            0 => pixel.r,
            1 => pixel.g,
            _ => pixel.b,
          };
          final normalizedValue = channelValue / 255;
          tensor[tensorIndex] = (normalizedValue - mean) / std;
          tensorIndex += 1;
        }
      }
    }

    return PreprocessedImageData(
      tensor: tensor,
      width: modelSpec.inputWidth,
      height: modelSpec.inputHeight,
      channels: 3,
      signature: decodedImage.signature,
      shape: <int>[1, 3, modelSpec.inputHeight, modelSpec.inputWidth],
    );
  }

  int _buildSignature(Uint8List bytes) {
    var hash = 17;
    for (final byte in bytes) {
      hash = (hash * 31 + byte) & 0x7fffffff;
    }
    return hash;
  }
}
