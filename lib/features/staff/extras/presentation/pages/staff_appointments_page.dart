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

/// Staff Appointments — web `/dashboard/appointments`.
class StaffAppointmentsPage extends StatefulWidget {
  const StaffAppointmentsPage({super.key});

  @override
  State<StaffAppointmentsPage> createState() => _StaffAppointmentsPageState();
}

class _StaffAppointmentsPageState extends State<StaffAppointmentsPage> {
  final _api = GetIt.instance<AppApiClient>();
  bool _loading = true;
  String? _error;
  List<_ApptRow> _items = const [];

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
      ApiEndpoints.appointments,
      query: const {'page': 1, 'limit': 50},
      silent: true,
    );
    if (!mounted) return;
    result.when(
      success: (body) {
        final items = JsonCodec.unwrapList(body).whereType<Map>().map((raw) {
          final json = JsonCodec.asMap(raw);
          final client = JsonCodec.mapAt(json, 'client');
          final residence = JsonCodec.mapAt(json, 'residence');
          final at = JsonCodec.dateTime(json['scheduledAt']);
          final type = JsonCodec.stringOr(json['type'], 'appointment');
          return _ApptRow(
            title: type.replaceAll('_', ' '),
            clientName: client == null
                ? 'Resident'
                : IsoDateRange.personName(client),
            residenceName: JsonCodec.stringOr(residence?['name'], ''),
            location: JsonCodec.stringOr(json['location'], ''),
            status: JsonCodec.stringOr(json['status'], ''),
            notes: JsonCodec.stringOr(json['notes'], ''),
            dateLabel: at == null
                ? '—'
                : '${at.toLocal().day.toString().padLeft(2, '0')}/'
                    '${at.toLocal().month.toString().padLeft(2, '0')}/'
                    '${at.toLocal().year} '
                    '${at.toLocal().hour.toString().padLeft(2, '0')}:'
                    '${at.toLocal().minute.toString().padLeft(2, '0')}',
          );
        }).toList();
        setState(() {
          _items = items;
          _loading = false;
        });
      },
      failure: (error) => setState(() {
        _error = error.message;
        _loading = false;
      }),
    );
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
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.textHeading,
                    ),
                    const Expanded(
                      child: Text(
                        'Appointments',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
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
                              if (_items.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'No appointments scheduled.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                )
                              else
                                for (final item in _items) ...[
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWhite,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.cardBorder,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: AppColors.textHeading,
                                                ),
                                              ),
                                            ),
                                            if (item.status.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .infoBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  item.status,
                                                  style: const TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.infoBlue,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.clientName,
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: AppColors.textHeading,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          [
                                            item.dateLabel,
                                            if (item.residenceName.isNotEmpty)
                                              item.residenceName,
                                            if (item.location.isNotEmpty)
                                              item.location,
                                          ].join(' · '),
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        if (item.notes.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            item.notes,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 12.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
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
      ),
    );
  }
}

class _ApptRow {
  final String title;
  final String clientName;
  final String residenceName;
  final String location;
  final String status;
  final String notes;
  final String dateLabel;

  const _ApptRow({
    required this.title,
    required this.clientName,
    required this.residenceName,
    required this.location,
    required this.status,
    required this.notes,
    required this.dateLabel,
  });
}
