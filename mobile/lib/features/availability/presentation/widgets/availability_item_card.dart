import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/availability/presentation/widgets/change_availability_dialog.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/shared/widgets/toast/kkfc_toaster.dart';

/// Item card for an individual menu item in the kitchen availability screen.
///
/// Displays:
/// - Menu item name
/// - Category · Brand
/// - Availability status (Available / Unavailable / Out of stock)
/// - 'Change' button that opens the confirmation dialog.
class AvailabilityItemCard extends ConsumerWidget {
  const AvailabilityItemCard({
    super.key,
    required this.item,
    required this.brandName,
    required this.channel,
    this.onUpdateAvailability,
    this.onAvailabilityChanged,
  });

  final MenuItem item;
  final String brandName;
  final MenuChannel channel;
  final Future<void> Function(bool availability)? onUpdateAvailability;
  final VoidCallback? onAvailabilityChanged;

  static String _labelForAvailability(MenuAvailability availability) =>
      switch (availability) {
        MenuAvailability.available => 'Available',
        MenuAvailability.stockout => 'Out of stock',
        MenuAvailability.manualOff => 'Unavailable',
        MenuAvailability.inactive => 'Inactive',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = item.availabilityFor(channel);
    final statusLabel = _labelForAvailability(availability);
    final isAvailable = availability == MenuAvailability.available;
    final categoryText = (item.category != null && item.category!.isNotEmpty)
        ? item.category!
        : 'Rice bowl';

    return Container(
      key: ValueKey('availability-item-card-${item.id}'),
      margin: const EdgeInsets.only(bottom: KkfcSpace.s12),
      padding: const EdgeInsets.all(KkfcSpace.s16),
      decoration: BoxDecoration(
        color: KkfcColors.surface,
        borderRadius: BorderRadius.circular(KkfcRadius.md),
        border: Border.all(
          color: KkfcColors.border,
          width: KkfcBorderWidth.thin,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item Name
                Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: KkfcColors.ink,
                  ),
                ),
                const SizedBox(height: KkfcSpace.s4),

                // Category · Brand
                Text(
                  '$categoryText · $brandName',
                  style: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: KkfcColors.ink3,
                  ),
                ),
                const SizedBox(height: KkfcSpace.s8),

                // Availability Status Text
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isAvailable
                        ? KkfcColors.ink
                        : KkfcColors.availabilityUnavailableText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KkfcSpace.s12),

          // Change Button
          OutlinedButton(
            key: ValueKey('availability-change-button-${item.id}'),
            onPressed: () async {
              final updated = await showChangeAvailabilityDialog(
                context,
                item: item,
                channel: channel,
                onUpdateAvailability: onUpdateAvailability,
              );

              if (updated == true && context.mounted) {
                ref.invalidate(menuItemsProvider);
                ref.invalidate(visibleMenuItemsProvider);
                onAvailabilityChanged?.call();

                final target = !isAvailable;
                KkfcToaster.success(
                  context,
                  message:
                      '${item.name} marked as ${target ? "available" : "unavailable"}',
                );
              }
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: KkfcColors.surface,
              side: const BorderSide(
                color: KkfcColors.borderStrong,
                width: KkfcBorderWidth.thin,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 22.0,
                vertical: 10.0,
              ),
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: KkfcColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
