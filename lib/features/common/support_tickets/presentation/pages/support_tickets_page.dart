import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/formatting/web_formats.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../hr/handovers/presentation/widgets/handover_common.dart';

/// Web "Support & Tickets" — GET/POST `/tickets` (tenant care-provider channel).
///
/// Distinct from `/support/tickets` (provider → platform owner).
class SupportTicketsPage extends StatefulWidget {
  const SupportTicketsPage({super.key});

  @override
  State<SupportTicketsPage> createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends State<SupportTicketsPage> {
  final _api = GetIt.instance<AppApiClient>();
  bool _loading = true;
  String? _error;
  List<_TicketRow> _tickets = const [];

  bool get _canCreate {
    if (!Get.isRegistered<UserSession>()) return true;
    final s = Get.find<UserSession>();
    return s.can('tickets:create') || s.can('tickets:write');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _api.get(
      ApiEndpoints.tickets,
      query: const {'page': 1, 'limit': 50},
      silent: true,
    );
    if (!mounted) return;
    result.when(
      success: (body) {
        setState(() {
          _tickets = _TicketRow.listFrom(body);
          _loading = false;
        });
      },
      failure: (error) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      },
    );
  }

  Future<void> _create() async {
    final draft = await showAppPopup<_NewTicketDraft>(
      context: context,
      builder: (_) => const _NewTicketDialog(),
    );
    if (draft == null || !mounted) return;
    final result = await _api.post(
      ApiEndpoints.tickets,
      data: {'subject': draft.subject, 'body': draft.body},
      silent: true,
      allowQueue: false,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        AppSnackbar.show('Ticket submitted', draft.subject);
        _load();
      },
      failure: (error) => AppSnackbar.show('Could not create ticket', error.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: _create,
              backgroundColor: AppColors.secondaryTeal,
              icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
              label: const Text(
                'New ticket',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.surfaceWhite,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textHeading,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Support & Tickets',
                        style: handoverText(context, 18, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading && _tickets.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  )
                : _error != null && _tickets.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: handoverText(
                                  context,
                                  14,
                                  color: AppColors.criticalRed,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : AppRefreshIndicator(
                        color: AppColors.secondaryTeal,
                        onRefresh: _load,
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(
                            ResponsiveHelper.getResponsiveWidth(context, 16),
                            16,
                            ResponsiveHelper.getResponsiveWidth(context, 16),
                            88,
                          ),
                          children: [
                            if (_tickets.isEmpty)
                              HandoverPanel(
                                padding: const EdgeInsets.all(28),
                                child: Text(
                                  'No support tickets yet.',
                                  textAlign: TextAlign.center,
                                  style: handoverText(
                                    context,
                                    14,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              )
                            else
                              for (final ticket in _tickets) ...[
                                HandoverPanel(
                                  child: InkWell(
                                    onTap: () => Get.to(
                                      () => SupportTicketThreadPage(
                                        ticketId: ticket.id,
                                        subject: ticket.subject,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ticket.subject,
                                          style: handoverText(
                                            context,
                                            15,
                                            weight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          [
                                            ticket.statusLabel,
                                            if (ticket.priority.isNotEmpty)
                                              ticket.priority,
                                            if (ticket.createdLabel.isNotEmpty)
                                              ticket.createdLabel,
                                          ].join(' · '),
                                          style: handoverText(
                                            context,
                                            12.5,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class SupportTicketThreadPage extends StatefulWidget {
  final String ticketId;
  final String subject;

  const SupportTicketThreadPage({
    super.key,
    required this.ticketId,
    required this.subject,
  });

  @override
  State<SupportTicketThreadPage> createState() =>
      _SupportTicketThreadPageState();
}

class _SupportTicketThreadPageState extends State<SupportTicketThreadPage> {
  final _api = GetIt.instance<AppApiClient>();
  final _reply = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<_TicketMessage> _messages = const [];

  bool get _canReply {
    if (!Get.isRegistered<UserSession>()) return true;
    final s = Get.find<UserSession>();
    return s.can('tickets:reply') ||
        s.can('tickets:create') ||
        s.can('tickets:write');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _api.get(
      ApiEndpoints.ticketMessages(widget.ticketId),
      silent: true,
    );
    if (!mounted) return;
    result.when(
      success: (body) {
        setState(() {
          _messages = _TicketMessage.listFrom(body);
          _loading = false;
        });
      },
      failure: (error) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      },
    );
  }

  Future<void> _send() async {
    final body = _reply.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    final result = await _api.post(
      ApiEndpoints.ticketMessages(widget.ticketId),
      data: {'body': body},
      silent: true,
      allowQueue: false,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    result.when(
      success: (_) {
        _reply.clear();
        _load();
      },
      failure: (error) => AppSnackbar.show('Could not send reply', error.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.surfaceWhite,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textHeading,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: handoverText(context, 17, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  )
                : _error != null && _messages.isEmpty
                    ? Center(child: Text(_error!))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final m = _messages[index];
                          return HandoverPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.body,
                                  style: handoverText(context, 14),
                                ),
                                if (m.sentLabel.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    m.sentLabel,
                                    style: handoverText(
                                      context,
                                      11.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
          if (_canReply)
            SafeArea(
              top: false,
              child: ColoredBox(
                color: AppColors.surfaceWhite,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reply,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Reply…',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _send,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.secondaryTeal,
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TicketRow {
  final String id;
  final String subject;
  final String status;
  final String priority;
  final String createdLabel;

  const _TicketRow({
    required this.id,
    required this.subject,
    required this.status,
    required this.priority,
    required this.createdLabel,
  });

  String get statusLabel {
    final s = status.trim();
    if (s.isEmpty) return 'Open';
    return s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');
  }

  static List<_TicketRow> listFrom(dynamic body) {
    return [
      for (final item in JsonCodec.unwrapList(body))
        if (item is Map)
          () {
            final json = JsonCodec.asMap(item);
            final id = JsonCodec.stringOr(json['id'], '');
            if (id.isEmpty) return null;
            final at = JsonCodec.dateTime(json['createdAt'] ?? json['updatedAt']);
            return _TicketRow(
              id: id,
              subject: JsonCodec.stringOr(json['subject'], 'Support request'),
              status: JsonCodec.stringOr(json['status'], 'open'),
              priority: JsonCodec.stringOr(json['priority'], ''),
              createdLabel: at == null ? '' : WebFormat.dateTime(at),
            );
          }(),
    ].whereType<_TicketRow>().toList();
  }
}

class _TicketMessage {
  final String body;
  final String sentLabel;

  const _TicketMessage({required this.body, required this.sentLabel});

  static List<_TicketMessage> listFrom(dynamic body) {
    return [
      for (final item in JsonCodec.unwrapList(body))
        if (item is Map)
          () {
            final json = JsonCodec.asMap(item);
            final text = JsonCodec.stringOr(json['body'], '');
            if (text.isEmpty) return null;
            final at = JsonCodec.dateTime(json['createdAt'] ?? json['sentAt']);
            return _TicketMessage(
              body: text,
              sentLabel: at == null ? '' : WebFormat.dateTime(at),
            );
          }(),
    ].whereType<_TicketMessage>().toList();
  }
}

class _NewTicketDraft {
  final String subject;
  final String body;

  const _NewTicketDraft({required this.subject, required this.body});
}

class _NewTicketDialog extends StatefulWidget {
  const _NewTicketDialog();

  @override
  State<_NewTicketDialog> createState() => _NewTicketDialogState();
}

class _NewTicketDialogState extends State<_NewTicketDialog> {
  final _subject = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetDialog(
      title: const Text('New support ticket'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _body,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Details'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final subject = _subject.text.trim();
            final body = _body.text.trim();
            if (subject.isEmpty || body.isEmpty) return;
            Navigator.of(context).pop(
              _NewTicketDraft(subject: subject, body: body),
            );
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
