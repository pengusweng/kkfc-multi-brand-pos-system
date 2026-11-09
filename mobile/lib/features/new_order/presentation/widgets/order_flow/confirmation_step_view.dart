import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/app/theme/typography.dart';

/// Step 5: Order confirmation and receipt view.
class ConfirmationStepView extends StatelessWidget {
  const ConfirmationStepView({
    super.key,
    required this.onDone,
    this.orderReference = 'Order #1042',
  });

  final VoidCallback onDone;
  final String orderReference;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F3EC),
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFDDD6C9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F4E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 36,
                  color: Color(0xFF166B3A),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Order Confirmed!',
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 22.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF19293E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ticket sent to kitchen · $orderReference',
                style: const TextStyle(
                  fontFamily: KkfcFonts.text,
                  fontSize: 14.0,
                  color: Color(0xFF586579),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA8562A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onDone();
                  },
                  child: const Text(
                    'Start New Order',
                    style: TextStyle(
                      fontFamily: KkfcFonts.ibmPlexSans,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
