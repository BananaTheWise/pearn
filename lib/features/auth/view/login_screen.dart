import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../auth/presenter/auth_presenter.dart';
import '../../auth/view/i_auth_view.dart';
import '../../auth/view/widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> implements IAuthView {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  late final AuthPresenter _authPresenter;

  // ---------------------------------------------------------------------------
  // Controllers
  // ---------------------------------------------------------------------------
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ---------------------------------------------------------------------------
  // UI state (controlled by the presenter via IAuthView methods)
  // ---------------------------------------------------------------------------
  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Form key for validation
  // ---------------------------------------------------------------------------
  final _formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    debugPrint('[UI][AUTH] Login screen initialized');
    _authPresenter = getIt<AuthPresenter>();
    _authPresenter.view = this; // Attach this view to the presenter
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // IAuthView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoginForm() {
    // No-op; this screen always shows the login form.
  }

  @override
  void showSignUpForm() {
    Navigator.pushNamed(context, '/signup');
  }

  @override
  void showValidationError(String message) {
    debugPrint('[UI][AUTH] Login validation error displayed');
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
        content: const Text('A verification link has been sent to your email address.'),
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
    debugPrint(isLoading ? '[UI][AUTH] Authentication loading' : '[UI][AUTH] Authentication completed');
    setState(() {
      _isLoading = isLoading;
      if (isLoading) _errorMessage = null; // clear error when loading starts
    });
  }

  @override
  void navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  // ---------------------------------------------------------------------------
  // User actions (all flow through the presenter)
  // ---------------------------------------------------------------------------

  Future<void> _onLoginPressed() async {
    debugPrint('[UI][AUTH] Login button pressed');

    // Client-side validation
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // The presenter will call showLoading(true/false) and handle errors
    await _authPresenter.login(email, password);
  }

  Future<void> _onGoogleSignInPressed() async {
    await _authPresenter.signInWithGoogle();
  }

  Future<void> _onForgotPasswordPressed() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showValidationError('Please enter your email to reset password');
      return;
    }
    await _authPresenter.requestPasswordReset(email);
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
                  // App logo / title
                  const Icon(Icons.school, size: 64, color: Colors.deepPurple),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome back',
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
                      return null;
                    },
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

                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onLoginPressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Log in'),
                  ),
                  const SizedBox(height: 16),

                  // Google sign-in button
                  GoogleSignInButton(
                    onPressed: _isLoading ? null : _onGoogleSignInPressed,
                    isLoading: false, // we already handle loading globally
                    isEnabled: !_isLoading,
                  ),
                  const SizedBox(height: 12),

                  // Forgot password
                  TextButton(
                    onPressed: _isLoading ? null : _onForgotPasswordPressed,
                    child: const Text('Forgot password?'),
                  ),
                  const SizedBox(height: 4),

                  // Sign up navigation
                  TextButton(
                    onPressed: _isLoading ? null : () => showSignUpForm(),
                    child: const Text("Don't have an account? Sign Up"),
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