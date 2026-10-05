import 'package:file_picker/file_picker.dart';

import '../../../../core/errors/app_snackbar.dart';
import '../domain/entities/client_extras.dart';
import '../../../../core/media/app_file_picker.dart';

/// Device file picking for the client photo and the care plan document.
abstract final class ClientFiles {
  static const _mb = 1024 * 1024;

  /// "Client Photo": image only, up to 2MB.
  static Future<ClientPickedFile?> pickPhoto() =>
      _pick(FileType.image, null, 2, 'Image only • JPG, PNG up to 2MB');

  /// "Upload Care Plan Document": PDF / DOC / DOCX up to 10MB.
  static Future<ClientPickedFile?> pickCarePlan() =>
      _pick(FileType.custom, const ['pdf', 'doc', 'docx'], 10, 'PDF or DOCX up to 10MB');

  static Future<ClientPickedFile?> _pick(
    FileType type,
    List<String>? extensions,
    int maxMb,
    String hint,
  ) async {
    final picked = await AppFilePicker.pickFiles(
      type: type,
      allowedExtensions: extensions,
    );
    final file = picked?.files.firstOrNull;
    final path = file?.path;
    if (file == null || path == null) return null;
    if (file.size > maxMb * _mb) {
      AppSnackbar.show('${file.name} is too large', hint, force: true);
      return null;
    }
    return ClientPickedFile(path: path, name: file.name, size: file.size);
  }
}
