import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_curved_header.dart';

/// "Reset your password" screen matched to the Forgot Password reference.
/// UI only — Send Reset Link navigates to OTP verification.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const Color _primaryTeal = Color(0xFF006D68);
  static const Color _labelColor = Color(0xFF2D3748);
  static const Color _hintColor = Color(0xFFA0AEC0);
  static const Color _fieldBorder = Color(0xFFE4E9EF);
  static const Color _infoBg = Color(0xFFE8F6F5);
  static const Color _infoBorder = Color(0xFFC5E8E5);
  static const Color _infoText = Color(0xFF0E5C58);

  final _emailController = TextEditingController();
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(GetIt.instance<AuthController>());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _goBack() => Get.back();

  Future<void> _onSendResetLink() async {
    final email = _emailController.text.trim();
    final ok = await _auth.sendPasswordReset(email);
    if (!ok) {
      if (mounted && _auth.errorMessage.value.isNotEmpty) {
        Get.snackbar(
          'Reset failed',
          _auth.errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }
    Get.toNamed(
      AppRoutes.otpVerification,
      arguments: {
        'email': email.isEmpty ? 'alex@sunrisehome.com' : email,
        'purpose': 'passwordReset',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerBottomRadius = ResponsiveHelper.getResponsiveRadius(context, 40);
    final overlap = ResponsiveHelper.getResponsiveHeight(context, 32);
    final topInset = MediaQuery.paddingOf(context).top;
    // back + gaps + icon + title + subtitle + bottom pad
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email address',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                        color: _labelColor,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                    _EmailField(
                      controller: _emailController,
                      hintColor: _hintColor,
                      borderColor: _fieldBorder,
                      focusColor: _primaryTeal,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                    const _SecurityInfoBox(
                      background: _infoBg,
                      border: _infoBorder,
                      foreground: _infoText,
                      accent: _primaryTeal,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 24)),
                    Obx(
                      () => _SendResetButton(
                        accent: _primaryTeal,
                        onPressed: _auth.isBusy.value ? () {} : _onSendResetLink,
                        label: _auth.isBusy.value ? 'Sending…' : 'Send Reset Link',
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
                    _BackToSignInRow(accent: _primaryTeal, onTap: _goBack),
                  ],
                ),
              ),
            ),
            _ForgotHeader(
              bottomRadius: headerBottomRadius,
              bottomPadding: ResponsiveHelper.getResponsiveHeight(context, 36),
              onBack: _goBack,
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgotHeader extends StatelessWidget {
  final double bottomPadding;
  final double bottomRadius;
  final VoidCallback onBack;

  const _ForgotHeader({
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
              color: const Color(0xFF0C6B66),
              borderRadius: BorderRadius.circular(iconRadius),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0C6B66).withValues(alpha: 0.45),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.lock_open_rounded,
              color: Colors.white,
              size: ResponsiveHelper.getResponsiveSize(context, 26),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
          Text(
            'Reset your password',
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
            "Enter your email and we'll send you a password reset link.",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
              color: const Color(0xFFD1D5DB),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final Color hintColor;
  final Color borderColor;
  final Color focusColor;

  const _EmailField({
    required this.controller,
    required this.hintColor,
    required this.borderColor,
    required this.focusColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 28);

    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w500,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Enter your email',
        hintStyle: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w400,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          color: hintColor,
        ),
        prefixIcon: Icon(
          Icons.mail_outline_rounded,
          size: ResponsiveHelper.getResponsiveSize(context, 20),
          color: hintColor,
        ),
        filled: true,
        fillColor: AppColors.surfaceWhite,
        isDense: true,
        contentPadding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: focusColor, width: 1.4),
        ),
      ),
    );
  }
}

class _SecurityInfoBox extends StatelessWidget {
  final Color background;
  final Color border;
  final Color foreground;
  final Color accent;

  const _SecurityInfoBox({
    required this.background,
    required this.border,
    required this.foreground,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveRadius(context, 14),
        ),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: ResponsiveHelper.getResponsiveHeight(context, 1),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: ResponsiveHelper.getResponsiveSize(context, 18),
              color: accent,
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Text(
              "For your security, the reset link will expire in 30 minutes. Check your spam folder if you don't see it.",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: foreground,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SendResetButton extends StatelessWidget {
  final Color accent;
  final VoidCallback onPressed;
  final String label;

  const _SendResetButton({
    required this.accent,
    required this.onPressed,
    this.label = 'Send Reset Link',
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
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              accent,
              Color.lerp(accent, const Color(0xFF0A4F4C), 0.35)!,
            ],
          ),
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
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              const AppSvgIcon(AppAssets.chevronRight, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackToSignInRow extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _BackToSignInRow({
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Text.rich(
          TextSpan(
            text: 'Remembered it? ',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w400,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: const Color(0xFF647285),
            ),
            children: [
              TextSpan(
                text: 'Back to Sign In',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: accent,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
