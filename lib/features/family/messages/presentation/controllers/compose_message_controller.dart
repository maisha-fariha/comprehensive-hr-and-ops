import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../domain/entities/family_messages_enums.dart';
import '../../domain/entities/message_recipient.dart';

/// GetX controller for the "New Message" compose screen.
///
/// This is a mock, front-end-only form: it owns simple mutable/observable
/// field state with no real validation or persistence - matching the
/// current scope of the Family Messages feature (no backend contract exists
/// yet), following the same convention as
/// `lib/features/staff/incidents/presentation/controllers/incident_creation_controller.dart`.
class ComposeMessageController extends GetxController {
  /// Preloaded with "Sarah M." to match the reference screenshot, which
  /// shows the compose screen already carrying one recipient chip.
  final RxList<MessageRecipient> recipients = <MessageRecipient>[
    const MessageRecipient(id: 'sarah-m', name: 'Sarah M.', initials: 'SM'),
  ].obs;

  final TextEditingController recipientInputController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final RxSet<MessageAttachmentType> selectedAttachments = <MessageAttachmentType>{}.obs;
  final RxBool isPriority = false.obs;

  void removeRecipient(MessageRecipient recipient) => recipients.remove(recipient);

  /// Turns whatever's currently typed in the recipient field into a new
  /// chip, then clears the field - there is no real contact directory to
  /// search against yet.
  void addRecipientFromInput() {
    final name = recipientInputController.text.trim();
    if (name.isEmpty) return;

    recipients.add(
      MessageRecipient(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        initials: _initialsFor(name),
      ),
    );
    recipientInputController.clear();
  }

  void toggleAttachment(MessageAttachmentType type) {
    if (selectedAttachments.contains(type)) {
      selectedAttachments.remove(type);
    } else {
      selectedAttachments.add(type);
    }
  }

  void togglePriority(bool value) => isPriority.value = value;

  /// Mock send action - there is no backend to persist the draft to, so this
  /// simply returns to the "Messages" list screen.
  void sendMessage() => Get.back();

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  void onClose() {
    recipientInputController.dispose();
    messageController.dispose();
    super.onClose();
  }
}
