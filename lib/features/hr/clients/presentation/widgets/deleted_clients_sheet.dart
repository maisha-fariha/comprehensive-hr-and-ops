import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../../domain/entities/client_summary.dart';
import '../clients_labels.dart';
import '../controllers/clients_controller.dart';
import 'clients_common.dart';

/// The web "Deleted residents" log: who was deleted, by whom and why, with
/// Restore.
class DeletedClientsSheet extends StatefulWidget {
  final ClientsController controller;

  const DeletedClientsSheet({super.key, required this.controller});

  @override
  State<DeletedClientsSheet> createState() => _DeletedClientsSheetState();
}

class _DeletedClientsSheetState extends State<DeletedClientsSheet> {
  List<DeletedClient>? _rows;
  String? _error;
  String _search = '';
  Timer? _debounce;
  final Set<String> _restoring = {};
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final result = await widget.controller.loadDeleted(search: _search);
    if (!mounted || generation != _generation) return;
    setState(() {
      result.when(
        success: (rows) {
          _rows = rows;
          _error = null;
        },
        failure: (e) {
          _rows = const [];
          _error = e.message;
        },
      );
    });
  }

  void _onSearch(String value) {
    _search = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  Future<void> _restore(DeletedClient row) async {
    setState(() => _restoring.add(row.client.id));
    final ok = await widget.controller.restoreClient(row);
    if (!mounted) return;
    setState(() {
      _restoring.remove(row.client.id);
      if (ok) _rows = [for (final r in _rows ?? const <DeletedClient>[]) if (r != row) r];
    });
  }

  static String _status(String value) => switch (value) {
        'active' => 'Active',
        'on_leave' => 'On leave',
        'discharged' => 'Discharged',
        'draft' => 'Draft',
        _ => ClientsLabels.humanise(value),
      };

  static String _when(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${ClientsLabels.date(local)} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return ClientSheetFrame(
      icon: Icons.history_rounded,
      title: 'Deleted residents',
      description: 'Records taken off the roster, with who deleted them and why. '
          'Restoring brings a resident back as they were.',
      footer: [
        HandoverButton(label: 'Close', onPressed: () => Navigator.of(context).pop()),
      ],
      children: [
        HrSearchField(hint: 'Search by name…', onChanged: _onSearch),
        const SizedBox(height: 12),
        if (rows == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppColors.secondaryTeal)),
          )
        else if (_error != null)
          _message(context, _error!, error: true)
        else if (rows.isEmpty)
          _message(
            context,
            _search.trim().isEmpty
                ? 'No resident has been deleted.'
                : 'No deleted resident matches that name.',
          )
        else
          for (final row in rows) ...[
            _tile(context, row),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _message(BuildContext context, String text, {bool error = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: handoverText(
            context,
            13,
            color: error ? AppColors.criticalRed : AppColors.textMuted,
          ),
        ),
      );

  Widget _tile(BuildContext context, DeletedClient row) {
    final c = row.client;
    final busy = _restoring.contains(c.id);
    final where = [
      c.residenceName ?? 'No residence',
      if (row.statusBeforeDelete case final s? when s.isNotEmpty) 'was ${_status(s)}',
    ].join(' · ');
    return Container(
      key: ValueKey('deleted-client-${c.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(c.fullName, style: handoverText(context, 14, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(where, style: handoverText(context, 12.5, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(
            'Deleted ${_when(row.deletedAt)}'
            '${row.deletedByName == null ? '' : ' by ${row.deletedByName}'}',
            style: handoverText(context, 12.5),
          ),
          const SizedBox(height: 2),
          Text(
            row.reason == null || row.reason!.isEmpty
                ? 'No reason given'
                : 'Reason: ${row.reason}',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: HandoverButton(
              key: ValueKey('deleted-client-restore-${c.id}'),
              label: busy ? 'Restoring…' : 'Restore',
              icon: Icons.restore_rounded,
              compact: true,
              onPressed: busy ? null : () => _restore(row),
            ),
          ),
        ],
      ),
    );
  }
}
