import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../auth/presenter/auth_presenter.dart';
import '../../auth/view/i_auth_view.dart';
import '../../auth/view/widgets/google_sign_in_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> implements IAuthView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final AuthPresenter _authPresenter;

  // ---------------------------------------------------------------------------
  // Controllers
  // ---------------------------------------------------------------------------
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ---------------------------------------------------------------------------
  // UI state
  // ---------------------------------------------------------------------------
  bool _isLoading = false;
  String? _errorMessage;
  bool _acceptedTerms = false; // Policy acceptance flag

  final _formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    debugPrint('[UI][AUTH] Signup screen initialized');
    _authPresenter = getIt<AuthPresenter>();
    _authPresenter.view = this;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // IAuthView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoginForm() {
    // Navigate back or to login screen
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void showSignUpForm() {
    // This screen already shows signup; no-op.
  }

  @override
  void showValidationError(String message) {
    debugPrint('[UI][AUTH] Signup validation error displayed');
    setState(() {
      _errorMessage = message;
    });
  }

  @override
  void showVerificationPrompt() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verify your email'),
        content: const Text(
          'A verification link has been sent to your email address. '
          'Please verify before signing in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void showLoading(bool isLoading) {
    debugPrint(isLoading ? '[UI][AUTH] Signup loading' : '[UI][AUTH] Signup completed');
    setState(() {
      _isLoading = isLoading;
      if (isLoading) _errorMessage = null;
    });
  }

  @override
  void navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------

  Future<void> _onSignUpPressed() async {
    debugPrint('[UI][AUTH] Signup button pressed');

    // Validate form fields
    if (!_formKey.currentState!.validate()) return;

    // Check terms acceptance
    if (!_acceptedTerms) {
      showValidationError('You must accept the terms and conditions.');
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // The presenter will handle everything, including showing errors and loading
    await _authPresenter.signUp(email, password);
  }

  Future<void> _onGoogleSignInPressed() async {
    // Reuse the same Google sign-in flow; presenter handles it.
    // Terms acceptance might still be required – the presenter can manage that.
    // If policy acceptance is required even for Google, the presenter can prompt.
    await _authPresenter.signInWithGoogle();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.person_add, size: 64, color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  Text(
                    'Create an account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Terms & conditions acceptance
                  CheckboxListTile(
                    value: _acceptedTerms,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                            });
                          },
                    title: const Text('I accept the Terms & Conditions'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),

                  // Error message
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Signup button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onSignUpPressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign Up'),
                  ),
                  const SizedBox(height: 16),

                  // Google sign-in alternative
                  GoogleSignInButton(
                    onPressed: _isLoading ? null : _onGoogleSignInPressed,
                    isEnabled: !_isLoading,
                  ),
                  const SizedBox(height: 12),

                  // Link to login
                  TextButton(
                    onPressed: _isLoading ? null : () => showLoginForm(),
                    child: const Text('Already have an account? Log in'),
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