import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firebase_service.dart';
import '../models/event_flow_models.dart';

/// 오브닝 당일 플로우 Firestore 접근.
///
/// 읽기: session(eventStage) · application(status) · participants · seating ·
///       choices(본인) · matches(당사자) · reports(본인)
/// 쓰기: choices/{uid}(본인 선택), reviews(후기)
/// participants/seating/matches/reports 쓰기는 운영자/Functions 전용
/// (firestore.rules §7, docs/ARCHITECTURE_PLAN.md §3.4~3.5).
class EventFlowRepository {
  EventFlowRepository._();
  static final EventFlowRepository instance = EventFlowRepository._();

  FirebaseService get _fs => FirebaseService.instance;

  // ── 읽기 스트림 ────────────────────────────────────────────────

  /// 세션 문서 — eventStage(당일 진행 단계) 동기화용.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSession(
    String sessionId,
  ) {
    return _fs.sessionDoc(sessionId).snapshots();
  }

  /// 내 신청 문서 — status(applied|verified|selected|…) 동기화용.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchApplication(
    String sessionId,
    String uid,
  ) {
    return _fs.applications(sessionId).doc(uid).snapshots();
  }

  /// 확정 참가자 로스터 (닉네임/프로필 카드).
  Stream<List<EventParticipant>> watchParticipants(String sessionId) {
    return _fs.participants(sessionId).snapshots().map(
          (snap) => snap.docs
              .map(EventParticipant.fromDoc)
              .toList(growable: false),
        );
  }

  /// 자리 배치 (테이블별 좌석도).
  Stream<List<SeatingTable>> watchSeating(String sessionId) {
    return _fs.seating(sessionId).snapshots().map(
          (snap) =>
              snap.docs.map(SeatingTable.fromDoc).toList(growable: false),
        );
  }

  /// 내 선택 문서.
  Stream<MyChoices?> watchMyChoices(String sessionId, String uid) {
    return _fs.choices(sessionId).doc(uid).snapshots().map(
          (doc) => doc.exists ? MyChoices.fromDoc(doc) : null,
        );
  }

  /// 내가 당사자인 매칭. 규칙상 pair 에 내 uid 가 있어야 읽을 수 있으므로
  /// arrayContains 쿼리만 사용하고 sessionId 는 클라이언트에서 거른다
  /// (복합 인덱스 불필요).
  Stream<List<EventMatch>> watchMyMatches(String uid, {String? sessionId}) {
    return _fs.matches.where('pair', arrayContains: uid).snapshots().map(
      (snap) {
        final matches =
            snap.docs.map(EventMatch.fromDoc).toList(growable: false);
        if (sessionId == null) {
          return matches;
        }
        return matches
            .where((match) => match.sessionId == sessionId)
            .toList(growable: false);
      },
    );
  }

  /// 내 케미 리포트 (본인 문서만 읽기 허용 → uid 등호 쿼리).
  Stream<List<EventReport>> watchMyReports(String uid, {String? sessionId}) {
    return _fs.reports.where('uid', isEqualTo: uid).snapshots().map(
      (snap) {
        final reports =
            snap.docs.map(EventReport.fromDoc).toList(growable: false);
        if (sessionId == null) {
          return reports;
        }
        return reports
            .where((report) => report.sessionId == sessionId)
            .toList(growable: false);
      },
    );
  }

  // ── 쓰기 ──────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _myChoicesDoc(
    String sessionId,
    String uid,
  ) =>
      _fs.choices(sessionId).doc(uid);

  /// 첫인상 선택 저장 — choices/{uid}.first = [상대 uid…]
  Future<void> saveFirstImpression(
    String sessionId,
    String uid, {
    required List<String> pickedUids,
    required Map<String, String> nicknames,
  }) {
    return _myChoicesDoc(sessionId, uid).set({
      'uid': uid,
      'first': pickedUids,
      'nicknames': nicknames,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 중간(베이킹 파트너) 선택 저장 — choices/{uid}.mid
  Future<void> saveMidChoice(
    String sessionId,
    String uid, {
    required List<String> pickedUids,
    required Map<String, String> nicknames,
  }) {
    return _myChoicesDoc(sessionId, uid).set({
      'uid': uid,
      'mid': pickedUids,
      'nicknames': nicknames,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 최종 선택(1·2순위 + 편지) 저장 — choices/{uid}.final / letter
  Future<void> saveFinalChoice(
    String sessionId,
    String uid, {
    required String firstUid,
    String? secondUid,
    String letter = '',
    required Map<String, String> nicknames,
  }) {
    return _myChoicesDoc(sessionId, uid).set({
      'uid': uid,
      'final': {
        'first': firstUid,
        if (secondUid != null) 'second': secondUid,
      },
      'letter': letter,
      'nicknames': nicknames,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 로테이션 장점 평가 저장 — choices/{uid}.traits.{상대uid}.{장점}
  Future<void> saveTraitVote(
    String sessionId,
    String uid, {
    required String targetUid,
    required String trait,
    required bool? like, // null 이면 평가 해제
  }) {
    if (like == null) {
      // 장점 문구에 공백/한글이 있어 문자열 경로 대신 FieldPath 사용.
      return _myChoicesDoc(sessionId, uid).update({
        FieldPath(['traits', targetUid, trait]): FieldValue.delete(),
      }).catchError((Object _) {
        // 문서/필드가 아직 없으면 지울 것도 없음.
      });
    }
    return _myChoicesDoc(sessionId, uid).set({
      'uid': uid,
      'traits': {
        targetUid: {trait: like},
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 후기 저장 — reviews/{auto} (규칙: uid 본인 문서만 생성 가능).
  Future<void> submitReview({
    required String sessionId,
    required String uid,
    required int stars,
    required String type,
    required String text,
  }) {
    return _fs.reviews.add({
      'uid': uid,
      'sessionId': sessionId,
      'stars': stars,
      'type': type,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
