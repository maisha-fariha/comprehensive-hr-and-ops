/// The file format of a shared Family document, driving the row's icon
/// glyph/tint and the "· PDF" / "· JPG" suffix on the subtext line.
enum FamilyDocumentFileType {
  pdf,
  jpg;

  /// Uppercase label shown after the update date, e.g. "PDF"/"JPG".
  String get label => switch (this) {
        FamilyDocumentFileType.pdf => 'PDF',
        FamilyDocumentFileType.jpg => 'JPG',
      };
}
