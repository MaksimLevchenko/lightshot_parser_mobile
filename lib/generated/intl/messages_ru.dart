// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ru locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ru';

  static String m0(images, wantedNumOfImages) =>
      "${Intl.plural(images, zero: 'Скачано 0 изображений из ${wantedNumOfImages}', one: 'Скачано 1 изображение из ${wantedNumOfImages}', few: 'Скачано ${images} изображения из ${wantedNumOfImages}', many: '', other: 'Скачано ${images} изображений из ${wantedNumOfImages}')}}";

  static String m1(error) => "Ошибка: ${error}";

  static String m2(newPath) => "Изображение сохранено в ${newPath}";

  static String m3(e) =>
      "Неизвестная ошибка: ${e}. Пожалуйста, обратитесь к разработчику";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "areYouSureYouWantToDeleteThisImage":
            MessageLookupByLibrary.simpleMessage(
                "Вы уверены, что хотите удалить это изображение?"),
        "cancel": MessageLookupByLibrary.simpleMessage("Отменить"),
        "confirmDeletion":
            MessageLookupByLibrary.simpleMessage("Подтвердите удаление"),
        "delete": MessageLookupByLibrary.simpleMessage("Удалить"),
        "download": MessageLookupByLibrary.simpleMessage("Начать скачивание"),
        "downloadErrorTryToChangeVpn": MessageLookupByLibrary.simpleMessage(
            "Ошибка при загрузке. Попробуйте сменить VPN"),
        "downloadedImagesOfWantednumofimages": m0,
        "errorError": m1,
        "galleryAppBar": MessageLookupByLibrary.simpleMessage("Галерея"),
        "imageDeleted":
            MessageLookupByLibrary.simpleMessage("Изображение удалено"),
        "imageSavedToPath": m2,
        "mainTitle": MessageLookupByLibrary.simpleMessage("Lightshot Parser"),
        "noDownloadFolderFound": MessageLookupByLibrary.simpleMessage(
            "Папка для загрузки не найдена"),
        "noPhotos": MessageLookupByLibrary.simpleMessage("Изображений нет"),
        "permissionDenied": MessageLookupByLibrary.simpleMessage(
            "Разрешение отклонено пользователем"),
        "photoViewer":
            MessageLookupByLibrary.simpleMessage("Просмотр изображений"),
        "seeAll": MessageLookupByLibrary.simpleMessage("Смотреть все"),
        "shareImage": MessageLookupByLibrary.simpleMessage(
            "Посмотрите это изображение из Lightshot Parser!"),
        "unknownErrorEPleaseContactToTheDev": m3
      };
}
