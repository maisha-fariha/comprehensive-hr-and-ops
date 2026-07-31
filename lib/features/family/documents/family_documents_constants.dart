import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'domain/entities/family_document_enums.dart';

/// Design tokens specific to the Family "Documents" feature that don't
/// belong in `lib/core/constants` (which is shared across every feature and
/// must not be edited by this feature). Colors already present in
/// `AppColors` are reused directly rather than introducing new values.
abstract final class FamilyDocumentsConstants {
  /// Icon-box background/foreground pair for a document row, keyed by file
  /// type: PDFs use the shared "critical" red/pink tint, the one JPG image
  /// file uses the shared "urgent" orange/tan tint — matching the reference
  /// screenshot without inventing new color tokens.
  static ({Color background, Color foreground}) fileTypeStyle(FamilyDocumentFileType fileType) {
    return switch (fileType) {
      FamilyDocumentFileType.pdf => (
          background: AppColors.criticalBackground,
          foreground: AppColors.criticalRed,
        ),
      FamilyDocumentFileType.jpg => (
          background: AppColors.urgentBackground,
          foreground: AppColors.urgentAmber,
        ),
    };
  }

  /// Glyph shown inside a document row's icon box. No existing SVG under
  /// `assets/icons/{dashboard,common,nav}` matches a document/image-file
  /// glyph and the Figma asset-download tool is unavailable this round
  /// (monthly quota exhausted), so this uses Material `Icons.description_outlined`
  /// / `Icons.image_outlined` as temporary stand-ins — see the feature's
  /// implementation report for the full list of substitutions.
  static IconData fileTypeIcon(FamilyDocumentFileType fileType) {
    return switch (fileType) {
      FamilyDocumentFileType.pdf => Icons.description_outlined,
      FamilyDocumentFileType.jpg => Icons.image_outlined,
    };
  }

  const FamilyDocumentsConstants._();
}
