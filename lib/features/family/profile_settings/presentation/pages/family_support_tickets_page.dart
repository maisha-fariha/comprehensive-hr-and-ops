import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_support_ticket.dart';
import '../controllers/family_profile_settings_controller.dart';
import '../widgets/family_profile_settings_header.dart';
import 'family_support_ticket_thread_page.dart';

/// Lists the signed-in family's support tickets from GET /family/tickets.
class FamilySupportTicketsPage extends StatefulWidget {
  const FamilySupportTicketsPage({super.key});

  @override
  State<FamilySupportTicketsPage> createState() =>
      _FamilySupportTicketsPageState();
}

class _FamilySupportTicketsPageState extends State<FamilySupportTicketsPage> {
  late final FamilyProfileSettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<FamilyProfileSettingsController>();
    _controller.loadSupportTickets();
  }

  Future<void> _createTicket() async {
    final message = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: TextField(
          controller: message,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'How can the care team help?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    final body = message.text.trim();
    message.dispose();
    if (sent != true || body.isEmpty) return;

    final ticketId = await _controller.submitSupportTicket(body);
    if (ticketId == null || !mounted) return;
    await Get.to(() => FamilySupportTicketThreadPage(ticketId: ticketId));
  }

  void _openThread(FamilySupportTicket ticket) {
    Get.to(() => FamilySupportTicketThreadPage(ticketId: ticket.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTicket,
        backgroundColor: AppColors.secondaryTeal,
        icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
        label: const Text(
          'New request',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: FamilyProfileSettingsHeader(
                onBackTap: () => Navigator.maybePop(context),
                initials: _controller.overview?.profile.initials ?? '',
                title: 'Support',
              ),
            ),
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 20,
                top: 16,
                bottom: 8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Support tickets',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 16),
                    color: const Color(0xFF1A2B48),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_controller.supportTicketsLoading.value &&
                    _controller.supportTickets.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondaryTeal,
                    ),
                  );
                }

                final error = _controller.supportTicketsError.value;
                if (error != null && _controller.supportTickets.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        all: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            error,
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
                            onPressed: _controller.loadSupportTickets,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryTeal,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final tickets = _controller.supportTickets;
                if (tickets.isEmpty) {
                  return RefreshIndicator(
                    color: AppColors.secondaryTeal,
                    onRefresh: _controller.loadSupportTickets,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height:
                              ResponsiveHelper.getResponsiveHeight(context, 80),
                        ),
                        const Center(
                          child: Text(
                            'No support tickets yet.\nTap New request to contact the care team.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.secondaryTeal,
                  onRefresh: _controller.loadSupportTickets,
                  child: ListView.separated(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: tickets.length,
                    separatorBuilder: (_, _) => SizedBox(
                      height: ResponsiveHelper.getResponsiveHeight(context, 10),
                    ),
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return _TicketRow(
                        ticket: ticket,
                        onTap: () => _openThread(ticket),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  final FamilySupportTicket ticket;
  final VoidCallback onTap;

  const _TicketRow({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveRadius(context, 16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 16),
        ),
        child: Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(context, all: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 16),
            ),
            border: Border.all(color: const Color(0xFFEEF1F4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                  color: const Color(0xFF1A2B48),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
              Text(
                [
                  ticket.status,
                  ticket.priority,
                  if (ticket.createdAtLabel.isNotEmpty) ticket.createdAtLabel,
                ].join(' · '),
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: const Color(0xFF71839B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
