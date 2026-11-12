import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';

/// The two top-level workspaces a privileged user can switch between.
enum KkfcWorkspace {
  pos('POS', 'Point of sale', Icons.point_of_sale_rounded, AppRoutes.menu),
  kds(
    'KDS',
    'Kitchen display',
    Icons.soup_kitchen_outlined,
    AppRoutes.kitchenTickets,
  );

  const KkfcWorkspace(this.label, this.description, this.icon, this.route);

  final String label;
  final String description;
  final IconData icon;
  final String route;
}

/// Dropdown in the app bar that lets SUPERADMIN and SUPERVISOR users switch
/// between the POS (menu / orders) and KDS (kitchen board) screens.
///
/// Renders nothing for roles that cannot switch workspaces.
class WorkspaceSwitcher extends ConsumerWidget {
  const WorkspaceSwitcher({super.key});

  KkfcWorkspace _currentWorkspace(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    final path = router?.routeInformationProvider.value.uri.path;
    return path == AppRoutes.kitchenTickets
        ? KkfcWorkspace.kds
        : KkfcWorkspace.pos;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(userRoleProvider);
    if (role == null || !role.canSwitchWorkspace) {
      return const SizedBox.shrink();
    }

    final current = _currentWorkspace(context);

    return Padding(
      padding: const EdgeInsets.only(right: KkfcSpace.s8),
      child: PopupMenuButton<KkfcWorkspace>(
        key: const ValueKey('workspace-switcher'),
        tooltip: 'Switch screen',
        position: PopupMenuPosition.under,
        initialValue: current,
        onSelected: (target) {
          if (target == current) return;
          GoRouter.maybeOf(context)?.go(target.route);
        },
        itemBuilder: (context) => [
          for (final workspace in KkfcWorkspace.values)
            PopupMenuItem<KkfcWorkspace>(
              key: ValueKey('workspace-option-${workspace.label}'),
              value: workspace,
              child: Row(
                children: [
                  Icon(workspace.icon, size: 18, color: KkfcColors.ink2),
                  const SizedBox(width: KkfcSpace.s12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workspace.label,
                          style: const TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textBase,
                            fontWeight: KkfcFontWeights.bold,
                            color: KkfcColors.ink,
                          ),
                        ),
                        Text(
                          workspace.description,
                          style: const TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: KkfcTextSizes.textSm,
                            color: KkfcColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (workspace == current)
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: KkfcColors.action,
                    ),
                ],
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: KkfcColors.shellRoleBg,
            borderRadius: BorderRadius.circular(KkfcRadius.pill),
            border: Border.all(color: KkfcColors.shellRoleBorder, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(current.icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                current.label,
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textMd,
                  fontWeight: KkfcFontWeights.medium,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
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
