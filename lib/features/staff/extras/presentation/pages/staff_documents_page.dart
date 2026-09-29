import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';

/// Staff Documents Management — web `/dashboard/documents`.
class StaffDocumentsPage extends StatefulWidget {
  const StaffDocumentsPage({super.key});

  @override
  State<StaffDocumentsPage> createState() => _StaffDocumentsPageState();
}

class _StaffDocumentsPageState extends State<StaffDocumentsPage> {
  final _api = GetIt.instance<AppApiClient>();
  bool _loading = true;
  String? _error;
  Map<String, int> _summary = const {};
  List<_DocRow> _items = const [];

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
    final summary = await _api.get(ApiEndpoints.documentsSummary, silent: true);
    final list = await _api.get(
      ApiEndpoints.documents,
      query: const {'page': 1, 'limit': 50},
      silent: true,
    );
    if (!mounted) return;

    String? err;
    summary.when(
      success: (body) {
        final map = JsonCodec.unwrapMap(body);
        _summary = {
          'documents': JsonCodec.integerOr(map['documents'], 0),
          'expiringSoon': JsonCodec.integerOr(map['expiringSoon'], 0),
          'expired': JsonCodec.integerOr(map['expired'], 0),
          'restricted': JsonCodec.integerOr(map['restricted'], 0),
        };
      },
      failure: (e) => err ??= e.message,
    );
    list.when(
      success: (body) {
        _items = JsonCodec.unwrapList(body).whereType<Map>().map((raw) {
          final json = JsonCodec.asMap(raw);
          final at = JsonCodec.dateTime(json['createdAt']);
          return _DocRow(
            name: JsonCodec.stringOr(json['name'], 'Document'),
            status: JsonCodec.stringOr(json['status'], ''),
            visibility: JsonCodec.stringOr(json['visibility'], ''),
            ownerType: JsonCodec.stringOr(json['ownerType'], ''),
            dateLabel: at == null
                ? ''
                : IsoDateRange.formatShortDate(at.toLocal()),
          );
        }).toList();
      },
      failure: (e) => err ??= e.message,
    );

    setState(() {
      _loading = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      bottomNavigationBar: StaffBottomNavBar(
        currentIndex: 4,
        onTap: (i) => Get.offAll(() => StaffShell(initialIndex: i)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _PageHeader(
              title: 'Documents Management',
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondaryTeal,
                      ),
                    )
                  : _error != null && _items.isEmpty
                      ? Center(child: Text(_error!))
                      : RefreshIndicator(
                          color: AppColors.secondaryTeal,
                          onRefresh: _load,
                          child: ListView(
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              horizontal: 16,
                              vertical: 12,
                            ),
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _Metric(
                                      label: 'Documents',
                                      value: '${_summary['documents'] ?? 0}',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _Metric(
                                      label: 'Expiring',
                                      value: '${_summary['expiringSoon'] ?? 0}',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _Metric(
                                      label: 'Restricted',
                                      value: '${_summary['restricted'] ?? 0}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'No documents yet.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                )
                              else
                                for (final item in _items) ...[
                                  _DocCard(item: item),
                                  const SizedBox(height: 10),
                                ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocRow {
  final String name;
  final String status;
  final String visibility;
  final String ownerType;
  final String dateLabel;

  const _DocRow({
    required this.name,
    required this.status,
    required this.visibility,
    required this.ownerType,
    required this.dateLabel,
  });
}

class _DocCard extends StatelessWidget {
  final _DocRow item;

  const _DocCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            item.name,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              if (item.status.isNotEmpty) item.status,
              if (item.ownerType.isNotEmpty) item.ownerType,
              if (item.visibility.isNotEmpty) item.visibility,
              if (item.dateLabel.isNotEmpty) item.dateLabel,
            ].join(' · '),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _PageHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceWhite,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textHeading,
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textHeading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
