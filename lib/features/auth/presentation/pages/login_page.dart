import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/roles/user_role.dart';
import '../../../../core/roles/user_session.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_svg_icon.dart';

/// Staff / Manager / Family login screen matching the MediFlow Care Platform
/// reference. UI-only — sign-in seeds [UserSession] and routes to the chosen
/// portal (no backend auth yet).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color _headerTop = Color(0xFF0B1E30);
  static const Color _headerMid = Color(0xFF0F2A38);
  static const Color _headerBottom = Color(0xFF0C3D42);
  static const Color _primaryTeal = Color(0xFF0E6867);
  static const Color _logoTeal = Color(0xFF0F7A78);
  static const Color _fieldBorder = Color(0xFFE8EDF2);
  static const Color _cardShadow = Color(0xFF142846);

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
    final session = Get.find<UserSession>();
    session.signIn(
      role: _selectedType.role,
      displayName: _selectedType.defaultDisplayName,
    );
    Get.offAllNamed(_selectedType.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _headerTop,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ResponsiveHelper.getResponsiveRadius(context, 36)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cardShadow.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ResponsiveHelper.getResponsiveRadius(context, 36)),
                ),
                child: SingleChildScrollView(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 22,
                    top: 28,
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
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                          color: AppColors.textHeading,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                      _buildAccountTypeRow(context),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
                      _buildLabeledField(
                        context,
                        label: 'Email address',
                        child: _buildTextField(
                          context,
                          controller: _emailController,
                          hint: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline_rounded,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                      _buildLabeledField(
                        context,
                        label: 'Password',
                        child: _buildTextField(
                          context,
                          controller: _passwordController,
                          hint: 'Enter your password',
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: ResponsiveHelper.getResponsiveSize(context, 20),
                              color: AppColors.textFaint,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                      _buildRememberForgotRow(context),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 22)),
                      _buildSignInButton(context),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                      _buildHipaaNote(context),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 28)),
                      _buildAssistanceDivider(context),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 16)),
                      _buildSupportRow(context),
                      SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 14)),
                      _buildLegalRow(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final logoSize = ResponsiveHelper.getResponsiveSize(context, 48);
    final logoRadius = ResponsiveHelper.getResponsiveRadius(context, 14);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.45, 1.0],
          colors: [_headerTop, _headerMid, _headerBottom],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Soft layered orbs matching the reference atmosphere.
          Positioned(
            top: -ResponsiveHelper.getResponsiveHeight(context, 90),
            right: -ResponsiveHelper.getResponsiveWidth(context, 70),
            child: _SoftOrb(
              size: ResponsiveHelper.getResponsiveSize(context, 260),
              colors: [
                const Color(0xFF1A3A4A).withValues(alpha: 0.55),
                const Color(0xFF1A3A4A).withValues(alpha: 0.0),
              ],
            ),
          ),
          Positioned(
            top: ResponsiveHelper.getResponsiveHeight(context, 20),
            right: -ResponsiveHelper.getResponsiveWidth(context, 20),
            child: _SoftOrb(
              size: ResponsiveHelper.getResponsiveSize(context, 180),
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
          Positioned(
            bottom: -ResponsiveHelper.getResponsiveHeight(context, 70),
            left: -ResponsiveHelper.getResponsiveWidth(context, 90),
            child: _SoftOrb(
              size: ResponsiveHelper.getResponsiveSize(context, 280),
              colors: [
                const Color(0xFF147A76).withValues(alpha: 0.28),
                const Color(0xFF147A76).withValues(alpha: 0.0),
              ],
            ),
          ),
          Positioned(
            bottom: ResponsiveHelper.getResponsiveHeight(context, 10),
            right: ResponsiveHelper.getResponsiveWidth(context, 30),
            child: _SoftOrb(
              size: ResponsiveHelper.getResponsiveSize(context, 120),
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 24,
                top: 28,
                bottom: 36,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: _logoTeal,
                          borderRadius: BorderRadius.circular(logoRadius),
                          boxShadow: [
                            BoxShadow(
                              color: _logoTeal.withValues(alpha: 0.55),
                              blurRadius: 18,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: CustomPaint(
                          size: Size(
                            ResponsiveHelper.getResponsiveSize(context, 26),
                            ResponsiveHelper.getResponsiveSize(context, 16),
                          ),
                          painter: const _PulseLinePainter(),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MediFlow',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                              color: Colors.white,
                              height: 1.05,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 2)),
                          Text(
                            'Care Platform',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w400,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                              color: const Color(0xFFB7C7CF),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 20)),
                  Container(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
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
                          width: ResponsiveHelper.getResponsiveSize(context, 22),
                          height: ResponsiveHelper.getResponsiveSize(context, 22),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: AppSvgIcon(
                            'assets/icons/daily_logs/daily_log_person.svg',
                            size: 12,
                            color: _headerTop,
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
                        Text(
                          'Care Team Portal',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 4)),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 28)),
                  Text(
                    'Welcome back, Care Team',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 28),
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
                  Text(
                    'Stay connected with your shifts, clients, and daily care tasks.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w400,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: const Color(0xFFC5D0D8),
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

  Widget _buildAccountTypeRow(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _AccountType.values.length; i++) ...[
          if (i > 0) SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: _AccountTypeCard(
              type: _AccountType.values[i],
              selected: _selectedType == _AccountType.values[i],
              accent: _primaryTeal,
              onTap: () => setState(() => _selectedType = _AccountType.values[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabeledField(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: AppColors.textHeading,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
        child,
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
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
          color: AppColors.textFaint,
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: ResponsiveHelper.getResponsiveSize(context, 20),
          color: AppColors.textFaint,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: _primaryTeal, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildRememberForgotRow(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: ResponsiveHelper.getResponsiveSize(context, 20),
                height: ResponsiveHelper.getResponsiveSize(context, 20),
                decoration: BoxDecoration(
                  color: _rememberMe ? _primaryTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getResponsiveRadius(context, 5),
                  ),
                  border: Border.all(
                    color: _rememberMe ? _primaryTeal : AppColors.textFaint,
                    width: 1.5,
                  ),
                ),
                child: _rememberMe
                    ? Icon(
                        Icons.check_rounded,
                        size: ResponsiveHelper.getResponsiveSize(context, 14),
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 8)),
              Text(
                'Remember me',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textBody,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          'Forgot password?',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: _primaryTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: ResponsiveHelper.getResponsiveHeight(context, 52),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveRadius(context, 14)),
          boxShadow: [
            BoxShadow(
              color: _primaryTeal.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _onSignIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryTeal,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveRadius(context, 14),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sign In as ${_selectedType.label}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
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

  Widget _buildHipaaNote(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: ResponsiveHelper.getResponsiveSize(context, 13),
          color: AppColors.textMuted,
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
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssistanceDivider(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1, color: AppColors.dividerLight),
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
              color: AppColors.textMuted,
            ),
          ),
        ),
        line,
      ],
    );
  }

  Widget _buildSupportRow(BuildContext context) {
    return Center(
      child: Text.rich(
        TextSpan(
          text: 'Need help? ',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w400,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            color: AppColors.textBody,
          ),
          children: [
            TextSpan(
              text: 'Contact Support',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                color: _primaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalRow(BuildContext context) {
    return Center(
      child: Text(
        'Privacy Policy · Terms of Service',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w400,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11),
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

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
    final radius = ResponsiveHelper.getResponsiveRadius(context, 14);
    final iconBoxRadius = ResponsiveHelper.getResponsiveRadius(context, 10);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: 8,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected ? accent : AppColors.cardBorder,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? null
              : [
                  BoxShadow(
                    color: AppColors.shadowNavy.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          children: [
            Container(
              width: ResponsiveHelper.getResponsiveSize(context, 40),
              height: ResponsiveHelper.getResponsiveSize(context, 40),
              decoration: BoxDecoration(
                color: selected ? accent : AppColors.filterButtonBackground,
                borderRadius: BorderRadius.circular(iconBoxRadius),
              ),
              alignment: Alignment.center,
              child: _buildIcon(context, selected ? Colors.white : AppColors.textMuted),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
            Text(
              type.label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                color: selected ? accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, Color color) {
    switch (type) {
      case _AccountType.manager:
        return Icon(
          Icons.how_to_reg_outlined,
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
          'assets/icons/daily_logs/daily_log_heart.svg',
          size: 20,
          color: color,
        );
    }
  }
}

class _SoftOrb extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _SoftOrb({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
          stops: const [0.35, 1.0],
        ),
      ),
    );
  }
}

/// Simplified ECG / pulse stroke used inside the MediFlow logo tile.
class _PulseLinePainter extends CustomPainter {
  const _PulseLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.height * 0.18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..lineTo(size.width * 0.18, size.height * 0.55)
      ..lineTo(size.width * 0.30, size.height * 0.18)
      ..lineTo(size.width * 0.42, size.height * 0.82)
      ..lineTo(size.width * 0.54, size.height * 0.38)
      ..lineTo(size.width * 0.66, size.height * 0.55)
      ..lineTo(size.width, size.height * 0.55);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
