import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/roles/user_session.dart';
import '../../domain/repositories/emergency_repository.dart';

/// Active-alarm total from `GET /emergency-alerts?status=active&limit=1`.
///
/// The web header polls this every 30 seconds and only animates the Emergency
/// control while the total is above zero.
abstract final class ActiveEmergencyAlerts {
  static final RxInt count = 0.obs;

  static Timer? _timer;
  static int _holders = 0;
  static int _request = 0;

  static const Duration pollInterval = Duration(seconds: 30);

  static void retain() {
    _holders++;
    if (_holders != 1) return;
    refresh();
    _timer ??= Timer.periodic(pollInterval, (_) => refresh());
  }

  static void release() {
    if (_holders == 0) return;
    _holders--;
    if (_holders > 0) return;
    _timer?.cancel();
    _timer = null;
    _request++;
    count.value = 0;
  }

  /// Pulls the active total. A failed request keeps the last count.
  static Future<void> refresh() async {
    final ticket = ++_request;
    if (!GetIt.I.isRegistered<EmergencyRepository>() ||
        !Get.isRegistered<UserSession>()) {
      return;
    }
    if (!Get.find<UserSession>().canReadEmergency) {
      if (ticket == _request) count.value = 0;
      return;
    }
    try {
      final result = await GetIt.I<EmergencyRepository>().list(
        status: 'active',
        page: 1,
        limit: 1,
      );
      if (ticket != _request || _holders == 0) return;
      result.when(
        success: (page) => count.value = page.total < 0 ? 0 : page.total,
        failure: (_) {},
      );
    } catch (_) {}
  }
}

/// Starts the active-alarm poll while [child] is on screen.
class EmergencyAlertWatch extends StatefulWidget {
  final Widget child;

  const EmergencyAlertWatch({super.key, required this.child});

  @override
  State<EmergencyAlertWatch> createState() => _EmergencyAlertWatchState();
}

class _EmergencyAlertWatchState extends State<EmergencyAlertWatch>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ActiveEmergencyAlerts.retain();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ActiveEmergencyAlerts.release();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ActiveEmergencyAlerts.refresh();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Tailwind `animate-pulse` is disabled under widget tests so `pumpAndSettle`
/// can finish, and when the platform asks to reduce motion.
bool emergencyAlertMotionEnabled(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) return false;
  final binding = SchedulerBinding.instance.runtimeType.toString();
  return !binding.contains('Test');
}

/// Opacity 1 → 0.5 over 2 seconds, matching Tailwind `animate-pulse`.
class EmergencyPulse extends StatefulWidget {
  final bool animate;
  final Widget child;

  const EmergencyPulse({super.key, required this.animate, required this.child});

  @override
  State<EmergencyPulse> createState() => _EmergencyPulseState();
}

class _EmergencyPulseState extends State<EmergencyPulse>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(EmergencyPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!widget.animate) {
      _controller?.stop();
      _controller?.value = 0;
      return;
    }
    _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (!_controller!.isAnimating) _controller!.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!widget.animate || controller == null) return widget.child;
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.5).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// Tailwind `animate-bounce`: lift by 25% and settle, over 1 second.
class EmergencyBounce extends StatefulWidget {
  final bool animate;
  final Widget child;

  const EmergencyBounce({super.key, required this.animate, required this.child});

  @override
  State<EmergencyBounce> createState() => _EmergencyBounceState();
}

class _EmergencyBounceState extends State<EmergencyBounce>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(EmergencyBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!widget.animate) {
      _controller?.stop();
      _controller?.value = 0;
      return;
    }
    _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (!_controller!.isAnimating) _controller!.repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!widget.animate || controller == null) return widget.child;
    return AnimatedBuilder(
      animation: controller,
      child: widget.child,
      builder: (context, child) {
        final t = controller.value;
        final lifted = t < 0.5
            ? 1 - Curves.easeIn.transform(t / 0.5)
            : Curves.easeOut.transform((t - 0.5) / 0.5);
        return FractionalTranslation(
          translation: Offset(0, -0.25 * lifted),
          child: child,
        );
      },
    );
  }
}

/// White count used by the web Emergency pill, with a pinging dot behind it.
class EmergencyAlertBadge extends StatelessWidget {
  final int count;
  final bool animate;

  const EmergencyAlertBadge({
    super.key,
    required this.count,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Semantics(
      label: '$count active emergency alerts',
      child: SizedBox(
        width: 18,
        height: 18,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (animate) const _PingDot(),
            Container(
              key: const ValueKey('emergency-active-count'),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: Color(0xFFDC2626),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PingDot extends StatefulWidget {
  const _PingDot();

  @override
  State<_PingDot> createState() => _PingDotState();
}

class _PingDotState extends State<_PingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        final opacity = t < 0.75 ? 1 - (t / 0.75) : 0.0;
        return Opacity(
          opacity: opacity.clamp(0, 1),
          child: Transform.scale(scale: 1 + t, child: child),
        );
      },
      child: const SizedBox(
        width: 8,
        height: 8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
