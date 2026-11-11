import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app/theme/typography.dart';

/// Navigation and action sub-header for the mobile order flow.
/// Contains the [< Back] button, current step title, and [Clear] button.
class OrderFlowHeader extends StatelessWidget {
  const OrderFlowHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onClear,
    this.showClear = true,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onClear;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 850.0;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWide ? 680.0 : double.infinity,
          ),
          child: Row(
            children: [
          // [< Back] button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: () {
                HapticFeedback.lightImpact();
                onBack();
              },
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: const Color(0xFFDDD6C9),
                    width: 1.0,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chevron_left,
                      size: 20,
                      color: Color(0xFF19293E),
                    ),
                    SizedBox(width: 2),
                    Text(
                      'Back',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF19293E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Step Title: "Current order", "Order details", etc. with smooth crossfade
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: <Widget>[...previousChildren, ?currentChild],
                );
              },
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.0, 0.15),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                title,
                key: ValueKey('header-title-$title'),
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF19293E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // [Clear] button with smooth fade
          AnimatedOpacity(
            opacity: (showClear && onClear != null) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: (showClear && onClear != null)
                ? Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.0),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onClear!();
                      },
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: const Color(0xFFEDB3AF),
                            width: 1.0,
                          ),
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB3261E),
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    ),
  ),
);
  }
}
