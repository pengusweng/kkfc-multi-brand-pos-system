import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';

/// Shows the "Choose menu" modal bottom sheet matching the visual design.
Future<({AssignedBrand brand, MenuChannel channel})?> showChooseMenuModal(
  BuildContext context, {
  required List<AssignedBrand> brands,
  required AssignedBrand currentBrand,
  required MenuChannel currentChannel,
}) {
  return showModalBottomSheet<({AssignedBrand brand, MenuChannel channel})>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => ChooseMenuModal(
      brands: brands,
      initialBrand: currentBrand,
      initialChannel: currentChannel,
    ),
  );
}

/// The "Choose menu" modal bottom sheet widget.
class ChooseMenuModal extends ConsumerStatefulWidget {
  const ChooseMenuModal({
    super.key,
    required this.brands,
    required this.initialBrand,
    required this.initialChannel,
  });

  final List<AssignedBrand> brands;
  final AssignedBrand initialBrand;
  final MenuChannel initialChannel;

  @override
  ConsumerState<ChooseMenuModal> createState() => _ChooseMenuModalState();
}

class _ChooseMenuModalState extends ConsumerState<ChooseMenuModal> {
  late AssignedBrand _selectedBrand = widget.initialBrand;
  late MenuChannel _selectedChannel = widget.initialChannel;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: mediaQuery.viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag handle pill
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12.0, bottom: 14.0),
                  width: 38.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),

              // Modal Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Choose menu',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF19293E),
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Text(
                      'Only menus you can manage are shown.',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 13.5,
                        color: Color(0xFF586579),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Brand & Channel Cards (Scrollable to prevent bottom overflow)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final brand in widget.brands) _buildBrandCard(brand),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12.0),

              // Bottom Actions: [ Switch menu ] and [ Cancel ]
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary: Switch menu
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const ValueKey('switch-menu-button'),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop((
                              brand: _selectedBrand,
                              channel: _selectedChannel,
                            ));
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFA8562A,
                            ), // Brand Brown
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text(
                            'Switch menu',
                            style: TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8.0),

                    // Secondary: Cancel
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          key: const ValueKey('cancel-switch-menu-button'),
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFFDDD6C9),
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
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19293E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandCard(AssignedBrand brand) {
    final channelsAsync = ref.watch(brandChannelsProvider(brand));
    final defaultChannels =
        brand.channels ??
        (brand.code.toUpperCase().contains('AI')
            ? const [MenuChannel.dineIn]
            : const [MenuChannel.dineIn, MenuChannel.takeaway]);

    final isAuthorized =
        channelsAsync.value?.isAuthorized ?? brand.isAuthorized;
    final channels = channelsAsync.value?.channels ?? defaultChannels;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.fromLTRB(14.0, 12.0, 14.0, 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8), // Soft card background
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Name Header
          Text(
            brand.name,
            style: const TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF19293E),
            ),
          ),
          const SizedBox(height: 8.0),

          if (isAuthorized)
            // Authorized Channels List with Radio Options
            Column(
              children: [
                for (final channel in channels)
                  _buildChannelRadioRow(brand, channel),
              ],
            )
          else
            // Unauthorized State: 🔒 Not authorized
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: const [
                  Icon(
                    Icons.lock_outline,
                    size: 16.0,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Not authorized',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChannelRadioRow(AssignedBrand brand, MenuChannel channel) {
    final isSelected =
        _selectedBrand.id == brand.id && _selectedChannel == channel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6.0),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedBrand = brand;
            _selectedChannel = channel;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 2.0),
          child: Row(
            children: [
              // Custom Radio Indicator matching mockup
              Container(
                width: 20.0,
                height: 20.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF19293E)
                        : const Color(0xFF94A3B8),
                    width: isSelected ? 2.0 : 1.5,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10.0,
                          height: 10.0,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF19293E),
                          ),
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 12.0),

              // Channel label
              Expanded(
                child: Text(
                  channel.label,
                  style: TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 14.0,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: const Color(0xFF19293E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
