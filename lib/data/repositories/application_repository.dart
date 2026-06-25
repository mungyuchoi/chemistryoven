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

  /// 회차 신청자 목록 + 각 사용자 프로필을 병합해 반환 (운영자용).
  /// 각 항목: { uid, ...application, 'user': {...users/{uid}} }
  Future<List<Map<String, dynamic>>> fetchSessionApplicants(
    String sessionId,
  ) async {
    final apps = await FirebaseService.instance.applications(sessionId).get();
    final result = <Map<String, dynamic>>[];
    for (final doc in apps.docs) {
      final userSnap =
          await FirebaseService.instance.userDoc(doc.id).get();
      result.add({
        'uid': doc.id,
        ...doc.data(),
        'user': userSnap.data() ?? <String, dynamic>{},
      });
    }
    return result;
  }

  /// 신청 상태 변경 (applied | selected | held | rejected).
  Future<void> updateStatus(String sessionId, String uid, String status) {
    return FirebaseService.instance.applications(sessionId).doc(uid).set(
      {'status': status},
      SetOptions(merge: true),
    );
  }

  /// 신청 취소.
  Future<void> cancel(String sessionId, String uid) {
    return FirebaseService.instance.applications(sessionId).doc(uid).delete();
  }
}
