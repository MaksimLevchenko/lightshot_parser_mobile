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
      "Downloaded ${images} of ${wantedNumOfImages}";

  static String m1(error) => "Error: ${error}";

  static String m2(newPath) => "Image saved to \$newPath";

  static String m3(e) => "Unknown error: ${e}, please contact to the dev";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "areYouSureYouWantToDeleteThisImage":
            MessageLookupByLibrary.simpleMessage(
                "Are you sure you want to delete this image?"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "confirmDeletion":
            MessageLookupByLibrary.simpleMessage("Confirm Deletion"),
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "download": MessageLookupByLibrary.simpleMessage("Download"),
        "downloadErrorTryToChangeVpn": MessageLookupByLibrary.simpleMessage(
            "Download error. Try to change VPN"),
        "downloadedImagesOfWantednumofimages": m0,
        "errorError": m1,
        "galleryAppBar": MessageLookupByLibrary.simpleMessage("Gallery"),
        "imageDeleted": MessageLookupByLibrary.simpleMessage("Image deleted"),
        "imageSavedToPath": m2,
        "mainTitle": MessageLookupByLibrary.simpleMessage("Lightshot Parser"),
        "noDownloadFolderFound":
            MessageLookupByLibrary.simpleMessage("No download folder found"),
        "noPhotos": MessageLookupByLibrary.simpleMessage("No photos"),
        "permissionDenied":
            MessageLookupByLibrary.simpleMessage("Permission denied"),
        "photoViewer": MessageLookupByLibrary.simpleMessage("Photo Viewer"),
        "seeAll": MessageLookupByLibrary.simpleMessage("See all"),
        "shareImage": MessageLookupByLibrary.simpleMessage(
            "Check out this image from Lightshot Parser"),
        "unknownErrorEPleaseContactToTheDev": m3
      };
}
