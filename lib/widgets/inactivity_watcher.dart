import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warnBefore;
  final Duration maxSession;
  final VoidCallback onTimeout;
  final void Function(Duration remaining)? onWarn;
  final VoidCallback? onActivity;
  final Widget child;

  const InactivityWatcher({
    super.key,
    required this.timeout,
    required this.onTimeout,
    required this.child,
    this.warnBefore = const Duration(seconds: 30),
    this.maxSession = const Duration(hours: 8),
    this.onWarn,
    this.onActivity,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _timer;
  Timer? _warnTimer;
  Timer? _sessionTimer;
  late DateTime _sessionStart;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _sessionStart = DateTime.now();
    _armSession();
    _restart();
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _armSession() {
    _sessionTimer?.cancel();
    final left = widget.maxSession - DateTime.now().difference(_sessionStart);
    if (left <= Duration.zero) {
      widget.onTimeout();
      return;
    }
    _sessionTimer = Timer(left, widget.onTimeout);
  }

  void _restart() {
    widget.onActivity?.call();
    _timer?.cancel();
    _warnTimer?.cancel();
    final warnAt = widget.timeout - widget.warnBefore;
    if (warnAt > Duration.zero) {
      _warnTimer = Timer(warnAt, () {
        widget.onWarn?.call(widget.warnBefore);
      });
    }
    _timer = Timer(widget.timeout, widget.onTimeout);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _timer?.cancel();
    _warnTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: widget.child,
    );
  }
}
