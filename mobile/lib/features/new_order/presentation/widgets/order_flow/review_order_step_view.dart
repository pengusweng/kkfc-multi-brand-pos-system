import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/models/order_draft_models.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/new_order/providers/order_draft_provider.dart';
import 'package:mobile/features/order_entry/data/repositories/order_entry_repository.dart';
import 'package:mobile/features/orders/cancel/presentation/pages/cancel_order_screen.dart';

/// Step 4: Review order details and line items before confirming.
/// Sends confirmation via POST /brands/:brandId/orders/:orderId/confirm.
class ReviewOrderStepView extends ConsumerStatefulWidget {
  const ReviewOrderStepView({
    super.key,
    required this.onConfirm,
    this.onCancelOrder,
  });

  final VoidCallback onConfirm;
  final VoidCallback? onCancelOrder;

  @override
  ConsumerState<ReviewOrderStepView> createState() =>
      _ReviewOrderStepViewState();
}

class _ReviewOrderStepViewState extends ConsumerState<ReviewOrderStepView> {
  bool _isSubmitting = false;

  String _formatModifiers(CartLine line, String brandName) {
    final parts = <String>[];
    for (final g in line.item.modifierGroups) {
      final selId = line.selections[g.id] ?? g.defaultOptionId;
      if (g.isAddOn && selId != ModifierGroup.addOnOn) continue;

      final opt = g.optionById(selId);
      if (opt.priceDeltaCentavos != 0) {
        final delta = opt.priceDeltaCentavos;
        final sign = delta > 0 ? '+' : '';
        final str = (delta % 100 == 0)
            ? '₱${delta ~/ 100}'
            : formatPeso(delta.abs());
        parts.add('${opt.label} ($sign$str)');
      } else {
        parts.add(opt.label);
      }
    }

    final mods = parts.join(', ');
    if (brandName.isNotEmpty) {
      return mods.isNotEmpty ? '$brandName · $mods' : brandName;
    }
    return mods;
  }

