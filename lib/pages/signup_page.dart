import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';

class SignupPage extends StatefulWidget {
  final String role;
  const SignupPage({super.key, required this.role});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToDashboard(dynamic user) {
    if (widget.role == 'teacher') {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => TeacherDashboard(user: user)));
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => StudentDashboard(user: user)));
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final user = await _authService.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: widget.role,
      );
      if (!mounted) return;
      _goToDashboard(user);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorText = _friendlyAuthError(e);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorText = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      default:
        return e.message ?? 'Sign up failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String roleLabel = widget.role == 'teacher' ? 'Teacher' : 'Student';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.authBackgroundStart,
              AppColors.authBackgroundEnd
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                    color: AppColors.authCard,
                    borderRadius: BorderRadius.circular(28)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.authTextSecondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Create Your Account',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.authButton)),
                      const SizedBox(height: 4),
                      Text('Please enter your details to sign up as $roleLabel',
                          style: const TextStyle(
                              color: AppColors.authTextSecondary)),
                      const SizedBox(height: 24),
                      const Text('Full Name',
                          style: TextStyle(
                              color: AppColors.authTextPrimary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style:
                            const TextStyle(color: AppColors.authTextPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.authFieldFill,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Please enter your name'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Enter your email',
                          style: TextStyle(
                              color: AppColors.authTextPrimary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style:
                            const TextStyle(color: AppColors.authTextPrimary),
                        decoration: InputDecoration(
                          hintText: 'name@company.com',
                          filled: true,
                          fillColor: AppColors.authFieldFill,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Please enter your email'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Password',
                          style: TextStyle(
                              color: AppColors.authTextPrimary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style:
                            const TextStyle(color: AppColors.authTextPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.authFieldFill,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.authTextSecondary),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter a password';
                          if (value.length < 6)
                            return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 14),
                        Text(_errorText!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.authButton,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _loading ? null : _handleSignup,
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Sign Up',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed:
                            _loading ? null : () => Navigator.pop(context),
                        child: const Text('Already have an account? Login',
                            style: TextStyle(color: AppColors.authButton)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
