import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../attendance/presentation/widgets/attendance_record_card.dart';
import '../../../handovers/presentation/widgets/handover_common.dart';
import '../../domain/entities/hr_document.dart';
import '../../domain/entities/hr_document_row.dart';
import '../controllers/hr_documents_controller.dart';
import 'hr_documents_common.dart';

/// The web document "View" modal, including Read & Sign.
class HrDocumentDetailSheet extends StatefulWidget {
  final HrDocumentRow row;
  final HrDocumentsController controller;
  final VoidCallback onDownload;
  final VoidCallback onEdit;

  const HrDocumentDetailSheet({
    super.key,
    required this.row,
    required this.controller,
    required this.onDownload,
    required this.onEdit,
  });

  @override
  State<HrDocumentDetailSheet> createState() => _HrDocumentDetailSheetState();
}

class _HrDocumentDetailSheetState extends State<HrDocumentDetailSheet> {
  late HrDocumentRow _row;
  HrAcknowledgmentProgress? _progress;
  bool _loadingProgress = false;
  bool _composing = false;
  bool _submitting = false;
  bool _showPreview = false;
  String? _formError;

  String _mode = 'parallel';
  String _audience = 'all';
  final Set<String> _roleCodes = {};
  final Set<String> _residenceIds = {};
  final Set<String> _userIds = {};
  final Set<String> _approverIds = {};
  String _dueDate = '';

