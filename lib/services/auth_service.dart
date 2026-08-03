import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// Handles sign up, sign in, sign out, and fetching the logged-in user's
/// profile (name + role) from Firestore.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Creates a new account and stores their name + role ('student' or
  /// 'teacher') in the `users` collection.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;

    final appUser =
        AppUser(uid: uid, name: name.trim(), email: email.trim(), role: role);
    await _db.collection('users').doc(uid).set(appUser.toMap());
    return appUser;
  }

  /// Signs in an existing user and returns their stored profile, including
  /// their role, so the app knows which dashboard to open.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    return getUserProfile(uid);
  }

  Future<AppUser> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('User profile not found. Please sign up again.');
    }
    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> signOut() => _auth.signOut();
}
