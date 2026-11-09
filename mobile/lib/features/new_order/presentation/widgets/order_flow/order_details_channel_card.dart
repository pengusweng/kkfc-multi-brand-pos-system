import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';

/// Card containing the segmented Channel pills and the Table / Reference input.
class OrderDetailsChannelCard extends StatelessWidget {
  const OrderDetailsChannelCard({
    super.key,
    required this.selectedChannel,
    required this.onChannelSelected,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.hasError,
    this.errorMessage,
  });

  final MenuChannel selectedChannel;
  final ValueChanged<MenuChannel> onChannelSelected;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool hasError;
  final String? errorMessage;

  String _fieldLabel(MenuChannel channel) {
    switch (channel) {
      case MenuChannel.dineIn:
        return 'Table';
      case MenuChannel.takeaway:
        return 'Pickup reference';
      case MenuChannel.grabFood:
        return 'GrabFood reference';
      case MenuChannel.foodpanda:
        return 'foodpanda reference';
    }
  }

  String _fieldHint(MenuChannel channel) {
    switch (channel) {
      case MenuChannel.dineIn:
        return 'For example: Table 4';
      case MenuChannel.takeaway:
        return 'For example: Counter #12';
      case MenuChannel.grabFood:
        return 'For example: GF-1042';
      case MenuChannel.foodpanda:
        return 'For example: FP-2041';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFDDD6C9), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Channel',
            style: TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF19293E),
            ),
          ),
          const SizedBox(height: 10),

          // Segmented Channel Pill Control
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEDE8DF),
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.all(3.0),
            child: Row(
              children: [
                for (final c in MenuChannel.values)
                  Expanded(
                    child: GestureDetector(
                      key: ValueKey('channel-${c.name}'),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChannelSelected(c);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedChannel == c
                              ? const Color(0xFF19293E)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          c.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 13.0,
                            fontWeight: selectedChannel == c
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: selectedChannel == c
                                ? Colors.white
                                : const Color(0xFF4B5565),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Field Label
          Text(
            _fieldLabel(selectedChannel),
            style: const TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF19293E),
            ),
          ),
          const SizedBox(height: 8),

          // Table / Reference TextField
          TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            style: const TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 14.5,
              color: Color(0xFF19293E),
            ),
            decoration: InputDecoration(
              hintText: _fieldHint(selectedChannel),
              hintStyle: const TextStyle(
                fontFamily: KkfcFonts.text,
                fontSize: 14.5,
                color: Color(0xFF76849A),
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: hasError
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF76849A),
                  width: hasError ? 1.2 : 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: hasError
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF76849A),
                  width: hasError ? 1.2 : 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: hasError
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF19293E),
                  width: 1.5,
                ),
              ),
            ),
          ),

          if (hasError && errorMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16.0,
                  color: Color(0xFFB42318),
                ),
                const SizedBox(width: 6.0),
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB42318),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