  String _paymentNote(MenuChannel channel) {
    switch (channel) {
      case MenuChannel.dineIn:
        return 'Guests pay after eating. Sending does not wait for payment.';
      case MenuChannel.takeaway:
        return 'Guests pay before eating or when claiming takeaway order.';
      case MenuChannel.grabFood:
      case MenuChannel.foodpanda:
        return 'Paid through delivery platform.';
    }
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
      return 'Could not confirm order. Please check your connection and try again.';
    }
    if (error is StateError) {
      return error.message;
    }
    return 'Could not confirm order. Please try again.';
  }

  void _navigateToCancelOrder(BuildContext context) {
    final draft = ref.read(activeOrderDraftProvider);
    final displayTicketNumber = draft?.ticketNumber ?? 'T-017';
    final displayOrderCode = (draft != null && draft.orderCode.isNotEmpty)
        ? draft.orderCode
        : 'ORD-2026-1105-017';
    final realOrderId = draft?.orderId;

    final router = GoRouter.maybeOf(context);
    if (router != null) {
      final queryParams = <String, String>{
        'orderCode': displayOrderCode,
        'ticketNumber': displayTicketNumber,
      };
      if (realOrderId != null) {
        queryParams['orderId'] = realOrderId;
      }
      final uri = Uri(
        path: AppRoutes.cancelOrder,
        queryParameters: queryParams,
      );
      router.push(uri.toString());
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => CancelOrderScreen(
            orderId: realOrderId,
            orderCode: displayOrderCode,
            ticketNumber: displayTicketNumber,
            onKeepOrder: () => Navigator.of(ctx).pop(),
            onBackToMenu: () {
              ref.read(cartProvider.notifier).clear();
              ref.read(orderReferenceProvider.notifier).clear();
              ref.read(activeOrderDraftProvider.notifier).clear();
              ref.read(clientOrderIdProvider.notifier).regenerate();
              widget.onCancelOrder?.call();
              Navigator.of(ctx).pop();
            },
          ),
        ),
      );
    }
  }

  Future<void> _onConfirmAndSend() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final draft = ref.read(activeOrderDraftProvider);
      final activeBrand = ref.read(activeBrandProvider);
      final allBrands = ref.read(assignedBrandsProvider);
      final brandId = (draft != null && draft.brandId.isNotEmpty)
          ? draft.brandId
          : resolveActiveBrandId(activeBrand, allBrands);
      final String orderId = (draft != null && draft.orderId.isNotEmpty)
          ? draft.orderId
          : ref.read(clientOrderIdProvider);
      final channel = ref.read(menuChannelProvider);

      final paymentMethod = channel.isPlatform ? 'PLATFORM_SETTLED' : 'CASH';
      final paymentStatus = channel.isPlatform ? 'PAID' : 'UNPAID';

      final confirmed = await ref
          .read(orderEntryRepositoryProvider)
          .confirmOrder(
            brandId: brandId,
            orderId: orderId,
            paymentMethod: paymentMethod,
            paymentStatus: paymentStatus,
          );

      final updatedDraft = OrderDraft.fromJson(confirmed);
      ref.read(activeOrderDraftProvider.notifier).set(updatedDraft);

      if (mounted) {
        setState(() => _isSubmitting = false);
        widget.onConfirm();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final message = _extractErrorMessage(e);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFB42318),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(menuChannelProvider);
    final reference = ref.watch(orderReferenceProvider);
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final itemCount = ref.watch(cartCountProvider);
    final activeBrand = ref.watch(activeBrandProvider);
    final brandName = activeBrand.name;
    final draft = ref.watch(activeOrderDraftProvider);

    final lineCount = cart.length;
    final effectiveReference = reference.isNotEmpty
        ? reference
        : (draft?.tableReference ??
              (channel == MenuChannel.dineIn ? 'Table 7' : 'Pickup'));

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Info Banner
              Container(
                margin: const EdgeInsets.only(bottom: 14.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FC),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: const Color(0xFFB9D7F9),
                    width: 1.0,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF19293E),
                      size: 20.0,
                    ),
                    SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'Not sent yet. Please review carefully before confirming.',
                        style: TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF19293E),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Card 1: Channel & Reference Meta Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: const Color(0xFFDDD6C9),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Channel',
                          style: TextStyle(
                            fontFamily: KkfcFonts.text,
                            fontSize: 15.0,
                            color: Color(0xFF586579),
                          ),
                        ),
                        Text(
                          channel.label,
                          style: const TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF19293E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Table / Reference Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          channel == MenuChannel.dineIn ? 'Table' : 'Reference',
                          style: const TextStyle(
                            fontFamily: KkfcFonts.text,
                            fontSize: 15.0,
                            color: Color(0xFF586579),
                          ),
                        ),
                        Text(
                          effectiveReference,
                          style: const TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF19293E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payment Status Row
                    Row(
                      children: [
                        const Text(
                          'Payment status ',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF19293E),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF1F5),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 13.0,
                                color: Color(0xFF586579),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                channel.isPlatform ? 'Paid' : 'Unpaid',
                                style: const TextStyle(
                                  fontFamily: KkfcFonts.ibmPlexSans,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF19293E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Text(
                      _paymentNote(channel),
                      style: const TextStyle(
                        fontFamily: KkfcFonts.text,
                        fontSize: 13.5,
                        color: Color(0xFF586579),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Card 2: Lines & Financial Summary
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: const Color(0xFFDDD6C9),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: "1 line · 2 items"
                    Text(
                      '$lineCount line${lineCount == 1 ? '' : 's'} · $itemCount item${itemCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF19293E),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Order Lines
                    for (int i = 0; i < cart.length; i++) ...[
                      if (i > 0)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF2ECE1),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quantity: "2×"
                          Text(
                            '${cart[i].quantity}×',
                            style: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19293E),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name & Modifiers
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cart[i].item.name,
                                  style: const TextStyle(
                                    fontFamily: KkfcFonts.ibmPlexSans,
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF19293E),
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatModifiers(cart[i], brandName),
                                  style: const TextStyle(
                                    fontFamily: KkfcFonts.text,
                                    fontSize: 13.0,
                                    color: Color(0xFF586579),
                                    height: 1.35,
                                  ),
                                ),
                                if (cart[i].kitchenNote != null &&
                                    cart[i].kitchenNote!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Note: ${cart[i].kitchenNote}',
                                    style: const TextStyle(
                                      fontFamily: KkfcFonts.text,
                                      fontSize: 12.5,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF76849A),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Line Total
                          Text(
                            formatPeso(cart[i].totalCentavos(channel)),
                            style: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19293E),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 18),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEDE8DF),
                    ),
                    const SizedBox(height: 14),

                    // Subtotal Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(
                            fontFamily: KkfcFonts.text,
                            fontSize: 15.0,
                            color: Color(0xFF586579),
                          ),
                        ),
                        Text(
                          formatPeso(total),
                          style: const TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF19293E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Total Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF19293E),
                          ),
                        ),
                        Text(
                          formatPeso(total),
                          style: const TextStyle(
                            fontFamily: KkfcFonts.ibmPlexSans,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF19293E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom Action Bar: "Confirm and send" & "Cancel order"
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: Material(
                    color: _isSubmitting
                        ? const Color(0xFF8B4722)
                        : const Color(0xFFA8562A),
                    borderRadius: BorderRadius.circular(10.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10.0),
                      onTap: _isSubmitting ? null : _onConfirmAndSend,
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.restaurant,
                                    color: Colors.white,
                                    size: 18.0,
                                  ),
                                  SizedBox(width: 8.0),
                                  Text(
                                    'Confirm and send',
                                    style: TextStyle(
                                      fontFamily: KkfcFonts.ibmPlexSans,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                TextButton(
                  key: const ValueKey('cancel-order-button'),
                  onPressed: _isSubmitting
                      ? null
                      : () => _navigateToCancelOrder(context),
                  child: const Text(
                    'Cancel order',
                    style: TextStyle(
                      fontFamily: KkfcFonts.ibmPlexSans,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB42318),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
