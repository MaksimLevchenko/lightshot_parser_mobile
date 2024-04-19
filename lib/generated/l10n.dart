// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Gallery`
  String get galleryAppBar {
    return Intl.message(
      'Gallery',
      name: 'galleryAppBar',
      desc: '',
      args: [],
    );
  }

  /// `Check out this image from Lightshot Parser`
  String get shareImage {
    return Intl.message(
      'Check out this image from Lightshot Parser',
      name: 'shareImage',
      desc: '',
      args: [],
    );
  }

  /// `Image saved to {newPath}`
  String imageSavedToPath(Object newPath) {
    return Intl.message(
      'Image saved to $newPath',
      name: 'imageSavedToPath',
      desc: '',
      args: [newPath],
    );
  }

  /// `Permission denied`
  String get permissionDenied {
    return Intl.message(
      'Permission denied',
      name: 'permissionDenied',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Deletion`
  String get confirmDeletion {
    return Intl.message(
      'Confirm Deletion',
      name: 'confirmDeletion',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete this image?`
  String get areYouSureYouWantToDeleteThisImage {
    return Intl.message(
      'Are you sure you want to delete this image?',
      name: 'areYouSureYouWantToDeleteThisImage',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Image deleted`
  String get imageDeleted {
    return Intl.message(
      'Image deleted',
      name: 'imageDeleted',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Photo Viewer`
  String get photoViewer {
    return Intl.message(
      'Photo Viewer',
      name: 'photoViewer',
      desc: '',
      args: [],
    );
  }

  /// `Download error. Try to change VPN`
  String get downloadErrorTryToChangeVpn {
    return Intl.message(
      'Download error. Try to change VPN',
      name: 'downloadErrorTryToChangeVpn',
      desc: '',
      args: [],
    );
  }

  /// `Unknown error: {e}, please contact to the dev`
  String unknownErrorEPleaseContactToTheDev(Object e) {
    return Intl.message(
      'Unknown error: $e, please contact to the dev',
      name: 'unknownErrorEPleaseContactToTheDev',
      desc: '',
      args: [e],
    );
  }

  /// `Error: {error}`
  String errorError(Object error) {
    return Intl.message(
      'Error: $error',
      name: 'errorError',
      desc: '',
      args: [error],
    );
  }

  /// `No download folder found`
  String get noDownloadFolderFound {
    return Intl.message(
      'No download folder found',
      name: 'noDownloadFolderFound',
      desc: '',
      args: [],
    );
  }

  /// `See all`
  String get seeAll {
    return Intl.message(
      'See all',
      name: 'seeAll',
      desc: '',
      args: [],
    );
  }

  /// `Downloaded {images} of {wantedNumOfImages}`
  String downloadedImagesOfWantednumofimages(
      Object images, Object wantedNumOfImages) {
    return Intl.message(
      'Downloaded $images of $wantedNumOfImages',
      name: 'downloadedImagesOfWantednumofimages',
      desc: '',
      args: [images, wantedNumOfImages],
    );
  }

  /// `Download`
  String get download {
    return Intl.message(
      'Download',
      name: 'download',
      desc: '',
      args: [],
    );
  }

  /// `Lightshot Parser`
  String get mainTitle {
    return Intl.message(
      'Lightshot Parser',
      name: 'mainTitle',
      desc: '',
      args: [],
    );
  }

  /// `No photos`
  String get noPhotos {
    return Intl.message(
      'No photos',
      name: 'noPhotos',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ru'),
      Locale.fromSubtags(languageCode: 'uk'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
