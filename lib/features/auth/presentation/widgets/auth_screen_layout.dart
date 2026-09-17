import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../core/constants/app_colors.dart';

/// Shared auth page shell: curved [header] sits on top of [body] so the
/// header's bottom curve rests on the form, without covering header text.
///
/// Paint order matters: body first, header last. Body tucks under the curve
/// by [curveOverlap]; first form content starts [bodyGap] below the curve.
class AuthScreenLayout extends StatefulWidget {
  final Widget header;
  final Widget body;
  final double horizontalPadding;
  final double bottomPadding;

  const AuthScreenLayout({
    super.key,
    required this.header,
    required this.body,
    this.horizontalPadding = 22,
    this.bottomPadding = 28,
  });

  /// How far the white body tucks under the curved header bottom.
  static double curveOverlap(BuildContext context) {
    return ResponsiveHelper.getResponsiveHeight(context, 28).clamp(20.0, 36.0);
  }

  /// Visible space from the curve edge to the first form field.
  static double bodyGap(BuildContext context) {
    return ResponsiveHelper.getResponsiveHeight(context, 16).clamp(12.0, 22.0);
  }

  @override
  State<AuthScreenLayout> createState() => _AuthScreenLayoutState();
}

class _AuthScreenLayoutState extends State<AuthScreenLayout> {
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant AuthScreenLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  void _measureHeader() {
    if (!mounted) return;
    final box =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final height = box.size.height;
    if ((height - _headerHeight).abs() < 0.5) return;
    setState(() => _headerHeight = height);
  }

  @override
  Widget build(BuildContext context) {
    final overlap = AuthScreenLayout.curveOverlap(context);
    final gap = AuthScreenLayout.bodyGap(context);
    final fallbackHeight = MediaQuery.paddingOf(context).top +
        ResponsiveHelper.getResponsiveHeight(context, 220).clamp(190.0, 280.0);
    final headerHeight = _headerHeight > 0 ? _headerHeight : fallbackHeight;
    final formTop = (headerHeight - overlap).clamp(0.0, double.infinity);

    // Re-check after this frame (text scale / rotation / first layout).
    _scheduleMeasure();

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Body underneath — tucks under the header curve.
          Padding(
            padding: EdgeInsets.only(top: formTop),
            child: ColoredBox(
              color: AppColors.surfaceWhite,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveHelper.getResponsiveWidth(
                    context,
                    widget.horizontalPadding,
                  ),
                  overlap + gap,
                  ResponsiveHelper.getResponsiveWidth(
                    context,
                    widget.horizontalPadding,
                  ),
                  ResponsiveHelper.getResponsiveHeight(
                    context,
                    widget.bottomPadding,
                  ),
                ),
                child: widget.body,
              ),
            ),
          ),
          // Header on top so the curve sits on the body without covering text.
          KeyedSubtree(
            key: _headerKey,
            child: widget.header,
          ),
        ],
      ),
    );
  }
}
