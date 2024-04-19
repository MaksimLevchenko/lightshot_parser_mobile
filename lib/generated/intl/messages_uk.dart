// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a uk locale. All the
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
  String get localeName => 'uk';

  static String m0(images, wantedNumOfImages) =>
      "${Intl.plural(images, zero: 'Завантажено 0 зображень з ${wantedNumOfImages}', one: 'Завантажено 1 зображення з ${wantedNumOfImages}', few: 'Завантажено ${images} зображень з ${wantedNumOfImages}', many: '', other: 'Завантажено ${images} зображень з ${wantedNumOfImages}')}";

  static String m1(error) => "Помилка: ${error}";

  static String m2(error) => "Помилка: ${error}\\nБудь ласка, спробуйте ще раз";

  static String m3(newPath) => "Зображення збережено в ${newPath}";

  static String m4(mask) => "Будь ласка, введіть адресу лише з a ${mask}";

  static String m5(e) =>
      "Невідома помилка: ${e}. Будь ласка, зверніться до розробника";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "areYouSureYouWantToDeleteThisImage":
            MessageLookupByLibrary.simpleMessage(
                "Ви впевнені, що хочете видалити це зображення?"),
        "cancel": MessageLookupByLibrary.simpleMessage("Скасувати"),
        "clearImages":
            MessageLookupByLibrary.simpleMessage("Видалити всі зображення"),
        "confirmDeletion":
            MessageLookupByLibrary.simpleMessage("Підтвердьте видалення"),
        "delete": MessageLookupByLibrary.simpleMessage("Видалити"),
        "download": MessageLookupByLibrary.simpleMessage("Почати скачування"),
        "downloadErrorTryToChangeVpn": MessageLookupByLibrary.simpleMessage(
            "Помилка під час завантаження. Спробуйте змінити VPN"),
        "downloadedImagesOfWantednumofimages": m0,
        "enterTheNumberOfImagesToDownload":
            MessageLookupByLibrary.simpleMessage(
                "Введіть кількість зображень для завантаження"),
        "enterTheStartingAddress":
            MessageLookupByLibrary.simpleMessage("Введіть початкову адресу"),
        "errorError": m1,
        "errorErrorNpleaseTryAgain": m2,
        "galleryAppBar": MessageLookupByLibrary.simpleMessage("Галерея"),
        "imageDeleted":
            MessageLookupByLibrary.simpleMessage("Зображення видалено"),
        "imageSavedToPath": m3,
        "mainTitle": MessageLookupByLibrary.simpleMessage("Lightshot Parser"),
        "noDownloadFolderFound": MessageLookupByLibrary.simpleMessage(
            "Папку для завантаження не знайдено"),
        "noPhotos": MessageLookupByLibrary.simpleMessage("Зображення немає"),
        "numberOfImagesToDownload":
            MessageLookupByLibrary.simpleMessage("Бажана кількість зображень"),
        "permissionDenied": MessageLookupByLibrary.simpleMessage(
            "Дозвіл відхилено користувачем"),
        "photoViewer":
            MessageLookupByLibrary.simpleMessage("Перегляд зображень"),
        "pleaseEnterAAddressWithOnlyAMask": m4,
        "pleaseEnterAMaxLengthAddress": MessageLookupByLibrary.simpleMessage(
            "Будь ласка, введіть адресу максимальної довжини"),
        "pleaseEnterANumberGreaterThan0": MessageLookupByLibrary.simpleMessage(
            "Будь ласка, введіть число більше 0"),
        "pleaseEnterAValidNumber":
            MessageLookupByLibrary.simpleMessage("Будь ласка, введіть число"),
        "pleaseEnterTheCorrectData": MessageLookupByLibrary.simpleMessage(
            "Будь ласка, введіть правильні дані"),
        "pleaseEnterTheNumberOfImagesToDownload":
            MessageLookupByLibrary.simpleMessage(
                "Будь ласка, введіть кількість зображень для завантаження"),
        "pleaseEnterTheStartingAddress": MessageLookupByLibrary.simpleMessage(
            "Будь ласка, введіть початкову адресу"),
        "recreateDatabase":
            MessageLookupByLibrary.simpleMessage("Перебудувати базу даних"),
        "save": MessageLookupByLibrary.simpleMessage("Зберегти"),
        "seeAll": MessageLookupByLibrary.simpleMessage("Дивитись все"),
        "settings": MessageLookupByLibrary.simpleMessage("Налаштування"),
        "settingsSaved":
            MessageLookupByLibrary.simpleMessage("Налаштування збережені"),
        "shareImage": MessageLookupByLibrary.simpleMessage(
            "Подивіться це зображення з Lightshot Parser!"),
        "startingAddress":
            MessageLookupByLibrary.simpleMessage("Початкова адреса"),
        "unknownErrorEPleaseContactToTheDev": m5,
        "useNewAddresses":
            MessageLookupByLibrary.simpleMessage("Використовувати нові адреси"),
        "useRandomAddresses": MessageLookupByLibrary.simpleMessage(
            "Використовуйте випадкові адреси")
      };
}
