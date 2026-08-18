import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../widgets/auth_curved_header.dart';

/// OTP / "Verify your email" screen matched to the OTP Verification reference.
/// UI only — Verify is a no-op for now.
class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  static const Color _primaryTeal = Color(0xFF126868);
  static const int _otpLength = 6;
  static const int _resendSeconds = 29;

  late final String _email;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  Timer? _timer;
  int _secondsLeft = _resendSeconds;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is String && args.trim().isNotEmpty) {
      _email = args.trim();
    } else if (args is Map && args['email'] is String) {
      _email = (args['email'] as String).trim().isNotEmpty
          ? (args['email'] as String).trim()
          : 'alex@sunrisehome.com';
    } else {
      _email = 'alex@sunrisehome.com';
    }

    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  String get _timerLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _onOtpChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 1) {
      for (var i = 0; i < _otpLength; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, _otpLength) - 1;
      _focusNodes[next.clamp(0, _otpLength - 1)].requestFocus();
      setState(() {});
      return;
    }

    if (_controllers[index].text != digits) {
      _controllers[index].text = digits;
      _controllers[index].selection = TextSelection.collapsed(offset: digits.length);
    }

    if (digits.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (digits.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _onResend() {
    if (_secondsLeft > 0) return;
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final headerBottomRadius = ResponsiveHelper.getResponsiveRadius(context, 40);
    final overlap = ResponsiveHelper.getResponsiveHeight(context, 32);
    final topInset = MediaQuery.paddingOf(context).top;
    // back + gaps + icon + title + email lines + bottom pad
    final headerBodyHeight = ResponsiveHelper.getResponsiveHeight(context, 209);
    final formTopInset = topInset + headerBodyHeight - overlap;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(top: formTopInset),
              child: Container(
                width: double.infinity,
                color: AppColors.surfaceWhite,
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 22,
                  top: overlap + ResponsiveHelper.getResponsiveHeight(context, 150),
                  bottom: 32,
                ),
                child: Column(
                  children: [
                    _OtpInputRow(
                      controllers: _controllers,
                      focusNodes: _focusNodes,
                      accent: _primaryTeal,
                      onChanged: _onOtpChanged,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                    _ResendRow(
                      secondsLeft: _secondsLeft,
                      timerLabel: _timerLabel,
                      onResend: _onResend,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 24)),
                    _VerifyButton(accent: _primaryTeal, onPressed: () {}),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                    const _SecurityNote(),
                  ],
                ),
              ),
            ),
            _OtpHeader(
              email: _email,
              bottomRadius: headerBottomRadius,
              bottomPadding: ResponsiveHelper.getResponsiveHeight(context, 36),
              onBack: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpHeader extends StatelessWidget {
  final String email;
  final double bottomPadding;
  final double bottomRadius;
  final VoidCallback onBack;

  const _OtpHeader({
    required this.email,
    required this.bottomPadding,
    required this.bottomRadius,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = ResponsiveHelper.getResponsiveSize(context, 52);
    final iconRadius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final backSize = ResponsiveHelper.getResponsiveSize(context, 40);

    return AuthCurvedHeader(
      bottomPadding: bottomPadding,
      bottomRadius: bottomRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: backSize,
              height: backSize,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 12),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: ResponsiveHelper.getResponsiveSize(context, 26),
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: const Color(0xFF126868),
              borderRadius: BorderRadius.circular(iconRadius),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF126868).withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.mark_email_unread_outlined,
              color: Colors.white,
              size: ResponsiveHelper.getResponsiveSize(context, 26),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          Text(
            'Verify your email',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 26),
              color: Colors.white,
              height: 1.15,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
          Text(
            'Enter the 6-digit code sent to',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
              color: const Color(0xFFD1D5DB),
              height: 1.4,
            ),
          ),
          Text(
            email,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpInputRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final Color accent;
  final void Function(int index, String value) onChanged;

  const _OtpInputRow({
    required this.controllers,
    required this.focusNodes,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final boxHeight = ResponsiveHelper.getResponsiveSize(context, 52);
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final gap = ResponsiveHelper.getResponsiveWidth(context, 8);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGaps = gap * (controllers.length - 1);
        final boxWidth = ((constraints.maxWidth - totalGaps) / controllers.length)
            .clamp(36.0, ResponsiveHelper.getResponsiveSize(context, 52));

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < controllers.length; i++)
              SizedBox(
                width: boxWidth,
                height: boxHeight,
                child: TextField(
                  controller: controllers[i],
                  focusNode: focusNodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: i == controllers.length - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                    color: AppColors.textPrimary,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (value) => onChanged(i, value),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surfaceWhite,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radius),
                      borderSide: const BorderSide(color: Color(0xFFE8EDF2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radius),
                      borderSide: const BorderSide(color: Color(0xFFE8EDF2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radius),
                      borderSide: BorderSide(color: accent, width: 1.5),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ResendRow extends StatelessWidget {
  final int secondsLeft;
  final String timerLabel;
  final VoidCallback onResend;

  const _ResendRow({
    required this.secondsLeft,
    required this.timerLabel,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final canResend = secondsLeft <= 0;

    return Center(
      child: GestureDetector(
        onTap: canResend ? onResend : null,
        behavior: HitTestBehavior.opaque,
        child: Text.rich(
          TextSpan(
            text: "Didn't get the code? ",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: const Color(0xFF8A97A8),
            ),
            children: [
              if (canResend)
                TextSpan(
                  text: 'Resend',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: const Color(0xFF126868),
                  ),
                )
              else ...[
                TextSpan(
                  text: 'Resend in ',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: const Color(0xFF647285),
                  ),
                ),
                TextSpan(
                  text: timerLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ],
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onPressed;

  const _VerifyButton({
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 15);

    return SizedBox(
      width: double.infinity,
      height: ResponsiveHelper.getResponsiveHeight(context, 52),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.38),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Verify',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Icon(
                Icons.check_rounded,
                size: ResponsiveHelper.getResponsiveSize(context, 20),
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: ResponsiveHelper.getResponsiveSize(context, 13),
          color: const Color(0xFF2E8C58),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
        Flexible(
          child: Text(
            'Your information is protected with secure encryption',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
              color: const Color(0xFF8A97A8),
            ),
          ),
        ),
      ],
    );
  }
}
