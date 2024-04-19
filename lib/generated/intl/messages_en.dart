// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(images, wantedNumOfImages) =>
      "${Intl.plural(images, zero: 'The images have not been downloaded yet', one: 'Downloaded 1 image out of ${wantedNumOfImages}', other: '${images} images out of ${wantedNumOfImages} have been downloaded')}";

  static String m1(error) => "Error: ${error}";

  static String m2(error) => "Error: ${error} \\nPlease try again";

  static String m3(newPath) => "Image saved to ${newPath}";

  static String m4(mask) => "Please enter a address with only a ${mask}";

  static String m5(e) => "Unknown error: ${e}. Please contact to the dev";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "areYouSureYouWantToDeleteThisImage":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to delete this image?"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "clearImages":
            MessageLookupByLibrary.simpleMessage("Delete all images"),
        "confirmDeletion":
            MessageLookupByLibrary.simpleMessage("Confirm deletion"),
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "download": MessageLookupByLibrary.simpleMessage("Begin downloading"),
        "downloadErrorTryToChangeVpn": MessageLookupByLibrary.simpleMessage(
            "Download error. Try to change VPN"),
        "downloadedImagesOfWantednumofimages": m0,
        "enterTheNumberOfImagesToDownload":
            MessageLookupByLibrary.simpleMessage(
                "Enter the number of images to download"),
        "enterTheStartingAddress":
            MessageLookupByLibrary.simpleMessage("Enter the starting address"),
        "errorError": m1,
        "errorErrorNpleaseTryAgain": m2,
        "galleryAppBar": MessageLookupByLibrary.simpleMessage("Gallery"),
        "imageDeleted": MessageLookupByLibrary.simpleMessage("Image deleted"),
        "imageSavedToPath": m3,
        "mainTitle": MessageLookupByLibrary.simpleMessage("Lightshot Parser"),
        "noDownloadFolderFound": MessageLookupByLibrary.simpleMessage(
            "The download folder was not found"),
        "noPhotos": MessageLookupByLibrary.simpleMessage("There are no images"),
        "numberOfImagesToDownload": MessageLookupByLibrary.simpleMessage(
            "The desired number of images"),
        "permissionDenied":
            MessageLookupByLibrary.simpleMessage("Permission denied"),
        "photoViewer": MessageLookupByLibrary.simpleMessage("Photo Viewer"),
        "pleaseEnterAAddressWithOnlyAMask": m4,
        "pleaseEnterAMaxLengthAddress": MessageLookupByLibrary.simpleMessage(
            "Please enter a max length address"),
        "pleaseEnterANumberGreaterThan0": MessageLookupByLibrary.simpleMessage(
            "Please enter a number greater than 0"),
        "pleaseEnterAValidNumber":
            MessageLookupByLibrary.simpleMessage("Please enter a number"),
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
        "seeAll": MessageLookupByLibrary.simpleMessage("See all"),
        "settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "settingsSaved": MessageLookupByLibrary.simpleMessage("Settings saved"),
        "shareImage": MessageLookupByLibrary.simpleMessage(
            "Check out this image from Lightshot Parser!"),
        "startingAddress":
            MessageLookupByLibrary.simpleMessage("Starting address"),
        "unknownErrorEPleaseContactToTheDev": m5,
        "useNewAddresses":
            MessageLookupByLibrary.simpleMessage("Use new addresses"),
        "useRandomAddresses":
            MessageLookupByLibrary.simpleMessage("Use random addresses")
      };
}
