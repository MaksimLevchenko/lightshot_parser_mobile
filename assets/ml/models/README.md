TODO(onnx-assets): Place the production ONNX models in this directory using these exact names:

- `assets/ml/models/nsfw.onnx`
- `assets/ml/models/documents.onnx`
- `assets/ml/models/games.onnx`

TODO(model-config): Verify the real model input names, output names, tensor shapes, normalization rules, and thresholds before replacing the mock backend.

TODO(android-runtime): Add the Android-specific ONNX Runtime backend binding and wire it into `InferenceBackend`.

TODO(windows-runtime): Add the Windows-specific ONNX Runtime backend binding and wire it into `InferenceBackend`.
