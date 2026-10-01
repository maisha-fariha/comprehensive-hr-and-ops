import 'package:gems_core/gems_core.dart';

import '../../../../../core/errors/app_snackbar.dart';

/// Runs a mutation like the web `mutateAsync` + toast pair. Returns the
/// error message, or null on success (after toasting [success] and calling
/// [onSuccess]).
Future<String?> runInventoryAction(
  Future<Result<void>> Function() action, {
  String? success,
  bool toastErrors = true,
  Future<void> Function()? onSuccess,
}) async {
  final result = await action();
  return result.when(
    success: (_) {
      if (success != null) AppSnackbar.show(success, '');
      onSuccess?.call();
      return null;
    },
    failure: (error) {
      if (toastErrors) AppSnackbar.show('Something went wrong', error.message);
      return error.message;
    },
  );
}
