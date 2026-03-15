import 'package:flutter/material.dart';

import 'package:lightshot_parser_mobile/core/theme/app_theme.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_category.dart';
import 'package:lightshot_parser_mobile/features/image_classification/domain/models/classification_result.dart';
import 'package:lightshot_parser_mobile/generated/l10n.dart';

class ClassificationBadge extends StatelessWidget {
  const ClassificationBadge({
    super.key,
    required this.classificationResult,
  });

  final ClassificationResult classificationResult;

  @override
  Widget build(BuildContext context) {
    final badgeData = _badgeData(context, classificationResult);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeData.$2,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: badgeData.$3),
      ),
      child: Text(
        badgeData.$1,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: badgeData.$3,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  (String, Color, Color) _badgeData(
    BuildContext context,
    ClassificationResult result,
  ) {
    if (result.isPending) {
      return (
        S.of(context).classificationLoading,
        AppColors.panelStrong,
        AppColors.accent,
      );
    }

    return switch (result.category) {
      ClassificationCategory.nsfw => (
          S.of(context).classificationCategoryNsfw,
          const Color(0xFFFDE8E7),
          AppColors.error,
        ),
      ClassificationCategory.people => (
          S.of(context).classificationCategoryPeople,
          const Color(0xFFE8F5EC),
          AppColors.success,
        ),
      ClassificationCategory.documents => (
          S.of(context).classificationCategoryDocuments,
          const Color(0xFFF5F0E3),
          AppColors.warning,
        ),
      ClassificationCategory.notClassified => (
          S.of(context).classificationCategoryNotClassified,
          const Color(0xFFF1F2F6),
          AppColors.textMuted,
        ),
      ClassificationCategory.unrecognized => (
          S.of(context).classificationCategoryUnrecognized,
          AppColors.panelStrong,
          AppColors.textMuted,
        ),
    };
  }
}
