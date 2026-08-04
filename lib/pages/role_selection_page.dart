import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.authCard,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.authTextSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to\nAttendance System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.authTextPrimary),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor:
                                AppColors.authButton.withOpacity(0.15),
                            child: const Icon(Icons.school,
                                color: AppColors.authButton, size: 30),
                          ),
                          const SizedBox(height: 8),
                          const Text('Student',
                              style:
                                  TextStyle(color: AppColors.authTextPrimary)),
                        ],
                      ),
                      const SizedBox(width: 40),
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor:
                                AppColors.authButton.withOpacity(0.15),
                            child: const Icon(Icons.cast_for_education,
                                color: AppColors.authButton, size: 30),
                          ),
                          const SizedBox(height: 8),
                          const Text('Teacher',
                              style:
                                  TextStyle(color: AppColors.authTextPrimary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.authButton,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppColors.authCard,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24))),
                          builder: (context) => _RolePickerSheet(mode: 'Login'),
                        );
                      },
                      child: const Text('Login',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.authTextPrimary,
                        side:
                            const BorderSide(color: AppColors.authTextPrimary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppColors.authCard,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24))),
                          builder: (context) =>
                              _RolePickerSheet(mode: 'Sign Up'),
                        );
                      },
                      child: const Text('Sign Up',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
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

class _RolePickerSheet extends StatelessWidget {
  final String mode;
  const _RolePickerSheet({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$mode as',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.authTextPrimary)),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.school, color: AppColors.authButton),
            title: const Text('Student',
                style: TextStyle(color: AppColors.authTextPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginPage(role: 'student')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.cast_for_education,
                color: AppColors.authButton),
            title: const Text('Teacher',
                style: TextStyle(color: AppColors.authTextPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginPage(role: 'teacher')));
            },
          ),
        ],
      ),
    );
  }
}
