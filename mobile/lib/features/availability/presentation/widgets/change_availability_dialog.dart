import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/availability/data/repositories/menu_item_availability_repository.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/shared/widgets/toast/kkfc_toaster.dart';

/// Modal dialog confirming availability change for a menu item.
///
/// Bidirectional:
/// - Available -> Unavailable: "Make item unavailable?", "Mark unavailable", calls PATCH with `{ availability: false }`.
/// - Unavailable -> Available: "Make item available?", "Mark available", calls PATCH with `{ availability: true }`.
class ChangeAvailabilityDialog extends ConsumerStatefulWidget {
  const ChangeAvailabilityDialog({
    super.key,
    required this.item,
    required this.channel,
    this.onUpdateAvailability,
  });

  final MenuItem item;
  final MenuChannel channel;
  final Future<void> Function(bool availability)? onUpdateAvailability;

  @override
  ConsumerState<ChangeAvailabilityDialog> createState() =>
      _ChangeAvailabilityDialogState();
}

class _ChangeAvailabilityDialogState
    extends ConsumerState<ChangeAvailabilityDialog> {
  bool _isLoading = false;

  bool get _isCurrentlyAvailable =>
      widget.item.availabilityFor(widget.channel) == MenuAvailability.available;

  bool get _targetAvailability => !_isCurrentlyAvailable;

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
    });

    final target = _targetAvailability;

    try {
      if (widget.onUpdateAvailability != null) {
        await widget.onUpdateAvailability!(target);
      } else {
        await ref
            .read(menuItemAvailabilityRepositoryProvider)
            .updateAvailability(
              menuItemId: widget.item.id,
              availability: target,
            );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      KkfcToaster.error(
        context,
        message: 'Failed to update availability for ${widget.item.name}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _targetAvailability;
    final title = target ? 'Make item available?' : 'Make item unavailable?';
    final actionLabel = target ? 'Mark available' : 'Mark unavailable';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: KkfcSpace.s20,
        vertical: KkfcSpace.s24,
      ),
      elevation: 0,
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440.0),
            child: Container(
              padding: const EdgeInsets.all(KkfcSpace.s24),
              decoration: BoxDecoration(
                color: KkfcColors.surface,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: KkfcColors.availabilityCardBorder,
                  width: 1.5,
                ),
                boxShadow: KkfcElevation.shadow3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Warning Icon Badge
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: const BoxDecoration(
                        color: KkfcColors.availabilityWarningBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: KkfcColors.availabilityWarningIcon,
                          size: 28.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: KkfcSpace.s20),

                  // Dialog Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: KkfcFonts.ibmPlexSans,
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: KkfcColors.ink,
                    ),
                  ),
                  const SizedBox(height: KkfcSpace.s12),

                  // Menu Item Name
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontFamily: KkfcFonts.ibmPlexSans,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                      color: KkfcColors.ink2,
                    ),
                  ),
                  const SizedBox(height: KkfcSpace.s16),

                  // Channel & Scope Note
                  Text(
                    '${widget.channel.label} · Other availability restrictions still apply.',
                    style: const TextStyle(
                      fontFamily: KkfcFonts.ibmPlexSans,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                      color: KkfcColors.ink2,
                    ),
                  ),
                  const SizedBox(height: KkfcSpace.s24),

                  // Primary Button: Mark available / Mark unavailable
                  SizedBox(
                    height: KkfcTargets.posMinimum,
                    child: FilledButton(
                      key: const ValueKey('change-availability-submit-button'),
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: KkfcColors.action,
                        disabledBackgroundColor: KkfcColors.ticketDisabledBg,
                        foregroundColor: KkfcColors.onSolid,
                        disabledForegroundColor: KkfcColors.ticketMuted,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: KkfcColors.onSolid,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.sync_rounded,
                                  size: 20.0,
                                  color: KkfcColors.onSolid,
                                ),
                                const SizedBox(width: KkfcSpace.s8),
                                Text(
                                  actionLabel,
                                  style: const TextStyle(
                                    fontFamily: KkfcFonts.ibmPlexSans,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w700,
                                    color: KkfcColors.onSolid,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: KkfcSpace.s12),

                  // Secondary Button: Cancel
                  SizedBox(
                    height: KkfcTargets.posMinimum,
                    child: OutlinedButton(
                      key: const ValueKey('change-availability-cancel-button'),
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: KkfcColors.surface,
                        side: const BorderSide(
                          color: KkfcColors.borderStrong,
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: KkfcColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to display [ChangeAvailabilityDialog].
///
/// Returns `true` if the item availability was updated successfully.
Future<bool?> showChangeAvailabilityDialog(
  BuildContext context, {
  required MenuItem item,
  required MenuChannel channel,
  Future<void> Function(bool availability)? onUpdateAvailability,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: KkfcColors.ink.withValues(alpha: KkfcOpacity.scrim),
    builder: (dialogContext) => ChangeAvailabilityDialog(
      item: item,
      channel: channel,
      onUpdateAvailability: onUpdateAvailability,
    ),
  );
}
