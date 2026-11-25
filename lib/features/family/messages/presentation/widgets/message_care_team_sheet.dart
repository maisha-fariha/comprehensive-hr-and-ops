import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../hr/clients/presentation/widgets/clients_common.dart';
import '../../../../hr/handovers/presentation/widgets/handover_common.dart';
import '../controllers/compose_message_controller.dart';
import '../pages/family_conversation_page.dart';

/// Web "Message Care Team" compose modal (`POST /family/messages`).
///
/// Returns the new conversation id when sent (may be empty), or `null` when
/// cancelled / failed.
Future<String?> showMessageCareTeamSheet(BuildContext context) {
  return showClientSheet<String>(
    context,
    const _MessageCareTeamSheet(),
  );
}

/// Opens the compose sheet, then the new thread after the sheet has closed.
Future<void> openMessageCareTeamComposer(BuildContext context) async {
  final conversationId = await showMessageCareTeamSheet(context);
  if (conversationId == null || conversationId.isEmpty) return;
  Get.to(() => FamilyConversationPage(conversationId: conversationId));
}

class _MessageCareTeamSheet extends StatefulWidget {
  const _MessageCareTeamSheet();

  @override
  State<_MessageCareTeamSheet> createState() => _MessageCareTeamSheetState();
}

class _MessageCareTeamSheetState extends State<_MessageCareTeamSheet> {
  late final ComposeMessageController _controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ComposeMessageController>()) {
      Get.delete<ComposeMessageController>(force: true);
    }
    _controller = Get.put(ComposeMessageController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<ComposeMessageController>()) {
      Get.delete<ComposeMessageController>(force: true);
    }
    super.dispose();
  }

  Future<void> _send() async {
    final conversationId = await _controller.sendMessage();
    if (!mounted || conversationId == null) return;
    Navigator.of(context).pop(conversationId);
  }

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));

    return Obx(() {
      final residents = _controller.residents.toList(growable: false);
      final selectedId = _controller.clientId.value;
      String? selectedName;
      for (final r in residents) {
        if (r.id == selectedId) {
          selectedName = r.name;
          break;
        }
      }
      final priority = _controller.priority.value;
      final busy = _controller.isSending.value || _controller.isUploading.value;

      return ClientSheetFrame(
        icon: Icons.forum_outlined,
        title: 'Message Care Team',
        description:
            'Reach out directly to the management, nursing, or activities team.',
        footer: [
          HandoverButton(
            label: 'Cancel',
            onPressed: busy ? null : () => Navigator.of(context).pop(),
          ),
          HandoverButton(
            label: _controller.isSending.value ? 'Sending…' : 'Send Message',
            filled: true,
            onPressed: !_controller.canSend ? null : _send,
          ),
        ],
        children: [
          if (_controller.formError.value != null) ...[
            ClientBanner(_controller.formError.value!, warning: true),
            gap,
          ],
          if (_controller.loadingResidents.value)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (residents.length > 1) ...[
              ClientSelect(
                label: 'Resident',
                value: selectedId ?? '',
                placeholder: 'Select resident',
                options: [for (final r in residents) (r.id, r.name)],
                enabled: !busy,
                error: _controller.clientError.value,
                onChanged: _controller.selectResident,
              ),
              // ClientSelect opens its own sheet; keep a tap path if needed.
              gap,
            ] else if (residents.length == 1) ...[
              clientFieldLabel(context, 'Resident'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.filterButtonBackground,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.searchBorder),
                ),
                child: Text(
                  selectedName ?? residents.first.name,
                  style: handoverText(context, 13.5, weight: FontWeight.w600),
                ),
              ),
              gap,
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.filterButtonBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Your message goes to the care home's manager and administration, and starts a new conversation. The resident's other family members on the portal can read it too.",
                style: handoverText(context, 12.5, color: AppColors.textMuted),
              ),
            ),
            gap,
            ClientInput(
              label: 'Subject (optional)',
              controller: _controller.subjectController,
              enabled: !busy,
              placeholder: 'e.g. Question about weekend visit or dietary change',
            ),
            gap,
            clientFieldLabel(context, 'Your message', required: true),
            TextField(
              controller: _controller.messageController,
              enabled: !busy,
              minLines: 4,
              maxLines: 8,
              onChanged: (_) {
                if (_controller.bodyError.value != null) {
                  _controller.bodyError.value = null;
                }
              },
              style: handoverText(context, 13.5),
              decoration: InputDecoration(
                isDense: true,
                hintText:
                    'Write your note or question here. The duty team reviews messages during working hours.',
                hintStyle:
                    handoverText(context, 13.5, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surfaceWhite,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(
                    color: _controller.bodyError.value == null
                        ? AppColors.searchBorder
                        : AppColors.criticalRed,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(
                    color: _controller.bodyError.value == null
                        ? AppColors.searchBorder
                        : AppColors.criticalRed,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: AppColors.secondaryTeal),
                ),
              ),
            ),
            clientFieldHelper(context, error: _controller.bodyError.value),
            gap,
            Text(
              'How soon does this need a reply?',
              style: handoverText(context, 13, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _PrioritySegment(
              value: priority,
              enabled: !busy,
              onChanged: _controller.setPriority,
            ),
            if (priority == MessageCarePriority.high) ...[
              const SizedBox(height: 8),
              Text(
                'Marked urgent for the care team. For an emergency, phone the home.',
                style: handoverText(context, 12, color: AppColors.textMuted),
              ),
            ],
            gap,
            clientFieldLabel(
              context,
              'Attachments (optional, up to ${ComposeMessageController.maxAttachments})',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: busy ? null : _controller.pickAttachment,
                icon: const Icon(
                  Icons.attach_file_rounded,
                  size: 18,
                  color: AppColors.secondaryTeal,
                ),
                label: Text(
                  'Attach a photo or file',
                  style: handoverText(
                    context,
                    13.5,
                    weight: FontWeight.w600,
                    color: AppColors.secondaryTeal,
                  ),
                ),
              ),
            ),
            if (_controller.attachments.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final file in _controller.attachments)
                    InputChip(
                      label: Text(file.fileName, overflow: TextOverflow.ellipsis),
                      onDeleted: busy
                          ? null
                          : () => _controller.removeAttachment(file),
                    ),
                ],
              ),
            ],
            if (_controller.isUploading.value) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(
                color: AppColors.secondaryTeal,
                minHeight: 2,
              ),
            ],
          ],
        ],
      );
    });
  }
}

class _PrioritySegment extends StatelessWidget {
  final MessageCarePriority value;
  final bool enabled;
  final ValueChanged<MessageCarePriority> onChanged;

  const _PrioritySegment({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.filterButtonBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.searchBorder),
      ),
      child: Row(
        children: [
          for (final option in MessageCarePriority.values)
            Expanded(
              child: GestureDetector(
                onTap: enabled ? () => onChanged(option) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == option
                        ? AppColors.textHeading
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option.label,
                    style: handoverText(
                      context,
                      12.5,
                      weight: FontWeight.w600,
                      color: value == option
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
