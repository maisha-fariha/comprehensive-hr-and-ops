import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Scrolls a bottom-sheet (or page) form to the first invalid field.
///
/// Matches the web portal `scrollToFirstError` behaviour: after validation
/// fails, bring the topmost errored field (and its inline message) into view
/// once layout has settled — including after the keyboard insets change.
abstract final class FormScrollToError {
  const FormScrollToError._();

  /// Default visual order map entry: [field] → [FormFieldAnchor.keyFor].
  static Key keyFor(String field) => FormFieldAnchor.keyFor(field);

  /// Scrolls to the first entry in [fieldKeys] (visual order) that also
  /// appears in [errors]. No-ops when [errors] is empty.
  ///
  /// Call immediately after `setState` that publishes the error map so the
  /// error widgets exist on the next frame.
  static void scrollToFirstError(
    BuildContext context, {
    required Map<String, String> errors,
    required Map<String, Key> fieldKeys,
    double alignment = 0.08,
    Duration duration = const Duration(milliseconds: 280),
    Curve curve = Curves.easeOutCubic,
  }) {
    if (errors.isEmpty || fieldKeys.isEmpty) return;
    final targets = <Key>[
      for (final entry in fieldKeys.entries)
        if (errors.containsKey(entry.key)) entry.value,
    ];
    scrollToFirstField(
      context,
      targets,
      alignment: alignment,
      duration: duration,
      curve: curve,
    );
  }

  /// After the next frame, scrolls the first of [fieldKeys] found under
  /// [context] into view. Prefer [scrollToFirstError] when you have an
  /// error map; use this when callers already built an ordered key list
  /// (e.g. multi-step client wizard).
  static void scrollToFirstField(
    BuildContext context,
    Iterable<Key> fieldKeys, {
    double alignment = 0.08,
    Duration duration = const Duration(milliseconds: 280),
    Curve curve = Curves.easeOutCubic,
  }) {
    final keys = [for (final key in fieldKeys) key];
    if (keys.isEmpty) return;

    void run({required bool retryForInsets}) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final target = _firstMounted(context, keys);
        if (target == null) return;
        Scrollable.ensureVisible(
          target,
          alignment: alignment,
          duration: duration,
          curve: curve,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );
        // Keyboard / sheet height can change after the first scroll; one
        // follow-up pass keeps the field + error above the soft keyboard.
        if (retryForInsets) {
          Future<void>.delayed(duration + const Duration(milliseconds: 60), () {
            if (!context.mounted) return;
            run(retryForInsets: false);
          });
        }
      });
    }

    run(retryForInsets: true);
  }
}

/// Wraps a form field (or dynamic row) so [FormScrollToError] can find it.
///
/// Put this around the label + input + inline error so both stay visible
/// after scrolling. Safe for list-generated fields — pass a stable [field]
/// id (and optional [index] for rows).
class FormFieldAnchor extends StatelessWidget {
  final String field;
  final int? index;
  final Widget child;

  const FormFieldAnchor({
    super.key,
    required this.field,
    this.index,
    required this.child,
  });

  static Key keyFor(String field, {int? index}) =>
      ValueKey(index == null ? 'form-field-$field' : 'form-field-$field-$index');

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: keyFor(field, index: index),
      child: child,
    );
  }
}

/// Backward-compatible free function used by older call sites.
void scrollToFirstField(
  BuildContext context,
  Iterable<Key> fieldKeys, {
  double alignment = 0.08,
  Duration duration = const Duration(milliseconds: 280),
  Curve curve = Curves.easeOutCubic,
}) {
  FormScrollToError.scrollToFirstField(
    context,
    fieldKeys,
    alignment: alignment,
    duration: duration,
    curve: curve,
  );
}

/// Convenience for the common `Map<String, String> _errors` pattern.
void scrollToFirstFormError(
  BuildContext context, {
  required Map<String, String> errors,
  required Map<String, Key> fieldKeys,
  double alignment = 0.08,
  Duration duration = const Duration(milliseconds: 280),
  Curve curve = Curves.easeOutCubic,
}) {
  FormScrollToError.scrollToFirstError(
    context,
    errors: errors,
    fieldKeys: fieldKeys,
    alignment: alignment,
    duration: duration,
    curve: curve,
  );
}

BuildContext? _firstMounted(BuildContext context, List<Key> keys) {
  for (final key in keys) {
    BuildContext? found;
    void visit(Element element) {
      if (found != null) return;
      if (element.widget.key == key) {
        found = element;
        return;
      }
      element.visitChildElements(visit);
    }

    context.visitChildElements(visit);
    final target = found;
    if (target != null) return target;
  }
  return null;
}
