import 'package:flutter/material.dart';

/// Builds [builder] only after the tab has been opened once, then keeps it
/// alive (IndexedStack-friendly). Unvisited tabs mount nothing → no API load.
class LazyIndexedTab extends StatefulWidget {
  final bool active;
  final WidgetBuilder builder;

  const LazyIndexedTab({
    super.key,
    required this.active,
    required this.builder,
  });

  @override
  State<LazyIndexedTab> createState() => _LazyIndexedTabState();
}

class _LazyIndexedTabState extends State<LazyIndexedTab>
    with AutomaticKeepAliveClientMixin {
  bool _built = false;

  @override
  bool get wantKeepAlive => _built;

  @override
  void initState() {
    super.initState();
    if (widget.active) _built = true;
  }

  @override
  void didUpdateWidget(covariant LazyIndexedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_built) {
      setState(() => _built = true);
      updateKeepAlive();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_built) return const SizedBox.shrink();
    return widget.builder(context);
  }
}
