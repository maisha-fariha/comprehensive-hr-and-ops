import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/client_extras.dart';
import '../../domain/entities/client_summary.dart';
import '../controllers/clients_controller.dart';
import 'client_form_sections.dart';
import 'clients_common.dart';

Future<bool?> showMoveClientSheet(
  BuildContext context,
  ClientsController controller,
  ClientSummary client,
) =>
    showClientSheet<bool>(
      context,
      MoveClientSheet(controller: controller, client: client),
    );

/// Web "Move to another home" (transfer) dialog.
class MoveClientSheet extends StatefulWidget {
  final ClientsController controller;
  final ClientSummary client;

  const MoveClientSheet({super.key, required this.controller, required this.client});

  @override
  State<MoveClientSheet> createState() => _MoveClientSheetState();
}

class _MoveClientSheetState extends State<MoveClientSheet> {
  final _reason = TextEditingController();
  final _overCapacity = TextEditingController();
  String _to = '';
  String? _roomId;
  List<ClientRoom>? _rooms;
  bool _atCapacity = false;
  bool _pending = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    _overCapacity.dispose();
    super.dispose();
  }

  Future<void> _pick(String id) async {
    setState(() {
      _to = id;
      _roomId = null;
      _rooms = null;
      _atCapacity = false;
      _error = null;
    });
    final rooms = await widget.controller.roomsFor(id);
    if (!mounted || _to != id) return;
    setState(() => _rooms = rooms);
  }

  Future<void> _move() async {
    if (_to.isEmpty) return;
    setState(() {
      _pending = true;
      _error = null;
    });
    final outcome = await widget.controller.moveClient(
      widget.client,
      ClientTransferRequest(
        toResidenceId: _to,
        roomId: _roomId,
        reason: _reason.text,
        overCapacityReason: _overCapacity.text,
      ),
    );
    if (!mounted) return;
    if (outcome.moved) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _pending = false;
      if (outcome.atCapacity) _atCapacity = true;
      _error = outcome.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.client;
    final controller = widget.controller;
    final options = [
      for (final id in controller.residenceOptions)
        if (id != c.residenceId) (id, controller.residenceLabel(id)),
    ];
    final canMove = _to.isNotEmpty &&
        !_pending &&
        (!_atCapacity || _overCapacity.text.trim().isNotEmpty);
    return ClientSheetFrame(
      icon: Icons.swap_horiz_rounded,
      title: 'Move to another home',
      description: '${c.fullName} is at ${c.residenceName ?? 'no recorded home'}. '
          'The move is recorded with its reason and the date.',
      tall: false,
      footerLeft: Text(
        c.roomNumber != null && c.roomNumber!.isNotEmpty
            ? 'Leaving room ${c.roomNumber}'
            : 'Not currently in a room',
        style: handoverText(context, 12.5, color: AppColors.textMuted),
      ),
      footer: [
        HandoverButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false)),
        HandoverButton(
          key: const ValueKey('move-client-submit'),
          label: _pending ? 'Moving…' : 'Move resident',
          icon: Icons.swap_horiz_rounded,
          filled: true,
          onPressed: canMove ? _move : null,
        ),
      ],
      children: [
        ClientSelect(
          key: const ValueKey('move-client-to'),
          label: 'Moving to',
          required: true,
          placeholder: 'Which home are they moving to',
          helper: 'The home they are in now is not listed',
          value: _to,
          options: options,
          onChanged: _pick,
        ),
        const SizedBox(height: 16),
        ClientRoomPicker(
          residenceId: _to.isEmpty ? null : _to,
          rooms: _rooms,
          value: _roomId,
          label: 'Room at the new home',
          onChanged: (v) => setState(() => _roomId = v),
        ),
        const SizedBox(height: 16),
        ClientInput(
          key: const ValueKey('move-client-reason'),
          label: 'Why they are moving',
          controller: _reason,
          lines: 3,
          helper: 'Kept on the transfer record — this is what somebody reads a year from now',
        ),
        if (_atCapacity) ...[
          const SizedBox(height: 16),
          ClientInput(
            key: const ValueKey('move-client-over-capacity'),
            label: 'Reason for moving them in anyway',
            required: true,
            controller: _overCapacity,
            lines: 2,
            helper: 'That home is already at its licensed bed count. '
                'A reason records the decision rather than bypassing it.',
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: handoverText(context, 12.5, color: AppColors.criticalRed)),
        ],
      ],
    );
  }
}
