import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firebase_service.dart';
import '../models/chemistry_session.dart';

/// 회차(sessions) Firestore 접근.
/// 쓰기는 운영자(roles: admin)만 가능 — 보안 규칙(§7) 참고.
class SessionRepository {
  SessionRepository._();
  static final SessionRepository instance = SessionRepository._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseService.instance.sessions;

  /// 회차 생성. 생성된 문서 id 반환.
  Future<String> createSession(ChemistrySession session) async {
    final ref = _col.doc();
    await ref.set(session.toMap());
    return ref.id;
  }

  /// 회차 목록 실시간 구독 (최신 생성순).
  Stream<List<ChemistrySession>> watchSessions() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map(ChemistrySession.fromDoc)
              .toList(growable: false),
        );
  }

  /// 회차 목록 1회 조회.
  Future<List<ChemistrySession>> fetchSessions() async {
    final snapshot =
        await _col.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map(ChemistrySession.fromDoc)
        .toList(growable: false);
  }

  Future<ChemistrySession?> fetchSession(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? ChemistrySession.fromDoc(doc) : null;
  }

  /// 회차 상태 변경(예: 'closed', 'confirmed').
  Future<void> updateStatus(String id, String status) {
    return _col.doc(id).set({'status': status}, SetOptions(merge: true));
  }

  /// 회차 커버(키비주얼) 이미지 URL 저장.
  Future<void> updateCover(String id, String coverUrl) {
    return _col.doc(id).set({'keyVisualUrl': coverUrl}, SetOptions(merge: true));
  }
}
