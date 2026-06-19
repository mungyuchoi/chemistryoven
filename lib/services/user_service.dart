import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_service.dart';

/// users/{uid} 문서 생성/갱신.
///
/// 스키마는 docs/ARCHITECTURE_PLAN.md §3.2 참고.
/// mileage_thief 의 get-then-merge 패턴: 신규면 기본 문서 생성, 기존이면 일부만 갱신.
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final FirebaseService _fs = FirebaseService.instance;

  /// 현재 동의 정책 버전 (약관 개정 시 갱신).
  static const String policyVersion = '2026-06';

  /// 로그인 직후 호출. 신규 사용자면 true 를 반환한다.
  Future<bool> saveUserOnLogin({
    required User user,
    required String provider,
    String? fcmToken,
  }) async {
    final ref = _fs.userDoc(user.uid);
    final snapshot = await ref.get();
    final now = FieldValue.serverTimestamp();

    final consent = <String, dynamic>{
      'termsAgreedAt': now,
      'privacyAgreedAt': now,
      'policyVersion': policyVersion,
    };

    if (snapshot.exists) {
      await ref.set({
        'lastLoginAt': now,
        'lastActiveAt': now,
        'consent': consent,
        if (fcmToken != null) 'fcmToken': fcmToken,
        if (user.displayName != null && user.displayName!.isNotEmpty)
          'displayName': user.displayName,
        if (user.photoURL != null) 'photoURL': user.photoURL,
      }, SetOptions(merge: true));
      return false;
    }

    await ref.set({
      'uid': user.uid,
      'provider': provider,
      'email': user.email,
      'displayName': (user.displayName == null || user.displayName!.isEmpty)
          ? '케미오븐 사용자'
          : user.displayName,
      'photoURL': user.photoURL,
      'phone': user.phoneNumber,
      'onboarding': {'completed': false},
      'verification': {'photo': 'pending', 'job': 'pending'},
      'roles': ['user'],
      'isBanned': false,
      'consent': consent,
      'fcmToken': fcmToken ?? '',
      'createdAt': now,
      'lastLoginAt': now,
      'lastActiveAt': now,
    });
    return true;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchUser(String uid) {
    return _fs.userDoc(uid).get();
  }
}
