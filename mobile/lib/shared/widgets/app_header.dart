import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/availability/data/models/availability_model.dart';
import 'package:mobile/shared/widgets/logout_button.dart';

/// The application top bar matching the KKFC POS design system.
///
/// Kept purely stateless: only the `'KKFC POS'` wordmark is constant,
/// while the section title, role badge, and actions vary depending
/// on the logged-in user's role.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title = 'Orders',
    this.titleWidget,
    this.role = 'Cashier Staff',
    this.onRoleTap,
    this.leading,
    this.trailing,
    this.actions,
    this.height = KkfcSizing.appBar,
    this.padding,
    this.backgroundColor,
    this.showLogout = true,
    // Legacy MenuHeader compatibility properties
    this.compact,
    this.channel,
    this.onChannelChanged,
    this.staffName,
    this.staffRole,
  });

  /// The section or screen title (e.g. 'Orders'). Defaults to 'Orders'.
  final String? title;

  /// Custom title widget, overriding [title] if provided.
  final Widget? titleWidget;

  /// Role label shown in the role badge/pill (e.g. 'Cashier Staff').
  /// Defaults to 'Cashier Staff'.
  final String? role;

  /// Callback when the role pill is tapped.
  final VoidCallback? onRoleTap;

  /// Custom leading widget placed before the 'KKFC POS' text.
  final Widget? leading;

  /// Custom trailing widget. If provided, replaces the default role pill.
  final Widget? trailing;

  /// Additional action widgets placed before the trailing / role widget.
  final List<Widget>? actions;

  /// Total height of the app header. Defaults to [KkfcSizing.appBar] (56px).
  final double height;

  /// Inset padding for the header row. Defaults to 20px horizontal.
  final EdgeInsetsGeometry? padding;

  /// Background color of the header bar. Defaults to [KkfcColors.shell] (#19293E).
  final Color? backgroundColor;

  /// Whether to display the logout button on the right side of the header.
  final bool showLogout;

  /// Legacy compatibility property from MenuHeader.
  final bool? compact;

  /// Legacy compatibility property from MenuHeader.
  final PosChannel? channel;

  /// Legacy compatibility property from MenuHeader.
  final ValueChanged<PosChannel>? onChannelChanged;

  /// Legacy compatibility property from MenuHeader.
  final String? staffName;

  /// Legacy compatibility property from MenuHeader.
  final String? staffRole;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final effectiveRole = staffRole ?? role;
    final isCompact = compact ?? (MediaQuery.sizeOf(context).width < 600);

    return Material(
      color: backgroundColor ?? KkfcColors.shell,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: isCompact ? KkfcSpace.s16 : KkfcSpace.s20,
              ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: [optional leading] + [KKFC POS if !isCompact] + [title / titleWidget]
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: KkfcSpace.s12),
                    ],
                    if (!isCompact) ...[
                      const Text(
                        'KKFC POS',
                        style: TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: KkfcTextSizes.textXs,
                          fontWeight: KkfcFontWeights.bold,
                          letterSpacing: 1.0,
                          color: Color(0xFF8C9BAE),
                        ),
                      ),
                      const SizedBox(width: KkfcSpace.s16),
                    ],
                    if (titleWidget != null) ...[
                      Flexible(child: titleWidget!),
                    ] else if (title != null && title!.isNotEmpty) ...[
                      Flexible(
                        child: Text(
                          title!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: isCompact ? 20.0 : KkfcTextSizes.textLg,
                            fontWeight: KkfcFontWeights.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Right side: [actions] + [trailing or role badge] + [logout]
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...?actions,
                  if (trailing != null)
                    trailing!
                  else if (effectiveRole != null && effectiveRole.isNotEmpty)
                    AppHeaderRoleChip(
                      role: effectiveRole,
                      onTap: onRoleTap,
                    ),
                  if (showLogout) ...[
                    const SizedBox(width: KkfcSpace.s8),
                    const LogoutButton(color: Colors.white),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Role badge / pill displayed on the right side of [AppHeader].
class AppHeaderRoleChip extends StatelessWidget {
  const AppHeaderRoleChip({
    super.key,
    required this.role,
    this.onTap,
  });

  final String role;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KkfcRadius.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF24364D),
            borderRadius: BorderRadius.circular(KkfcRadius.pill),
            border: Border.all(
              color: const Color(0xFF384B66),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                role,
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textMd,
                  fontWeight: KkfcFontWeights.medium,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility alias for [AppHeader].
typedef MenuHeader = AppHeader;
