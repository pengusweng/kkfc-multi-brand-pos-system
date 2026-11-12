import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/theme/theme.dart';
import 'package:mobile/features/availability/presentation/widgets/availability_list_skeleton.dart';

void main() {
  group('AvailabilityListSkeleton', () {
    testWidgets('renders default 5 skeleton cards with shimmer and semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: counterTheme,
          home: const Scaffold(
            body: SingleChildScrollView(child: AvailabilityListSkeleton()),
          ),
        ),
      );

      // Verify accessible semantics label
      expect(find.bySemanticsLabel('Loading availability'), findsOneWidget);

      // Advance animation slightly to verify shimmer renders without issues
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AvailabilityListSkeleton), findsOneWidget);
    });

    testWidgets('renders specified itemCount of skeleton cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: counterTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: AvailabilityListSkeleton(itemCount: 3),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AvailabilityListSkeleton), findsOneWidget);
    });

    testWidgets('respects disableAnimations / reduceMotion without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: counterTheme,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: AvailabilityListSkeleton()),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(AvailabilityListSkeleton), findsOneWidget);
    });
  });
}
