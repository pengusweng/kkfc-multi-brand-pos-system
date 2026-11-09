import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/models/order_draft_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/order_details_channel_card.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/order_details_error_banner.dart';
import 'package:mobile/features/new_order/presentation/widgets/order_flow/order_details_summary_card.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/new_order/providers/order_draft_provider.dart';
import 'package:mobile/features/order_entry/data/repositories/order_entry_repository.dart';
import 'package:mobile/shared/store_reference.dart';

/// Step 3: Order details matching the visual design.
/// Includes Channel segmented picker, Table / Reference field with error validation,
/// financial summary, payment status badge, and sticky "Review order" button.
/// On tapping "Review order", validates fields and creates an order draft via POST /brands/:brandId/orders.
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
  bool _isSubmitting = false;
  String? _apiErrorMessage;

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
    if (channel.isPlatform) {
      return text.trim().isNotEmpty;
    }
    return true;
  }

  String _bannerErrorMessage(MenuChannel channel) {
    if (channel == MenuChannel.dineIn) {
      return 'Enter the table before reviewing a dine-in order.';
    }
    if (channel.isPlatform) {
      return 'Enter the platform order reference before reviewing.';
    }
    return 'Enter the order reference before reviewing.';
  }

  String _fieldErrorMessage(MenuChannel channel) {
    if (channel == MenuChannel.dineIn) {
      return 'Table is required.';
    }
    if (channel.isPlatform) {
      return 'Reference is required.';
    }
    return 'Reference is required.';
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
        if (message is List && message.isNotEmpty) {
          return message.first.toString();
        }
      }
      return 'Could not create order draft. Please check your connection and try again.';
    }
    if (error is StateError) {
      return error.message;
    }
    return 'Could not create order draft. Please try again.';
  }

  Future<void> _onReviewOrder() async {
    if (_isSubmitting) return;

    final channel = ref.read(menuChannelProvider);
    final text = _referenceController.text.trim();
    final isValid = _isValidForChannel(channel, text);

    if (!isValid) {
      HapticFeedback.heavyImpact();
      setState(() {
        _showValidationError = true;
        _apiErrorMessage = null;
      });
      _focusNode.requestFocus();
      return;
    }

    setState(() {
      _showValidationError = false;
      _apiErrorMessage = null;
      _isSubmitting = true;
    });
    HapticFeedback.mediumImpact();
    ref.read(orderReferenceProvider.notifier).set(text);

    try {
      final lines = ref.read(cartProvider);
      if (lines.isEmpty) {
        setState(() {
          _isSubmitting = false;
          _apiErrorMessage = 'Add at least one item before reviewing the order.';
        });
        return;
      }

      final activeBrand = ref.read(activeBrandProvider);
      final allBrands = ref.read(assignedBrandsProvider);
      final brandId = resolveActiveBrandId(activeBrand, allBrands);
      final orderId = ref.read(clientOrderIdProvider);

      final storeRef = channel.isPlatform
          ? formatStoreReference(
              brandName: activeBrand.name,
              channelLabel: channel.label,
            )
          : null;

      final created = await ref
          .read(orderEntryRepositoryProvider)
          .createOrder(
            brandId: brandId,
            orderId: orderId,
            channel: channel,
            lines: lines,
            reference: text,
            merchantStoreReference: storeRef,
          );

      final draft = OrderDraft.fromJson(created);
      ref.read(activeOrderDraftProvider.notifier).set(draft);

      if (mounted) {
        setState(() => _isSubmitting = false);
        widget.onContinue();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _apiErrorMessage = _extractErrorMessage(e);
        });
      }
    }
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
                // Error Alert Banner (e.g. "Enter the table before reviewing a dine-in order." or API error)
                if (hasError)
                  OrderDetailsErrorBanner(
                    message: _bannerErrorMessage(channel),
                  )
                else if (_apiErrorMessage != null)
                  OrderDetailsErrorBanner(
                    message: _apiErrorMessage!,
                  ),

                // Card 1: Channel & Table Input
                OrderDetailsChannelCard(
                  selectedChannel: channel,
                  onChannelSelected: (c) {
                    ref.read(menuChannelProvider.notifier).select(c);
                    setState(() {
                      _apiErrorMessage = null;
                      if (_showValidationError) {
                        _showValidationError =
                            !_isValidForChannel(c, _referenceController.text);
                      }
                    });
                  },
                  controller: _referenceController,
                  focusNode: _focusNode,
                  onChanged: (val) {
                    ref.read(orderReferenceProvider.notifier).set(val);
                    if (_apiErrorMessage != null || _showValidationError) {
                      setState(() {
                        _apiErrorMessage = null;
                        if (_showValidationError &&
                            _isValidForChannel(channel, val)) {
                          _showValidationError = false;
                        }
                      });
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
                color: _isSubmitting
                    ? const Color(0xFF8B4722)
                    : const Color(0xFFA8562A),
                borderRadius: BorderRadius.circular(10.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10.0),
                  onTap: _isSubmitting ? null : _onReviewOrder,
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
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