  HrDocumentsController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _row = widget.row;
    _audience = _defaultAudience();
    if (_row.ackRequired && _c.canWrite) {
      _loadProgress();
    }
  }

  String _defaultAudience() {
    final visibility = _row.visibility;
    if (visibility == 'family') return 'family';
    if (visibility == 'all' || visibility.isEmpty) return 'all';
    return 'users';
  }

  List<(String, String)> get _audienceOptions {
    final visibility = _row.visibility;
    final includeFamily =
        visibility == 'family' || visibility == 'all' || visibility.isEmpty;
    final staffBands = visibility != 'family';
    return [
      if (staffBands) ...[
        ('all', 'Everyone on staff who can open it'),
        ('roles', 'Particular roles'),
        ('residences', 'Staff of particular residences'),
      ],
      ('users', 'Particular people'),
      if (_row.ownerType == 'staff') ('owner', 'The staff member it belongs to'),
      if (includeFamily) ('family', 'Family contacts for this resident'),
    ];
  }

  Future<void> _loadProgress() async {
    setState(() => _loadingProgress = true);
    final result = await _c.loadAcknowledgments(_row.id);
    if (!mounted) return;
    result.when(
      success: (progress) => setState(() {
        _progress = progress;
        _loadingProgress = false;
      }),
      failure: (_) => setState(() => _loadingProgress = false),
    );
  }

  String? _validateForm() {
    if (_audience == 'roles' && _roleCodes.isEmpty) {
      return 'Choose at least one role';
    }
    if (_audience == 'residences' && _residenceIds.isEmpty) {
      return 'Choose at least one residence';
    }
    if (_audience == 'users' && _userIds.isEmpty) {
      return 'Choose who must sign';
    }
    if (_mode == 'sequential' && _approverIds.isEmpty) {
      return 'Choose who signs first';
    }
    return null;
  }

  Map<String, dynamic> _buildBody() {
    final audience = <String, dynamic>{
      'audience': _audience,
      if (_audience == 'roles') 'roleCodes': _roleCodes.toList(),
      if (_audience == 'residences') 'residenceIds': _residenceIds.toList(),
      if (_audience == 'users') 'userIds': _userIds.toList(),
    };
    Map<String, dynamic> due = const {};
    if (_dueDate.isNotEmpty) {
      final parts = _dueDate.split('-');
      if (parts.length == 3) {
        final endOfDay = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
          23,
          59,
          59,
          999,
        );
        due = {'dueAt': endOfDay.toUtc().toIso8601String()};
      }
    }
    if (_mode == 'sequential') {
      return {
        'mode': 'sequential',
        'steps': [
          {
            'audience': 'users',
            'userIds': _approverIds.toList(),
            'anyOne': true,
          },
          audience,
        ],
        ...due,
      };
    }
    return {'mode': 'parallel', ...audience, ...due};
  }

  Future<void> _submitSigning() async {
    final error = _validateForm();
    if (error != null) {
      setState(() => _formError = error);
      return;
    }
    setState(() {
      _formError = null;
      _submitting = true;
    });
    final result = await _c.sendForSigning(_row.id, _buildBody());
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (progress) {
        setState(() {
          _progress = progress;
          _composing = false;
          _row = HrDocumentRow.from(
            HrDocument(
              id: _row.document.id,
              name: _row.document.name,
              documentTypeId: _row.document.documentTypeId,
              fileUrl: _row.document.fileUrl,
              ownerType: _row.document.ownerType,
              ownerId: _row.document.ownerId,
              expiresAt: _row.document.expiresAt,
              status: _row.document.status,
              visibility: _row.document.visibility,
              notes: _row.document.notes,
              uploadedBy: _row.document.uploadedBy,
              deletedAt: _row.document.deletedAt,
              createdAt: _row.document.createdAt,
              source: _row.document.source,
              ackRequired: true,
              signingMode: progress.mode,
              signingHeld: progress.held,
              ackDueAt: progress.dueAt,
              ackRequestedAt: progress.requestedAt,
              myAckRequired: _row.document.myAckRequired,
              myAcknowledgedAt: _row.document.myAcknowledgedAt,
              myAckDueAt: _row.document.myAckDueAt,
            ),
            directories: {
              for (final MapEntry(:key, :value) in _c.directories.entries)
                key: {for (final o in value) o.id: o.name},
            },
            typeNames: _c.typeNames,
            now: DateTime.now(),
          );
        });
      },
      failure: (_) {},
    );
  }

  Future<void> _acknowledge() async {
    setState(() => _submitting = true);
    final result = await _c.acknowledgeDocument(_row.id);
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (_) => Navigator.of(context).maybePop(),
      failure: (_) {},
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_dueDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    String two(int v) => v.toString().padLeft(2, '0');
    setState(() {
      _dueDate = '${picked.year}-${two(picked.month)}-${two(picked.day)}';
    });
  }

  Future<void> _toggleMulti({
    required String title,
    required List<HrSignOption> options,
    required Set<String> selected,
  }) async {
    final picked = await pickHandoverOption(
      context,
      title: title,
      options: [for (final o in options) (o.id, o.label)],
      selected: null,
    );
    if (picked == null) return;
    setState(() {
      if (selected.contains(picked)) {
        selected.remove(picked);
      } else {
        selected.add(picked);
      }
    });
  }

  String _labelsFor(Set<String> ids, List<HrSignOption> options) {
    if (ids.isEmpty) return '';
    final byId = {for (final o in options) o.id: o.label};
    return [for (final id in ids) byId[id] ?? id].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final downloading = _c.busyId.value?.startsWith('download:') ?? false;
      return _buildSheet(context, downloading: downloading);
    });
  }

  Widget _buildSheet(BuildContext context, {required bool downloading}) {
    final (icon, fg, _) = hrFileStyle(_row.fileKind);
    final canWrite = _c.canWrite;

    Widget field(String label, String value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: handoverText(context, 11, weight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              value.isEmpty ? '—' : value,
              style: handoverText(context, 13.5, weight: FontWeight.w600, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 14),
          ],
        );
    Widget section(String title, List<Widget> children, {IconData? leading}) =>
        HandoverPanel(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leading != null) ...[
                    Icon(leading, size: 16, color: AppColors.primaryNavy),
                    const SizedBox(width: 8),
                  ],
                  Text(title, style: handoverText(context, 13, weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        );

    return HrSheetFrame(
      key: const ValueKey('document-detail'),
      icon: icon,
      iconBackground: _row.fileKind == HrFileKind.file ? AppColors.filterButtonBackground : fg,
      iconForeground: _row.fileKind == HrFileKind.file ? AppColors.textMuted : AppColors.surfaceWhite,
      title: _row.name,
      badges: [
        HrDocPill.owner(_row.ownerType, _row.ownerTypeLabel),
        AttendancePill(label: _row.statusLabel, tone: hrStatusTone(_row.statusTone), dot: true),
      ],
      description: 'Filed against ${_row.ownerName}',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_row.fileUrl != null) ...[
            _PreviewTabs(
              showPreview: _showPreview,
              fileKind: _row.fileKind,
              onDetails: () => setState(() => _showPreview = false),
              onPreview: () => setState(() => _showPreview = true),
            ),
            const SizedBox(height: 16),
          ],
          if (_showPreview && _row.fileUrl != null)
            _InAppPreviewCard(
              name: _row.name,
              downloading: downloading,
              onDownload: widget.onDownload,
            )
          else ...[
            section('Document Details', [
              field('Owner', '${_row.ownerName} · ${_row.ownerTypeLabel}'),
              field('Category', _row.category),
              field('Visible to', _row.visibilityLabel),
              field('Held as', _row.isStaffCertificate ? 'Staff certificate' : 'Document'),
            ]),
            if (_row.showReadAndSign(canWrite)) ...[
              const SizedBox(height: 16),
              _buildReadAndSign(context, section),
            ],
            const SizedBox(height: 16),
            section('Filing & Expiry', [
              field('Filed', _row.uploadedDate),
              field('Expiry Date', _row.expiryDate ?? 'Not tracked'),
              field('Status', _row.withdrawn ? 'Withdrawn' : _row.statusLabel),
              if (_row.notes != null) ...[
                Text(_row.notes!, style: handoverText(context, 13.5)),
                const SizedBox(height: 14),
              ],
            ]),
            if (_row.isStaffCertificate) ...[
              const SizedBox(height: 16),
              Text(
                'Certificates are held on the staff record and are edited there, not in the registry.',
                style: handoverText(context, 13, color: AppColors.textMuted),
              ),
            ],
          ],
        ],
      ),
      footer: [
        if (_row.fileUrl != null)
          HandoverButton(
            key: const ValueKey('document-detail-preview-toggle'),
            label: _showPreview ? 'Show Details' : 'Preview File',
            icon: _showPreview ? Icons.description_outlined : Icons.visibility_outlined,
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
        HandoverButton(
          key: const ValueKey('document-detail-close'),
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
        if (_row.fileUrl != null)
          HandoverButton(
            key: const ValueKey('document-detail-download'),
            label: downloading ? 'Downloading…' : 'Download',
            icon: Icons.download_rounded,
            onPressed: downloading ? null : widget.onDownload,
          ),
        if (_row.canEdit(canWrite))
          HandoverButton(
            key: const ValueKey('document-detail-edit'),
            label: 'Edit',
            icon: Icons.edit_outlined,
            filled: true,
            onPressed: widget.onEdit,
          ),
      ],
    );
  }

  Widget _buildReadAndSign(
    BuildContext context,
    Widget Function(String, List<Widget>, {IconData? leading}) section,
  ) {
    final canWrite = _c.canWrite;
    final children = <Widget>[];

    if (_row.myAckRequired && _row.myAcknowledgedAt == null) {
      children.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.urgentBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.urgentAmber.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are asked to read this document and confirm you agree'
                '${_row.myAckDueAt == null ? '' : ' by ${WebFormat.date(_row.myAckDueAt)}'}.',
                style: handoverText(context, 13),
              ),
              const SizedBox(height: 10),
              HandoverButton(
                label: _submitting ? 'Signing…' : 'Sign Document',
                icon: Icons.draw_outlined,
                filled: true,
                onPressed: _submitting ? null : _acknowledge,
              ),
            ],
          ),
        ),
      );
    }

    if (!canWrite) {
      return section('Read & Sign', children, leading: Icons.draw_outlined);
    }

    if (_row.ackRequired && !_composing) {
      if (_loadingProgress) {
        children.add(
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      } else if (_progress != null) {
        final progress = _progress!;
        children.addAll([
          Text(
            '${progress.acknowledged} of ${progress.required} signed'
            '${progress.pending > 0 ? ' · ${progress.pending} pending' : ''}'
            '${progress.overdue > 0 ? ' · ${progress.overdue} overdue' : ''}',
            style: handoverText(context, 13.5, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            progress.mode == 'sequential'
                ? 'Signing in order'
                : 'Everyone signs, in any order',
            style: handoverText(context, 12.5, color: AppColors.textMuted),
          ),
          if (progress.dueAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Due ${WebFormat.date(progress.dueAt)}',
              style: handoverText(context, 12.5, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          for (final person in progress.people)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    person.signed ? Icons.check_circle : Icons.schedule,
                    size: 16,
                    color: person.signed
                        ? AppColors.successGreen
                        : person.overdue
                            ? AppColors.criticalRed
                            : AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      person.name,
                      style: handoverText(context, 13),
                    ),
                  ),
                  Text(
                    person.signed
                        ? WebFormat.date(person.acknowledgedAt)
                        : person.overdue
                            ? 'Overdue'
                            : 'Pending',
                    style: handoverText(
                      context,
                      12,
                      color: person.signed
                          ? AppColors.successGreen
                          : person.overdue
                              ? AppColors.criticalRed
                              : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (progress.pending > 0)
                HandoverButton(
                  label: 'Remind',
                  icon: Icons.notifications_outlined,
                  onPressed: _submitting ? null : () => _c.remindSigning(_row.id),
                ),
              HandoverButton(
                label: 'Send again',
                icon: Icons.send_outlined,
                onPressed: () => setState(() => _composing = true),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ]);
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Signing has been requested for this document.',
              style: handoverText(context, 13, color: AppColors.textMuted),
            ),
          ),
        );
      }
    } else if (!_composing) {
      children.addAll([
        Text(
          'Ask people to read this and confirm they agree — at once, or an approver first — and see who has.',
          style: handoverText(context, 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: HandoverButton(
            label: 'Send for signing',
            icon: Icons.send_outlined,
            filled: true,
            onPressed: () => setState(() => _composing = true),
          ),
        ),
        const SizedBox(height: 10),
      ]);
    }

    if (_composing) {
      children.addAll([
        if (_formError != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.criticalBackgroundSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _formError!,
              style: handoverText(context, 13, color: AppColors.criticalRed),
            ),
          ),
          const SizedBox(height: 10),
        ],
        HandoverSelect(
          label: 'Signing order',
          value: _mode == 'sequential'
              ? 'Sign in order: an approver first, then everyone else'
              : 'Everyone signs, in any order',
          placeholder: 'Choose order',
          onTap: () async {
            final picked = await pickHandoverOption(
              context,
              title: 'Signing order',
              options: const [
                ('parallel', 'Everyone signs, in any order'),
                ('sequential', 'Sign in order: an approver first, then everyone else'),
              ],
              selected: _mode,
            );
            if (picked != null) setState(() => _mode = picked);
          },
        ),
        const SizedBox(height: 12),
        HandoverSelect(
          label: 'Who must sign',
          value: HrDocumentOptions.label(_audienceOptions, _audience, _audience),
          placeholder: 'Say who must sign',
          required: true,
          onTap: () async {
            final picked = await pickHandoverOption(
              context,
              title: 'Who must sign',
              options: _audienceOptions,
              selected: _audience,
            );
            if (picked != null) setState(() => _audience = picked);
          },
        ),
        if (_audience == 'roles') ...[
          const SizedBox(height: 12),
          HandoverSelect(
            label: 'Roles',
            value: _labelsFor(_roleCodes, _c.signRoles),
            placeholder: 'Choose roles',
            required: true,
            onTap: () => _toggleMulti(
              title: 'Roles',
              options: _c.signRoles,
              selected: _roleCodes,
            ),
          ),
        ],
        if (_audience == 'residences') ...[
          const SizedBox(height: 12),
          HandoverSelect(
            label: 'Residences',
            value: _labelsFor(
              _residenceIds,
              [
                for (final o in _c.directoryFor('residence'))
                  HrSignOption(id: o.id, label: o.name),
              ],
            ),
            placeholder: 'Choose residences',
            required: true,
            onTap: () => _toggleMulti(
              title: 'Residences',
              options: [
                for (final o in _c.directoryFor('residence'))
                  HrSignOption(id: o.id, label: o.name),
              ],
              selected: _residenceIds,
            ),
          ),
        ],
        if (_audience == 'users') ...[
          const SizedBox(height: 12),
          HandoverSelect(
            label: 'People',
            value: _labelsFor(_userIds, _c.signUsers),
            placeholder: 'Choose people',
            required: true,
            onTap: () => _toggleMulti(
              title: 'People',
              options: _c.signUsers,
              selected: _userIds,
            ),
          ),
        ],
        if (_mode == 'sequential') ...[
          const SizedBox(height: 12),
          HandoverSelect(
            label: 'Approver first',
            value: _labelsFor(_approverIds, _c.signUsers),
            placeholder: 'Choose who signs first',
            required: true,
            onTap: () => _toggleMulti(
              title: 'Approver first',
              options: _c.signUsers,
              selected: _approverIds,
            ),
          ),
        ],
        const SizedBox(height: 12),
        HandoverSelect(
          label: 'Due date (optional)',
          value: _dueDate.isEmpty ? null : _dueDate,
          placeholder: 'No deadline',
          onTap: _pickDueDate,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            HandoverButton(
              label: 'Cancel',
              onPressed: _submitting
                  ? null
                  : () => setState(() {
                        _composing = false;
                        _formError = null;
                      }),
            ),
            const SizedBox(width: 8),
            HandoverButton(
              label: _submitting ? 'Sending…' : 'Send for signing',
              icon: Icons.send_outlined,
              filled: true,
              onPressed: _submitting ? null : _submitSigning,
            ),
          ],
        ),
        const SizedBox(height: 10),
      ]);
    }

    return section('Read & Sign', children, leading: Icons.draw_outlined);
  }
}

