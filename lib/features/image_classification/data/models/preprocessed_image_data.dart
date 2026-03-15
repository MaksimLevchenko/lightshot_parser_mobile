import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class PreprocessedImageData extends Equatable {
  const PreprocessedImageData({
    required this.tensor,
    required this.width,
    required this.height,
    required this.channels,
    required this.signature,
  });

  final Float32List tensor;
  final int width;
  final int height;
  final int channels;
  final int signature;

  @override
  List<Object?> get props => <Object?>[
        tensor.length,
        width,
        height,
        channels,
        signature,
      ];
}
