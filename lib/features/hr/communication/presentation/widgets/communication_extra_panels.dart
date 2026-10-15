import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_error_dialog.dart';
import '../../../../../core/roles/user_session.dart';
import '../../domain/repositories/communication_repository.dart';

class AnnouncementsPanel extends StatefulWidget {
  final CommunicationRepository repository;

  const AnnouncementsPanel({super.key, required this.repository});

  @override
  State<AnnouncementsPanel> createState() => _AnnouncementsPanelState();
}

class _AnnouncementsPanelState extends State<AnnouncementsPanel> {
  bool _loading = true;
  String? _error;
  String _view = 'feed';
  int _unread = 0;
  List<HrAnnouncement> _items = const [];

  bool get _canSend {
    if (!Get.isRegistered<UserSession>()) return false;
    final session = Get.find<UserSession>();
    if (!session.canWriteMessaging) return false;
    final raw = (session.roleRaw ?? '')
        .toLowerCase()
        .replaceAll('-', '_')
        .split(RegExp(r'[^a-z_]+'))
        .where((part) => part.isNotEmpty);
    return raw.any(
      (role) =>
          role == 'tenant_admin' || role == 'manager' || role == 'residence_manager',
    );
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
    final result = await widget.repository.getAnnouncements(view: _view);
    if (!mounted) return;
    result.when(
      success: (feed) => setState(() {
        _items = feed.items;
        _unread = feed.unreadCount;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = error.message;
        _loading = false;
      }),
    );
  }

  void _selectView(String view) {
    if (_view == view) return;
    setState(() => _view = view);
    _load();
  }

  Future<void> _markRead(HrAnnouncement item) async {
    final result = await widget.repository.markAnnouncementRead(item.id);
    if (!mounted) return;
    result.when(
      success: (_) => _load(),
      failure: (error) => AppErrorDialog.showResultError(
        error,
        fallbackTitle: 'Could not mark as read',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final forMe = _view == 'feed'
        ? (_unread > 0 ? 'For me ($_unread unread)' : 'For me')
        : 'For me';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ViewChip(
                label: forMe,
                selected: _view == 'feed',
                onTap: () => _selectView('feed'),
              ),
              if (_canSend)
                _ViewChip(
                  label: 'Sent by me',
                  selected: _view == 'sent',
                  onTap: () => _selectView('sent'),
                ),
            ],
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _MessageState(message: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return _MessageState(
        title: _view == 'sent' ? 'You have not sent an announcement' : 'No announcements',
        message: 'Announcements from management appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.read ? AppColors.surfaceWhite : const Color(0xFFF3FBFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textHeading,
                      ),
                    ),
                    if (item.important) const _Pill(label: 'Important'),
                    if (!item.read) const _Pill(label: 'New'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.authorName} · ${item.createdLabel} · To ${item.audienceLabel}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (!item.read) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _markRead(item),
                    icon: const Icon(Icons.done_all, size: 14),
                    label: const Text('Mark as read'),
                  ),
                ],
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.body,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13.5,
                      color: AppColors.textHeading,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class CommunicationLogPanel extends StatefulWidget {
  final CommunicationRepository repository;
  final ValueChanged<String>? onOpenConversation;

  const CommunicationLogPanel({
    super.key,
    required this.repository,
    this.onOpenConversation,
  });

  @override
  State<CommunicationLogPanel> createState() => _CommunicationLogPanelState();
}

class _CommunicationLogPanelState extends State<CommunicationLogPanel> {
  bool _loading = true;
  String? _error;
  List<CommunicationLogEntry> _items = const [];

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
    final result = await widget.repository.getCommunicationLogs();
    if (!mounted) return;
    result.when(
      success: (items) => setState(() {
        _items = items;
        _loading = false;
      }),
      failure: (error) => setState(() {
        _error = error.message;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _MessageState(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return const _MessageState(message: 'No communications match.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 8),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Material(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: item.conversationId == null
                  ? null
                  : () => widget.onOpenConversation?.call(item.conversationId!),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.whenLabel,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.sender} → ${item.recipient} · ${item.typeLabel}',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (item.preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.preview,
                        style: const TextStyle(fontFamily: 'Manrope', fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ViewChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.secondaryTeal : const Color(0xFFEEF1F5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: label == 'Important' ? const Color(0xFFFDECEC) : const Color(0xFFE8F4F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: label == 'Important' ? AppColors.criticalRed : AppColors.secondaryTeal,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;

  const _MessageState({required this.message, this.title, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Text(
                title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
