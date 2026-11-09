import 'package:flutter/material.dart';
import 'package:mobile/app/theme/typography.dart';

/// Top alert banner shown when order details validation fails.
class OrderDetailsErrorBanner extends StatelessWidget {
  const OrderDetailsErrorBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3F2),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFFECDCA), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB42318),
            size: 20.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB42318),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
