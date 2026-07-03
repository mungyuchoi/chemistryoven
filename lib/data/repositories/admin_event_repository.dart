import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firebase_service.dart';
import '../models/event_flow_models.dart';

/// 운영자용 당일 진행 Firestore 작업 모음.
///
/// 모든 쓰기는 firestore.rules 의 isAdmin() (users/{uid}.roles 에 'admin')
/// 권한을 전제로 한다. 스키마: docs/ARCHITECTURE_PLAN.md §3.4~3.5.
class AdminEventRepository {
  AdminEventRepository._();
  static final AdminEventRepository instance = AdminEventRepository._();

  FirebaseService get _fs => FirebaseService.instance;

  // ── 당일 단계(eventStage) 제어 ─────────────────────────────────
  // 참가자 앱은 sessions/{id}.eventStage 를 구독해 화면을 이동한다.

  static const List<String> eventStages = [
    'nicknameCheck',
    'firstImpressionChoice',
    'rotationTalk',
    'middleChoice',
    'seatingGuide',
    'pairBaking',
    'finalChoice',
    'matchResult',
    'chemistryReport',
    'review',
  ];

  static const Map<String, String> eventStageLabels = {
    'nicknameCheck': '닉네임 확인',
    'firstImpressionChoice': '첫인상 선택',
    'rotationTalk': '로테이션 대화',
    'middleChoice': '중간 선택',
    'seatingGuide': '자리배치 공개',
    'pairBaking': '페어 베이킹',
    'finalChoice': '최종 선택',
    'matchResult': '매칭 결과',
    'chemistryReport': '케미 리포트',
    'review': '후기 작성',
  };

  Future<void> setEventStage(String sessionId, String stage) {
    return _fs.sessionDoc(sessionId).set(
      {'eventStage': stage},
      SetOptions(merge: true),
    );
  }

  // ── 참가자 확정 + 캐릭터(닉네임) 배정 ──────────────────────────

