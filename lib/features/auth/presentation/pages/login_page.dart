import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/roles/user_role.dart';
import '../../../../core/roles/user_session.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_svg_icon.dart';

/// MediFlow Care Platform login screen — UI matched to the Staff Login
/// reference. Sign-in seeds [UserSession] and routes to the chosen portal.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _primaryTeal = Color(0xFF006D68);
  static const Color _fieldBorder = Color(0xFFE4E9EF);
  static const Color _labelColor = Color(0xFF2D3748);
  static const Color _hintColor = Color(0xFFA0AEC0);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AccountType _selectedType = _AccountType.staff;
  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() {
    Get.find<UserSession>().signIn(
      role: _selectedType.role,
      displayName: _selectedType.defaultDisplayName,
    );
    Get.offAllNamed(_selectedType.route);
  }

  @override
  Widget build(BuildContext context) {
    final headerBottomRadius = ResponsiveHelper.getResponsiveRadius(context, 40);
    final overlap = ResponsiveHelper.getResponsiveHeight(context, 32);
    final topInset = MediaQuery.paddingOf(context).top;
    // Approximate header content height so the form can tuck underneath.
    final headerBodyHeight = ResponsiveHelper.getResponsiveHeight(context, 209);
    final headerHeight = topInset + headerBodyHeight;
    final formTopInset = headerHeight - overlap;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Form sits under the rounded header bottom.
            Padding(
              padding: EdgeInsets.only(top: formTopInset),
              child: Container(
                width: double.infinity,
                color: AppColors.surfaceWhite,
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 22,
                  top: overlap + ResponsiveHelper.getResponsiveHeight(context, 120),
                  bottom: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select your account type',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        color: _labelColor,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    _AccountTypeRow(
                      selected: _selectedType,
                      accent: _primaryTeal,
                      onChanged: (type) => setState(() => _selectedType = type),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
                    _FieldLabel(text: 'Email address', color: _labelColor),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                    _LoginTextField(
                      controller: _emailController,
                      hint: 'Enter your email',
                      hintColor: _hintColor,
                      borderColor: _fieldBorder,
                      focusColor: _primaryTeal,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: 'assets/icons/common/email.svg',
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    _FieldLabel(text: 'Password', color: _labelColor),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                    _LoginTextField(
                      controller: _passwordController,
                      hint: 'Enter your password',
                      hintColor: _hintColor,
                      borderColor: _fieldBorder,
                      focusColor: _primaryTeal,
                      obscureText: _obscurePassword,
                      prefixIcon: 'assets/icons/common/lock.svg',
                      suffix: GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: ResponsiveHelper.getResponsivePadding(
                            context,
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: ResponsiveHelper.getResponsiveSize(context, 20),
                            color: _hintColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    _RememberForgotRow(
                      rememberMe: _rememberMe,
                      accent: _primaryTeal,
                      onToggleRemember: () => setState(() => _rememberMe = !_rememberMe),
                      onForgotPassword: () => Get.toNamed(AppRoutes.forgotPassword),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
                    _SignInButton(
                      label: 'Sign In as ${_selectedType.label}',
                      accent: _primaryTeal,
                      onPressed: _onSignIn,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                    const _HipaaNote(accent: _primaryTeal),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 26)),
                    const _AssistanceDivider(),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                    _SupportRow(accent: _primaryTeal),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
                    const _LegalRow(),
                    SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                  ],
                ),
              ),
            ),
            // Header painted last so its bottom radius overlaps the form.
            _LoginHeader(
              bottomRadius: headerBottomRadius,
              bottomPadding: ResponsiveHelper.getResponsiveHeight(context, 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _LoginHeader extends StatelessWidget {
  final double bottomPadding;
  final double bottomRadius;

  const _LoginHeader({
    required this.bottomPadding,
    required this.bottomRadius,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = ResponsiveHelper.getResponsiveSize(context, 46);
    final logoRadius = ResponsiveHelper.getResponsiveRadius(context, 13);
    final badgeIconSize = ResponsiveHelper.getResponsiveSize(context, 22);
    final badgeIconRadius = ResponsiveHelper.getResponsiveRadius(context, 6);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.60, 1.0],
          colors: [
            Color(0xFF1E3A5F),
            Color(0xFF16293F),
            Color(0xFF0E7C7B),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1A2F).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Top-right circle shape container (light opacity).
          Positioned(
            top: -ResponsiveHelper.getResponsiveHeight(context, 100),
            right: -ResponsiveHelper.getResponsiveWidth(context, 100),
            child: Container(
              width: ResponsiveHelper.getResponsiveSize(context, 230),
              height: ResponsiveHelper.getResponsiveSize(context, 230),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Bottom-left circle shape container (light opacity teal).
          Positioned(
            bottom: -ResponsiveHelper.getResponsiveHeight(context, 90),
            left: -ResponsiveHelper.getResponsiveWidth(context, 50),
            child: Container(
              width: ResponsiveHelper.getResponsiveSize(context, 180),
              height: ResponsiveHelper.getResponsiveSize(context, 180),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveHelper.getResponsiveWidth(context, 24),
                ResponsiveHelper.getResponsiveHeight(context, 18),
                ResponsiveHelper.getResponsiveWidth(context, 24),
                bottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branding: logo + MediFlow / Care Platform
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0E7C7B),
                              Color(0xFF0A5F5E),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(logoRadius),
                        ),
                        alignment: Alignment.center,
                        child: CustomPaint(
                          size: Size(
                            ResponsiveHelper.getResponsiveSize(context, 23),
                            ResponsiveHelper.getResponsiveSize(context, 14),
                          ),
                          painter: const _PulseLinePainter(),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MediFlow',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 21),
                                color: Colors.white,
                                height: 1.05,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                            Text(
                              'Care Platform',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w400,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                                color: const Color(0xFFA8B8C4),
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 18)),

                  // Care Team Portal pill — rounded-square person icon per reference
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveHelper.getResponsiveWidth(context, 8),
                      ResponsiveHelper.getResponsiveHeight(context, 6),
                      ResponsiveHelper.getResponsiveWidth(context, 12),
                      ResponsiveHelper.getResponsiveHeight(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveRadius(context, 24),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: badgeIconSize,
                          height: badgeIconSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(badgeIconRadius),
                          ),
                          alignment: Alignment.center,
                          child: AppSvgIcon(
                            'assets/icons/daily_logs/daily_log_person.svg',
                            size: 12,
                            color: const Color(0xFF0D1B2A),
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                        Text(
                          'Care Team Portal',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w500,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 26)),

                  Text(
                    'Welcome back, Care Team',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 26),
                      color: Colors.white,
                      height: 1.18,
                      letterSpacing: -0.35,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                  Text(
                    'Stay connected with your shifts, clients, and daily care tasks.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                      color: const Color(0xFFA0AEC0),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Account type ────────────────────────────────────────────────────────────

class _AccountTypeRow extends StatelessWidget {
  final _AccountType selected;
  final Color accent;
  final ValueChanged<_AccountType> onChanged;

  const _AccountTypeRow({
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _AccountType.values.length; i++) ...[
          if (i > 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: _AccountTypeCard(
              type: _AccountType.values[i],
              selected: selected == _AccountType.values[i],
              accent: accent,
              onTap: () => onChanged(_AccountType.values[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  final _AccountType type;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.type,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 16);
    final iconBoxRadius = ResponsiveHelper.getResponsiveRadius(context, 12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: 8,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: selected? Color(0xFFF0F8F7) : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: selected ? accent : const Color(0xFFEEF1F4),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? accent.withValues(alpha: 0.12)
                    : const Color(0xFF142846).withValues(alpha: 0.06),
                blurRadius: selected ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSize(context, 42),
                height: ResponsiveHelper.getResponsiveSize(context, 42),
                decoration: BoxDecoration(
                  color: selected ? accent : const Color(0xFFF4F6F7),
                  borderRadius: BorderRadius.circular(iconBoxRadius),
                ),
                alignment: Alignment.center,
                child: _buildIcon(
                  context,
                  selected ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  type.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    color: selected ? accent : const Color(0xFF647285),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, Color color) {
    switch (type) {
      case _AccountType.manager:
        return AppSvgIcon(
          'assets/icons/common/manager.svg',
          size: ResponsiveHelper.getResponsiveSize(context, 22),
          color: color,
        );
      case _AccountType.staff:
        return AppSvgIcon(
          'assets/icons/daily_logs/daily_log_person.svg',
          size: 20,
          color: color,
        );
      case _AccountType.family:
        return AppSvgIcon(
          'assets/icons/common/family.svg',
          size: 20,
          color: color,
        );
    }
  }
}

// ── Form controls ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _FieldLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w600,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
        color: color,
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color hintColor;
  final Color borderColor;
  final Color focusColor;
  final String prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  const _LoginTextField({
    required this.controller,
    required this.hint,
    required this.hintColor,
    required this.borderColor,
    required this.focusColor,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    // Pill-shaped fields per reference.
    final radius = ResponsiveHelper.getResponsiveRadius(context, 28);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontWeight: FontWeight.w500,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w400,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          color: hintColor,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SvgPicture.asset(
            prefixIcon,
            width: ResponsiveHelper.getResponsiveSize(context, 20),
          ),
        ),
        suffixIcon: suffix,
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

class _RememberForgotRow extends StatelessWidget {
  final bool rememberMe;
  final Color accent;
  final VoidCallback onToggleRemember;
  final VoidCallback onForgotPassword;

  const _RememberForgotRow({
    required this.rememberMe,
    required this.accent,
    required this.onToggleRemember,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: GestureDetector(
            onTap: onToggleRemember,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: ResponsiveHelper.getResponsiveSize(context, 20),
                  height: ResponsiveHelper.getResponsiveSize(context, 20),
                  decoration: BoxDecoration(
                    color: rememberMe ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getResponsiveRadius(context, 5),
                    ),
                    border: Border.all(
                      color: rememberMe ? accent : const Color(0xFFA0AEC0),
                      width: 1.5,
                    ),
                  ),
                  child: rememberMe
                      ? Icon(
                          Icons.check_rounded,
                          size: ResponsiveHelper.getResponsiveSize(context, 14),
                          color: Colors.white,
                        )
                      : null,
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                Flexible(
                  child: Text(
                    'Remember me',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w500,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                      color: const Color(0xFF3A4B60),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 100)),
        GestureDetector(
          onTap: onForgotPassword,
          behavior: HitTestBehavior.opaque,
          child: Text(
            'Forgot password?',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: accent,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignInButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onPressed;

  const _SignInButton({
    required this.label,
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

class _HipaaNote extends StatelessWidget {
  final Color accent;

  const _HipaaNote({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/common/lock.svg',
          width: ResponsiveHelper.getResponsiveSize(context, 13),
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 6)),
        Flexible(
          child: Text(
            'HIPAA compliant · protected with secure encryption.',
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

class _AssistanceDivider extends StatelessWidget {
  const _AssistanceDivider();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: const Color(0xFFEEF1F4)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 12),
          child: Text(
            'Need assistance?',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              color: const Color(0xFF8A97A8),
            ),
          ),
        ),
        line,
      ],
    );
  }
}

class _SupportRow extends StatelessWidget {
  final Color accent;

  const _SupportRow({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text.rich(
        TextSpan(
          text: 'Need help? ',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: const Color(0xFF3A4B60),
          ),
          children: [
            TextSpan(
              text: 'Contact Support',
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
    );
  }
}

class _LegalRow extends StatelessWidget {
  const _LegalRow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Privacy Policy · Terms of Service',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w400,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: const Color(0xFF8A97A8),
        ),
      ),
    );
  }
}

// ── Shared bits ─────────────────────────────────────────────────────────────

enum _AccountType {
  manager(
    label: 'Manager',
    role: UserRole.hr,
    route: AppRoutes.hr,
    defaultDisplayName: 'Alex',
  ),
  staff(
    label: 'Staff',
    role: UserRole.staff,
    route: AppRoutes.staff,
    defaultDisplayName: 'Jordan',
  ),
  family(
    label: 'Family',
    role: UserRole.family,
    route: AppRoutes.family,
    defaultDisplayName: 'Sam',
  );

  final String label;
  final UserRole role;
  final String route;
  final String defaultDisplayName;

  const _AccountType({
    required this.label,
    required this.role,
    required this.route,
    required this.defaultDisplayName,
  });
}

class _PulseLinePainter extends CustomPainter {
  const _PulseLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = (size.height * 0.2).clamp(1.6, 2.4)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Clean ECG-style pulse matching the MediFlow logo tile.
    final path = Path()
      ..moveTo(0, size.height * 0.52)
      ..lineTo(size.width * 0.22, size.height * 0.52)
      ..lineTo(size.width * 0.32, size.height * 0.12)
      ..lineTo(size.width * 0.44, size.height * 0.88)
      ..lineTo(size.width * 0.56, size.height * 0.36)
      ..lineTo(size.width * 0.66, size.height * 0.52)
      ..lineTo(size.width, size.height * 0.52);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
