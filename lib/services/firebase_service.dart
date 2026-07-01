import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase 인스턴스 및 Firestore 컬렉션 경로 접근을 한 곳에 모은 헬퍼.
///
/// 스키마는 docs/ARCHITECTURE_PLAN.md 의 "3. Firestore 데이터 모델" 참고:
///   users/{uid}, characters/{id}, sessions/{id}/(applications|participants|seating|choices),
///   matches/{id}, reports/{id}, config/app, prompts/{version}
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  FirebaseFirestore get db => FirebaseFirestore.instance;
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// 현재 로그인 사용자 (없으면 null).
  User? get currentUser => auth.currentUser;
  String? get uid => auth.currentUser?.uid;

  // ── 최상위 컬렉션 ──────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get users => db.collection('users');
  CollectionReference<Map<String, dynamic>> get characters =>
      db.collection('characters');
  CollectionReference<Map<String, dynamic>> get sessions =>
      db.collection('sessions');
  CollectionReference<Map<String, dynamic>> get matches =>
      db.collection('matches');
  CollectionReference<Map<String, dynamic>> get reports =>
      db.collection('reports');
  CollectionReference<Map<String, dynamic>> get payments =>
      db.collection('payments');
  CollectionReference<Map<String, dynamic>> get reviews =>
      db.collection('reviews');
  CollectionReference<Map<String, dynamic>> get prompts =>
      db.collection('prompts');
  CollectionReference<Map<String, dynamic>> get handles =>
      db.collection('handles');

  // ── 문서 / 서브컬렉션 ─────────────────────────────────────────
  DocumentReference<Map<String, dynamic>> userDoc(String uid) => users.doc(uid);

  /// 온보딩 설문 결과 서브컬렉션 문서: users/{uid}/onboarding/current
  /// (설문 원본/선호값/기본 캐릭터를 users 문서에서 분리해 보관).
  DocumentReference<Map<String, dynamic>> onboardingDoc(String uid) =>
      userDoc(uid).collection('onboarding').doc('current');

  DocumentReference<Map<String, dynamic>> sessionDoc(String sessionId) =>
      sessions.doc(sessionId);

  CollectionReference<Map<String, dynamic>> applications(String sessionId) =>
      sessionDoc(sessionId).collection('applications');

  CollectionReference<Map<String, dynamic>> participants(String sessionId) =>
      sessionDoc(sessionId).collection('participants');

  CollectionReference<Map<String, dynamic>> seating(String sessionId) =>
      sessionDoc(sessionId).collection('seating');

  CollectionReference<Map<String, dynamic>> choices(String sessionId) =>
      sessionDoc(sessionId).collection('choices');

  DocumentReference<Map<String, dynamic>> get appConfig =>
      db.collection('config').doc('app');
}
