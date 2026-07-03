import 'package:cloud_firestore/cloud_firestore.dart';

import 'demo_models.dart';

/// 오브닝 당일(라이브) 데이터 모델.
///
/// Firestore 스키마는 docs/ARCHITECTURE_PLAN.md §3.4~3.5 참고:
///   sessions/{id}/participants/{uid}, seating/{tableId}, choices/{uid},
///   matches/{matchId}, reports/{reportId}
///
/// 쓰기 주체:
///   participants·seating → 운영자/Functions,  choices → 본인,
///   matches·reports → Functions(운영자) 전용. 클라이언트는 읽기만.

/// sessions/{id}.eventStage 값 ↔ [DemoFlowStep] 매핑.
/// 운영자가 세션 문서의 eventStage 필드를 바꾸면 참가자 화면이 동기화된다
/// (하이브리드: 필드가 없으면 로컬 진행 유지, 서버 값은 앞으로만 이동).
DemoFlowStep? flowStepFromEventStage(String? stage) {
  if (stage == null || stage.isEmpty) {
    return null;
  }
  for (final step in DemoFlowStep.values) {
    if (step.name == stage) {
      return step;
    }
  }
  return null;
}

/// applications/{uid}.status → 신청 단계 [DemoFlowStep] 매핑.
DemoFlowStep? flowStepFromApplicationStatus(String? status) {
  switch (status) {
    case 'applied':
      return DemoFlowStep.verificationWaiting;
    case 'verified':
      return DemoFlowStep.verificationApproved;
    case 'selecting':
      return DemoFlowStep.aiSelectionWaiting;
    case 'selected':
      return DemoFlowStep.selected;
    case 'paymentWaiting':
      return DemoFlowStep.paymentWaiting;
    case 'paid':
    case 'confirmed':
      return DemoFlowStep.confirmed;
    default:
      // held / rejected 등은 단계 이동 없음 (화면 정책 미정).
      return null;
  }
}

/// sessions/{id}/participants/{uid} — 확정 참가자 (회차 닉네임 + 프로필 카드).
class EventParticipant {
  const EventParticipant({
    required this.uid,
    required this.nickname,
    this.gender = '',
    this.characterId,
    this.tableId,
    this.seatPos,
    this.mark = '',
    this.age,
    this.job = '',
    this.region = '',
    this.intro = '',
    this.taste = const [],
    this.dessert = const [],
    this.drink = '',
    this.smoke = '',
    this.good = const [],
    this.chemistryScore,
  });

  final String uid;
  final String nickname;
  final String gender; // 'M' | 'F'
  final String? characterId;
  final String? tableId;
  final int? seatPos;
  final String mark; // 아바타 이니셜 (없으면 닉네임 첫 글자)
  final int? age;
  final String job;
  final String region;
  final String intro;
  final List<String> taste;
  final List<String> dessert;
  final String drink;
  final String smoke;
  final List<String> good;
  final int? chemistryScore;

  String get displayMark =>
      mark.isNotEmpty ? mark : (nickname.isNotEmpty ? nickname[0] : '?');

  factory EventParticipant.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final profile = (data['profile'] as Map<String, dynamic>?) ?? const {};
    return EventParticipant(
      uid: doc.id,
      nickname: (data['nickname'] as String?) ?? '',
      gender: (data['gender'] as String?) ?? '',
      characterId: data['characterId'] as String?,
      tableId: data['tableId'] as String?,
      seatPos: (data['seatPos'] as num?)?.toInt(),
      mark: (data['mark'] as String?) ?? '',
      age: (profile['age'] as num?)?.toInt(),
      job: (profile['job'] as String?) ?? '',
      region: (profile['region'] as String?) ?? '',
      intro: (profile['intro'] as String?) ?? '',
      taste: _stringList(profile['taste']),
      dessert: _stringList(profile['dessert']),
      drink: (profile['drink'] as String?) ?? '',
      smoke: (profile['smoke'] as String?) ?? '',
      good: _stringList(profile['good']),
      chemistryScore: (data['chemistryScore'] as num?)?.toInt(),
    );
  }

  /// 선택 후보 카드용 변환.
  ChoiceCandidate toChoiceCandidate() {
    return ChoiceCandidate(
      nickname: nickname,
      gender: gender == 'M' ? '남' : (gender == 'F' ? '여' : gender),
      keywords: taste.isNotEmpty ? taste : good,
      chemistryScore: chemistryScore ?? 0,
    );
  }
}

