import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/order_details_channel_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/order_details_error_banner.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/order_details_summary_card.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// Step 3: Order details matching the visual design.
/// Includes Channel segmented picker, Table / Reference field with error validation,
/// financial summary, payment status badge, and sticky "Review order" button.
class OrderDetailsStepView extends ConsumerStatefulWidget {
  const OrderDetailsStepView({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  ConsumerState<OrderDetailsStepView> createState() =>
      _OrderDetailsStepViewState();
}

class _OrderDetailsStepViewState extends ConsumerState<OrderDetailsStepView> {
  late final TextEditingController _referenceController;
  late final FocusNode _focusNode;
  bool _showValidationError = false;

  @override
  void initState() {
    super.initState();
    _referenceController = TextEditingController(
      text: ref.read(orderReferenceProvider),
    );
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isValidForChannel(MenuChannel channel, String text) {
    if (channel == MenuChannel.dineIn) {
      return text.trim().isNotEmpty;
    }
    return true;
  }

  String _bannerErrorMessage(MenuChannel channel) {
    if (channel == MenuChannel.dineIn) {
      return 'Enter the table before reviewing a dine-in order.';
    }
    return 'Enter the order reference before reviewing.';
  }

  String _fieldErrorMessage(MenuChannel channel) {
    if (channel == MenuChannel.dineIn) {
      return 'Table is required.';
    }
    return 'Reference is required.';
  }

  void _onReviewOrder() {
    final channel = ref.read(menuChannelProvider);
    final text = _referenceController.text.trim();
    final isValid = _isValidForChannel(channel, text);

    if (!isValid) {
      HapticFeedback.heavyImpact();
      setState(() => _showValidationError = true);
      _focusNode.requestFocus();
      return;
    }

    setState(() => _showValidationError = false);
    HapticFeedback.mediumImpact();
    ref.read(orderReferenceProvider.notifier).set(text);
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(menuChannelProvider);
    final total = ref.watch(cartTotalProvider);
    final hasError =
        _showValidationError &&
        !_isValidForChannel(channel, _referenceController.text);

    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFF7F4EE),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Error Alert Banner (e.g. "Enter the table before reviewing a dine-in order.")
                if (hasError)
                  OrderDetailsErrorBanner(
                    message: _bannerErrorMessage(channel),
                  ),

                // Card 1: Channel & Table Input
                OrderDetailsChannelCard(
                  selectedChannel: channel,
                  onChannelSelected: (c) {
                    ref.read(menuChannelProvider.notifier).select(c);
                    if (_showValidationError) {
                      setState(() {
                        _showValidationError =
                            !_isValidForChannel(c, _referenceController.text);
                      });
                    }
                  },
                  controller: _referenceController,
                  focusNode: _focusNode,
                  onChanged: (val) {
                    ref.read(orderReferenceProvider.notifier).set(val);
                    if (_showValidationError &&
                        _isValidForChannel(channel, val)) {
                      setState(() => _showValidationError = false);
                    }
                  },
                  hasError: hasError,
                  errorMessage: _fieldErrorMessage(channel),
                ),

                const SizedBox(height: 14),

                // Card 2: Subtotal, Total, Payment status
                OrderDetailsSummaryCard(
                  subtotalCentavos: total,
                  totalCentavos: total,
                  channel: channel,
                ),
              ],
            ),
          ),
        ),

        // Bottom Action Bar: "Review order"
        Container(
          color: const Color(0xFFF7F4EE),
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
                  onTap: _onReviewOrder,
                  child: const Center(
                    child: Text(
                      'Review order',
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
