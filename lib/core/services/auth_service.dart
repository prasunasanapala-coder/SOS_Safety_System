import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../models/user_profile.dart';

class AuthService extends ChangeNotifier {
  bool get _usesDemoFirebaseConfig {
    if (Firebase.apps.isEmpty) {
      return true;
    }

    final options = Firebase.app().options;
    final apiKey = options.apiKey.toLowerCase();
    final projectId = options.projectId.toLowerCase();

    return apiKey.contains('dummy') ||
        apiKey.contains('demo') ||
        projectId.contains('demo') ||
        projectId.contains('dummy');
  }

  FirebaseAuth? get _auth =>
      Firebase.apps.isNotEmpty && !_usesDemoFirebaseConfig
      ? FirebaseAuth.instance
      : null;
  FirebaseFirestore? get _firestore =>
      Firebase.apps.isNotEmpty && !_usesDemoFirebaseConfig
      ? FirebaseFirestore.instance
      : null;

  UserProfile? _user;
  bool _isLoading = true;

  UserProfile? get currentUser => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    if (_usesDemoFirebaseConfig) {
      _user = UserProfile(
        uid: 'demo-user',
        fullName: 'Demo User',
        email: 'demo@sos-safety.app',
        phone: '+1 555 010 2222',
        createdAt: DateTime.now(),
      );
      _isLoading = false;
      notifyListeners();
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final auth = _auth;
    final firestore = _firestore;
    if (auth != null && auth.currentUser != null && firestore != null) {
      final doc = await firestore
          .collection('users')
          .doc(auth.currentUser!.uid)
          .get();
      if (doc.exists) {
        _user = UserProfile.fromMap(doc.data() ?? {}, auth.currentUser!.uid);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_usesDemoFirebaseConfig) {
        _user = UserProfile(
          uid: 'demo-user',
          fullName: 'Demo User',
          email: email.trim(),
          phone: '+1 555 010 2222',
          createdAt: DateTime.now(),
        );
        return;
      }

      final auth = _auth;
      final firestore = _firestore;

      if (auth != null && firestore != null) {
        final credential = await auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final doc = await firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();
        if (doc.exists) {
          _user = UserProfile.fromMap(doc.data() ?? {}, credential.user!.uid);
        } else {
          _user = UserProfile(
            uid: credential.user!.uid,
            fullName: credential.user!.displayName ?? 'User',
            email: credential.user!.email ?? email,
            phone: credential.user!.phoneNumber ?? '',
            createdAt: DateTime.now(),
          );
        }
      } else {
        _user = UserProfile(
          uid: 'demo-user',
          fullName: 'Demo User',
          email: email.trim(),
          phone: '+1 555 010 2222',
          createdAt: DateTime.now(),
        );
      }
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('invalid-api-key') ||
          message.contains('api-key') ||
          _usesDemoFirebaseConfig) {
        _user = UserProfile(
          uid: 'demo-user',
          fullName: 'Demo User',
          email: email.trim(),
          phone: '+1 555 010 2222',
          createdAt: DateTime.now(),
        );
        return;
      }
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final auth = _auth;
      final firestore = _firestore;

      if (auth != null && firestore != null) {
        final credential = await auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final profile = UserProfile(
          uid: credential.user!.uid,
          fullName: fullName,
          email: email.trim(),
          phone: phone,
          createdAt: DateTime.now(),
        );

        await firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(profile.toMap());
        _user = profile;
      } else {
        _user = UserProfile(
          uid: 'demo-user',
          fullName: fullName,
          email: email.trim(),
          phone: phone,
          createdAt: DateTime.now(),
        );
      }
    } catch (error) {
      _user = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    final auth = _auth;
    if (auth != null) {
      await auth.sendPasswordResetEmail(email: email.trim());
      return;
    }

    debugPrint('Demo mode: password reset email sent to $email');
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      final auth = _auth;
      if (auth != null) {
        await auth.signOut();
      }
    } finally {
      _user = null;
      _isLoading = false;
      notifyListeners();
    }
  }
}
