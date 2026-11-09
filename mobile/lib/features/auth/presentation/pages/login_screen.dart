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

/// Draws soft, elegant organic wave curves and precision contour lines
/// on the warm sand canvas background.
class _LoginCanvasWavesPainter extends CustomPainter {
  const _LoginCanvasWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;

    // 0. Soft ambient luminous warmth behind the composition
    final glowPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.25, 0.15),
        radius: 0.85,
        colors: [
          Color(0x22F9EBE2), // Subtle copper action-tint glow
          Color(0x00F9EBE2),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    // =========================================================================
    // WAVE 1: Broad Base Sand Dune (Expansive rolling groundwave)
    // =========================================================================
    final path1 = Path()
      ..moveTo(0, h * 0.90)
      ..cubicTo(
        w * 0.18, h * 0.84,
        w * 0.32, h * 0.88,
        w * 0.48, h * 0.80,
      )
      ..cubicTo(
        w * 0.64, h * 0.72,
        w * 0.78, h * 0.78,
        w * 0.90, h * 0.68,
      )
      ..cubicTo(
        w * 0.95, h * 0.63,
        w * 0.98, h * 0.60,
        w, h * 0.58,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fill1 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0x10DDD6C9), Color(0x3EDDD6C9)],
      ).createShader(rect);
    canvas.drawPath(path1, fill1);

    // =========================================================================
    // WAVE 2: Mid-tier Warm Amber & Sand Wave (Secondary fluid contour)
    // =========================================================================
    final path2 = Path()
      ..moveTo(w * 0.18, h)
      ..cubicTo(
        w * 0.32, h * 0.88,
        w * 0.46, h * 0.82,
        w * 0.60, h * 0.85,
      )
      ..cubicTo(
        w * 0.74, h * 0.88,
        w * 0.86, h * 0.74,
        w, h * 0.68,
      )
      ..lineTo(w, h)
      ..close();

    final fill2 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topRight,
        colors: [Color(0x14C5A28D), Color(0x3AC5A28D)],
      ).createShader(rect);
    canvas.drawPath(path2, fill2);

    // =========================================================================
    // WAVE 3: Foreground Terracotta Copper Dune (Artisanal brand core)
    // =========================================================================
    final path3 = Path()
      ..moveTo(w * 0.42, h)
      ..cubicTo(
        w * 0.58, h * 0.91,
        w * 0.70, h * 0.84,
        w * 0.82, h * 0.86,
      )
      ..cubicTo(
        w * 0.91, h * 0.88,
        w * 0.96, h * 0.80,
        w, h * 0.78,
      )
      ..lineTo(w, h)
      ..close();

    final fill3 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topRight,
        colors: [Color(0x18A8562A), Color(0x3CB86843)],
      ).createShader(rect);
    canvas.drawPath(path3, fill3);

    // =========================================================================
    // WAVE 4: Top-Left Organic Aether Curve (Visual counter-balance)
    // =========================================================================
    final path4 = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.36, 0)
      ..cubicTo(
        w * 0.28, h * 0.14,
        w * 0.22, h * 0.22,
        w * 0.12, h * 0.30,
      )
      ..cubicTo(
        w * 0.06, h * 0.35,
        w * 0.02, h * 0.40,
        0, h * 0.44,
      )
      ..close();

    final fill4 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x28DDD6C9), Color(0x08DDD6C9)],
      ).createShader(rect);
    canvas.drawPath(path4, fill4);

    // =========================================================================
    // CONTOUR ACCENTS: Hand-crafted Precision Stroke Lines
    // =========================================================================

    // Contour 1: Tracing the ridge of Wave 1
    final strokePath1 = Path()
      ..moveTo(0, h * 0.90)
      ..cubicTo(
        w * 0.18, h * 0.84,
        w * 0.32, h * 0.88,
        w * 0.48, h * 0.80,
      )
      ..cubicTo(
        w * 0.64, h * 0.72,
        w * 0.78, h * 0.78,
        w * 0.90, h * 0.68,
      )
      ..cubicTo(
        w * 0.95, h * 0.63,
        w * 0.98, h * 0.60,
        w, h * 0.58,
      );

    final strokePaint1 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0x15A8562A), Color(0x45A8562A), Color(0x20C5A28D)],
      ).createShader(rect);
    canvas.drawPath(strokePath1, strokePaint1);

    // Contour 2: Harmonic Echo line floating above Wave 1
    final strokePath2 = Path()
      ..moveTo(0, h * 0.87)
      ..cubicTo(
        w * 0.18, h * 0.81,
        w * 0.32, h * 0.85,
        w * 0.48, h * 0.77,
      )
      ..cubicTo(
        w * 0.64, h * 0.69,
        w * 0.78, h * 0.75,
        w * 0.90, h * 0.65,
      )
      ..cubicTo(
        w * 0.95, h * 0.60,
        w * 0.98, h * 0.57,
        w, h * 0.55,
      );

    final strokePaint2 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0x05C5A28D), Color(0x30C5A28D), Color(0x05C5A28D)],
      ).createShader(rect);
    canvas.drawPath(strokePath2, strokePaint2);

    // Contour 3: Tracing the ridge of Wave 2
    final strokePath3 = Path()
      ..moveTo(w * 0.18, h)
      ..cubicTo(
        w * 0.32, h * 0.88,
        w * 0.46, h * 0.82,
        w * 0.60, h * 0.85,
      )
      ..cubicTo(
        w * 0.74, h * 0.88,
        w * 0.86, h * 0.74,
        w, h * 0.68,
      );

    final strokePaint3 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0x10B86843), Color(0x48B86843), Color(0x20A8562A)],
      ).createShader(rect);
    canvas.drawPath(strokePath3, strokePaint3);

    // Contour 4: Tracing the ridge of Wave 3 (Warm copper foreground crest)
    final strokePath4 = Path()
      ..moveTo(w * 0.42, h)
      ..cubicTo(
        w * 0.58, h * 0.91,
        w * 0.70, h * 0.84,
        w * 0.82, h * 0.86,
      )
      ..cubicTo(
        w * 0.91, h * 0.88,
        w * 0.96, h * 0.80,
        w, h * 0.78,
      );

    final strokePaint4 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topRight,
        colors: [Color(0x20A8562A), Color(0x55A8562A), Color(0x15A8562A)],
      ).createShader(rect);
    canvas.drawPath(strokePath4, strokePaint4);

    // Contour 5: Top-Left Aura contour stroke
    final strokePath5 = Path()
      ..moveTo(w * 0.36, 0)
      ..cubicTo(
        w * 0.28, h * 0.14,
        w * 0.22, h * 0.22,
        w * 0.12, h * 0.30,
      )
      ..cubicTo(
        w * 0.06, h * 0.35,
        w * 0.02, h * 0.40,
        0, h * 0.44,
      );

    final strokePaint5 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0x35C5A28D), Color(0x15DDD6C9)],
      ).createShader(rect);
    canvas.drawPath(strokePath5, strokePaint5);

    // Contour 6: Inner Top-Left echo arc
    final strokePath6 = Path()
      ..moveTo(w * 0.26, 0)
      ..cubicTo(
        w * 0.20, h * 0.10,
        w * 0.15, h * 0.16,
        w * 0.08, h * 0.22,
      )
      ..cubicTo(
        w * 0.04, h * 0.26,
        w * 0.01, h * 0.29,
        0, h * 0.32,
      );

    final strokePaint6 = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x20DDD6C9);
    canvas.drawPath(strokePath6, strokePaint6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
