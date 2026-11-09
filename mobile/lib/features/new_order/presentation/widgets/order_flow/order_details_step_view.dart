import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// Step 3: Customer and order reference details without rerouting.
class OrderDetailsStepView extends ConsumerStatefulWidget {
  const OrderDetailsStepView({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  ConsumerState<OrderDetailsStepView> createState() =>
      _OrderDetailsStepViewState();
}

class _OrderDetailsStepViewState extends ConsumerState<OrderDetailsStepView> {
  late final TextEditingController _referenceController;
  late final TextEditingController _customerNotesController;

  @override
  void initState() {
    super.initState();
    _referenceController = TextEditingController(
      text: ref.read(orderReferenceProvider),
    );
    _customerNotesController = TextEditingController();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _customerNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(menuChannelProvider);
    final count = ref.watch(cartCountProvider);
    final total = ref.watch(cartTotalProvider);

    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFF7F3EC),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Dining Channel Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: const Color(0xFFDDD6C9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Channel',
                        style: TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF19293E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          for (final c in MenuChannel.values)
                            ChoiceChip(
                              label: Text(c.label),
                              selected: channel == c,
                              selectedColor: const Color(0xFFE7ECF4),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                fontFamily: KkfcFonts.ibmPlexSans,
                                fontSize: 13.5,
                                fontWeight: channel == c
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: channel == c
                                    ? const Color(0xFF19293E)
                                    : const Color(0xFF586579),
                              ),
                              side: BorderSide(
                                color: channel == c
                                    ? const Color(0xFF19293E)
                                    : const Color(0xFF76849A),
                                width: channel == c ? 1.5 : 1.0,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  ref
                                      .read(menuChannelProvider.notifier)
                                      .select(c);
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Table / Order Reference Input
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: const Color(0xFFDDD6C9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.referenceLabel,
                        style: const TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF19293E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: const Color(0xFF76849A)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _referenceController,
                          onChanged: (val) {
                            ref
                                .read(orderReferenceProvider.notifier)
                                .set(val);
                          },
                          decoration: InputDecoration(
                            hintText: channel == MenuChannel.dineIn
                                ? 'e.g. Table 12'
                                : 'e.g. Order #1042',
                            hintStyle: const TextStyle(
                              color: Color(0xFF8C97A5),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'General Order Notes (Optional)',
                        style: TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF19293E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: const Color(0xFF76849A)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _customerNotesController,
                          maxLines: 2,
                          maxLength: 120,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Priority order, pack separately',
                            hintStyle: TextStyle(
                              color: Color(0xFF8C97A5),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Mini Order Summary
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: const Color(0xFFDDD6C9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$count item${count == 1 ? '' : 's'} · ${channel.label}',
                        style: const TextStyle(
                          fontFamily: KkfcFonts.text,
                          fontSize: 14.0,
                          color: Color(0xFF586579),
                        ),
                      ),
                      Text(
                        formatPeso(total),
                        style: const TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF19293E),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Action Bar
        Container(
          color: const Color(0xFFF7F3EC),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: Material(
                color: const Color(0xFFA8562A),
                borderRadius: BorderRadius.circular(10.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10.0),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onContinue();
                  },
                  child: const Center(
                    child: Text(
                      'Continue to payment',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
