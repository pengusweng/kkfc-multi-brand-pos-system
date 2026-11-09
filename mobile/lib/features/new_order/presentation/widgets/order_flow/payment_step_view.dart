import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// Step 4: Payment and tender view.
class PaymentStepView extends ConsumerStatefulWidget {
  const PaymentStepView({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<PaymentStepView> createState() => _PaymentStepViewState();
}

class _PaymentStepViewState extends ConsumerState<PaymentStepView> {
  String _selectedPaymentMethod = 'Cash';

  static const _paymentMethods = [
    {'name': 'Cash', 'icon': Icons.payments_outlined},
    {'name': 'GCash', 'icon': Icons.phone_android_outlined},
    {'name': 'Maya', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'Card', 'icon': Icons.credit_card_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(cartTotalProvider);

    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xFFF7F3EC),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Payment Method Card
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
                        'Select Payment Method',
                        style: TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF19293E),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                        children: [
                          for (final m in _paymentMethods) ...[
                            Builder(
                              builder: (context) {
                                final isSelected =
                                    _selectedPaymentMethod == m['name'];
                                return InkWell(
                                  borderRadius: BorderRadius.circular(8.0),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedPaymentMethod =
                                          m['name'] as String;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE7ECF4)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF19293E)
                                            : const Color(0xFF76849A),
                                        width: isSelected ? 1.5 : 1.0,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          m['icon'] as IconData,
                                          size: 20,
                                          color: isSelected
                                              ? const Color(0xFF19293E)
                                              : const Color(0xFF586579),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          m['name'] as String,
                                          style: TextStyle(
                                            fontFamily: KkfcFonts.ibmPlexSans,
                                            fontSize: 14.0,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? const Color(0xFF19293E)
                                                : const Color(0xFF586579),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Amount Breakdown Card
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: const Color(0xFFDDD6C9)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payable Amount',
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
                              fontSize: 20.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFA8562A),
                              fontFeatures: [FontFeature.tabularFigures()],
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
                    widget.onComplete();
                  },
                  child: Center(
                    child: Text(
                      'Confirm & Pay ${formatPeso(total)}',
                      style: const TextStyle(
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
