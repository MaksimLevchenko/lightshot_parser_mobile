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

  /// `Delete all images`
  String get clearImages {
    return Intl.message(
      'Delete all images',
      name: 'clearImages',
      desc: '',
      args: [],
    );
  }

  /// `Confirm deletion`
  String get confirmDeletion {
    return Intl.message(
      'Confirm deletion',
      name: 'confirmDeletion',
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

  /// `Begin downloading`
  String get download {
    return Intl.message(
      'Begin downloading',
      name: 'download',
      desc: '',
      args: [],
    );
  }

  /// `{images, plural, zero{The images have not been downloaded yet} one{Downloaded 1 image out of {wantedNumOfImages}} other{{images} images out of {wantedNumOfImages} have been downloaded}}`
  String downloadedImagesOfWantednumofimages(
      num images, Object wantedNumOfImages) {
    return Intl.plural(
      images,
      zero: 'The images have not been downloaded yet',
      one: 'Downloaded 1 image out of $wantedNumOfImages',
      other: '$images images out of $wantedNumOfImages have been downloaded',
      name: 'downloadedImagesOfWantednumofimages',
      desc: '',
      args: [images, wantedNumOfImages],
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

  /// `Enter the number of images to download`
  String get enterTheNumberOfImagesToDownload {
    return Intl.message(
      'Enter the number of images to download',
      name: 'enterTheNumberOfImagesToDownload',
      desc: '',
      args: [],
    );
  }

  /// `Enter the starting address`
  String get enterTheStartingAddress {
    return Intl.message(
      'Enter the starting address',
      name: 'enterTheStartingAddress',
      desc: '',
      args: [],
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

  /// `Error: {error} \nPlease try again`
  String errorErrorNpleaseTryAgain(Object error) {
    return Intl.message(
      'Error: $error \nPlease try again',
      name: 'errorErrorNpleaseTryAgain',
      desc: '',
      args: [error],
    );
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

  /// `Image deleted`
  String get imageDeleted {
    return Intl.message(
      'Image deleted',
      name: 'imageDeleted',
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

  /// `Lightshot Parser`
  String get mainTitle {
    return Intl.message(
      'Lightshot Parser',
      name: 'mainTitle',
      desc: '',
      args: [],
    );
  }

  /// `The download folder was not found`
  String get noDownloadFolderFound {
    return Intl.message(
      'The download folder was not found',
      name: 'noDownloadFolderFound',
      desc: '',
      args: [],
    );
  }

  /// `There are no images`
  String get noPhotos {
    return Intl.message(
      'There are no images',
      name: 'noPhotos',
      desc: '',
      args: [],
    );
  }

  /// `The desired number of images`
  String get numberOfImagesToDownload {
    return Intl.message(
      'The desired number of images',
      name: 'numberOfImagesToDownload',
      desc: '',
      args: [],
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

  /// `Photo Viewer`
  String get photoViewer {
    return Intl.message(
      'Photo Viewer',
      name: 'photoViewer',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a address with only a {mask}`
  String pleaseEnterAAddressWithOnlyAMask(Object mask) {
    return Intl.message(
      'Please enter a address with only a $mask',
      name: 'pleaseEnterAAddressWithOnlyAMask',
      desc: '',
      args: [mask],
    );
  }

  /// `Please enter a max length address`
  String get pleaseEnterAMaxLengthAddress {
    return Intl.message(
      'Please enter a max length address',
      name: 'pleaseEnterAMaxLengthAddress',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a number greater than 0`
  String get pleaseEnterANumberGreaterThan0 {
    return Intl.message(
      'Please enter a number greater than 0',
      name: 'pleaseEnterANumberGreaterThan0',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a number`
  String get pleaseEnterAValidNumber {
    return Intl.message(
      'Please enter a number',
      name: 'pleaseEnterAValidNumber',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the correct data`
  String get pleaseEnterTheCorrectData {
    return Intl.message(
      'Please enter the correct data',
      name: 'pleaseEnterTheCorrectData',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the number of images to download`
  String get pleaseEnterTheNumberOfImagesToDownload {
    return Intl.message(
      'Please enter the number of images to download',
      name: 'pleaseEnterTheNumberOfImagesToDownload',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the starting address`
  String get pleaseEnterTheStartingAddress {
    return Intl.message(
      'Please enter the starting address',
      name: 'pleaseEnterTheStartingAddress',
      desc: '',
      args: [],
    );
  }

  /// `Recreate database`
  String get recreateDatabase {
    return Intl.message(
      'Recreate database',
      name: 'recreateDatabase',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
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

  /// `Settings`
  String get settings {
    return Intl.message(
      'Settings',
      name: 'settings',
      desc: '',
      args: [],
    );
  }

  /// `Settings saved`
  String get settingsSaved {
    return Intl.message(
      'Settings saved',
      name: 'settingsSaved',
      desc: '',
      args: [],
    );
  }

  /// `Check out this image from Lightshot Parser!`
  String get shareImage {
    return Intl.message(
      'Check out this image from Lightshot Parser!',
      name: 'shareImage',
      desc: '',
      args: [],
    );
  }

  /// `Starting address`
  String get startingAddress {
    return Intl.message(
      'Starting address',
      name: 'startingAddress',
      desc: '',
      args: [],
    );
  }

  /// `Unknown error: {e}. Please contact to the dev`
  String unknownErrorEPleaseContactToTheDev(Object e) {
    return Intl.message(
      'Unknown error: $e. Please contact to the dev',
      name: 'unknownErrorEPleaseContactToTheDev',
      desc: '',
      args: [e],
    );
  }

  /// `Use new addresses`
  String get useNewAddresses {
    return Intl.message(
      'Use new addresses',
      name: 'useNewAddresses',
      desc: '',
      args: [],
    );
  }

  /// `Use random addresses`
  String get useRandomAddresses {
    return Intl.message(
      'Use random addresses',
      name: 'useRandomAddresses',
      desc: '',
      args: [],
    );
  }

  /// `Use proxy`
  String get useProxy {
    return Intl.message(
      'Use proxy',
      name: 'useProxy',
      desc: '',
      args: [],
    );
  }

  /// `Use proxy auth`
  String get useProxyAuth {
    return Intl.message(
      'Use proxy auth',
      name: 'useProxyAuth',
      desc: '',
      args: [],
    );
  }

  /// `Proxy address`
  String get proxyAddress {
    return Intl.message(
      'Proxy address',
      name: 'proxyAddress',
      desc: '',
      args: [],
    );
  }

  /// `Enter the proxy address`
  String get enterTheProxyAddress {
    return Intl.message(
      'Enter the proxy address',
      name: 'enterTheProxyAddress',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the proxy address`
  String get pleaseEnterTheProxyAddress {
    return Intl.message(
      'Please enter the proxy address',
      name: 'pleaseEnterTheProxyAddress',
      desc: '',
      args: [],
    );
  }

  /// `Proxy port`
  String get proxyPort {
    return Intl.message(
      'Proxy port',
      name: 'proxyPort',
      desc: '',
      args: [],
    );
  }

  /// `Enter the proxy port`
  String get enterTheProxyPort {
    return Intl.message(
      'Enter the proxy port',
      name: 'enterTheProxyPort',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the proxy port`
  String get pleaseEnterTheProxyPort {
    return Intl.message(
      'Please enter the proxy port',
      name: 'pleaseEnterTheProxyPort',
      desc: '',
      args: [],
    );
  }

  /// `Proxy login`
  String get proxyLogin {
    return Intl.message(
      'Proxy login',
      name: 'proxyLogin',
      desc: '',
      args: [],
    );
  }

  /// `Enter the proxy login`
  String get enterTheProxyLogin {
    return Intl.message(
      'Enter the proxy login',
      name: 'enterTheProxyLogin',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the proxy login`
  String get pleaseEnterTheProxyLogin {
    return Intl.message(
      'Please enter the proxy login',
      name: 'pleaseEnterTheProxyLogin',
      desc: '',
      args: [],
    );
  }

  /// `Proxy password`
  String get proxyPassword {
    return Intl.message(
      'Proxy password',
      name: 'proxyPassword',
      desc: '',
      args: [],
    );
  }

  /// `Enter the proxy password`
  String get enterTheProxyPassword {
    return Intl.message(
      'Enter the proxy password',
      name: 'enterTheProxyPassword',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the proxy password`
  String get pleaseEnterTheProxyPassword {
    return Intl.message(
      'Please enter the proxy password',
      name: 'pleaseEnterTheProxyPassword',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid IP address`
  String get pleaseEnterAValidIpAddress {
    return Intl.message(
      'Please enter a valid IP address',
      name: 'pleaseEnterAValidIpAddress',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid port`
  String get pleaseEnterAValidPort {
    return Intl.message(
      'Please enter a valid port',
      name: 'pleaseEnterAValidPort',
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
