Production ONNX models are expected in this directory with these exact names:

- `assets/ml/models/nsfw.onnx`
- `assets/ml/models/documents_float.onnx`
- `assets/ml/models/people_yolo.onnx`

The current production classification pipeline:

- runs NSFW classification first;
- runs document classification next when the NSFW threshold is not reached;
- runs YOLO-based people detection last;
- preloads models during app bootstrap;
- uses a worker isolate on supported native platforms and falls back to the main isolate if needed.

Notes:

- Native worker classification materializes model assets into a temporary directory before runtime initialization.
- If model filenames, input/output names, or tensor shapes change, update `lib/features/image_classification/data/models/classification_model_specs.dart`.
- Re-verify thresholds and output contracts after replacing any model.