/// sessions/{id}/seating/{tableId} 의 한 좌석.
class SeatEntry {
  const SeatEntry({required this.uid, required this.nickname, this.seatPos});

  final String uid;
  final String nickname;
  final int? seatPos;

  factory SeatEntry.fromMap(Map<String, dynamic> map) {
    return SeatEntry(
      uid: (map['uid'] as String?) ?? '',
      nickname: (map['nickname'] as String?) ?? '',
      seatPos: (map['seatPos'] as num?)?.toInt(),
    );
  }
}

/// sessions/{id}/seating/{tableId} — 테이블 좌석도.
/// 좌석 규칙: seatPos 0·1 이 한 페어(옆자리), 2·3 이 맞은편 페어.
class SeatingTable {
  const SeatingTable({
    required this.tableId,
    this.theme = '',
    this.seats = const [],
  });

  final String tableId;
  final String theme;
  final List<SeatEntry> seats;

  factory SeatingTable.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final seatsRaw = (data['seats'] as List?) ?? const [];
    return SeatingTable(
      tableId: (data['tableId'] as String?) ?? doc.id,
      theme: (data['theme'] as String?) ?? '',
      seats: seatsRaw
          .whereType<Map<String, dynamic>>()
          .map(SeatEntry.fromMap)
          .toList(growable: false),
    );
  }

  bool containsUid(String uid) => seats.any((seat) => seat.uid == uid);

  SeatEntry? seatOf(String uid) {
    for (final seat in seats) {
      if (seat.uid == uid) {
        return seat;
      }
    }
    return null;
  }

  /// 내 옆자리 페어 (seatPos 0↔1, 2↔3).
  SeatEntry? pairOf(String uid) {
    final mine = seatOf(uid);
    if (mine?.seatPos == null) {
      return null;
    }
    final pairPos = mine!.seatPos!.isEven ? mine.seatPos! + 1 : mine.seatPos! - 1;
    for (final seat in seats) {
      if (seat.seatPos == pairPos) {
        return seat;
      }
    }
    return null;
  }

  /// 맞은편(다른 페어) 좌석들.
  List<SeatEntry> oppositesOf(String uid) {
    final mine = seatOf(uid);
    if (mine?.seatPos == null) {
      return const [];
    }
    final myPairBase = (mine!.seatPos! ~/ 2) * 2;
    return seats
        .where(
          (seat) =>
              seat.seatPos != null && (seat.seatPos! ~/ 2) * 2 != myPairBase,
        )
        .toList(growable: false);
  }
}

/// sessions/{id}/choices/{uid} — 내 선택 문서.
/// { first: [uid…], mid: [uid…], final: {first, second}, letter,
///   nicknames: {uid: 닉네임}, traits: {uid: {장점: bool}} }
class MyChoices {
  const MyChoices({
    this.first = const [],
    this.mid = const [],
    this.finalFirst,
    this.finalSecond,
    this.letter = '',
    this.nicknames = const {},
    this.traits = const {},
  });

  final List<String> first; // uid 목록
  final List<String> mid;
  final String? finalFirst;
  final String? finalSecond;
  final String letter;
  final Map<String, String> nicknames; // uid → 닉네임 (표시 복원용)
  final Map<String, Map<String, bool>> traits; // uid → {장점: 좋아요}

