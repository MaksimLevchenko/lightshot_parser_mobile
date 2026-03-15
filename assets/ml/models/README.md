Production ONNX models are expected in this directory using these exact names:

- `assets/ml/models/nsfw.onnx`
- `assets/ml/models/documents.onnx`

The current production pipeline uses `flutter_onnxruntime` with:

- `nsfw.onnx`
- `documents.onnx`

TODO(model-config): Recalibrate thresholds and re-verify output contracts if the exported models change.

TODO(android-runtime): Validate release configuration on Android with the final shipping build variant.

TODO(windows-runtime): Validate release configuration on Windows with the final shipping build variant.
