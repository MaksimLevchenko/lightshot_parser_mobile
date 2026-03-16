# Lightshot Parser

![LightshotParser icon](https://github.com/MaksimLevchenko/lightshot_parser_mobile/blob/main/assets/icons/logo_with_background.png)

Lightshot Parser is a Flutter application for collecting images from public screenshot hosts and managing them in a local gallery. The current app supports both `prnt.sc` (Lightshot) and `imgur.com`, stores downloaded files in a persistent local index, and can classify images on-device with ONNX models.

## What the app does

- downloads images from Lightshot and Imgur;
- skips items that were already processed earlier;
- keeps a local gallery backed by `sqflite`;
- classifies downloaded images into `nsfw`, `documents`, `people`, `not classified`, or `unrecognized`;
- resumes pending classifications after app restart;
- lets you reclassify the whole gallery or only items downloaded while ML was disabled;
- supports HTTP proxy configuration, including proxy authentication;
- shows progress and completion notifications;
- lets you open, share, delete, and save images from the gallery;
- supports English, Russian, and Ukrainian localizations.

## Current stack

- Flutter with `flutter_bloc`
- `dio` + `http` for networking
- `sqflite` / `sqflite_common_ffi` for the local database
- `awesome_notifications` for local notifications
- `flutter_onnxruntime` for on-device inference

## Image classification

The classification pipeline runs locally and uses three ONNX models from `assets/ml/models/`:

- `nsfw.onnx`
- `documents_float.onnx`
- `people_yolo.onnx`

The app warms up the inference backend during bootstrap. On native platforms it tries to run classification in a worker isolate and falls back to the main isolate if worker initialization fails.

## Running locally

1. Install Flutter for your platform.
2. Run `flutter pub get`.
3. Start the app with `flutter run`.

The repository already contains Flutter platform folders for Android, iOS, Windows, Linux, macOS, and Web. In practice, the current feature set is primarily oriented around native platforms because file storage, notifications, and ONNX runtime are part of the main flow.

## Build notes

- Assets from `assets/icons/` and `assets/ml/models/` must be present.
- The app stores gallery metadata in a local SQLite database and migrates legacy `db.txt` tracking data on first launch.
- Notification support depends on platform-specific capabilities and permissions.

## Project layout

- `lib/features/download/` - download sources, repositories, and download flow
- `lib/features/gallery/` - local gallery persistence and presentation
- `lib/features/image_classification/` - preprocessing, inference backends, and classification service
- `lib/features/photo_viewer/` - viewing, sharing, deleting, and exporting images
- `lib/features/settings/` - source selection, proxy setup, ML toggle, and maintenance actions
- `lib/services/notification_service.dart` - local notification integration

## Verification

- `flutter analyze` - passes
- `flutter test` - not run because the repository currently has no `test/` directory

## Installation

Download a packaged build from the [Releases page](https://github.com/MaksimLevchenko/lightshot_parser_mobile/releases) when one is available, or build the app locally with Flutter.

## Contacts

Contact [MaksimLevchenko](https://t.me/H2S_Rn) on Telegram.

## Disclaimer

Use this app responsibly and comply with the terms of service, copyright rules, and local laws that apply to the content you access or download. The authors and maintainers are not responsible for misuse.
