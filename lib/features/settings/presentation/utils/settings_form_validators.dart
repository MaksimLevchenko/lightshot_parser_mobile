import 'package:flutter/widgets.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';

class SettingsFormValidators {
  static String? validateWantedNumOfImages(
    BuildContext context,
    String? value,
  ) {
    final normalizedValue = value ?? '';
    if (normalizedValue.isEmpty) {
      return S.of(context).pleaseEnterTheNumberOfImagesToDownload;
    }
    final parsedValue = int.tryParse(normalizedValue);
    if (parsedValue == null) {
      return S.of(context).pleaseEnterAValidNumber;
    }
    if (parsedValue < 1) {
      return S.of(context).pleaseEnterANumberGreaterThan0;
    }
    return null;
  }

  static String? validateStartingUrl(
    BuildContext context, {
    required bool useRandomAddress,
    required bool useNewAddresses,
    required String? value,
  }) {
    if (useRandomAddress) {
      return null;
    }
    final normalizedValue = value ?? '';
    final expectedLength = useNewAddresses ? 12 : 6;
    final mask = useNewAddresses
        ? RegExp(r'^[a-zA-Z0-9_-]{12}$')
        : RegExp(r'^[a-z0-9]{6}$');
    if (normalizedValue.isEmpty) {
      return S.of(context).pleaseEnterTheStartingAddress;
    }
    if (normalizedValue.length != expectedLength) {
      return S.of(context).pleaseEnterAMaxLengthAddress;
    }
    if (!mask.hasMatch(normalizedValue)) {
      final symbols =
          useNewAddresses ? '(a-z, A-Z, 0-9, _ and -)' : '(a-z, 0-9)';
      return S.of(context).pleaseEnterAAddressWithOnlyAMask(symbols);
    }
    return null;
  }

  static String? validateImgurStartingId(
    BuildContext context, {
    required bool useRandomAddress,
    required int idLength,
    required String? value,
  }) {
    if (useRandomAddress) {
      return null;
    }
    final normalizedValue = value ?? '';
    if (normalizedValue.isEmpty) {
      return S.of(context).pleaseEnterTheStartingAddress;
    }
    if (normalizedValue.length != idLength) {
      return S.of(context).pleaseEnterAMaxLengthAddress;
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(normalizedValue)) {
      return S.of(context).pleaseEnterAAddressWithOnlyAMask(
            '(a-z, A-Z, 0-9)',
          );
    }
    return null;
  }

  static String? validateProxyAddress(BuildContext context, String? value) {
    final normalizedValue = value ?? '';
    final addressMask =
        RegExp(r'^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$');
    if (normalizedValue.isEmpty) {
      return S.of(context).pleaseEnterTheProxyAddress;
    }
    if (!addressMask.hasMatch(normalizedValue)) {
      return S.of(context).pleaseEnterAValidIpAddress;
    }
    return null;
  }

  static String? validateProxyPort(BuildContext context, String? value) {
    final normalizedValue = value ?? '';
    if (normalizedValue.isEmpty) {
      return S.of(context).pleaseEnterTheProxyPort;
    }
    if (!RegExp(r'^[0-9]{1,5}$').hasMatch(normalizedValue)) {
      return S.of(context).pleaseEnterAValidPort;
    }
    return null;
  }

  static String? validateRequired(
    String? value,
    String emptyMessage,
  ) {
    if ((value ?? '').isEmpty) {
      return emptyMessage;
    }
    return null;
  }
}
