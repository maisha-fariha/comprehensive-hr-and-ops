import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_support_ticket_thread.dart';
import '../controllers/family_profile_settings_controller.dart';
import '../widgets/family_profile_settings_header.dart';

/// Support thread: GET /family/tickets/{id} + …/messages.
/// Reply: POST /tickets/{id}/messages. Close: POST /tickets/{id}/close.
class FamilySupportTicketThreadPage extends StatefulWidget {
  final String ticketId;

  const FamilySupportTicketThreadPage({super.key, required this.ticketId});

  @override
  State<FamilySupportTicketThreadPage> createState() =>
      _FamilySupportTicketThreadPageState();
}

class _FamilySupportTicketThreadPageState
    extends State<FamilySupportTicketThreadPage> {
  late final FamilyProfileSettingsController _controller;
  final TextEditingController _replyController = TextEditingController();
  FamilySupportTicketThread? _thread;
  bool _loading = true;
  bool _sending = false;
  bool _closing = false;
  String? _error;

  bool get _isClosed {
    final status = _thread?.ticket.status.toLowerCase() ?? '';
    return status == 'closed' || status == 'resolved';
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.find<FamilyProfileSettingsController>();
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final thread =
        await _controller.loadSupportTicketThread(widget.ticketId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _thread = thread;
      if (thread == null) {
        _error = 'Could not load this support thread.';
      }
    });
  }

  Future<void> _sendReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty || _sending || _isClosed) return;
    setState(() => _sending = true);
    final ok = await _controller.replyToSupportTicket(
      ticketId: widget.ticketId,
      body: body,
    );
    if (!mounted) return;
    if (ok) {
      _replyController.clear();
      setState(() => _sending = false);
      await _load();
    } else if (mounted) {
      setState(() => _sending = false);
    }
  }

  Future<void> _closeTicket() async {
    if (_closing || _isClosed) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Close ticket?'),
        content: const Text(
          'You will not be able to send more replies on this request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Close ticket'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _closing = true);
    final ok = await _controller.closeSupportTicket(widget.ticketId);
    if (!mounted) return;
    setState(() => _closing = false);
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: FamilyProfileSettingsHeader(
                onBackTap: () => Navigator.maybePop(context),
                initials: _controller.overview?.profile.initials ?? '',
                title: 'Support thread',
              ),
            ),
            if (thread != null)
              Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 20,
                  top: 14,
                  bottom: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thread.ticket.subject,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                16,
                              ),
                              color: const Color(0xFF1A2B48),
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveHelper.getResponsiveHeight(
                              context,
                              4,
                            ),
                          ),
                          Text(
                            '${thread.ticket.status} · ${thread.ticket.priority}',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w500,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                12,
                              ),
                              color: const Color(0xFF71839B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isClosed)
                      TextButton(
                        onPressed: _closing ? null : _closeTicket,
                        child: _closing
                            ? SizedBox(
                                width: ResponsiveHelper.getResponsiveWidth(
                                  context,
                                  16,
                                ),
                                height: ResponsiveHelper.getResponsiveHeight(
                                  context,
                                  16,
                                ),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.secondaryTeal,
                                ),
                              )
                            : Text(
                                'Close',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    13,
                                  ),
                                  color: AppColors.secondaryTeal,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondaryTeal,
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              all: 24,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(
                                  height: ResponsiveHelper.getResponsiveHeight(
                                    context,
                                    12,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _load,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryTeal,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.secondaryTeal,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              horizontal: 20,
                              vertical: 12,
                            ),
                            itemCount: thread!.messages.isEmpty
                                ? 1
                                : thread.messages.length,
                            separatorBuilder: (_, _) => SizedBox(
                              height: ResponsiveHelper.getResponsiveHeight(
                                context,
                                10,
                              ),
                            ),
                            itemBuilder: (context, index) {
                              if (thread.messages.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 40),
                                  child: Center(
                                    child: Text(
                                      'No replies yet. The care team will respond here.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final message = thread.messages[index];
                              return Align(
                                alignment: message.fromFamily
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.sizeOf(context).width * 0.78,
                                  ),
                                  padding:
                                      ResponsiveHelper.getResponsivePadding(
                                    context,
                                    all: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: message.fromFamily
                                        ? const Color(0xFFE8F5F3)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveHelper.getResponsiveRadius(
                                        context,
                                        14,
                                      ),
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFEEF1F4),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.body,
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontWeight: FontWeight.w500,
                                          fontSize: ResponsiveHelper
                                              .getResponsiveFontSize(
                                            context,
                                            13.5,
                                          ),
                                          color: const Color(0xFF1A2B48),
                                          height: 1.35,
                                        ),
                                      ),
                                      if (message.sentAtLabel.isNotEmpty) ...[
                                        SizedBox(
                                          height: ResponsiveHelper
                                              .getResponsiveHeight(context, 6),
                                        ),
                                        Text(
                                          message.sentAtLabel,
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.w500,
                                            fontSize: ResponsiveHelper
                                                .getResponsiveFontSize(
                                              context,
                                              11,
                                            ),
                                            color: const Color(0xFF71839B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            if (thread != null && !_loading && _error == null)
              _isClosed
                  ? Container(
                      width: double.infinity,
                      color: AppColors.surfaceWhite,
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Text(
                        'This ticket is closed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w500,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            13,
                          ),
                          color: const Color(0xFF71839B),
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceWhite,
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              minLines: 1,
                              maxLines: 4,
                              enabled: !_sending,
                              decoration: const InputDecoration(
                                hintText: 'Reply to the care team…',
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendReply(),
                            ),
                          ),
                          IconButton(
                            onPressed: _sending ? null : _sendReply,
                            icon: _sending
                                ? SizedBox(
                                    width: ResponsiveHelper.getResponsiveWidth(
                                      context,
                                      18,
                                    ),
                                    height:
                                        ResponsiveHelper.getResponsiveHeight(
                                      context,
                                      18,
                                    ),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.secondaryTeal,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: AppColors.secondaryTeal,
                                  ),
                          ),
                        ],
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
