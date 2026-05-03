import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

// ── Forgot Password ─────────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSendMail() async {
  final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter your email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final result = await AuthService.sendOtp(email: email);
      debugPrint('Send OTP result: $result');

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/reset_password',
          arguments: email,
        );
      }
    } catch (e) {
      debugPrint('Send OTP error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Could not send email. Please check the address and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            'Forgot Password?',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your email and we\'ll send you a code to reset your password.',
            style: TextStyle(color: AppColors.textLight, fontSize: 12),
          ),

          if (_hasError) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: AppColors.accentRed, fontSize: 12),
            ),
          ],

          const SizedBox(height: 28),
          LabeledInput(
            label: 'Enter your email',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            hasError: _hasError,
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
              label: 'Send Code',
              onPressed: _onSendMail,
            ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (_) => false),
              child: const Text(
                '← Go back to login page',
                style: TextStyle(color: AppColors.textLight, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reset Password (OTP + New Password) ─────────────────────────────────────
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onReset() async {
    final otp = _otpCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (otp.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    // Retrieve email passed from ForgotPasswordScreen
    final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    try {
      final result = await AuthService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      debugPrint('Reset password result: $result');

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/reset_pw_confirmation');
      }
    } catch (e) {
      debugPrint('Reset password error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Invalid or expired code. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            'Reset Password',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the code sent to your email, then choose a new password.',
            style: TextStyle(color: AppColors.textLight, fontSize: 12),
          ),

          if (_hasError) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: AppColors.accentRed, fontSize: 12),
            ),
          ],

          const SizedBox(height: 28),

          LabeledInput(
            label: 'Enter OTP code',
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            hasError: _hasError,
          ),
          const SizedBox(height: 14),
          LabeledInput(
            label: 'New password',
            obscure: true,
            controller: _newPasswordCtrl,
            hasError: _hasError,
          ),
          const SizedBox(height: 14),
          LabeledInput(
            label: 'Confirm new password',
            obscure: true,
            controller: _confirmPasswordCtrl,
            hasError: _hasError,
          ),
          const SizedBox(height: 24),

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
              label: 'Reset Password',
              onPressed: _onReset,
            ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (_) => false),
              child: const Text(
                '← Go back to login page',
                style: TextStyle(color: AppColors.textLight, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create Account ──────────────────────────────────────────────────────────
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _hasError = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    if (_usernameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _confirmPasswordCtrl.text.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.register(
        name: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      debugPrint("REGISTER RESPONSE: $result");

      if (result['success'] == true) {
        final token = result['data']?['token'] ?? result['token'];
        if (token != null) {
          ApiService.setToken(token);
        }

        if (!mounted) return;
        Navigator.pushNamed(context, '/create_acc_confirmation');
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = result['message'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            'Create Account',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),

          if (_hasError && _errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.accentRed,
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 24),

          LabeledInput(
            label: 'Username',
            controller: _usernameCtrl,
            hasError: _hasError,
          ),
          const SizedBox(height: 12),

          LabeledInput(
            label: 'Email',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            hasError: _hasError,
          ),
          const SizedBox(height: 12),

          LabeledInput(
            label: 'Password',
            obscure: true,
            controller: _passwordCtrl,
            hasError: _hasError,
          ),
          const SizedBox(height: 12),

          LabeledInput(
            label: 'Confirm Password',
            obscure: true,
            controller: _confirmPasswordCtrl,
            hasError: _hasError,
          ),

          const SizedBox(height: 24),

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
              label: 'Create',
              onPressed: _onCreate,
            ),

          const SizedBox(height: 14),

          Center(
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () => Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (_) => false),
              child: const Text(
                '← Back to login',
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
}

// ── Email Confirmation ──────────────────────────────────────────────────────
class EmailConfirmationScreen extends StatelessWidget {
  const EmailConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SuccessScreen(
      message: 'Email has been sent successfully',
      backLabel: '← Go to Login',
      onBack: () => Navigator.pushNamedAndRemoveUntil(
          context, '/login', (_) => false),
    );
  }
}

// ── Reset PW Confirmation ───────────────────────────────────────────────────
class ResetPwConfirmationScreen extends StatelessWidget {
  const ResetPwConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SuccessScreen(
      message: 'Your password has been reset successfully',
      backLabel: '← Go to Login',
      onBack: () => Navigator.pushNamedAndRemoveUntil(
          context, '/login', (_) => false),
    );
  }
}

// ── Create Acc Confirmation ─────────────────────────────────────────────────
class CreateAccConfirmationScreen extends StatelessWidget {
  const CreateAccConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SuccessScreen(
      message: 'Your account has been\ncreated successfully',
      backLabel: '← Go to Login',
      onBack: () => Navigator.pushNamedAndRemoveUntil(
          context, '/login', (_) => false),
    );
  }
}