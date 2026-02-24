import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../database/hive_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        return await _auth.signInWithPopup(provider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();

        if (googleUser == null) {
          return null;
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

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn?.signOut();
    }
    await _auth.signOut();
  }

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

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

class GuestModeNotifier extends StateNotifier<bool> {
  GuestModeNotifier() : super(HiveDatabase.instance.isGuestMode);

  Future<void> setGuestMode(bool value) async {
    await HiveDatabase.instance.setGuestMode(value);
    state = value;
  }
}

final isGuestModeProvider = StateNotifierProvider<GuestModeNotifier, bool>((
  ref,
) {
  return GuestModeNotifier();
});

final isLoggedInProvider = Provider<bool>((ref) {
  final hasUser = ref.watch(currentUserProvider) != null;
  final isGuest = ref.watch(isGuestModeProvider);
  return hasUser || isGuest;
});
