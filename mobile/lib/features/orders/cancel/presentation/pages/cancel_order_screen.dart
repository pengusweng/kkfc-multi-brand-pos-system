import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/app/routes.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';
import 'package:mobile/features/new_order/providers/order_draft_provider.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_models.dart';
import 'package:mobile/features/orders/cancel/data/models/cancel_order_outcome.dart';
import 'package:mobile/features/orders/cancel/data/repositories/cancel_order_repository.dart';
import 'package:mobile/features/orders/cancel/data/seed/sample_cancel_order.dart';
import 'package:mobile/shared/widgets/app_header.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';

/// Cancel order screen matching the redesigned mobile workflow:
/// 1. Initial State: Order info card, reason field, disclaimer, "Keep order" and "Cancel order" buttons.
/// 2. Validation Error: Red border, error message "Enter a reason for cancelling (up to 280 characters)."
/// 3. Active Typing: Blue border, dynamic counter "X/280 characters".
/// 4. Cancelled State: Green checkmark badge, "Order cancelled" card, "Back to menu" button.
class CancelOrderScreen extends ConsumerStatefulWidget {
  const CancelOrderScreen({
    super.key,
    this.orderId,
    this.orderCode,
    this.ticketNumber,
    this.kitchenStage,
    this.initialStep = CancelOrderStep.review,
    this.initialReason,
    this.ticket = sampleCancelOrder,
    this.onKeepOrder,
    this.onReturnToOrder,
    this.onBackToMenu,
    this.onRefresh,
  });

  /// Real order UUID. Enables live cancellation request to the server.
  final String? orderId;

  /// Display code for the order (e.g. 'ORD-2026-1105-017' or 'GC-00001').
  final String? orderCode;

  /// Kitchen ticket identifier (e.g. 'T-017').
  final String? ticketNumber;

  /// Kitchen stage description.
  final String? kitchenStage;

  /// Initial step (for compatibility with step enum).
  final CancelOrderStep initialStep;

  /// Optional prefilled reason.
  final String? initialReason;

  final CancelOrderTicket ticket;

  final VoidCallback? onKeepOrder;
  final VoidCallback? onReturnToOrder;
  final VoidCallback? onBackToMenu;
  final VoidCallback? onRefresh;

  @override
  ConsumerState<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends ConsumerState<CancelOrderScreen> {
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  late final TextEditingController _reasonController;
  late final FocusNode _focusNode;

  late bool _isCancelled;
  late bool _hasError;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isCancelled = widget.initialStep == CancelOrderStep.cancelled;
    _hasError = widget.initialStep == CancelOrderStep.reasonRequired;
    _reasonController = TextEditingController(
      text: widget.initialReason ?? '',
    );
    _focusNode = FocusNode();

    _reasonController.addListener(() {
      if (_hasError && _reasonController.text.trim().isNotEmpty) {
        setState(() {
          _hasError = false;
        });
      } else {
        setState(() {});
      }
    });

    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _displayOrderCode {
    if (widget.orderCode != null && widget.orderCode!.isNotEmpty) {
      return widget.orderCode!;
    }
    final draft = ref.watch(activeOrderDraftProvider);
    if (draft != null && draft.orderCode.isNotEmpty) {
      return draft.orderCode;
    }
    return widget.orderId ?? 'ORD-2026-1105-017';
  }

  String get _displayTicketNumber {
    if (widget.ticketNumber != null && widget.ticketNumber!.isNotEmpty) {
      return widget.ticketNumber!;
    }
    final draft = ref.watch(activeOrderDraftProvider);
    if (draft?.ticketNumber != null && draft!.ticketNumber!.isNotEmpty) {
      return draft.ticketNumber!;
    }
    return widget.ticket.number.isNotEmpty ? widget.ticket.number : 'T-017';
  }

  String get _displayKitchenStage {
    if (widget.kitchenStage != null && widget.kitchenStage!.isNotEmpty) {
      return widget.kitchenStage!;
    }
    return 'Queued · preparation not started';
  }

  Future<void> _handleCancelOrder() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    setState(() {
      _hasError = false;
      _submitting = true;
      _errorMessage = null;
    });

    final effectiveOrderId =
        widget.orderId ?? ref.read(activeOrderDraftProvider)?.orderId;

    if (effectiveOrderId == null) {
      // Demo mode: simulate cancellation locally
      setState(() {
        _submitting = false;
        _isCancelled = true;
      });
      return;
    }

    // Live mode
    final brandId = await _resolveBrandId();
    if (!mounted) return;

    if (brandId == null) {
      setState(() {
        _submitting = false;
        _errorMessage =
            'The signed-in user is not assigned to a brand, so the order '
            'cannot be resolved.';
      });
      return;
    }

    final result = await ref
        .read(cancelOrderRepositoryProvider)
        .cancel(
          brandId: brandId,
          orderId: effectiveOrderId,
          reason: reason,
        );

    if (!mounted) return;

    setState(() {
      _submitting = false;
      switch (result) {
        case CancelOrderAccepted():
          _isCancelled = true;
        case CancelOrderDenied(:final message):
          _errorMessage = message;
      }
    });
  }

