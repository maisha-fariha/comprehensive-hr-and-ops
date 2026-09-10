import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:printing/printing.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/storage/media_store_download.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/incident_investigation_summary.dart';
import '../../domain/entities/investigation_incident.dart';
import '../../domain/repositories/incidents_repository.dart';
import '../controllers/incidents_controller.dart';
import '../pages/incident_creation_page.dart';
import 'incident_icon_style.dart';

/// Opens the Investigation Summary sheet for an Under Review card.
Future<void> showInvestigationSummarySheet(
  BuildContext context, {
  required InvestigationIncident incident,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InvestigationSummarySheet(incident: incident),
  );
}

class _InvestigationSummarySheet extends StatefulWidget {
  final InvestigationIncident incident;

  const _InvestigationSummarySheet({required this.incident});

  @override
  State<_InvestigationSummarySheet> createState() =>
      _InvestigationSummarySheetState();
}

class _InvestigationSummarySheetState
    extends State<_InvestigationSummarySheet> {
  late final IncidentsRepository _repository;
  IncidentInvestigationSummary? _summary;
  String? _error;
  bool _loading = true;
  bool _pdfBusy = false;

  @override
  void initState() {
    super.initState();
    _repository = GetIt.instance<IncidentsRepository>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result =
        await _repository.getInvestigationSummary(widget.incident.id);
    if (!mounted) return;
    result.when(
      success: (summary) {
        setState(() {
          _summary = summary;
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

  Future<void> _handlePdf({required bool forPrint}) async {
    if (_pdfBusy) return;
    setState(() => _pdfBusy = true);
    final result = await _repository.downloadCirPdf(widget.incident.id);
    if (!mounted) return;

    await result.when(
      success: (bytes) async {
        final pdfBytes = Uint8List.fromList(bytes);
        final shortId = widget.incident.id.length > 8
            ? widget.incident.id.substring(0, 8)
            : widget.incident.id;
        final fileName = 'CIR-$shortId.pdf';
        try {
          if (forPrint) {
            await Printing.layoutPdf(
              name: fileName,
              onLayout: (_) async => pdfBytes,
            );
          } else {
            // Android 10+: MediaStore Downloads (scoped storage).
            final saveResult = await MediaStoreDownload.savePdf(
              fileName: fileName,
              bytes: pdfBytes,
            );
            if (!mounted) return;
            if (saveResult.success) {
              AppSnackbar.show(
                'PDF downloaded',
                'Saved to ${saveResult.displayLocation}',
              );
            } else {
              AppSnackbar.show(
                'Could not download PDF',
                saveResult.error ?? 'Could not save the PDF to Downloads.',
              );
            }
          }
        } catch (error) {
          if (!mounted) return;
          AppSnackbar.show(
            forPrint ? 'Could not print' : 'Could not download PDF',
            error.toString(),
          );
        }
      },
      failure: (error) async {
        AppSnackbar.show(
          forPrint ? 'Could not print' : 'Could not download PDF',
          error.message,
        );
      },
    );

    if (mounted) setState(() => _pdfBusy = false);
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.92;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 20),
            ),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            Container(
              width: ResponsiveHelper.getResponsiveWidth(context, 40),
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.searchBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Expanded(child: _body()),
            _Footer(
              onClose: _close,
              onEdit: () async {
                final incidentId = widget.incident.id;
                _close();
                final updated = await Get.to<bool>(
                  () => IncidentCreationPage(editIncidentId: incidentId),
                );
                if (updated == true &&
                    Get.isRegistered<IncidentsController>()) {
                  await Get.find<IncidentsController>().refresh();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondaryTeal),
      );
    }
    if (_error != null || _summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Could not load investigation.',
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
      );
    }

    final summary = _summary!;
    final iconStyle = IncidentIconStyle.forKind(summary.iconKind);

    return ListView(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 20,
        top: 12,
        bottom: 16,
      ),
      children: [
        _Header(
          title: summary.title,
          meta: summary.headerMeta,
          iconStyle: iconStyle,
          onClose: _close,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
        _DetailsCard(summary: summary),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        _DescriptionCard(description: summary.description),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        _ReportFormCard(
          sections: summary.formSections,
          pdfBusy: _pdfBusy,
          onPrint: () => _handlePdf(forPrint: true),
          onDownload: () => _handlePdf(forPrint: false),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
        _StatusCard(statusLabel: summary.statusLabel),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String meta;
  final IncidentIconStyle iconStyle;
  final VoidCallback onClose;

  const _Header({
    required this.title,
    required this.meta,
    required this.iconStyle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final iconBox = ResponsiveHelper.getResponsiveSize(context, 44);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconBox,
          height: iconBox,
          decoration: BoxDecoration(
            color: iconStyle.background,
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 12),
            ),
          ),
          alignment: Alignment.center,
          child: iconStyle.asset != null
              ? AppSvgIcon(iconStyle.asset!, size: 22, color: iconStyle.color)
              : Icon(
                  iconStyle.materialIcon ?? Icons.shield_outlined,
                  size: ResponsiveHelper.getResponsiveSize(context, 22),
                  color: iconStyle.color,
                ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 18),
                  color: AppColors.textHeading,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
              Text(
                meta,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.surfaceWhite,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.searchBorder),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onClose,
            child: SizedBox(
              width: ResponsiveHelper.getResponsiveSize(context, 36),
              height: ResponsiveHelper.getResponsiveSize(context, 36),
              child: Icon(
                Icons.close_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 18),
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final IncidentInvestigationSummary summary;

  const _DetailsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Incident Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: 'CLIENT', value: summary.clientName),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          _DetailRow(label: 'RESIDENCE', value: summary.residenceName),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          _DetailRow(label: 'REPORTED', value: summary.reportedAtLabel),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          _DetailRow(label: 'REPORTED BY', value: summary.reportedByName),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String statusLabel;

  const _StatusCard({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Status',
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.urgentBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 7),
                height: ResponsiveHelper.getResponsiveSize(context, 7),
                decoration: const BoxDecoration(
                  color: AppColors.eveningIndicator,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              Text(
                statusLabel,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.eveningIndicator,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String description;

  const _DescriptionCard({required this.description});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Description',
      child: Text(
        description,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w400,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }
}

class _ReportFormCard extends StatelessWidget {
  final List<CirFormSection> sections;
  final bool pdfBusy;
  final VoidCallback onPrint;
  final VoidCallback onDownload;

  const _ReportFormCard({
    required this.sections,
    required this.pdfBusy,
    required this.onPrint,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Report form',
      titleTrailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillButton(
            label: 'Print',
            icon: Icons.print_outlined,
            filled: false,
            onTap: pdfBusy ? null : onPrint,
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
          _PillButton(
            label: 'Download PDF',
            icon: Icons.download_outlined,
            filled: true,
            onTap: pdfBusy ? null : onDownload,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'As filed. The form is stored with the report, so this is what was asked at the time.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          for (final section in sections) ...[
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
            Text(
              section.title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                color: AppColors.textHeading,
              ),
            ),
            if (section.fields.isEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: ResponsiveHelper.getResponsiveHeight(context, 8),
                ),
                child: Text(
                  'No filed answers in this section.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                    color: AppColors.textMuted,
                  ),
                ),
              )
            else
              for (final field in section.fields) ...[
                SizedBox(
                  height: ResponsiveHelper.getResponsiveHeight(context, 12),
                ),
                _DetailRow(label: field.label.toUpperCase(), value: field.value),
              ],
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? titleTrailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.titleTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.searchBorder),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 15),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              if (titleTrailing != null) titleTrailing!,
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
            letterSpacing: 0.4,
            color: AppColors.textMuted,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: AppColors.textHeading,
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.filled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: filled
          ? (enabled
              ? AppColors.primaryNavy
              : AppColors.primaryNavy.withValues(alpha: 0.5))
          : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveRadius(context, 10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 10),
        ),
        child: Container(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 10),
            ),
            border: filled ? null : Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: ResponsiveHelper.getResponsiveSize(context, 14),
                color: filled ? Colors.white : AppColors.textHeading,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                  color: filled ? Colors.white : AppColors.textHeading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onEdit;

  const _Footer({required this.onClose, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 20,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: _FooterButton(
                  label: 'Close',
                  filled: false,
                  onTap: onClose,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
              Expanded(
                child: _FooterButton(
                  label: 'Edit',
                  filled: true,
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final bool filled;
  final IconData? icon;
  final VoidCallback? onTap;

  const _FooterButton({
    required this.label,
    required this.filled,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primaryNavy : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveRadius(context, 12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 12),
        ),
        child: Container(
          alignment: Alignment.center,
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 12),
            ),
            border: filled ? null : Border.all(color: AppColors.searchBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: ResponsiveHelper.getResponsiveSize(context, 16),
                  color: filled ? Colors.white : AppColors.textHeading,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 14),
                  color: filled ? Colors.white : AppColors.textHeading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
