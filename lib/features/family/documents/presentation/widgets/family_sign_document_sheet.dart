import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';
import '../../../appointments/presentation/widgets/appointment_form_fields.dart';
import '../../domain/entities/family_document.dart';

/// Web "Confirm & Sign Document" dialog.
Future<bool?> showFamilySignDocumentSheet({
  required BuildContext context,
  required FamilyDocument document,
  required String defaultSignerName,
  required Future<bool> Function() onConfirm,
}) {
  return showAppBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    builder: (context) => _SignSheet(
      document: document,
      defaultSignerName: defaultSignerName,
      onConfirm: onConfirm,
    ),
  );
}

class _SignSheet extends StatefulWidget {
  final FamilyDocument document;
  final String defaultSignerName;
  final Future<bool> Function() onConfirm;

  const _SignSheet({
    required this.document,
    required this.defaultSignerName,
    required this.onConfirm,
  });

  @override
  State<_SignSheet> createState() => _SignSheetState();
}

class _SignSheetState extends State<_SignSheet> {
  late final TextEditingController _name;
  bool _agreed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.defaultSignerName);
    _name.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _ready => _agreed && _name.text.trim().length >= 2 && !_busy;

  Future<void> _submit() async {
    if (!_ready) return;
    setState(() => _busy = true);
    final signed = await widget.onConfirm();
    if (!mounted) return;
    setState(() => _busy = false);
    if (signed) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 12);
    final gap = SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16));
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Confirm & Sign Document',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  color: AppColors.primaryNavy,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
              Text(
                'Please review the document and provide your legal confirmation below.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                  color: AppColors.textMuted,
                  height: 1.3,
                ),
              ),
              gap,
              Container(
                padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: AppColors.searchBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.document.title,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        color: AppColors.textHeading,
                      ),
                    ),
                    Text(
                      'Electronic Signature Required',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              gap,
              InkWell(
                onTap: _busy ? null : () => setState(() => _agreed = !_agreed),
                borderRadius: BorderRadius.circular(radius),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: AppColors.searchBorder),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _agreed,
                        activeColor: AppColors.secondaryTeal,
                        onChanged: _busy ? null : (value) => setState(() => _agreed = value ?? false),
                      ),
                      Expanded(
                        child: Text(
                          'I confirm I have read and agree to this document.',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              gap,
              const AppointmentFieldLabel('Full Legal Name', required: true),
              AbsorbPointer(
                absorbing: _busy,
                child: AppointmentTextField(
                  controller: _name,
                  hint: 'Type your full legal name to confirm intent',
                ),
              ),
              const AppointmentFieldHelper(
                'By typing your full legal name, you adopt this as your legally binding electronic signature.',
              ),
              gap,
              Text(
                'Your signature is captured with your user credentials, timestamp, and network address for audit and compliance.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
              gap,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textHeading,
                        side: const BorderSide(color: AppColors.searchBorder),
                        backgroundColor: AppColors.surfaceWhite,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveHelper.getResponsiveHeight(context, 14),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                  Expanded(
                    child: FilledButton(
                      onPressed: _ready ? _submit : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        disabledBackgroundColor: AppColors.primaryNavy.withValues(alpha: 0.5),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveHelper.getResponsiveHeight(context, 14),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
                      ),
                      child: Text(
                        _busy ? 'Recording signature…' : 'Confirm & Sign',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
