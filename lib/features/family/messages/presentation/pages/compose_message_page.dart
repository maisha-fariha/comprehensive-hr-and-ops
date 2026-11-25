import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/message_care_team_sheet.dart';
import 'family_conversation_page.dart';

/// Opens the web-parity "Message Care Team" compose sheet.
///
/// Kept as a route entry for older `Get.to(ComposeMessagePage)` call sites;
/// the UI itself is the modal sheet matching web.
class ComposeMessagePage extends StatefulWidget {
  const ComposeMessagePage({super.key});

  @override
  State<ComposeMessagePage> createState() => _ComposeMessagePageState();
}

class _ComposeMessagePageState extends State<ComposeMessagePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final conversationId = await showMessageCareTeamSheet(context);
      if (!mounted) return;
      final sent = conversationId != null;
      Navigator.of(context).pop(sent);
      if (conversationId != null && conversationId.isNotEmpty) {
        Get.to(() => FamilyConversationPage(conversationId: conversationId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}
