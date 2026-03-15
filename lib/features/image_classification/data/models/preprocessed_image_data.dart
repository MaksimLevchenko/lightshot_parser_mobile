import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class PreprocessedImageData extends Equatable {
  PreprocessedImageData({
    required this.tensor,
    required this.width,
    required this.height,
    required this.channels,
    required this.signature,
    List<int>? shape,
  }) : shape = List<int>.unmodifiable(
          shape ?? <int>[1, channels, height, width],
        );

  final Float32List tensor;
  final int width;
  final int height;
  final int channels;
  final int signature;
  final List<int> shape;

  @override
  List<Object?> get props => <Object?>[
        tensor.length,
        width,
        height,
        channels,
        signature,
        shape,
      ];
}
