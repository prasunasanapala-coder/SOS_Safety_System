import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/status_banner.dart';

/// Email + password sign-in (Experiments 7a, 7b).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // On success the AuthProvider status changes and AuthGate/AuthGuard
    // swap this screen for the home screen by themselves.
    await context.read<AuthProvider>().signIn(
          _emailController.text,
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxWidth: 480,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Icon(Icons.shield_outlined, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Welcome back',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Sign in to see your contacts and history.', textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.lg),
                  if (auth.error != null) ...[
                    StatusBanner(message: auth.error!, kind: BannerKind.error),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: AppStyles.input('Email', icon: Icons.email_outlined),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: AppStyles.input('Password', icon: Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: Validators.existingPassword,
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
                        : const Text('Sign in'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: auth.busy
                        ? null
                        : () {
                            auth.clearError();
                            Navigator.of(context).pushNamed(AppRoutes.resetPassword);
                          },
                    child: const Text('Forgot password?'),
                  ),
                  TextButton(
                    onPressed: auth.busy
                        ? null
                        : () {
                            auth.clearError();
                            Navigator.of(context).pushNamed(AppRoutes.register);
                          },
                    child: const Text('Create an account'),
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