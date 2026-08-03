import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'models/app_user.dart';
import 'services/auth_service.dart';
import 'pages/role_selection_page.dart';
import 'pages/student_dashboard.dart';
import 'pages/teacher_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Watches Firebase's login state. If someone is already signed in (e.g.
/// they close and reopen the app), skip straight to their dashboard instead
/// of showing the role selection / login screens again.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final firebaseUser = snapshot.data;
        if (firebaseUser == null) {
          return const RoleSelectionPage();
        }

        return FutureBuilder<AppUser>(
          future: authService.getUserProfile(firebaseUser.uid),
          builder: (context, profileSnap) {
            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (profileSnap.hasError || !profileSnap.hasData) {
              // Profile missing (e.g. was deleted from Firestore) — sign out
              // and send back to role selection rather than getting stuck.
              authService.signOut();
              return const RoleSelectionPage();
            }

            final user = profileSnap.data!;
            if (user.role == 'teacher') {
              return TeacherDashboard(user: user);
            }
            return StudentDashboard(user: user);
          },
        );
      },
    );
  }
}
