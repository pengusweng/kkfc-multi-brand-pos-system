import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';

/// Renders the button loading content (spinner + optional label)
/// or smoothly switches to the idle content.
class KkfcButtonLoadingState extends StatelessWidget {
  const KkfcButtonLoadingState({
    super.key,
    required this.isLoading,
    required this.idleContent,
    this.loadingLabel,
    required this.foregroundColor,
    required this.iconSize,
    required this.textStyle,
  });

  final bool isLoading;
  final Widget idleContent;
  final String? loadingLabel;
  final Color foregroundColor;
  final double iconSize;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : KkfcMotion.durMicro,
      switchInCurve: KkfcMotion.easeOut,
      switchOutCurve: KkfcMotion.easeIn,
      child: isLoading
          ? Row(
              key: const ValueKey('button_loading'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: KkfcBorderWidth.thick,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                ),
                if (loadingLabel != null && loadingLabel!.isNotEmpty) ...[
                  const SizedBox(width: KkfcSpace.space2),
                  Flexible(
                    child: Text(
                      loadingLabel!,
                      style: textStyle.copyWith(color: foregroundColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            )
          : KeyedSubtree(
              key: const ValueKey('button_idle'),
              child: idleContent,
            ),
    );
  }
}
