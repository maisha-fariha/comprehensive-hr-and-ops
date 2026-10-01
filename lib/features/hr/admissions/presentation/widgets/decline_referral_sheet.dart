import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/referral.dart';
import '../controllers/admissions_controller.dart';
import 'admissions_common.dart';

Future<void> showDeclineReferralSheet(
  BuildContext context, {
  required AdmissionsController controller,
  required String referralId,
}) =>
    showAdmissionSheet<void>(
      context,
      DeclineReferralSheet(controller: controller, referralId: referralId),
    );

/// The web "Decline" modal; the API refuses to close without a reason.
class DeclineReferralSheet extends StatefulWidget {
  final AdmissionsController controller;
  final String referralId;

  const DeclineReferralSheet({
    super.key,
    required this.controller,
    required this.referralId,
  });

  @override
  State<DeclineReferralSheet> createState() => _DeclineReferralSheetState();
}

class _DeclineReferralSheetState extends State<DeclineReferralSheet> {
  final _reason = TextEditingController();
  Referral? _referral;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await widget.controller.repository.referral(widget.referralId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _referral = result.when(success: (r) => r, failure: (_) => null);
    });
  }

  Future<void> _decline() async {
    setState(() {
      _error = null;
      _saving = true;
    });
    final error = await widget.controller
        .decline(widget.referralId, _reason.text.trim());
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final r = _referral;
    final closed = r != null && r.isClosed;
    const gap = SizedBox(height: 14);
    return AdmissionSheetFrame(
      icon: Icons.cancel_outlined,
      tall: false,
      title: r != null
          ? 'Decline ${r.fullName}'
          : _loading
              ? 'Loading…'
              : 'Decline',
      description:
          'Closes the referral. The API will not close one without a reason recorded.',
      footer: [
        HandoverButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _reason,
          builder: (context, value, _) => HandoverButton(
            key: const ValueKey('decline-submit'),
            label: _saving ? 'Declining…' : 'Decline',
            icon: Icons.cancel_outlined,
            foreground: AppColors.criticalRed,
            onPressed: _saving || closed || value.text.trim().isEmpty
                ? null
                : _decline,
          ),
        ),
      ],
      children: [
        if (closed) ...[
          const AdmissionNotice('This referral is already closed.'),
          gap,
        ],
        if (_error != null) ...[
          AdmissionErrorBanner(_error!, key: const ValueKey('decline-error')),
          gap,
        ],
        AdmissionInput(
          key: const ValueKey('decline-reason'),
          label: 'Reason',
          required: true,
          controller: _reason,
          enabled: !closed,
          helper: 'Recorded on the referral — the API will not close one without it',
        ),
      ],
    );
  }
}
