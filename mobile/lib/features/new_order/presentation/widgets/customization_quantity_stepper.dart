import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app/theme/color_tokens.dart';
import 'package:mobile/app/theme/typography.dart';

/// Stepper widget for item customization that allows:
/// 1. Directly typing the desired quantity into the numeric text field.
/// 2. Tapping or holding either button to continually increment or decrement.
class CustomizationQuantityStepper extends StatefulWidget {
  const CustomizationQuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.min = 1,
    this.max = 999,
    this.enabled = true,
    this.holdDelay = const Duration(milliseconds: 350),
    this.repeatInterval = const Duration(milliseconds: 80),
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool enabled;
  final Duration holdDelay;
  final Duration repeatInterval;

  @override
  State<CustomizationQuantityStepper> createState() =>
      _CustomizationQuantityStepperState();
}

class _CustomizationQuantityStepperState
    extends State<CustomizationQuantityStepper> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.quantity}');
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(CustomizationQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity) {
      final currentParsed = int.tryParse(_controller.text.trim());
      if (currentParsed != widget.quantity && !_focusNode.hasFocus) {
        _controller.text = '${widget.quantity}';
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitText();
    }
  }

  void _commitText() {
    final text = _controller.text.trim();
    final parsed = int.tryParse(text);
    final valid = (parsed ?? widget.min).clamp(widget.min, widget.max);
    if (_controller.text != '$valid') {
      _controller.text = '$valid';
    }
    if (valid != widget.quantity) {
      widget.onChanged(valid);
    }
  }

  void _handleTextChanged(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null && parsed >= widget.min) {
      final clamped = parsed.clamp(widget.min, widget.max);
      if (clamped != widget.quantity) {
        widget.onChanged(clamped);
      }
    }
  }

  void _stepDown() {
    if (!widget.enabled || widget.quantity <= widget.min) return;
    final next = (widget.quantity - 1).clamp(widget.min, widget.max);
    _controller.text = '$next';
    widget.onChanged(next);
  }

  void _stepUp() {
    if (!widget.enabled || widget.quantity >= widget.max) return;
    final next = (widget.quantity + 1).clamp(widget.min, widget.max);
    _controller.text = '$next';
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final canDecrement = widget.enabled && widget.quantity > widget.min;
    final canIncrement = widget.enabled && widget.quantity < widget.max;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HoldableStepperButton(
          key: const ValueKey('customize-quantity-decrement'),
          icon: Icons.remove,
          tooltip: 'Decrease quantity',
          enabled: canDecrement,
          canStep: () => widget.enabled && widget.quantity > widget.min,
          onStep: _stepDown,
          holdDelay: widget.holdDelay,
          repeatInterval: widget.repeatInterval,
        ),
        const SizedBox(width: 8),
        Container(
          width: 52,
          height: 38,
          decoration: BoxDecoration(
            color: KkfcColors.surface,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? KkfcColors.borderStrong
                  : KkfcColors.border,
              width: _focusNode.hasFocus ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: TextField(
              key: const ValueKey('customize-quantity-field'),
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onChanged: _handleTextChanged,
              onSubmitted: (_) => _commitText(),
              style: const TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: 16.0,
                fontWeight: FontWeight.w700,
                color: KkfcColors.ink,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              cursorColor: KkfcColors.ink,
              decoration: const InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        HoldableStepperButton(
          key: const ValueKey('customize-quantity-increment'),
          icon: Icons.add,
          tooltip: 'Increase quantity',
          enabled: canIncrement,
          isDarkBorder: true,
          canStep: () => widget.enabled && widget.quantity < widget.max,
          onStep: _stepUp,
          holdDelay: widget.holdDelay,
          repeatInterval: widget.repeatInterval,
        ),
      ],
    );
  }
}

/// A button that executes [onStep] on initial press and continuously repeats
/// [onStep] with haptic feedback when held down.
class HoldableStepperButton extends StatefulWidget {
  const HoldableStepperButton({
    super.key,
    required this.icon,
    required this.onStep,
    this.enabled = true,
    this.isDarkBorder = false,
    this.canStep,
    this.tooltip,
    this.holdDelay = const Duration(milliseconds: 350),
    this.repeatInterval = const Duration(milliseconds: 80),
  });

  final IconData icon;
  final VoidCallback onStep;
  final bool enabled;
  final bool isDarkBorder;
  final bool Function()? canStep;
  final String? tooltip;
  final Duration holdDelay;
  final Duration repeatInterval;

  @override
  State<HoldableStepperButton> createState() => _HoldableStepperButtonState();
}

class _HoldableStepperButtonState extends State<HoldableStepperButton> {
  Timer? _holdDelayTimer;
  Timer? _periodicTimer;
  bool _stepped = false;

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  void _stopTimers() {
    _holdDelayTimer?.cancel();
    _holdDelayTimer = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled) return;
    if (widget.canStep != null && !widget.canStep!()) return;

    _stepped = true;
    HapticFeedback.lightImpact();
    widget.onStep();

    _holdDelayTimer?.cancel();
    _holdDelayTimer = Timer(widget.holdDelay, () {
      _periodicTimer?.cancel();
      _periodicTimer = Timer.periodic(widget.repeatInterval, (timer) {
        if (!mounted ||
            !widget.enabled ||
            (widget.canStep != null && !widget.canStep!())) {
          timer.cancel();
          _periodicTimer = null;
          return;
        }
        HapticFeedback.selectionClick();
        widget.onStep();
      });
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    _stopTimers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _stepped = false;
      }
    });
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _stopTimers();
    _stepped = false;
  }

  void _handleTap() {
    if (!widget.enabled) return;
    if (!_stepped) {
      if (widget.canStep != null && !widget.canStep!()) return;
      HapticFeedback.lightImpact();
      widget.onStep();
    }
    _stepped = false;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isDarkBorder
        ? KkfcColors.borderStrong
        : KkfcColors.border;
    final iconColor = widget.enabled
        ? KkfcColors.ink
        : KkfcColors.neutralBorder;

    Widget button = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: KkfcColors.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: widget.enabled ? _handlePointerDown : null,
          onPointerUp: widget.enabled ? _handlePointerUp : null,
          onPointerCancel: widget.enabled ? _handlePointerCancel : null,
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: widget.enabled ? _handleTap : null,
            child: Center(child: Icon(widget.icon, size: 16, color: iconColor)),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}
