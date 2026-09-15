import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/repositories/staff_tasks_messages_repository.dart';

enum StaffQuickLinkKind { training, documents }

/// List pages for Quick Links that do not already have a dedicated screen
/// (Training / Documents). Notifications reuse [PortalNotificationsPage].
class StaffQuickLinkListPage extends StatefulWidget {
  final StaffQuickLinkKind kind;

  const StaffQuickLinkListPage({super.key, required this.kind});

  @override
  State<StaffQuickLinkListPage> createState() => _StaffQuickLinkListPageState();
}

class _StaffQuickLinkListPageState extends State<StaffQuickLinkListPage> {
  late final StaffTasksMessagesRepository _repository;
  bool _loading = true;
  String? _error;
  List<Map<String, String>> _items = const [];

  String get _title => switch (widget.kind) {
        StaffQuickLinkKind.training => 'Training',
        StaffQuickLinkKind.documents => 'Documents',
      };

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<StaffTasksMessagesRepository>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = switch (widget.kind) {
      StaffQuickLinkKind.training => _repository.getTrainingAssignments(),
      StaffQuickLinkKind.documents => _repository.getDocuments(),
    };
    final response = await result;
    if (!mounted) return;
    response.when(
      success: (items) {
        setState(() {
          _items = items;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryTeal),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? const Center(
                      child: Text(
                        'Nothing here yet.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.secondaryTeal,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          all: 16,
                        ),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => SizedBox(
                          height:
                              ResponsiveHelper.getResponsiveHeight(context, 8),
                        ),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textHeading,
                                  ),
                                ),
                                if ((item['subtitle'] ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      item['subtitle']!,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
