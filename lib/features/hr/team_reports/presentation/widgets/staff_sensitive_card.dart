import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/staff_sensitive.dart';
import '../../domain/repositories/team_reports_repository.dart';

/// "SIN & Banking" on a staff profile. Masked by default; revealing the full
/// numbers and every change are audited by the API.
class StaffSensitiveCard extends StatefulWidget {
  final String staffId;
  final bool canWrite;

  const StaffSensitiveCard({
    super.key,
    required this.staffId,
    this.canWrite = false,
  });

  @override
  State<StaffSensitiveCard> createState() => _StaffSensitiveCardState();
}

class _StaffSensitiveCardState extends State<StaffSensitiveCard> {
  final _repository = GetIt.instance<TeamReportsRepository>();
  final _sin = TextEditingController();
  final _institution = TextEditingController();
  final _transit = TextEditingController();
  final _account = TextEditingController();

  bool _loading = true;
  String? _loadError;
  StaffSensitive? _data;
  StaffSensitive? _revealed;
  bool _revealing = false;
  bool _editing = false;
  bool _saving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sin.dispose();
    _institution.dispose();
    _transit.dispose();
    _account.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _repository.getStaffSensitive(widget.staffId);
    if (!mounted) return;
    result.when(
      success: (data) => setState(() {
        _data = data;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _loadError = error.message;
        _loading = false;
      }),
    );
  }

  Future<void> _reveal() async {
    setState(() => _revealing = true);
    final result =
        await _repository.getStaffSensitive(widget.staffId, reveal: true);
    if (!mounted) return;
    setState(() => _revealing = false);
    result.when(
      success: (data) => setState(() => _revealed = data),
      failure: (error) =>
          AppSnackbar.show('Could not reveal', error.message, force: true),
    );
  }

  Future<void> _save(Map<String, dynamic> body) async {
    setState(() {
      _saving = true;
      _formError = null;
    });
    final result =
        await _repository.updateStaffSensitive(widget.staffId, body);
    if (!mounted) return;
    result.when(
      success: (data) {
        _sin.clear();
        _institution.clear();
        _transit.clear();
        _account.clear();
        setState(() {
          _data = data;
          _revealed = null;
          _editing = false;
          _saving = false;
        });
        AppSnackbar.show('Saved', '', force: true);
      },
      failure: (error) => setState(() {
        _saving = false;
        _formError = error.message;
      }),
    );
  }

  void _submit() {
    final body = <String, dynamic>{};
    final sin = _sin.text.trim();
    if (sin.isNotEmpty) body['sin'] = sin;
    final banking = [_institution, _transit, _account]
        .map((c) => c.text.trim())
        .toList();
    if (banking.any((v) => v.isNotEmpty)) {
      if (!banking.every((v) => v.isNotEmpty)) {
        setState(() => _formError =
            'Banking needs all three: institution, transit and account number.');
        return;
      }
      body['banking'] = {
        'institutionNumber': banking[0],
        'transitNumber': banking[1],
        'accountNumber': banking[2],
      };
    }
    if (body.isEmpty) {
      setState(() => _formError =
          'Type a new SIN or new banking details — blank boxes keep what is on file.');
      return;
    }
    _save(body);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('staff-sensitive-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SIN & Banking',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14.5,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Personal information under PIPEDA. Encrypted at rest; every reveal '
            'and change is recorded in the audit log.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Text('Loading…', style: _mutedStyle)
          else if (_loadError != null)
            Text(
              _loadError!,
              style: _mutedStyle.copyWith(color: AppColors.criticalRed),
            )
          else
            ..._content(),
        ],
      ),
    );
  }

  List<Widget> _content() {
    final shown = _revealed ?? _data ?? const StaffSensitive();
    final onFile = _data?.anyOnFile ?? false;
    return [
      Wrap(
        spacing: 20,
        runSpacing: 10,
        children: [
          _Field('Social Insurance Number', shown.sinLabel,
              muted: !shown.sinOnFile),
          _Field('Institution', shown.institutionLabel,
              muted: !shown.bankingOnFile),
          _Field('Transit', shown.transitLabel, muted: !shown.bankingOnFile),
          _Field('Account', shown.accountLabel, muted: !shown.bankingOnFile),
        ],
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (onFile)
            _revealed != null
                ? OutlinedButton.icon(
                    key: const ValueKey('staff-sensitive-hide'),
                    onPressed: () => setState(() => _revealed = null),
                    icon: const Icon(Icons.visibility_off_outlined, size: 16),
                    label: const Text('Hide'),
                  )
                : OutlinedButton.icon(
                    key: const ValueKey('staff-sensitive-reveal'),
                    onPressed: _revealing ? null : _reveal,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: Text(_revealing ? 'Revealing…' : 'Reveal'),
                  ),
          if (widget.canWrite && !_editing)
            OutlinedButton.icon(
              key: const ValueKey('staff-sensitive-edit'),
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
            ),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 13, color: AppColors.textMuted),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Viewing the full numbers is logged.',
                  style: _mutedStyle,
                ),
              ),
            ],
          ),
        ],
      ),
      if (_editing) ...[
        const SizedBox(height: 12),
        _editor(),
      ],
    ];
  }

  Widget _editor() {
    final data = _data;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_formError != null) ...[
            Text(
              _formError!,
              style: _mutedStyle.copyWith(
                color: AppColors.criticalRed,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
          ],
          _input(
            'staff-sensitive-sin',
            'New SIN',
            _sin,
            (data?.sinOnFile ?? false)
                ? 'Leave blank to keep the one on file'
                : '123 456 789',
          ),
          _input('staff-sensitive-institution', 'Institution #', _institution,
              '001'),
          _input('staff-sensitive-transit', 'Transit #', _transit, '12345'),
          _input('staff-sensitive-account', 'Account #', _account, '1234567'),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              if (data?.sinOnFile ?? false)
                TextButton(
                  onPressed: _saving ? null : () => _save({'sin': null}),
                  child: const Text('Remove SIN'),
                ),
              if (data?.bankingOnFile ?? false)
                TextButton(
                  onPressed: _saving ? null : () => _save({'banking': null}),
                  child: const Text('Remove banking'),
                ),
              OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          _editing = false;
                          _formError = null;
                        }),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const ValueKey('staff-sensitive-save'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondaryTeal,
                ),
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _input(
    String key,
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        key: ValueKey(key),
        controller: controller,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: AppColors.surfaceWhite,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

const _mutedStyle = TextStyle(
  fontFamily: 'Outfit',
  fontSize: 12,
  color: AppColors.textMuted,
);

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;

  const _Field(this.label, this.value, {this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            letterSpacing: 0.5,
            color: muted ? AppColors.textMuted : AppColors.textHeading,
          ),
        ),
      ],
    );
  }
}
