import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/features/auth/data/models/login_status.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/features/auth/presentation/widgets/brand_panel.dart';
import 'package:mobile/features/auth/presentation/widgets/login_form_card.dart';
import 'package:mobile/features/auth/presentation/widgets/login_layout.dart';
import 'package:mobile/features/auth/presentation/widgets/session_expired/session_expired_dialog.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/shared/widgets/kkfc_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  LoginStatus _status = LoginStatus.idle;
  bool _expiredDialogShown = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearNotice() {
    if (_status.hasNotice) setState(() => _status = LoginStatus.idle);
  }

  /// The 401 interceptor flags the expiry before the router lands here, so
  /// this runs from build (initial check) and from the listener (later flips).
  void _maybeShowSessionExpired() {
    if (_expiredDialogShown || !ref.read(sessionExpiredProvider)) return;
    _expiredDialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showSessionExpiredDialog(
        context,
        preservedItemCount: 0,
        onSignIn: () {
          Navigator.of(context).pop();
          ref.read(sessionExpiredProvider.notifier).set(false);
        },
      );
    });
  }

  Future<void> _submit() async {
    if (_status.isSubmitting) return;
    FocusScope.of(context).unfocus();

    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _status = LoginStatus.missingFields);
      return;
    }

    setState(() => _status = LoginStatus.submitting);

    try {
      final token = await ref
          .read(authRepositoryProvider)
          .login(username: _username.text.trim(), password: _password.text);

      if (!mounted) return;
      final role = ref.read(authRepositoryProvider).cachedRole;
      if (role != null) {
        ref.read(userRoleProvider.notifier).setRole(role);
      }
      ref.read(sessionTokenProvider.notifier).setToken(token);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = switch (e.kind) {
          AuthFailure.invalidCredentials => LoginStatus.invalidCredentials,
          AuthFailure.network ||
          AuthFailure.unexpected => LoginStatus.networkError,
        };
      });
    } catch (_) {
      // Never leave the form stuck on the spinner.
      if (!mounted) return;
      setState(() => _status = LoginStatus.networkError);
    }
  }

  Widget _form() => LoginFormCard(
    usernameController: _username,
    passwordController: _password,
    status: _status,
    onSubmit: _submit,
    onEdited: _clearNotice,
  );

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(sessionExpiredProvider, (_, expired) {
      if (expired) _maybeShowSessionExpired();
    });
    _maybeShowSessionExpired();

    final compact = LoginLayout.isCompact(context);

    return KkfcScaffold(
      body: Container(
        color: KkfcColors.canvas, // Warm sand ground #F7F3EC
        child: Column(
          children: [
            // Top Navy Shell Header (KKFC / Staff POS / Brands)
            BrandPanel(compact: compact),

            // Main Canvas with fluid background waves and centered Card
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _LoginCanvasWavesPainter()),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact
                            ? KkfcSpace.space4
                            : KkfcSpace.space8,
                        vertical: KkfcSpace.space6,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440.0),
                        child: _form(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws soft, elegant organic wave curves on the warm sand canvas background.
class _LoginCanvasWavesPainter extends CustomPainter {
  const _LoginCanvasWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Wave 1: Soft sand flowing from bottom right with multi-crest fluid waves
    final paint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0x18DDD6C9), Color(0x42DDD6C9)],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(size.width * 0.30, size.height)
      ..cubicTo(
        size.width * 0.48,
        size.height * 0.84, // First crest
        size.width * 0.62,
        size.height * 0.94, // Trough dip
        size.width * 0.76,
        size.height * 0.80, // Second crest
      )
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.70, // Upward slope
        size.width * 0.94,
        size.height * 0.74, // Subtle wave ripple
        size.width,
        size.height * 0.58, // Edge finish
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path1, paint1);

    // Wave 2: Deeper soft wavy curve in bottom right corner
    final paint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topRight,
        colors: [Color(0x18C5A28D), Color(0x38C5A28D)],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(size.width * 0.52, size.height)
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.88, // Inner crest
        size.width * 0.75,
        size.height * 0.96, // Inner trough
        size.width * 0.84,
        size.height * 0.86, // Second inner crest
      )
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.78,
        size.width * 0.97,
        size.height * 0.80,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path2, paint2);

    // Wave 3: Subtle top-left organic curve
    final paint3 = Paint()
      ..color = const Color(0x18DDD6C9)
      ..style = PaintingStyle.fill;

    final path3 = Path()
      ..moveTo(0, size.height * 0.12)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.18,
        size.width * 0.22,
        size.height * 0.32,
        0,
        size.height * 0.45,
      )
      ..close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
