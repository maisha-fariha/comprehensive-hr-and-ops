import 'package:flutter/foundation.dart';

/// Uploaded file ready to send in `attachments[]` on a family message.
@immutable
class MessageAttachment {
  final String fileUrl;
  final String fileType;
  final String fileName;

  const MessageAttachment({
    required this.fileUrl,
    required this.fileType,
    required this.fileName,
  });

  Map<String, dynamic> toJson() => {
        'fileUrl': fileUrl,
        'fileType': fileType,
        'fileName': fileName,
      };
}