class _PreviewTabs extends StatelessWidget {
  final bool showPreview;
  final HrFileKind fileKind;
  final VoidCallback onDetails;
  final VoidCallback onPreview;

  const _PreviewTabs({
    required this.showPreview,
    required this.fileKind,
    required this.onDetails,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final kindLabel = switch (fileKind) {
      HrFileKind.pdf => 'PDF',
      HrFileKind.image => 'IMAGE',
      _ => null,
    };
    Widget tab({
      required bool selected,
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      String? badge,
    }) {
      return Expanded(
        child: Material(
          color: selected ? AppColors.secondaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: selected ? AppColors.surfaceWhite : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: handoverText(
                        context,
                        12.5,
                        weight: FontWeight.w600,
                        color: selected ? AppColors.surfaceWhite : AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (badge != null && selected) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: handoverText(
                          context,
                          10,
                          weight: FontWeight.w700,
                          color: AppColors.surfaceWhite,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          tab(
            selected: !showPreview,
            icon: Icons.description_outlined,
            label: 'Document Details',
            onTap: onDetails,
          ),
          tab(
            selected: showPreview,
            icon: Icons.visibility_outlined,
            label: 'In-App Preview',
            badge: kindLabel,
            onTap: onPreview,
          ),
        ],
      ),
    );
  }
}

class _InAppPreviewCard extends StatelessWidget {
  final String name;
  final bool downloading;
  final VoidCallback onDownload;

  const _InAppPreviewCard({
    required this.name,
    required this.downloading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return HandoverPanel(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.secondaryTeal,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: handoverText(context, 16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'This document is securely encrypted on the care home server. Click below to download or view the full file.',
            textAlign: TextAlign.center,
            style: handoverText(context, 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          HandoverButton(
            label: downloading ? 'Downloading…' : 'Download File to Device',
            icon: Icons.download_rounded,
            filled: true,
            onPressed: downloading ? null : onDownload,
          ),
        ],
      ),
    );
  }
}
