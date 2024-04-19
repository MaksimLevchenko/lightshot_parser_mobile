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
      "${Intl.plural(images, zero: 'Скачано 0 изображений из ${wantedNumOfImages}', one: 'Скачано 1 изображение из ${wantedNumOfImages}', few: 'Скачано ${images} изображения из ${wantedNumOfImages}', many: '', other: 'Скачано ${images} изображений из ${wantedNumOfImages}')}";

  static String m1(error) => "Ошибка: ${error}";

  static String m2(error) => "Error: ${error} \\nPlease try again";

  static String m3(newPath) => "Изображение сохранено в ${newPath}";

  static String m4(mask) => "Please enter a address with only a ${mask}";

  static String m5(e) =>
      "Неизвестная ошибка: ${e}. Пожалуйста, обратитесь к разработчику";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "areYouSureYouWantToDeleteThisImage":
            MessageLookupByLibrary.simpleMessage(
                "Вы уверены, что хотите удалить это изображение?"),
        "cancel": MessageLookupByLibrary.simpleMessage("Отменить"),
        "clearImages": MessageLookupByLibrary.simpleMessage("Clear images"),
        "confirmDeletion":
            MessageLookupByLibrary.simpleMessage("Подтвердите удаление"),
        "delete": MessageLookupByLibrary.simpleMessage("Удалить"),
        "download": MessageLookupByLibrary.simpleMessage("Начать скачивание"),
        "downloadErrorTryToChangeVpn": MessageLookupByLibrary.simpleMessage(
            "Ошибка при загрузке. Попробуйте сменить VPN"),
        "downloadedImagesOfWantednumofimages": m0,
        "enterTheNumberOfImagesToDownload":
            MessageLookupByLibrary.simpleMessage(
                "Enter the number of images to download"),
        "enterTheStartingAddress":
            MessageLookupByLibrary.simpleMessage("Enter the starting address"),
        "errorError": m1,
        "errorErrorNpleaseTryAgain": m2,
        "galleryAppBar": MessageLookupByLibrary.simpleMessage("Галерея"),
        "imageDeleted":
            MessageLookupByLibrary.simpleMessage("Изображение удалено"),
        "imageSavedToPath": m3,
        "mainTitle": MessageLookupByLibrary.simpleMessage("Lightshot Parser"),
        "noDownloadFolderFound": MessageLookupByLibrary.simpleMessage(
            "Папка для загрузки не найдена"),
        "noPhotos": MessageLookupByLibrary.simpleMessage("Изображений нет"),
        "numberOfImagesToDownload": MessageLookupByLibrary.simpleMessage(
            "Number of images to download"),
        "permissionDenied": MessageLookupByLibrary.simpleMessage(
            "Разрешение отклонено пользователем"),
        "photoViewer":
            MessageLookupByLibrary.simpleMessage("Просмотр изображений"),
        "pleaseEnterAAddressWithOnlyAMask": m4,
        "pleaseEnterAMaxLengthAddress": MessageLookupByLibrary.simpleMessage(
            "Please enter a max length address"),
        "pleaseEnterANumberGreaterThan0": MessageLookupByLibrary.simpleMessage(
            "Please enter a number greater than 0"),
        "pleaseEnterAValidNumber":
            MessageLookupByLibrary.simpleMessage("Please enter a valid number"),
        "pleaseEnterTheCorrectData": MessageLookupByLibrary.simpleMessage(
            "Please enter the correct data"),
        "pleaseEnterTheNumberOfImagesToDownload":
            MessageLookupByLibrary.simpleMessage(
                "Please enter the number of images to download"),
        "pleaseEnterTheStartingAddress": MessageLookupByLibrary.simpleMessage(
            "Please enter the starting address"),
        "recreateDatabase":
            MessageLookupByLibrary.simpleMessage("Recreate database"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "seeAll": MessageLookupByLibrary.simpleMessage("Смотреть все"),
        "settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "settingsSaved": MessageLookupByLibrary.simpleMessage("Settings saved"),
        "shareImage": MessageLookupByLibrary.simpleMessage(
            "Посмотрите это изображение из Lightshot Parser!"),
        "startingAddress":
            MessageLookupByLibrary.simpleMessage("Starting address"),
        "unknownErrorEPleaseContactToTheDev": m5,
        "useNewAddresses":
            MessageLookupByLibrary.simpleMessage("Use new addresses"),
        "useRandomAddresses":
            MessageLookupByLibrary.simpleMessage("Use random addresses")
      };
}
