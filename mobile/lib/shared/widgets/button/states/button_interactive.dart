import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

/// Interactive wrapper providing physical press feedback:
/// "Every control scales to 0.97 fast on press and returns on the spring."
/// Respects [MediaQuery.disableAnimationsOf].
class KkfcPressScaleWrapper extends StatefulWidget {
  const KkfcPressScaleWrapper({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  State<KkfcPressScaleWrapper> createState() => _KkfcPressScaleWrapperState();
}

class _KkfcPressScaleWrapperState extends State<KkfcPressScaleWrapper> {
  bool _isPressed = false;

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (!widget.enabled || reduceMotion) {
      return widget.child;
    }

    final duration = _isPressed ? KkfcMotion.durPress : KkfcMotion.durRelease;
    final curve = _isPressed ? Curves.easeOut : KkfcMotion.easeSpring;

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: AnimatedScale(
        scale: _isPressed ? KkfcMotion.pressScale : 1.0,
        duration: duration,
        curve: curve,
        child: widget.child,
      ),
    );
  }
}
