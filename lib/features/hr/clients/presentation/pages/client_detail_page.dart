import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../../domain/entities/client_summary.dart';
import '../client_form.dart';
import '../clients_labels.dart';
import '../controllers/clients_controller.dart';
import '../widgets/client_family_contacts.dart';
import '../widgets/client_form_sections.dart';
import '../widgets/clients_common.dart';

/// Web "Client Details": the complete record, read-only for View and
/// editable for Edit ("Save & Close").
class ClientDetailPage extends StatefulWidget {
  final ClientSummary client;
  final bool editing;

  const ClientDetailPage({super.key, required this.client, this.editing = false});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

const _sections = [
  ('basic', 'Basic Information', 'Personal details'),
  ('residence', 'Residence Assignment', 'Assignment details'),
  ('family', 'Family / Guardian', 'Family / contact'),
  ('medical', 'Medical Information', 'Health information'),
  ('care', 'Care Planning', 'Goals & progress'),
  ('spend', 'Inventory Spend', 'Purchases & stock'),
];

class _ClientDetailPageState extends State<ClientDetailPage> {
  late ClientsController _controller;
  late ClientSummary _client = widget.client;
  late ClientForm _form = ClientForm.fromClient(widget.client);
  late bool _editing = widget.editing;
  final _keys = {for (final s in _sections) s.$1: GlobalKey()};
  String _active = 'basic';
  int _contacts = 0;
  bool _dirty = false;
  bool _saving = false;
  String? _error;

  bool get _readOnly => !_controller.canUpdate || !_editing;

  @override
  void initState() {
    super.initState();
    try {
      _controller = Get.find<ClientsController>();
    } catch (_) {
      _controller = Get.put(GetIt.instance<ClientsController>());
    }
    _loadDetail();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final detail = await _controller.loadClient(widget.client.id);
    if (!mounted || detail == null) return;
    setState(() {
      _client = detail;
      if (!_dirty) {
        _form.dispose();
        _form = ClientForm.fromClient(detail);
      }
    });
  }

  void _changed() => setState(() => _dirty = true);

