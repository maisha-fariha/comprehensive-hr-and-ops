import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../../domain/entities/client_summary.dart';
import '../controllers/clients_controller.dart';
import '../widgets/client_card.dart';

/// Resident profile: summary, medical info, care plan and transfer history.
class ClientDetailPage extends StatefulWidget {
  final ClientSummary client;

  const ClientDetailPage({super.key, required this.client});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  late ClientSummary _client = widget.client;
  ClientsController? _controller;
  bool _loadingDetail = true;

  @override
  void initState() {
    super.initState();
    try {
      _controller = Get.find<ClientsController>();
    } catch (_) {
      _controller = Get.put(GetIt.instance<ClientsController>());
    }
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final detail = await _controller?.loadClient(widget.client.id);
    if (!mounted) return;
    setState(() {
      if (detail != null) _client = detail;
      _loadingDetail = false;
    });
  }

  String _residenceLabel(String? id) {
    if (id == null) return '—';
    return _controller?.residenceLabel(id) ?? id;
  }

  @override
  Widget build(BuildContext context) {
    final c = _client;
    final gap = ResponsiveHelper.getResponsiveHeight(context, 12);
    final age = c.age;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: hrSubPageAppBar(context, c.fullName),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: AppDimens.screenPaddingHorizontal,
            vertical: 16,
          ),
          children: [
            ClientCard(
              client: c,
              residenceName: c.residenceId == null
                  ? c.residenceName
                  : _residenceLabel(c.residenceId),
            ),
            SizedBox(height: gap),
            HrSectionCard(
              title: 'Overview',
              child: Column(
                children: [
                  HrInfoRow(label: 'Client ID', value: c.shortId),
                  HrInfoRow(
                    label: 'Residence',
                    value: c.residenceName ?? _residenceLabel(c.residenceId),
                  ),
                  HrInfoRow(label: 'Room', value: c.room ?? '—'),
                  HrInfoRow(label: 'Care level', value: hrHumanize(c.careLevel)),
                  HrInfoRow(label: 'Status', value: hrHumanize(c.status)),
                  HrInfoRow(
                    label: 'Date of birth',
                    value: c.dateOfBirth == null
                        ? '—'
                        : '${hrFormatDate(c.dateOfBirth)}'
                            '${age == null ? '' : ' · $age years'}',
                  ),
                ],
              ),
            ),
            SizedBox(height: gap),
            HrSectionCard(
              title: 'Medical info',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _subLabel(context, 'Allergies'),
                  HrChipWrap(
                    items: c.allergies,
                    emptyLabel: 'No known allergies',
                    background: AppColors.criticalBackgroundSoft,
                    foreground: AppColors.criticalRed,
                  ),
                  SizedBox(height: gap),
                  _subLabel(context, 'Conditions'),
                  HrChipWrap(
                    items: c.conditions,
                    emptyLabel: 'No conditions recorded',
                  ),
                ],
              ),
            ),
            SizedBox(height: gap),
            HrSectionCard(
              title: 'Care plan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.carePlanGoals.isEmpty)
                    _muted(context, 'No care plan goals recorded.')
                  else
                    for (final goal in c.carePlanGoals)
                      Padding(
                        padding: ResponsiveHelper.getResponsivePadding(
                          context,
                          vertical: 4,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: AppColors.secondaryTeal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: _body(context, goal)),
                          ],
                        ),
                      ),
                  if (c.reviewCycleDays != null) ...[
                    SizedBox(height: gap),
                    _muted(context, 'Reviewed every ${c.reviewCycleDays} days'),
                  ],
                ],
              ),
            ),
            SizedBox(height: gap),
            HrSectionCard(
              title: 'Transfer history',
              child: _loadingDetail
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                    )
                  : c.transfers.isEmpty
                      ? _muted(context, 'No transfers recorded.')
                      : Column(
                          children: [
                            for (final t in c.transfers)
                              Padding(
                                padding: ResponsiveHelper.getResponsivePadding(
                                  context,
                                  vertical: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 18,
                                      color: AppColors.infoBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _body(
                                            context,
                                            t.fromResidenceId == null
                                                ? 'Placed at ${_residenceLabel(t.toResidenceId)}'
                                                : '${_residenceLabel(t.fromResidenceId)} → '
                                                    '${_residenceLabel(t.toResidenceId)}',
                                          ),
                                          _muted(
                                            context,
                                            [
                                              hrFormatDate(t.transferredAt?.toLocal()),
                                              ?t.reason,
                                            ].join(' · '),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: AppTextStyles.base(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            fontWeight: AppFontWeight.semiBold,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _body(BuildContext context, String text) => Text(
        text,
        style: AppTextStyles.base(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
          fontWeight: AppFontWeight.medium,
          color: AppColors.textHeading,
        ),
      );

  Widget _muted(BuildContext context, String text) => Text(
        text,
        style: AppTextStyles.base(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
          fontWeight: AppFontWeight.regular,
          color: AppColors.textMuted,
        ),
      );
}
