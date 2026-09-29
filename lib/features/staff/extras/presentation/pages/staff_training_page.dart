import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/iso_date_range.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../presentation/widgets/staff_bottom_nav_bar.dart';
import '../../../staff_shell.dart';
import 'staff_training_certificates_page.dart';
import 'staff_training_quiz_page.dart';

/// Staff Training — web `/dashboard/training`.
class StaffTrainingPage extends StatefulWidget {
  const StaffTrainingPage({super.key});

  @override
  State<StaffTrainingPage> createState() => _StaffTrainingPageState();
}

class _StaffTrainingPageState extends State<StaffTrainingPage> {
  final _api = GetIt.instance<AppApiClient>();
  bool _loading = true;
  String? _error;
  List<_TrainRow> _items = const [];

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
    final staffId = Get.find<UserSession>().staffId?.trim();
    final result = await _api.get(
      ApiEndpoints.trainingAssignments,
      query: {
        if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
        'page': 1,
        'limit': 50,
      },
      silent: true,
    );
    if (!mounted) return;
    result.when(
      success: (body) {
        final items = JsonCodec.unwrapList(body).whereType<Map>().map((raw) {
          final json = JsonCodec.asMap(raw);
          final course = JsonCodec.mapAt(json, 'course') ?? const {};
          final due = JsonCodec.dateTime(json['dueAt']);
          final completed = JsonCodec.dateTime(json['completedAt']);
          return _TrainRow(
            id: JsonCodec.stringOr(json['id'], ''),
            courseId: JsonCodec.stringOr(
              json['courseId'] ?? course['id'],
              '',
            ),
            title: JsonCodec.stringOr(
              course['title'] ?? json['courseName'],
              'Training',
            ),
            status: JsonCodec.stringOr(json['status'], ''),
            mandatory: JsonCodec.boolean(json['mandatory']) ?? false,
            dueLabel: due == null
                ? ''
                : 'Due ${IsoDateRange.formatShortDate(due.toLocal())}',
            completedLabel: completed == null
                ? ''
                : 'Completed ${IsoDateRange.formatShortDate(completed.toLocal())}',
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
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.textHeading,
                    ),
                    const Expanded(
                      child: Text(
                        'Training',
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
                    TextButton(
                      onPressed: () => Get.to(
                        () => const StaffTrainingCertificatesPage(),
                      ),
                      child: const Text('Certificates'),
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
                                    'No training assignments.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                )
                              else
                                for (final item in _items) ...[
                                  Material(
                                    color: AppColors.surfaceWhite,
                                    borderRadius: BorderRadius.circular(14),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: item.courseId.isEmpty
                                          ? null
                                          : () => Get.to(
                                                () => StaffTrainingQuizPage(
                                                  courseId: item.courseId,
                                                  courseTitle: item.title,
                                                ),
                                              ),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(14),
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
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                      color: AppColors
                                                          .textHeading,
                                                    ),
                                                  ),
                                                ),
                                                if (item.mandatory)
                                                  const Text(
                                                    'Mandatory',
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors
                                                          .urgentAmber,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              [
                                                if (item.status.isNotEmpty)
                                                  item.status,
                                                if (item.dueLabel.isNotEmpty)
                                                  item.dueLabel,
                                                if (item.completedLabel
                                                    .isNotEmpty)
                                                  item.completedLabel,
                                              ].join(' · '),
                                              style: const TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 12,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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

class _TrainRow {
  final String id;
  final String courseId;
  final String title;
  final String status;
  final bool mandatory;
  final String dueLabel;
  final String completedLabel;

  const _TrainRow({
    required this.id,
    required this.courseId,
    required this.title,
    required this.status,
    required this.mandatory,
    required this.dueLabel,
    required this.completedLabel,
  });
}