  /// applications 에서 status 가 selected/paid/confirmed 인 신청자를
  /// participants 로 확정하고, 성별에 맞는 캐릭터 닉네임을 중복 없이 배정한다.
  /// 생성/갱신된 참가자 수를 반환.
  Future<int> confirmParticipants(String sessionId) async {
    final apps = await _fs.applications(sessionId).get();
    final targets = apps.docs.where((doc) {
      final status = (doc.data()['status'] as String?) ?? '';
      return status == 'selected' || status == 'paid' || status == 'confirmed';
    }).toList();
    if (targets.isEmpty) {
      return 0;
    }

    final existing = await _fs.participants(sessionId).get();
    final usedNicknames = existing.docs
        .map((doc) => (doc.data()['nickname'] as String?) ?? '')
        .where((nickname) => nickname.isNotEmpty)
        .toSet();
    final existingUids = existing.docs.map((doc) => doc.id).toSet();

    final characterSnap = await _fs.characters.get();
    final charactersByGender = <bool, List<Map<String, dynamic>>>{
      true: [],
      false: [],
    };
    for (final doc in characterSnap.docs) {
      final data = doc.data();
      charactersByGender[(data['forMen'] as bool?) ?? false]!.add(data);
    }

    String pickNickname(String gender) {
      final pool = charactersByGender[gender == 'M'] ?? const [];
      for (final character in pool) {
        final name = (character['name'] as String?) ?? '';
        if (name.isNotEmpty && !usedNicknames.contains(name)) {
          usedNicknames.add(name);
          return name;
        }
      }
      // 캐릭터가 모자라면 번호 붙임.
      final fallback = '참가자${usedNicknames.length + 1}';
      usedNicknames.add(fallback);
      return fallback;
    }

    final batch = _fs.db.batch();
    var written = 0;
    for (final doc in targets) {
      if (existingUids.contains(doc.id)) {
        continue; // 이미 확정된 참가자는 유지 (닉네임 보존)
      }
      final app = doc.data();
      final gender = (app['gender'] as String?) ?? 'M';
      final userSnap = await _fs.userDoc(doc.id).get();
      final user = userSnap.data() ?? const <String, dynamic>{};

      int? age;
      final birth = (user['birth'] as String?) ?? '';
      if (birth.length >= 4) {
        final year = int.tryParse(birth.substring(0, 4));
        if (year != null) {
          age = DateTime.now().year - year;
        }
      }

      final nickname = pickNickname(gender);
      batch.set(_fs.participants(sessionId).doc(doc.id), {
        'uid': doc.id,
        'nickname': nickname,
        'gender': gender,
        'characterId': app['baseCharacterId'],
        'profile': {
          if (age != null) 'age': age,
          'job': user['job'] ?? '',
          'region': user['region'] ?? '',
          'intro': user['intro'] ?? '',
          'taste': user['keywords'] ?? const <String>[],
        },
        'chemistryScore': (app['totalScore'] as num?)?.toInt() ?? 0,
        'confirmedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      written += 1;
    }
    if (written > 0) {
      await batch.commit();
    }

    // 신청 문서도 confirmed 로 승격 → 참가자 앱 단계가 '최종 확정'으로 이동.
    final statusBatch = _fs.db.batch();
    for (final doc in targets) {
      statusBatch.set(
        _fs.applications(sessionId).doc(doc.id),
        {'status': 'confirmed'},
        SetOptions(merge: true),
      );
    }
    await statusBatch.commit();
    return written;
  }

  /// 캐릭터 닉네임 전체 재배정 (기존 배정 무시하고 다시 뽑기).
  Future<int> reassignNicknames(String sessionId) async {
    final participants = await _fs.participants(sessionId).get();
    if (participants.docs.isEmpty) {
      return 0;
    }
    final characterSnap = await _fs.characters.get();
    final pools = <bool, List<String>>{true: [], false: []};
    for (final doc in characterSnap.docs) {
      final data = doc.data();
      final name = (data['name'] as String?) ?? '';
      if (name.isNotEmpty) {
        pools[(data['forMen'] as bool?) ?? false]!.add(name);
      }
    }
    pools[true]!.shuffle();
    pools[false]!.shuffle();

    final batch = _fs.db.batch();
    var index = 0;
    final counters = <bool, int>{true: 0, false: 0};
    for (final doc in participants.docs) {
      final gender = (doc.data()['gender'] as String?) ?? 'M';
      final key = gender == 'M';
      final pool = pools[key]!;
      final count = counters[key]!;
      final nickname =
          count < pool.length ? pool[count] : '참가자${index + 1}';
      counters[key] = count + 1;
      batch.set(doc.reference, {'nickname': nickname}, SetOptions(merge: true));
      index += 1;
    }
    await batch.commit();
    return participants.docs.length;
  }

  // ── 투표(선택) 현황 ────────────────────────────────────────────

  /// 참가자별 choices 제출 현황.
  /// 반환: [{participant, hasFirst, hasMid, hasFinal}]
  Future<List<Map<String, dynamic>>> fetchChoiceStatus(String sessionId) async {
    final participants = await _fs.participants(sessionId).get();
    final choices = await _fs.choices(sessionId).get();
    final byUid = {for (final doc in choices.docs) doc.id: doc.data()};

    return participants.docs.map((doc) {
      final choice = byUid[doc.id] ?? const <String, dynamic>{};
      final finalMap = (choice['final'] as Map<String, dynamic>?) ?? const {};
      return <String, dynamic>{
        'participant': EventParticipant.fromDoc(doc),
        'hasFirst': (choice['first'] as List?)?.isNotEmpty ?? false,
        'hasMid': (choice['mid'] as List?)?.isNotEmpty ?? false,
        'hasFinal': finalMap['first'] != null,
      };
    }).toList(growable: false);
  }

  // ── 자리배치 ──────────────────────────────────────────────────

  /// 자동 자리배치.
  /// 1순위: 중간 선택 쌍방 페어, 2순위: 케미 점수순 이성 페어.
  /// 테이블당 2페어(4명). seatPos 0·1=옆자리 페어, 2·3=맞은편 페어.
  /// 생성된 테이블 수 반환.
  Future<int> autoAssignSeating(String sessionId) async {
    final participantSnap = await _fs.participants(sessionId).get();
    final participants =
        participantSnap.docs.map(EventParticipant.fromDoc).toList();
    if (participants.length < 2) {
      return 0;
    }
    final choiceSnap = await _fs.choices(sessionId).get();
    final midPick = <String, String>{}; // uid → 중간선택 상대 uid
    for (final doc in choiceSnap.docs) {
      final mid = (doc.data()['mid'] as List?) ?? const [];
      if (mid.isNotEmpty) {
        midPick[doc.id] = mid.first.toString();
      }
    }

    final byUid = {for (final p in participants) p.uid: p};
    final paired = <String>{};
    final pairs = <List<EventParticipant>>[];

    // 1) 중간 선택 쌍방 페어
    midPick.forEach((uid, target) {
      if (paired.contains(uid) || paired.contains(target)) {
        return;
      }
      if (midPick[target] == uid &&
          byUid.containsKey(uid) &&
          byUid.containsKey(target)) {
        pairs.add([byUid[uid]!, byUid[target]!]);
        paired..add(uid)..add(target);
      }
    });

    // 2) 남은 인원: 케미 점수순 이성 매칭 (이성 없으면 순서대로)
    final rest = participants.where((p) => !paired.contains(p.uid)).toList()
      ..sort(
        (a, b) => (b.chemistryScore ?? 0).compareTo(a.chemistryScore ?? 0),
      );
    while (rest.isNotEmpty) {
      final first = rest.removeAt(0);
      final oppositeIndex =
          rest.indexWhere((p) => p.gender != first.gender);
      if (oppositeIndex >= 0) {
        pairs.add([first, rest.removeAt(oppositeIndex)]);
      } else if (rest.isNotEmpty) {
        pairs.add([first, rest.removeAt(0)]);
      } else {
        pairs.add([first]); // 홀수 인원
      }
    }

    // 기존 배치 삭제 후 새로 작성
    final existing = await _fs.seating(sessionId).get();
    final clearBatch = _fs.db.batch();
    for (final doc in existing.docs) {
      clearBatch.delete(doc.reference);
    }
    await clearBatch.commit();

    final batch = _fs.db.batch();
    var tableCount = 0;
    for (var i = 0; i < pairs.length; i += 2) {
      // A, B, C… 26개 초과 시 번호로 폴백 (테이블 id 중복 방지).
      final tableId = tableCount < 26
          ? '${String.fromCharCode(65 + tableCount)} 테이블'
          : '테이블 ${tableCount + 1}';
      final seats = <Map<String, dynamic>>[];
      void addPair(List<EventParticipant> pair, int basePos) {
        for (var j = 0; j < pair.length; j++) {
          seats.add({
            'uid': pair[j].uid,
            'nickname': pair[j].nickname,
            'seatPos': basePos + j,
          });
        }
      }

      addPair(pairs[i], 0);
      if (i + 1 < pairs.length) {
        addPair(pairs[i + 1], 2);
      }
      batch.set(_fs.seating(sessionId).doc(tableId), {
        'tableId': tableId,
        'seats': seats,
        'createdAt': FieldValue.serverTimestamp(),
      });
      for (final seat in seats) {
        batch.set(
          _fs.participants(sessionId).doc(seat['uid'] as String),
          {'tableId': tableId, 'seatPos': seat['seatPos']},
          SetOptions(merge: true),
        );
      }
      tableCount += 1;
    }
    await batch.commit();
    return tableCount;
  }

  /// 두 좌석 교체 (같은/다른 테이블 모두 지원).
  Future<void> swapSeats(
    String sessionId, {
    required String tableIdA,
    required int seatPosA,
    required String tableIdB,
    required int seatPosB,
  }) async {
    final tableADoc = await _fs.seating(sessionId).doc(tableIdA).get();
    final tableBDoc = tableIdA == tableIdB
        ? tableADoc
        : await _fs.seating(sessionId).doc(tableIdB).get();
    final seatsA = List<Map<String, dynamic>>.from(
      ((tableADoc.data()?['seats'] as List?) ?? const [])
          .map((seat) => Map<String, dynamic>.from(seat as Map)),
    );
    final seatsB = tableIdA == tableIdB
        ? seatsA
        : List<Map<String, dynamic>>.from(
            ((tableBDoc.data()?['seats'] as List?) ?? const [])
                .map((seat) => Map<String, dynamic>.from(seat as Map)),
          );

    final indexA = seatsA.indexWhere((seat) => seat['seatPos'] == seatPosA);
    final indexB = seatsB.indexWhere((seat) => seat['seatPos'] == seatPosB);
    if (indexA < 0 || indexB < 0) {
      throw StateError('교체할 좌석을 찾지 못했습니다.');
    }

    // uid/nickname 만 서로 교환 (seatPos 는 자리 고정)
    final personA = {
      'uid': seatsA[indexA]['uid'],
      'nickname': seatsA[indexA]['nickname'],
    };
    final personB = {
      'uid': seatsB[indexB]['uid'],
      'nickname': seatsB[indexB]['nickname'],
    };
    seatsA[indexA]['uid'] = personB['uid'];
    seatsA[indexA]['nickname'] = personB['nickname'];
    seatsB[indexB]['uid'] = personA['uid'];
    seatsB[indexB]['nickname'] = personA['nickname'];

    final batch = _fs.db.batch();
    batch.set(
      _fs.seating(sessionId).doc(tableIdA),
      {'seats': seatsA},
      SetOptions(merge: true),
    );
    if (tableIdA != tableIdB) {
      batch.set(
        _fs.seating(sessionId).doc(tableIdB),
        {'seats': seatsB},
        SetOptions(merge: true),
      );
    }
    batch.set(
      _fs.participants(sessionId).doc(personA['uid'] as String),
      {'tableId': tableIdB, 'seatPos': seatPosB},
      SetOptions(merge: true),
    );
    batch.set(
      _fs.participants(sessionId).doc(personB['uid'] as String),
      {'tableId': tableIdA, 'seatPos': seatPosA},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  // ── 매칭 집계/생성 ─────────────────────────────────────────────

  /// 최종 선택 집계 미리보기.
  /// 반환: { mutual: [[uidA, uidB]…], oneWay: [{from, to}…], nicknames: {uid: 닉네임} }
  Future<Map<String, dynamic>> aggregateFinalChoices(String sessionId) async {
    final participantSnap = await _fs.participants(sessionId).get();
    final nicknames = <String, String>{
      for (final doc in participantSnap.docs)
        doc.id: (doc.data()['nickname'] as String?) ?? doc.id,
    };
    final choiceSnap = await _fs.choices(sessionId).get();
    final finalPick = <String, String>{};
    final letters = <String, String>{};
    for (final doc in choiceSnap.docs) {
      final data = doc.data();
      final finalMap = (data['final'] as Map<String, dynamic>?) ?? const {};
      final first = finalMap['first'] as String?;
      if (first != null) {
        finalPick[doc.id] = first;
      }
      final letter = (data['letter'] as String?) ?? '';
      if (letter.isNotEmpty) {
        letters[doc.id] = letter;
      }
    }

    final mutual = <List<String>>[];
    final oneWay = <Map<String, String>>[];
    final consumed = <String>{};
    finalPick.forEach((uid, target) {
      if (consumed.contains(uid)) {
        return;
      }
      if (finalPick[target] == uid) {
        mutual.add([uid, target]);
        consumed..add(uid)..add(target);
      } else {
        oneWay.add({'from': uid, 'to': target});
        consumed.add(uid);
      }
    });

    return {
      'mutual': mutual,
      'oneWay': oneWay,
      'nicknames': nicknames,
      'letters': letters,
    };
  }

  /// 쌍방 매칭을 matches 컬렉션에 생성 (연락처 공개 트리거).
  /// 이미 생성된 쌍은 건너뛴다. 생성 수 반환.
  Future<int> createMatches(String sessionId) async {
    final aggregate = await aggregateFinalChoices(sessionId);
    final mutual = aggregate['mutual'] as List<List<String>>;
    final nicknames = aggregate['nicknames'] as Map<String, String>;
    final letters = aggregate['letters'] as Map<String, String>;
    if (mutual.isEmpty) {
      return 0;
    }

    final existingSnap =
        await _fs.matches.where('sessionId', isEqualTo: sessionId).get();
    final existingPairs = existingSnap.docs
        .map((doc) => ((doc.data()['pair'] as List?) ?? const [])
            .map((uid) => uid.toString())
            .toList()
          ..sort())
        .map((pair) => pair.join('|'))
        .toSet();

    final batch = _fs.db.batch();
    var created = 0;
    for (final pair in mutual) {
      final key = ([...pair]..sort()).join('|');
      if (existingPairs.contains(key)) {
        continue;
      }
      batch.set(_fs.matches.doc(), {
        'sessionId': sessionId,
        'pair': pair,
        'nicknames': {
          pair[0]: nicknames[pair[0]] ?? pair[0],
          pair[1]: nicknames[pair[1]] ?? pair[1],
        },
        'letters': {
          if (letters[pair[0]] != null) pair[0]: letters[pair[0]],
          if (letters[pair[1]] != null) pair[1]: letters[pair[1]],
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      created += 1;
    }
    if (created > 0) {
      await batch.commit();
    }
    return created;
  }

  // ── 케미 리포트 생성 (규칙 기반 v0 — Gemini Functions 전 임시) ──

  /// 참가자별 선택 흐름 기반 간단 리포트 생성. 생성 수 반환.
  Future<int> generateBasicReports(String sessionId) async {
    final participantSnap = await _fs.participants(sessionId).get();
    final choiceSnap = await _fs.choices(sessionId).get();
    final choicesByUid = {
      for (final doc in choiceSnap.docs) doc.id: doc.data(),
    };
    final existingSnap =
        await _fs.reports.where('sessionId', isEqualTo: sessionId).get();
    final alreadyReported = existingSnap.docs
        .map((doc) => (doc.data()['uid'] as String?) ?? '')
        .toSet();

    final batch = _fs.db.batch();
    var created = 0;
    for (final doc in participantSnap.docs) {
      if (alreadyReported.contains(doc.id)) {
        continue;
      }
      final participant = EventParticipant.fromDoc(doc);
      final choice = choicesByUid[doc.id] ?? const <String, dynamic>{};
      final first = (choice['first'] as List?) ?? const [];
      final mid = (choice['mid'] as List?) ?? const [];
      final finalMap = (choice['final'] as Map<String, dynamic>?) ?? const {};
      final consistent = first.isNotEmpty &&
          finalMap['first'] != null &&
          first.first == finalMap['first'];

      final items = <String>[
        if (first.isNotEmpty) '첫인상 선택 제출 완료',
        if (mid.isNotEmpty) '중간(베이킹 파트너) 선택 제출 완료',
        if (finalMap['first'] != null) '최종 선택 제출 완료',
        consistent ? '첫인상 → 최종까지 선택 일관성 높음' : '대화 후 선택이 달라진 열린 탐색형',
      ];
      batch.set(_fs.reports.doc(), {
        'sessionId': sessionId,
        'uid': doc.id,
        'model': 'rule-based-v0',
        'promptVersion': 'v0',
        'content': {
          'nickname': participant.nickname,
          'summary': consistent
              ? '${participant.nickname}님은 첫인상과 최종 선택이 일치한 확신형 참가자였어요.'
              : '${participant.nickname}님은 대화를 통해 마음이 움직인 탐색형 참가자였어요.',
          'score': participant.chemistryScore ?? 0,
          'items': items,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      created += 1;
    }
    if (created > 0) {
      await batch.commit();
    }
    return created;
  }

  // ── 후기 ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchReviews(String sessionId) async {
    final snap =
        await _fs.reviews.where('sessionId', isEqualTo: sessionId).get();
    return snap.docs
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList(growable: false);
  }
}
