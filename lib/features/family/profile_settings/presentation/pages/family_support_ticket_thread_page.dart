import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_support_ticket_thread.dart';
import '../controllers/family_profile_settings_controller.dart';
import '../widgets/family_profile_settings_header.dart';

/// Support thread: GET /family/tickets/{id} + …/messages.
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
  FamilySupportTicketThread? _thread;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<FamilyProfileSettingsController>();
    _load();
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
                child: Align(
                  alignment: Alignment.centerLeft,
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
                        height:
                            ResponsiveHelper.getResponsiveHeight(context, 4),
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
          ],
        ),
      ),
    );
  }
}
