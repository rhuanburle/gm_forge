import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// AuthService - Handles Firebase Authentication
///
/// Supports:
/// - Google Sign-In (primary)
/// - Anonymous auth (guest mode)
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Conditionally initialize GoogleSignIn only for mobile/desktop
  // On Web, initializing this without a ClientID in index.html causes a crash
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  /// Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: Use Firebase Auth popup directly (no extra config needed)
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      } else {
        // Mobile: Use google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();

        if (googleUser == null) {
          return null; // User cancelled
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in anonymously (guest mode)
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// Sign out
  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn?.signOut();
    }
    await _auth.signOut();
  }

  /// Link anonymous account to Google
  Future<UserCredential?> linkWithGoogle() async {
    if (currentUser == null || !currentUser!.isAnonymous) return null;

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await currentUser!.linkWithPopup(provider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await currentUser!.linkWithCredential(credential);
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Singleton provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Stream provider for auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Is logged in provider
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
