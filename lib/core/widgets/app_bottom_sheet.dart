import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';

/// Shared modal sheet. Every popup in the app goes through here so the
/// system navigation bar never covers the actions.
abstract final class AppBottomSheet {
  static int _open = 0;

  /// True while a sheet opened by [showAppBottomSheet] is on screen.
  static bool get isOpen => _open > 0;

  const AppBottomSheet._();
}

/// Shows [builder] as a modal bottom sheet with the bottom system inset
/// reserved for the navigation bar.
///
/// The child's [MediaQueryData.size] height is the space above that bar, so
/// sheets that size themselves as a fraction of the screen still fit.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  RouteSettings? routeSettings,
  bool useSafeArea = true,
}) {
  AppBottomSheet._open++;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior ?? Clip.antiAlias,
    constraints: constraints,
    barrierColor: barrierColor,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    routeSettings: routeSettings,
    // Flutter's flag only insets the top. The bottom inset is applied below.
    useSafeArea: false,
    builder: (sheetContext) {
      return _BottomSafeArea(
        applyBottom: useSafeArea,
        child: Builder(builder: builder),
      );
    },
  ).whenComplete(() {
    if (AppBottomSheet._open > 0) AppBottomSheet._open--;
  });
}

/// Center popups use the same sheet. [barrierDismissible] matches [showDialog].
Future<T?> showAppPopup<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  return showAppBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: barrierDismissible,
    enableDrag: barrierDismissible,
    useRootNavigator: useRootNavigator,
    barrierColor: barrierColor,
    routeSettings: routeSettings,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      final keyboard = media.viewInsets.bottom;
      final height = math.max(0.0, media.size.height - keyboard);
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: MediaQuery(
          data: media.copyWith(size: Size(media.size.width, height)),
          child: Builder(builder: builder),
        ),
      );
    },
  );
}

/// [Get.dialog] replacement. The widget is the sheet body.
Future<T?> showAppPopupWidget<T>(
  Widget child, {
  bool barrierDismissible = true,
  Color? barrierColor,
  BuildContext? context,
}) {
  final ctx = context ?? Get.overlayContext ?? Get.context;
  if (ctx == null) return Future<T?>.value();
  return showAppPopup<T>(
    context: ctx,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    builder: (_) => child,
  );
}

/// Reserves the navigation-bar inset and tells the child the screen is only
/// as tall as the space above it.
class _BottomSafeArea extends StatelessWidget {
  const _BottomSafeArea({required this.child, required this.applyBottom});

  final Widget child;
  final bool applyBottom;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final nav = applyBottom ? media.viewPadding.bottom : 0.0;
    final safeHeight = math.max(0.0, media.size.height - nav);
    return Padding(
      padding: EdgeInsets.only(bottom: nav),
      child: MediaQuery(
        data: media.copyWith(
          size: Size(media.size.width, safeHeight),
          padding: media.padding.copyWith(bottom: 0),
          viewPadding: media.viewPadding.copyWith(bottom: 0),
        ),
        child: child,
      ),
    );
  }
}

/// Confirm / form body that used to be an [AlertDialog].
///
/// Subclasses [AlertDialog] so existing finders still match, and lays out to
/// its content so the sheet hugs the message and actions.
class AppSheetDialog extends AlertDialog {
  const AppSheetDialog({
    super.key,
    super.title,
    super.titlePadding,
    super.content,
    super.contentPadding,
    super.actions,
    super.actionsPadding,
    super.shape,
    super.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidget = title;
    final contentWidget = content;
    final actionWidgets = actions;
    return Material(
      color: backgroundColor ?? Colors.transparent,
      shape: shape,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titleWidget != null)
            Padding(
              padding: titlePadding ??
                  const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textHeading,
                ),
                child: titleWidget,
              ),
            ),
          if (contentWidget != null)
            Padding(
              padding: contentPadding ??
                  const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w400,
                  fontSize: 14.5,
                  height: 1.4,
                  color: AppColors.textBody,
                ),
                child: contentWidget,
              ),
            ),
          if (actionWidgets != null && actionWidgets.isNotEmpty)
            Padding(
              padding: actionsPadding ??
                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                overflowAlignment: OverflowBarAlignment.end,
                children: actionWidgets,
              ),
            ),
        ],
      ),
    );
  }
}

/// Body that used to be a [Dialog]. Passes bounded height through so forms
/// that flex inside the dialog keep the same layout.
class AppSheetPanel extends StatelessWidget {
  const AppSheetPanel({
    super.key,
    required this.child,
    this.backgroundColor,
    this.clipBehavior,
    this.insetPadding,
    this.shape,
  });

  final Widget child;
  final Color? backgroundColor;
  final Clip? clipBehavior;
  final EdgeInsets? insetPadding;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: insetPadding ?? EdgeInsets.zero,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        clipBehavior: clipBehavior ?? Clip.none,
        shape: shape,
        child: child,
      ),
    );
  }
}
