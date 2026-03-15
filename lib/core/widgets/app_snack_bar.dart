import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';

SnackBar buildAppSnackBar({
  required String message,
  Color backgroundColor = AppColors.success,
}) {
  return SnackBar(
    content: Center(child: Text(message)),
    duration: const Duration(seconds: 2),
    backgroundColor: backgroundColor,
  );
}