  Future<String?> _resolveBrandId() async {
    final draftBrandId = ref.read(activeOrderDraftProvider)?.brandId;
    if (draftBrandId != null && draftBrandId.isNotEmpty) {
      return draftBrandId;
    }
    final activeId = ref.read(activeBrandProvider).id;
    if (_uuid.hasMatch(activeId)) return activeId;
    try {
      final authBrand = await ref.read(authenticatedBrandIdProvider.future);
      if (authBrand.isNotEmpty) return authBrand;
    } on Object {
      // ignore
    }
    return activeId.isNotEmpty ? activeId : null;
  }

  void _handleKeepOrder() {
    if (widget.onKeepOrder != null) {
      widget.onKeepOrder!();
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      _navigate(widget.orderId != null ? AppRoutes.orders : AppRoutes.menu);
    }
  }

  void _handleBackToMenu() {
    ref.read(cartProvider.notifier).clear();
    ref.read(orderReferenceProvider.notifier).clear();
    ref.read(activeOrderDraftProvider.notifier).clear();
    ref.read(clientOrderIdProvider.notifier).regenerate();

    if (widget.onBackToMenu != null) {
      widget.onBackToMenu!();
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(AppRoutes.menu);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.menu,
        (route) => false,
      );
    }
  }

  void _navigate(String location) {
    GoRouter.maybeOf(context)?.go(location);
  }

  @override
  Widget build(BuildContext context) {
    return KkfcScaffold(
      body: Container(
        color: const Color(0xFFF7F4EE),
        child: Column(
          children: [
            // Top AppHeader: Navy ("Orders" / "Cashier Staff v") matching the mockup without logout icon
            const AppHeader(
              title: 'Orders',
              compact: true,
              showLogout: false,
            ),

            if (!_isCancelled) ...[
              // White Title Bar: "Cancel order"
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                child: const Text(
                  'Cancel order',
                  style: TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF19293E),
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEDE8DF)),

              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderInfoCard(),
                      const SizedBox(height: 20.0),
                      _buildReasonSection(),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16.0),
                        _buildErrorMessageBanner(),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
              _buildBottomActionBar(),
            ] else ...[
              // Success Screen ("Order cancelled")
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: 24.0,
                    left: 16.0,
                    right: 16.0,
                    bottom: 24.0,
                  ),
                  child: _buildCancelledCard(),
                ),
              ),

              // Success Bottom Action Bar: "Back to menu"
              _buildCancelledActionBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFDDD6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order',
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 14.0,
                  color: Color(0xFF586579),
                ),
              ),
              Text(
                _displayOrderCode,
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF19293E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kitchen ticket',
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 14.0,
                  color: Color(0xFF586579),
                ),
              ),
              Text(
                _displayTicketNumber,
                style: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF19293E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Kitchen stage',
            style: TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 14.0,
              color: Color(0xFF586579),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            _displayKitchenStage,
            style: const TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFF19293E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    final borderColor = _hasError
        ? const Color(0xFFD92D20)
        : _focusNode.hasFocus
            ? const Color(0xFF2E90FA)
            : const Color(0xFFDDD6C9);

    final borderWidth = _hasError || _focusNode.hasFocus ? 1.5 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason for cancelling',
          style: TextStyle(
            fontFamily: KkfcFonts.ibmPlexSans,
            fontSize: 14.0,
            fontWeight: FontWeight.w700,
            color: Color(0xFF19293E),
          ),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: _reasonController,
          focusNode: _focusNode,
          minLines: 3,
          maxLines: 4,
          maxLength: 280,
          buildCounter: (
            context, {
            required currentLength,
            required isFocused,
            maxLength,
          }) =>
              null,
          style: const TextStyle(
            fontFamily: KkfcFonts.ibmPlexSans,
            fontSize: 14.0,
            color: Color(0xFF19293E),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'For example: guest changed their mind',
            hintStyle: const TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 14.0,
              color: Color(0xFF98A2B3),
            ),
            contentPadding: const EdgeInsets.all(12.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: borderColor, width: borderWidth),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: borderColor, width: borderWidth),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: borderColor, width: borderWidth),
            ),
          ),
        ),
        const SizedBox(height: 6.0),
        Text(
          '${_reasonController.text.length}/280 characters',
          style: const TextStyle(
            fontFamily: KkfcFonts.ibmPlexSans,
            fontSize: 12.0,
            color: Color(0xFF667085),
          ),
        ),
        if (_hasError) ...[
          const SizedBox(height: 6.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                size: 16.0,
                color: Color(0xFFD92D20),
              ),
              SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  'Enter a reason for cancelling (up to 280 characters).',
                  style: TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFD92D20),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Padding(
              padding: EdgeInsets.only(top: 2.0),
              child: Icon(
                Icons.info_outline,
                size: 16.0,
                color: Color(0xFF667085),
              ),
            ),
            SizedBox(width: 6.0),
            Expanded(
              child: Text(
                'Cancelling does not refund a payment or change stock.',
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 13.0,
                  color: Color(0xFF586579),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorMessageBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFFFDA29B)),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(
          fontFamily: KkfcFonts.ibmPlexSans,
          fontSize: 13.0,
          color: Color(0xFFB42318),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEDE8DF), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48.0,
              child: OutlinedButton(
                key: const ValueKey('keep-order-button'),
                onPressed: _submitting ? null : _handleKeepOrder,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF384B66), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Keep order',
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
          const SizedBox(width: 12.0),
          Expanded(
            child: SizedBox(
              height: 48.0,
              child: OutlinedButton(
                key: const ValueKey('submit-cancel-order-button'),
                onPressed: _submitting ? null : _handleCancelOrder,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFFECDCA), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Color(0xFFB42318),
                        ),
                      )
                    : const Text(
                        'Cancel order',
                        style: TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB42318),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFA3D9B5), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F7EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xFF166B3A),
              size: 24.0,
            ),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Order cancelled',
            style: TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 22.0,
              fontWeight: FontWeight.w700,
              color: Color(0xFF19293E),
            ),
          ),
          const SizedBox(height: 12.0),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: 14.0,
                color: Color(0xFF586579),
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Order '),
                TextSpan(
                  text: _displayOrderCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF19293E),
                  ),
                ),
                const TextSpan(text: ' and kitchen ticket '),
                TextSpan(
                  text: _displayTicketNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF19293E),
                  ),
                ),
                const TextSpan(text: ' are cancelled.'),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          const Text(
            'No refund or stock change was made.',
            style: TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 14.0,
              color: Color(0xFF586579),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledActionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEDE8DF), width: 1.0),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48.0,
        child: FilledButton(
          key: const ValueKey('back-to-menu-button'),
          onPressed: _handleBackToMenu,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFA8562A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: const Text(
            'Back to menu',
            style: TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
