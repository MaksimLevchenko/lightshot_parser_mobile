import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum TensorDataType {
  float32,
  uint8,
}

enum TensorLayout {
  nchw,
  nhwc,
}

class PreprocessedImageData extends Equatable {
  PreprocessedImageData({
    required this.tensor,
    required this.width,
    required this.height,
    required this.channels,
    required this.signature,
    required this.dataType,
    required this.layout,
    List<int>? shape,
  }) : shape = List<int>.unmodifiable(
          shape ?? <int>[1, channels, height, width],
        );

  final TypedData tensor;
  final int width;
  final int height;
  final int channels;
  final int signature;
  final TensorDataType dataType;
  final TensorLayout layout;
  final List<int> shape;

  int get tensorElementCount => switch (dataType) {
        TensorDataType.float32 => tensor.lengthInBytes ~/ Float32List.bytesPerElement,
        TensorDataType.uint8 => tensor.lengthInBytes ~/ Uint8List.bytesPerElement,
      };

  @override
  List<Object?> get props => <Object?>[
        tensor.runtimeType,
        tensorElementCount,
        width,
        height,
        channels,
        signature,
        dataType,
        layout,
        shape,
      ];
}
