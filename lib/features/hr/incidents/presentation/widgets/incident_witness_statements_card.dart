import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/incident_witness_statement.dart';
import '../../domain/repositories/incidents_repository.dart';

/// Incident Details "Witness statements" card — web parity: lists each
/// account, and with `incidents:write` lets the manager take and sign one.
class IncidentWitnessStatementsCard extends StatefulWidget {
  final String incidentId;
  final IncidentsRepository repository;
  final bool canWrite;

  const IncidentWitnessStatementsCard({
    super.key,
    required this.incidentId,
    required this.repository,
    required this.canWrite,
  });

  @override
  State<IncidentWitnessStatementsCard> createState() =>
      _IncidentWitnessStatementsCardState();
}

class _IncidentWitnessStatementsCardState
    extends State<IncidentWitnessStatementsCard> {
  static const _emptyCopy =
      'None recorded. A name on its own is not an account of what happened.';

  final _nameController = TextEditingController();
  final _statementController = TextEditingController();

  List<IncidentWitnessStatement> _statements = const [];
  bool _isLoading = true;
  bool _isFormOpen = false;
  bool _isSaving = false;
  String _witnessType = 'staff';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statementController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await widget.repository.getWitnessStatements(
      widget.incidentId,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _statements = result.when(
        success: (data) => data,
        failure: (_) => _statements,
      );
    });
  }

  void _resetForm() {
    setState(() {
      _isFormOpen = false;
      _witnessType = 'staff';
    });
    _nameController.clear();
    _statementController.clear();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final statement = _statementController.text.trim();
    if (name.isEmpty || statement.isEmpty) {
      AppSnackbar.show('A statement needs a name and an account.', '');
      return;
    }
    setState(() => _isSaving = true);
    final result = await widget.repository.addWitnessStatement(
      incidentId: widget.incidentId,
      witnessType: _witnessType,
      witnessName: name,
      statementText: statement,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    result.when(
      success: (_) {
        AppSnackbar.show('Statement recorded', '');
        _resetForm();
        _load();
      },
      failure: (error) => AppSnackbar.show('Could not save statement', error.message),
    );
  }

  Future<void> _sign(IncidentWitnessStatement statement) async {
    setState(() => _isSaving = true);
    final result = await widget.repository.signWitnessStatement(
      incidentId: widget.incidentId,
      statementId: statement.id,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    result.when(
      success: (_) {
        AppSnackbar.show('Signed — this statement can no longer be edited', '');
        _load();
      },
      failure: (error) => AppSnackbar.show('Could not sign', error.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10));

    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, all: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Witness statements',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              if (widget.canWrite && !_isFormOpen)
                OutlinedButton.icon(
                  key: const ValueKey('incident-take-statement'),
                  onPressed: () => setState(() => _isFormOpen = true),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Take a statement'),
                  style: _outlinedStyle(),
                ),
            ],
          ),
          gap,
          if (_isLoading)
            _muted(context, 'Loading…')
          else if (_statements.isEmpty && !_isFormOpen)
            _muted(context, _emptyCopy),
          for (final statement in _statements) ...[
            _StatementTile(
              statement: statement,
              canSign: widget.canWrite,
              busy: _isSaving,
              onSign: () => _sign(statement),
            ),
            gap,
          ],
          if (_isFormOpen) _form(context),
        ],
      ),
    );
  }

  Widget _form(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: const ValueKey('incident-statement-type'),
            initialValue: _witnessType,
            decoration: _decoration(
              'Who is speaking *',
              helper: 'Who the witness is decides how the account is weighed.',
            ),
            items: [
              for (final entry in IncidentWitnessStatement.witnessTypes.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) => setState(() => _witnessType = value ?? 'staff'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('incident-statement-name'),
            controller: _nameController,
            decoration: _decoration(
              'Name *',
              hint: 'As they gave it',
              helper: 'Recorded as written, so it stays true to the day.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('incident-statement-text'),
            controller: _statementController,
            minLines: 3,
            maxLines: 6,
            decoration: _decoration(
              'What they saw *',
              hint: 'In their own words, as close as possible…',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isSaving ? null : _resetForm,
                style: _outlinedStyle(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const ValueKey('incident-statement-save'),
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondaryTeal,
                  textStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(_isSaving ? 'Saving…' : 'Save statement'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, {String? hint, String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      isDense: true,
    );
  }

  ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.textHeading,
        side: const BorderSide(color: AppColors.cardBorder),
        textStyle: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600),
      );

  Widget _muted(BuildContext context, String text) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      );
}

class _StatementTile extends StatelessWidget {
  final IncidentWitnessStatement statement;
  final bool canSign;
  final bool busy;
  final VoidCallback onSign;

  const _StatementTile({
    required this.statement,
    required this.canSign,
    required this.busy,
    required this.onSign,
  });

  static String _signedLabel(DateTime at) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    return '${at.day} ${months[at.month - 1]} ${at.year}, '
        '$hour:$minute ${at.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final Widget trailing;
    if (statement.isSigned) {
      trailing = _Pill(
        label: 'Signed ${_signedLabel(statement.signedAt!)}',
        background: AppColors.activeBackground,
        foreground: AppColors.activeGreen,
        icon: Icons.how_to_reg_rounded,
      );
    } else if (canSign) {
      trailing = OutlinedButton.icon(
        key: ValueKey('incident-statement-sign-${statement.id}'),
        onPressed: busy ? null : onSign,
        icon: const Icon(Icons.draw_outlined, size: 16),
        label: const Text('Sign'),
      );
    } else {
      trailing = const _Pill(
        label: 'Unsigned',
        background: AppColors.urgentBackground,
        foreground: AppColors.urgentAmber,
      );
    }

    return Container(
      padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statement.witnessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textHeading,
                      ),
                    ),
                    Text(
                      statement.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: trailing),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statement.statementText,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
