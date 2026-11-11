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
import 'package:mobile/shared/widgets/wave_accents.dart';

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

/// Backward compatibility alias for [CanvasWavesPainter].
typedef _LoginCanvasWavesPainter = CanvasWavesPainter;
