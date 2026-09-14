import 'package:flutter/foundation.dart';

/// One uploaded file linked to a daily-log entry (`attachments[]`).
@immutable
class DailyNoteAttachment {
  final String fileUrl;
  final String fileType;
  final String? fileName;

  const DailyNoteAttachment({
    required this.fileUrl,
    required this.fileType,
    this.fileName,
  });
}
