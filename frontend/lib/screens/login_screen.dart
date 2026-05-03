import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _onLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      );

      final token = result['token'] ?? result['data']?['token'];
      if (token != null) {
        ApiService.setToken(token);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = result['message'] ?? 'Login failed. Please try again.';
          });
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid email or password. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCreateAccount() async {
    final shouldGo = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Account'),
          content: const Text(
            'Do you want to create a new account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (shouldGo == true) {
      Navigator.pushNamed(context, '/create_account');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      formContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'LOGIN',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
          if (_hasError) ...[
            const SizedBox(height: 6),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: AppColors.accentRed,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 24),
          LabeledInput(
            label: 'Email',
            controller: _emailCtrl,
            hasError: _hasError,
          ),
          const SizedBox(height: 14),
          LabeledInput(
            label: 'Password',
            obscure: true,
            controller: _passwordCtrl,
            hasError: _hasError,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const SizedBox(
              height: 48,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.accentPink),
                ),
              ),
            )
          else
            PinkButton(
              label: 'Login',
              onPressed: _onLogin,
            ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _onCreateAccount,
              child: const Text(
                'Create new account',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}