  factory MyChoices.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final finalMap = (data['final'] as Map<String, dynamic>?) ?? const {};
    final nicknamesRaw =
        (data['nicknames'] as Map<String, dynamic>?) ?? const {};
    final traitsRaw = (data['traits'] as Map<String, dynamic>?) ?? const {};
    return MyChoices(
      first: _stringList(data['first']),
      mid: _stringList(data['mid']),
      finalFirst: finalMap['first'] as String?,
      finalSecond: finalMap['second'] as String?,
      letter: (data['letter'] as String?) ?? '',
      nicknames: nicknamesRaw.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      traits: traitsRaw.map(
        (uid, votes) => MapEntry(
          uid,
          ((votes as Map<String, dynamic>?) ?? const {}).map(
            (trait, like) => MapEntry(trait, like == true),
          ),
        ),
      ),
    );
  }

  String? nicknameOf(String? uid) => uid == null ? null : nicknames[uid];
}

/// matches/{matchId} — 쌍방 매칭 (Functions/운영자 생성, 클라이언트 읽기 전용).
/// { sessionId, pair: [uidA, uidB], nicknames: {uid: 닉네임},
///   letters: {uid: 보낸 편지}, contacts: {uid: {...}}, createdAt }
class EventMatch {
  const EventMatch({
    required this.id,
    required this.sessionId,
    required this.pair,
    this.nicknames = const {},
    this.letters = const {},
    this.contacts = const {},
    this.createdAt,
  });

  final String id;
  final String sessionId;
  final List<String> pair;
  final Map<String, String> nicknames;
  final Map<String, String> letters;
  final Map<String, Map<String, dynamic>> contacts;
  final DateTime? createdAt;

  factory EventMatch.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final nicknamesRaw =
        (data['nicknames'] as Map<String, dynamic>?) ?? const {};
    final lettersRaw = (data['letters'] as Map<String, dynamic>?) ?? const {};
    final contactsRaw =
        (data['contacts'] as Map<String, dynamic>?) ?? const {};
    return EventMatch(
      id: doc.id,
      sessionId: (data['sessionId'] as String?) ?? '',
      pair: _stringList(data['pair']),
      nicknames:
          nicknamesRaw.map((key, value) => MapEntry(key, value.toString())),
      letters:
          lettersRaw.map((key, value) => MapEntry(key, value.toString())),
      contacts: contactsRaw.map(
        (key, value) => MapEntry(
          key,
          (value as Map<String, dynamic>?) ?? <String, dynamic>{},
        ),
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  String? partnerOf(String uid) {
    for (final member in pair) {
      if (member != uid) {
        return member;
      }
    }
    return null;
  }
}

/// reports/{reportId} — 개인 케미 리포트 (Functions 생성, 본인 읽기 전용).
/// { sessionId, uid, content: {nickname, summary, score, items[]}, createdAt }
class EventReport {
  const EventReport({
    required this.id,
    required this.sessionId,
    required this.uid,
    this.nickname = '',
    this.summary = '',
    this.score = 0,
    this.items = const [],
    this.createdAt,
  });

  final String id;
  final String sessionId;
  final String uid;
  final String nickname;
  final String summary;
  final int score;
  final List<String> items;
  final DateTime? createdAt;

  factory EventReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final content = (data['content'] as Map<String, dynamic>?) ?? const {};
    return EventReport(
      id: doc.id,
      sessionId: (data['sessionId'] as String?) ?? '',
      uid: (data['uid'] as String?) ?? '',
      nickname: (content['nickname'] as String?) ?? '',
      summary: (content['summary'] as String?) ?? '',
      score: (content['score'] as num?)?.toInt() ?? 0,
      items: _stringList(content['items']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 기존 데모 UI(ChemistryReport 카드)에서 그대로 쓰기 위한 변환.
  ChemistryReport toDisplayReport() {
    return ChemistryReport(
      id: id,
      nickname: nickname,
      summary: summary,
      score: score,
      items: items,
      sent: true,
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }
  return const [];
}
