import 'package:flutter/widgets.dart';
import 'package:lightshot_parser_mobile/features/download/domain/models/download_source.dart';

class DownloadSourceTexts {
  static String sourceLabel(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return '\u0418\u0441\u0442\u043e\u0447\u043d\u0438\u043a';
      case 'uk':
        return '\u0414\u0436\u0435\u0440\u0435\u043b\u043e';
      default:
        return 'Source';
    }
  }

  static String currentSourceLabel(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return '\u0422\u0435\u043a\u0443\u0449\u0438\u0439 \u0438\u0441\u0442\u043e\u0447\u043d\u0438\u043a';
      case 'uk':
        return '\u041f\u043e\u0442\u043e\u0447\u043d\u0435 \u0434\u0436\u0435\u0440\u0435\u043b\u043e';
      default:
        return 'Current source';
    }
  }

  static String lightshotSettings(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return 'Lightshot \u043d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438';
      case 'uk':
        return 'Lightshot \u043d\u0430\u043b\u0430\u0448\u0442\u0443\u0432\u0430\u043d\u043d\u044f';
      default:
        return 'Lightshot settings';
    }
  }

  static String imgurSettings(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return 'Imgur \u043d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438';
      case 'uk':
        return 'Imgur \u043d\u0430\u043b\u0430\u0448\u0442\u0443\u0432\u0430\u043d\u043d\u044f';
      default:
        return 'Imgur settings';
    }
  }

  static String startingId(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return '\u0421\u0442\u0430\u0440\u0442\u043e\u0432\u044b\u0439 ID';
      case 'uk':
        return '\u0421\u0442\u0430\u0440\u0442\u043e\u0432\u0438\u0439 ID';
      default:
        return 'Starting ID';
    }
  }

  static String enterTheStartingId(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u0441\u0442\u0430\u0440\u0442\u043e\u0432\u044b\u0439 ID';
      case 'uk':
        return '\u0412\u0432\u0435\u0434\u0456\u0442\u044c \u0441\u0442\u0430\u0440\u0442\u043e\u0432\u0438\u0439 ID';
      default:
        return 'Enter the starting ID';
    }
  }

  static String imgurIdLength(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'ru':
        return '\u0414\u043b\u0438\u043d\u0430 ID Imgur';
      case 'uk':
        return '\u0414\u043e\u0432\u0436\u0438\u043d\u0430 ID Imgur';
      default:
        return 'Imgur ID length';
    }
  }

  static String sourceName(BuildContext context, DownloadSource source) {
    switch (source) {
      case DownloadSource.lightshot:
        return 'Lightshot';
      case DownloadSource.imgur:
        return 'Imgur';
    }
  }
}
