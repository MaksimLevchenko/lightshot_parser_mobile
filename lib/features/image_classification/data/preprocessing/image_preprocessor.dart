import 'dart:math' as math;
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
    return switch (modelSpec.taskType) {
      ModelTaskType.binaryClassifier => _preprocessClassifierImage(
          decodedImage: decodedImage,
          modelSpec: modelSpec,
        ),
      ModelTaskType.personDetector => _preprocessPersonDetectorImage(
          decodedImage: decodedImage,
        ),
      ModelTaskType.personDetectorYolo => _preprocessYoloPersonDetectorImage(
          decodedImage: decodedImage,
          modelSpec: modelSpec,
        ),
    };
  }

  PreprocessedImageData _preprocessClassifierImage({
    required DecodedImageData decodedImage,
    required ModelSpec modelSpec,
  }) {
    final inputWidth = modelSpec.inputWidth!;
    final inputHeight = modelSpec.inputHeight!;
    final resizedImage = image_package.copyResize(
      decodedImage.image,
      width: inputWidth,
      height: inputHeight,
      interpolation: image_package.Interpolation.average,
    );

    final tensorLength = inputWidth * inputHeight * 3;
    final tensor = Float32List(tensorLength);
    var tensorIndex = 0;

    for (var channel = 0; channel < 3; channel += 1) {
      final mean = modelSpec.normalizationMean[channel];
      final std = modelSpec.normalizationStd[channel];
      for (var y = 0; y < inputHeight; y += 1) {
        for (var x = 0; x < inputWidth; x += 1) {
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
      width: inputWidth,
      height: inputHeight,
      channels: 3,
      signature: decodedImage.signature,
      dataType: TensorDataType.float32,
      layout: TensorLayout.nchw,
      shape: <int>[1, 3, inputHeight, inputWidth],
    );
  }

  PreprocessedImageData _preprocessPersonDetectorImage({
    required DecodedImageData decodedImage,
  }) {
    final image = decodedImage.image;
    final tensor = Uint8List(image.width * image.height * 3);
    var tensorIndex = 0;

    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < image.width; x += 1) {
        final pixel = image.getPixel(x, y);
        tensor[tensorIndex] = pixel.r.toInt();
        tensor[tensorIndex + 1] = pixel.g.toInt();
        tensor[tensorIndex + 2] = pixel.b.toInt();
        tensorIndex += 3;
      }
    }

    return PreprocessedImageData(
      tensor: tensor,
      width: image.width,
      height: image.height,
      channels: 3,
      signature: decodedImage.signature,
      dataType: TensorDataType.uint8,
      layout: TensorLayout.nhwc,
      shape: <int>[1, image.height, image.width, 3],
    );
  }

  PreprocessedImageData _preprocessYoloPersonDetectorImage({
    required DecodedImageData decodedImage,
    required ModelSpec modelSpec,
  }) {
    final inputWidth = modelSpec.inputWidth!;
    final inputHeight = modelSpec.inputHeight!;
    final letterboxedImage = _letterboxImage(
      image: decodedImage.image,
      targetWidth: inputWidth,
      targetHeight: inputHeight,
    );

    final tensorLength = inputWidth * inputHeight * 3;
    final tensor = Float32List(tensorLength);
    var tensorIndex = 0;

    for (var channel = 0; channel < 3; channel += 1) {
      for (var y = 0; y < inputHeight; y += 1) {
        for (var x = 0; x < inputWidth; x += 1) {
          final pixel = letterboxedImage.getPixel(x, y);
          final channelValue = switch (channel) {
            0 => pixel.r,
            1 => pixel.g,
            _ => pixel.b,
          };
          tensor[tensorIndex] = channelValue / 255.0;
          tensorIndex += 1;
        }
      }
    }

    return PreprocessedImageData(
      tensor: tensor,
      width: inputWidth,
      height: inputHeight,
      channels: 3,
      signature: decodedImage.signature,
      dataType: TensorDataType.float32,
      layout: TensorLayout.nchw,
      shape: <int>[1, 3, inputHeight, inputWidth],
    );
  }

  image_package.Image _letterboxImage({
    required image_package.Image image,
    required int targetWidth,
    required int targetHeight,
  }) {
    final scale = math.min(
      targetWidth / image.width,
      targetHeight / image.height,
    );
    final resizedWidth =
        math.max(1, math.min(targetWidth, (image.width * scale).round()));
    final resizedHeight =
        math.max(1, math.min(targetHeight, (image.height * scale).round()));
    final resizedImage = image_package.copyResize(
      image,
      width: resizedWidth,
      height: resizedHeight,
      interpolation: image_package.Interpolation.average,
    );

    final output = image_package.Image(
      width: targetWidth,
      height: targetHeight,
      numChannels: 3,
    );
    image_package.fill(output, color: image_package.ColorRgb8(0, 0, 0));

    final dx = ((targetWidth - resizedWidth) / 2).floor();
    final dy = ((targetHeight - resizedHeight) / 2).floor();
    image_package.compositeImage(
      output,
      resizedImage,
      dstX: dx,
      dstY: dy,
    );
    return output;
  }

  int _buildSignature(Uint8List bytes) {
    var hash = 17;
    for (final byte in bytes) {
      hash = (hash * 31 + byte) & 0x7fffffff;
    }
    return hash;
  }
}
