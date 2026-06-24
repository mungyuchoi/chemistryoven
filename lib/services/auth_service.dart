import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// 소셜 로그인 → Firebase Auth 연동.
///
/// - 구글: GoogleSignIn → GoogleAuthProvider credential
/// - 애플(iOS): SignInWithApple(nonce+sha256) → OAuthProvider("apple.com")
/// - 카카오: Cloud Functions 커스텀 토큰 방식 (추후 추가, docs/ARCHITECTURE_PLAN.md §5.2)
///
/// 사용자가 로그인을 취소하면 null 을 반환한다.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// 구글 로그인. 취소 시 null.
  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      return null; // 사용자 취소
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  /// 애플 로그인 (iOS). 취소 시 예외(SignInWithAppleAuthorizationException) 발생 가능.
  Future<User?> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    final result = await _auth.signInWithCredential(oauthCredential);
    final user = result.user;

    // 애플은 최초 로그인 시에만 이름을 제공한다. 비어 있으면 채워준다.
    if (user != null && (user.displayName == null || user.displayName!.isEmpty)) {
      final fullName = [appleCredential.givenName, appleCredential.familyName]
          .where((part) => part != null && part.isNotEmpty)
          .join(' ')
          .trim();
      if (fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
      }
    }
    return user;
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // 구글 세션이 없을 수 있음 — 무시
    }
    await _auth.signOut();
  }

  /// 회원탈퇴. 최근 로그인이 아니면 'requires-recent-login' 예외가 날 수 있다.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    await user.delete();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // 무시
    }
  }

  // ── nonce 유틸 (애플 로그인 보안용) ──────────────────────────
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
