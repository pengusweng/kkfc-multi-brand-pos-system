import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/auth/data/models/login_status.dart';
import 'package:mobile/features/auth/presentation/widgets/login_notice.dart';
import 'package:mobile/features/auth/presentation/widgets/login_password_field.dart';
import 'package:mobile/shared/widgets/kkfc_loading_button.dart';
import 'package:mobile/shared/widgets/kkfc_text_field.dart';

/// Clean, centered Sign In card matching the updated KKFC POS design.
class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.status,
    required this.onSubmit,
    required this.onEdited,
    this.onWebManagementTap,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final LoginStatus status;
  final VoidCallback onSubmit;
  final VoidCallback onEdited;
  final VoidCallback? onWebManagementTap;

  @override
  Widget build(BuildContext context) {
    final enabled = !status.isSubmitting;

    return Container(
      padding: const EdgeInsets.all(KkfcSpace.space8), // 32.0
      decoration: BoxDecoration(
        color: KkfcColors.surface, // Pure white #FFFFFF
        borderRadius: BorderRadius.circular(KkfcRadius.md),
        border: Border.all(
          color: KkfcColors.border, // #DDD6C9
          width: KkfcBorderWidth.thin,
        ),
      ),
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Sign in',
              style: KkfcTypography.text2xl.copyWith(
                color: KkfcColors.ink,
                fontWeight: KkfcFontWeights.bold,
              ),
            ),
            const SizedBox(height: KkfcSpace.space6), // 24.0
            // Username Label
            Text(
              'Username',
              style: KkfcTypography.textSm.copyWith(
                color: KkfcColors.ink,
                fontWeight: KkfcFontWeights.semiBold,
              ),
            ),
            const SizedBox(height: KkfcSpace.space2), // 8.0
            // Username Input
            KkfcTextField(
              hint: 'Enter username',
              controller: usernameController,
              enabled: enabled,
              hasError: status.fieldsInError,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              onChanged: (_) => onEdited(),
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: KkfcSpace.space4), // 16.0
            // Password Label
            Text(
              'Password',
              style: KkfcTypography.textSm.copyWith(
                color: KkfcColors.ink,
                fontWeight: KkfcFontWeights.semiBold,
              ),
            ),
            const SizedBox(height: KkfcSpace.space2), // 8.0
            // Password Input with integrated Show/Hide toggle
            LoginPasswordField(
              controller: passwordController,
              enabled: enabled,
              hasError: status.fieldsInError,
              onChanged: (_) => onEdited(),
              onSubmitted: onSubmit,
            ),

            // Error / Validation Notice
            LoginNotice(status: status),
            const SizedBox(height: KkfcSpace.space6), // 24.0
            // Sign In Button
            KkfcLoadingButton(
              label: 'Sign in',
              loadingLabel: 'Signing in…',
              isLoading: status.isSubmitting,
              onPressed: onSubmit,
            ),
            const SizedBox(height: KkfcSpace.space4), // 16.0
          ],
        ),
      ),
    );
  }
}
