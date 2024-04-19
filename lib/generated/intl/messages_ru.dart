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
      "${Intl.plural(images, zero: 'Скачано 0 изображений из ${wantedNumOfImages}', one: 'Скачано 1 изображение из ${wantedNumOfImages}', few: 'Скачано ${images} изображения из ${wantedNumOfImages}', many: 'Скачано ${images} изображений из ${wantedNumOfImages}', other: 'Скачано ${images} изображений из ${wantedNumOfImages}')}";

  static String m1(error) => "Ошибка: ${error}";

  static String m2(error) => "Ошибка: ${error}\nПожалуйста, попробуйте еще раз";

  static String m3(newPath) => "Изображение сохранено в ${newPath}";

  static String m4(mask) =>
      "Пожалуйста, введите адрес, состоящий только из ${mask}";

  static String m5(e) =>
      "Неизвестная ошибка: ${e}. Пожалуйста, обратитесь к разработчику";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "areYouSureYouWantToDeleteThisImage":
            MessageLookupByLibrary.simpleMessage(
                "Вы уверены, что хотите удалить это изображение?"),
        "cancel": MessageLookupByLibrary.simpleMessage("Отменить"),
        "clearImages":
            MessageLookupByLibrary.simpleMessage("Удалить все изображения"),
        "confirmDeletion":
            MessageLookupByLibrary.simpleMessage("Подтвердите удаление"),
        "delete": MessageLookupByLibrary.simpleMessage("Удалить"),
        "download": MessageLookupByLibrary.simpleMessage("Начать скачивание"),
        "downloadErrorTryToChangeVpn": MessageLookupByLibrary.simpleMessage(
            "Ошибка при загрузке. Попробуйте сменить VPN"),
        "downloadedImagesOfWantednumofimages": m0,
        "enterTheNumberOfImagesToDownload":
            MessageLookupByLibrary.simpleMessage(
                "Введите количество изображений для загрузки"),
        "enterTheProxyAddress":
            MessageLookupByLibrary.simpleMessage("Enter the proxy address"),
        "enterTheProxyLogin":
            MessageLookupByLibrary.simpleMessage("Enter the proxy login"),
        "enterTheProxyPassword":
            MessageLookupByLibrary.simpleMessage("Enter the proxy password"),
        "enterTheProxyPort":
            MessageLookupByLibrary.simpleMessage("Enter the proxy port"),
        "enterTheStartingAddress":
            MessageLookupByLibrary.simpleMessage("Введите начальный адрес"),
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
            "Желаемое количество картинок"),
        "permissionDenied": MessageLookupByLibrary.simpleMessage(
            "Разрешение отклонено пользователем"),
        "photoViewer":
            MessageLookupByLibrary.simpleMessage("Просмотр изображений"),
        "pleaseEnterAAddressWithOnlyAMask": m4,
        "pleaseEnterAMaxLengthAddress": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, введите адрес максимальной длины"),
        "pleaseEnterANumberGreaterThan0": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, введите число больше 0"),
        "pleaseEnterAValidIpAddress": MessageLookupByLibrary.simpleMessage(
            "Please enter a valid IP address"),
        "pleaseEnterAValidNumber":
            MessageLookupByLibrary.simpleMessage("Пожалуйста, введите число"),
        "pleaseEnterAValidPort":
            MessageLookupByLibrary.simpleMessage("Please enter a valid port"),
        "pleaseEnterTheCorrectData": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, введите правильные данные"),
        "pleaseEnterTheNumberOfImagesToDownload":
            MessageLookupByLibrary.simpleMessage(
                "Пожалуйста, введите количество изображений для загрузки"),
        "pleaseEnterTheProxyAddress": MessageLookupByLibrary.simpleMessage(
            "Please enter the proxy address"),
        "pleaseEnterTheProxyLogin": MessageLookupByLibrary.simpleMessage(
            "Please enter the proxy login"),
        "pleaseEnterTheProxyPassword": MessageLookupByLibrary.simpleMessage(
            "Please enter the proxy password"),
        "pleaseEnterTheProxyPort":
            MessageLookupByLibrary.simpleMessage("Please enter the proxy port"),
        "pleaseEnterTheStartingAddress": MessageLookupByLibrary.simpleMessage(
            "Пожалуйста, введите начальный адрес"),
        "proxyAddress": MessageLookupByLibrary.simpleMessage("Proxy address"),
        "proxyLogin": MessageLookupByLibrary.simpleMessage("Proxy login"),
        "proxyPassword": MessageLookupByLibrary.simpleMessage("Proxy password"),
        "proxyPort": MessageLookupByLibrary.simpleMessage("Proxy port"),
        "recreateDatabase":
            MessageLookupByLibrary.simpleMessage("Пересоздать базу данных"),
        "save": MessageLookupByLibrary.simpleMessage("Сохранить"),
        "seeAll": MessageLookupByLibrary.simpleMessage("Смотреть все"),
        "settings": MessageLookupByLibrary.simpleMessage("Настройки"),
        "settingsSaved":
            MessageLookupByLibrary.simpleMessage("Настройки сохранены"),
        "shareImage": MessageLookupByLibrary.simpleMessage(
            "Посмотрите это изображение из Lightshot Parser!"),
        "startingAddress":
            MessageLookupByLibrary.simpleMessage("Начальный адрес"),
        "unknownErrorEPleaseContactToTheDev": m5,
        "useNewAddresses":
            MessageLookupByLibrary.simpleMessage("Использовать новые адреса"),
        "useProxy": MessageLookupByLibrary.simpleMessage("Use proxy"),
        "useProxyAuth": MessageLookupByLibrary.simpleMessage("Use proxy auth"),
        "useRandomAddresses": MessageLookupByLibrary.simpleMessage(
            "Использовать случайные адреса")
      };
}
