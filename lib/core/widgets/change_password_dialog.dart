import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../errors/app_snackbar.dart';
import 'package:comprehensive_hr_and_ops/core/widgets/app_bottom_sheet.dart';

/// Sends the change and returns `null` on success, or the message to show
/// inside the dialog.
typedef ChangePasswordSubmit = Future<String?> Function({
  required String currentPassword,
  required String newPassword,
});

/// Current / new / confirm password dialog shared by every portal
/// (`POST /auth/change-password`). Copy and validation mirror the web
/// profile page; the dialog stays open on failure and shows the error
/// inline, and a "Password changed" confirmation follows a success.
Future<bool> showChangePasswordDialog(
  BuildContext context, {
  required ChangePasswordSubmit onSubmit,
}) async {
  final changed = await showAppPopup<bool>(
    context: context,
    builder: (_) => ChangePasswordDialog(onSubmit: onSubmit),
  );
  if (changed != true) return false;
  AppSnackbar.show(
    'Password changed',
    'Use your new password the next time you sign in.',
    force: true,
  );
  return true;
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, required this.onSubmit});

  final ChangePasswordSubmit onSubmit;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_current, _next, _confirm]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canSubmit =>
      !_saving &&
      _current.text.isNotEmpty &&
      _next.text.isNotEmpty &&
      _confirm.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _error = null);
    if (_next.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'The two new passwords do not match.');
      return;
    }
    setState(() => _saving = true);
    final error = await widget.onSubmit(
      currentPassword: _current.text,
      newPassword: _next.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetDialog(
      title: const Text('Change password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Container(
                key: const ValueKey('change-password-error'),
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.criticalRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.criticalRed,
                  ),
                ),
              ),
            PasswordField(
              controller: _current,
              label: 'Current password',
              autofillHints: const [AutofillHints.password],
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _next,
              label: 'New password',
              hint: 'At least 8 characters',
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _confirm,
              label: 'Confirm new password',
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canSubmit ? _submit : null,
          child: Text(_saving ? 'Saving…' : 'Change password'),
        ),
      ],
    );
  }
}

/// Obscured text field with a show / hide eye toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: !_visible,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: IconButton(
          tooltip: _visible ? 'Hide password' : 'Show password',
          icon: Icon(
            _visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}
