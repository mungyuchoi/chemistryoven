import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firebase_service.dart';

/// 회차 신청(sessions/{id}/applications/{uid}) Firestore 접근.
/// 본인만 자기 신청 문서를 생성/조회 (보안 규칙 §7).
class ApplicationRepository {
  ApplicationRepository._();
  static final ApplicationRepository instance = ApplicationRepository._();

  /// 회차 신청. 문서 id = uid (1인 1신청, 재신청 시 merge).
  Future<void> apply({
    required String sessionId,
    required String uid,
    String displayName = '',
    String? gender,
    String? baseCharacterId,
  }) {
    return FirebaseService.instance.applications(sessionId).doc(uid).set({
      'uid': uid,
      'displayName': displayName,
      if (gender != null) 'gender': gender,
      if (baseCharacterId != null) 'baseCharacterId': baseCharacterId,
      'status': 'applied',
      'appliedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 이미 신청했는지 여부.
  Future<bool> hasApplied(String sessionId, String uid) async {
    final doc =
        await FirebaseService.instance.applications(sessionId).doc(uid).get();
    return doc.exists;
  }

  /// 신청 취소.
  Future<void> cancel(String sessionId, String uid) {
    return FirebaseService.instance.applications(sessionId).doc(uid).delete();
  }
}
