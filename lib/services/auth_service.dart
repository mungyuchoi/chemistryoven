import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/constants/kakao_config.dart';
import 'functions_service.dart';

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

  /// 카카오 OAuth code 획득 (authorize → FlutterWebAuth2 → code/state 검증).
  /// 사용자가 취소하면 null 을 반환한다.
  Future<String?> _kakaoAuthCode() async {
    final state = _generateNonce(24);
    final authorizeUri = Uri.https('kauth.kakao.com', '/oauth/authorize', {
      'response_type': 'code',
      'client_id': kakaoRestApiKey,
      'redirect_uri': kakaoRedirectUri,
      'state': state,
      'scope': 'profile_nickname,profile_image',
    });

    final String callbackResult;
    try {
      callbackResult = await FlutterWebAuth2.authenticate(
        url: authorizeUri.toString(),
        callbackUrlScheme: kakaoAuthCallbackScheme,
      );
    } on PlatformException catch (error) {
      // 사용자가 로그인 창을 닫으면 취소로 처리
      final code = error.code.toLowerCase();
      if (code.contains('cancel')) {
        return null;
      }
      rethrow;
    }

    final callbackUri = Uri.parse(callbackResult);
    final authError = callbackUri.queryParameters['error'];
    if (authError != null && authError.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'kakao-auth-failed',
        message: '카카오 인증 실패: $authError',
      );
    }

    final code = callbackUri.queryParameters['code'];
    final returnedState = callbackUri.queryParameters['state'];
    if (code == null || returnedState != state) {
      throw FirebaseAuthException(
        code: 'kakao-callback-invalid',
        message: '카카오 콜백 검증에 실패했어요.',
      );
    }
    return code;
  }

  /// 카카오 로그인 (REST OAuth code → Cloud Function 커스텀 토큰 → Firebase).
  /// 사용자가 취소하면 null 반환.
  Future<User?> signInWithKakao() async {
    final code = await _kakaoAuthCode();
    if (code == null) {
      return null; // 사용자 취소
    }
    final firebaseToken = await FunctionsService.instance
        .createKakaoCustomToken(code: code, redirectUri: kakaoRedirectUri);
    final result = await _auth.signInWithCustomToken(firebaseToken);
    return result.user;
  }

  /// 카카오 본인 인증 (계정 생성 X). 현재 로그인 유저에 인증 기록 후 카카오 닉네임 반환.
  /// 사용자가 취소하면 null 반환.
  Future<String?> verifyKakao() async {
    final code = await _kakaoAuthCode();
    if (code == null) {
      return null; // 사용자 취소
    }
    return FunctionsService.instance
        .verifyKakaoAccount(code: code, redirectUri: kakaoRedirectUri);
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