  int get _completed {
    final f = _form;
    bool filled(String v) => v.trim().isNotEmpty;
    return [
      filled(f.firstName.text) && filled(f.lastName.text) && filled(f.dob),
      f.residenceComplete,
      _contacts > 0,
      f.medicalFilled,
      f.careFilled,
    ].where((v) => v).length;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await _controller.updateClient(_client, _form);
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

  void _jump(String id) {
    setState(() => _active = id);
    final ctx = _keys[id]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250));
    }
  }

  String _residenceLabel(String? id) =>
      id == null ? '—' : _controller.residenceLabel(id);

  @override
  Widget build(BuildContext context) {
    final c = _client;
    final done = _completed;
    final readOnly = _readOnly;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: hrSubPageAppBar(context, 'Client Details'),
      body: Column(
        children: [
          _header(context, c),
          ClientStatusBar(
            TextSpan(
              text: readOnly
                  ? 'Viewing the complete client record. Fields are read-only.'
                  : 'Editing the complete client record.',
            ),
          ),
          ColoredBox(
            color: AppColors.surfaceWhite,
            child: ClientStepChips(
              current: _active,
              onTap: _jump,
              steps: [
                for (var i = 0; i < _sections.length; i++)
                  (_sections[i].$1, _sections[i].$2, _sections[i].$3, i < done),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClientProgressCard(
                    caption: 'Record Completion',
                    fraction: done / 5,
                    line: '$done of 5 sections complete · ${(done / 5 * 100).round()}%',
                  ),
                  const SizedBox(height: 14),
                  if (_error != null) ...[ClientBanner(_error!), const SizedBox(height: 14)],
                  _panel(
                    'basic',
                    ClientBasicSection(
                      form: _form,
                      errors: const {},
                      enabled: !readOnly,
                      onChanged: _changed,
                    ),
                  ),
                  _panel(
                    'residence',
                    ClientResidenceSection(
                      form: _form,
                      errors: const {},
                      enabled: !readOnly,
                      residenceEnabled: false,
                      residenceOptions: [
                        for (final id in _controller.residenceOptions)
                          (id, _controller.residenceLabel(id)),
                        if (c.residenceId != null &&
                            !_controller.residenceNames.containsKey(c.residenceId))
                          (c.residenceId!, c.residenceName ?? _residenceLabel(c.residenceId)),
                      ],
                      roomsFor: _controller.roomsFor,
                      onChanged: _changed,
                    ),
                  ),
                  KeyedSubtree(
                    key: _keys['family'],
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ClientFamilyContacts(
                        controller: _controller,
                        clientId: c.id,
                        readOnly: readOnly,
                        onCount: (n) => setState(() => _contacts = n),
                      ),
                    ),
                  ),
                  _panel(
                    'medical',
                    ClientMedicalSection(form: _form, enabled: !readOnly, onChanged: _changed),
                  ),
                  _panel(
                    'care',
                    ClientCareSection(form: _form, enabled: !readOnly, onChanged: _changed),
                  ),
                  _panel('spend', ClientSpendSection(controller: _controller, clientId: c.id)),
                  if (c.transfers.isNotEmpty) _transfers(context, c),
                ],
              ),
            ),
          ),
          _footer(context, done, readOnly),
        ],
      ),
    );
  }

  Widget _panel(String id, Widget child) => Padding(
        key: _keys[id],
        padding: const EdgeInsets.only(bottom: 14),
        child: HandoverPanel(padding: const EdgeInsets.all(16), child: child),
      );

  Widget _header(BuildContext context, ClientSummary c) {
    final photo = c.photoUrl;
    return Container(
      width: double.infinity,
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFB4805A),
            foregroundImage: photo == null ? null : NetworkImage(photo),
            onForegroundImageError: photo == null ? null : (_, _) {},
            child: const Icon(Icons.person_outline_rounded, color: AppColors.surfaceWhite),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(c.fullName, style: handoverText(context, 16, weight: FontWeight.w700)),
                    ClientPill(
                      label: ClientsLabels.humanise(c.status).toUpperCase(),
                      tone: ClientToneColors.forStatus(c.status),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    c.fullName,
                    'ID #${c.shortId}',
                    ?c.residenceName,
                    if (c.careLevel != null) 'Care ${c.careLevel}',
                  ].join(' · '),
                  style: handoverText(context, 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _transfers(BuildContext context, ClientSummary c) {
    return HandoverPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transfer history', style: handoverText(context, 15, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final t in c.transfers)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.infoBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.fromResidenceId == null
                              ? 'Placed at ${_residenceLabel(t.toResidenceId)}'
                              : '${_residenceLabel(t.fromResidenceId)} → '
                                  '${_residenceLabel(t.toResidenceId)}',
                          style: handoverText(context, 13, weight: FontWeight.w500),
                        ),
                        Text(
                          [ClientsLabels.date(t.transferredAt?.toLocal()), ?t.reason].join(' · '),
                          style: handoverText(context, 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, int done, bool readOnly) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Step $done of 5 completed',
              style: handoverText(context, 12, color: AppColors.textMuted),
            ),
          ),
          HandoverButton(
            label: readOnly ? 'Close' : 'Cancel',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          if (readOnly)
            if (_controller.canUpdate)
              HandoverButton(
                key: const ValueKey('client-edit-record'),
                label: 'Edit Record',
                filled: true,
                onPressed: () => setState(() => _editing = true),
              )
            else
              const SizedBox.shrink()
          else
            HandoverButton(
              key: const ValueKey('client-save-close'),
              label: _saving ? 'Saving…' : 'Save & Close',
              filled: true,
              onPressed: _saving ? null : _save,
            ),
        ],
      ),
    );
  }
}
