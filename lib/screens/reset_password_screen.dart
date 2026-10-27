import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/status_banner.dart';

/// Password reset by email.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await context.read<AuthProvider>().sendPasswordReset(_emailController.text);
    if (mounted) setState(() => _sent = ok);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxWidth: 480,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Enter your account email and we will send a reset link.'),
                  const SizedBox(height: AppSpacing.md),
                  if (auth.error != null) ...[
                    StatusBanner(message: auth.error!, kind: BannerKind.error),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (_sent) ...[
                    const StatusBanner(
                      kind: BannerKind.success,
                      title: 'Request sent',
                      message:
                          'If an account exists for that email, a reset link is on its way. Check your inbox and spam folder.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: AppStyles.input('Email', icon: Icons.email_outlined),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: auth.busy ? null : _submit,
                    child: auth.busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Send reset link'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}