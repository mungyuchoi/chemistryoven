import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/chemistry_session.dart';
import '../../data/models/demo_models.dart';
import '../../data/models/event_flow_models.dart';
import '../../data/repositories/chemistry_repository.dart';
import '../../data/repositories/event_flow_repository.dart';

/// 오브닝 플로우 상태.
///
/// 두 가지 모드로 동작한다:
/// - 데모(기본): 기존과 동일하게 로컬 상태로만 단계를 진행.
/// - 라이브([attachLive] 호출 후): Firestore 와 하이브리드 동기화.
///   * 서버 → 앱: sessions/{id}.eventStage, applications/{uid}.status 가
///     바뀌면 단계를 앞으로만 이동(로컬 진행도 계속 가능).
///   * 앱 → 서버: 첫인상/중간/최종 선택·편지·장점 평가는 choices/{uid} 에,
///     후기는 reviews 에 저장.
///   * participants/seating/matches/reports 는 읽기 전용 구독
///     (쓰기는 운영자/Functions — firestore.rules §7).
class DemoFlowProvider extends ChangeNotifier {
  DemoFlowProvider(
    this._repository, {
    EventFlowRepository? eventFlowRepository,
  }) : _eventFlow = eventFlowRepository ?? EventFlowRepository.instance;

  static const String _defaultFinalMessage =
      '오늘 대화가 편안해서 조금 더 알아가 보고 싶어요.';

  final ChemistryRepository _repository;
  final EventFlowRepository _eventFlow;

  DemoFlowStep _currentStep = DemoFlowStep.beforeApplication;
  String? _selectedClassId;
  final Map<ChoicePhase, String> _selectedChoices = <ChoicePhase, String>{};
  String _finalMessage = _defaultFinalMessage;
  bool _reviewWritten = false;

  // 로테이션 단계에서 현재 선택된 상대 닉네임.
  String _rotationSelection = '소금빵';
  // 로테이션 장점 평가: '닉네임::장점' -> true(좋아요)/false(싫어요).
  final Map<String, bool> _traitVotes = <String, bool>{};
  // 최종 선택 2순위 닉네임.
  String? _finalSecondChoice;

  // ── 라이브 상태 ───────────────────────────────────────────────
  String? _liveSessionId;
  String? _liveUid;
  ChemistrySession? _liveSession;
  List<EventParticipant> _liveParticipants = const [];
  List<SeatingTable> _liveSeating = const [];
  MyChoices? _liveChoices;
  EventMatch? _liveMatch;
  EventReport? _liveReport;
  final List<StreamSubscription<dynamic>> _liveSubs =
      <StreamSubscription<dynamic>>[];

  bool get isLive => _liveSessionId != null;
  String? get liveSessionId => _liveSessionId;

  List<DemoFlowStep> get steps => DemoFlowStep.values;
  DemoFlowStep get currentStep => _currentStep;
  int get currentIndex => steps.indexOf(_currentStep);
  bool get reviewWritten => _reviewWritten;
  String get finalMessage => _finalMessage;
  String get rotationSelection => _rotationSelection;
  String? get finalSecondChoice => _finalSecondChoice;
  Map<ChoicePhase, String> get selectedChoices =>
      Map.unmodifiable(_selectedChoices);

  bool? traitVote(String nickname, String trait) {
    return _traitVotes['$nickname::$trait'];
  }

  ChemistryClass get featuredClass => _repository.fetchFeaturedClass();

  ChemistryClass get selectedClass {
    final live = _liveSession;
    if (live != null) {
      return live.toDisplayClass();
    }
    final classes = _repository.fetchClasses();
    return classes.firstWhere(
      (demoClass) => demoClass.id == _selectedClassId,
      orElse: () => featuredClass,
    );
  }

  // ── 라이브 연결 ───────────────────────────────────────────────

  /// 로그인 사용자가 신청한 회차를 찾은 뒤 호출한다.
  /// 서버 상태(신청 status, eventStage, 선택 문서 등)를 구독해
  /// 로컬 플로우와 동기화한다.
  void attachLive({
    required String sessionId,
    required String uid,
    ChemistrySession? session,
  }) {
    if (_liveSessionId == sessionId && _liveUid == uid) {
      return;
    }
    detachLive(notify: false);
    _liveSessionId = sessionId;
    _liveUid = uid;
    _liveSession = session;
    _selectedClassId = sessionId;

    _liveSubs.add(
      _eventFlow.watchSession(sessionId).listen(
        (doc) {
          if (doc.exists) {
            _liveSession = ChemistrySession.fromDoc(doc);
            final stage = doc.data()?['eventStage'] as String?;
            _applyServerStep(flowStepFromEventStage(stage));
          }
          notifyListeners();
        },
        onError: (Object error) =>
            debugPrint('[flow] session 구독 오류: $error'),
      ),
    );
    _liveSubs.add(
      _eventFlow.watchApplication(sessionId, uid).listen(
        (doc) {
          if (doc.exists) {
            final status = doc.data()?['status'] as String?;
            _applyServerStep(flowStepFromApplicationStatus(status));
          }
          notifyListeners();
        },
        onError: (Object error) =>
            debugPrint('[flow] application 구독 오류: $error'),
      ),
    );
    _liveSubs.add(
      _eventFlow.watchParticipants(sessionId).listen(
        (participants) {
          _liveParticipants = participants;
          _rebuildOthers();
          // 로스터보다 choices 문서가 먼저 도착한 경우를 위해 재수화.
          _hydrateFromChoices(_liveChoices);
          notifyListeners();
        },
        onError: (Object error) =>
            debugPrint('[flow] participants 구독 오류: $error'),
      ),
    );
    _liveSubs.add(
      _eventFlow.watchSeating(sessionId).listen(
        (tables) {
          _liveSeating = tables;
          notifyListeners();
        },
        onError: (Object error) =>
            debugPrint('[flow] seating 구독 오류: $error'),
      ),
    );
    _liveSubs.add(
      _eventFlow.watchMyChoices(sessionId, uid).listen(
        (choices) {
          _liveChoices = choices;
          _hydrateFromChoices(choices);
          notifyListeners();
        },
        onError: (Object error) =>
            debugPrint('[flow] choices 구독 오류: $error'),
      ),
    );
    _liveSubs.add(
      _eventFlow.watchMyMatches(uid, sessionId: sessionId).listen(
        (matches) {
          _liveMatch = matches.isEmpty ? null : matches.first;
          notifyListeners();
        },
        onError: (Object error) =>
            debugPrint('[flow] matches 구독 오류: $error'),
      ),
    );
    _liveSubs.add(
      _eventFlow.watchMyReports(uid, sessionId: sessionId).listen(
        (reports) {
          _liveReport = reports.isEmpty ? null : reports.first;
          notifyListeners();
        },
        onError: (Object error) =>
            debugPrint('[flow] reports 구독 오류: $error'),
      ),
    );

    // 신청 이후 상태이므로 최소 인증 대기 단계로.
    _applyServerStep(DemoFlowStep.verificationWaiting);
    notifyListeners();
  }

  void detachLive({bool notify = true}) {
    for (final sub in _liveSubs) {
      unawaited(sub.cancel());
    }
    _liveSubs.clear();
    _liveSessionId = null;
    _liveUid = null;
    _liveSession = null;
    _liveParticipants = const [];
    _liveOthers = const [];
    _liveSeating = const [];
    _liveChoices = null;
    _liveMatch = null;
    _liveReport = null;
    if (notify) {
      notifyListeners();
    }
  }

  /// 서버 단계는 앞으로만 반영한다 (로컬에서 이미 더 나아갔으면 유지).
  void _applyServerStep(DemoFlowStep? step) {
    if (step == null) {
      return;
    }
    if (steps.indexOf(step) > currentIndex) {
      _currentStep = step;
      _prefillChoiceIfNeeded();
    }
  }

  /// 서버 choices 문서 → 로컬 상태 복원 (로컬에 이미 값이 있으면 로컬 우선).
  void _hydrateFromChoices(MyChoices? choices) {
    if (choices == null) {
      return;
    }
    void fill(ChoicePhase phase, String? uid) {
      if (uid == null) {
        return;
      }
      final nickname = choices.nicknameOf(uid) ?? _nicknameForUid(uid);
      if (nickname != null && !_selectedChoices.containsKey(phase)) {
        _selectedChoices[phase] = nickname;
      }
    }

    fill(
      ChoicePhase.firstImpression,
      choices.first.isEmpty ? null : choices.first.first,
    );
    fill(ChoicePhase.middle, choices.mid.isEmpty ? null : choices.mid.first);
    fill(ChoicePhase.finalChoice, choices.finalFirst);
    final second = choices.finalSecond;
    _finalSecondChoice ??=
        choices.nicknameOf(second) ?? (second == null ? null : _nicknameForUid(second));
    if (_finalMessage == _defaultFinalMessage && choices.letter.isNotEmpty) {
      _finalMessage = choices.letter;
    }
    choices.traits.forEach((uid, votes) {
      final nickname = choices.nicknameOf(uid) ?? _nicknameForUid(uid);
      if (nickname == null) {
        return;
      }
      votes.forEach((trait, like) {
        _traitVotes.putIfAbsent('$nickname::$trait', () => like);
      });
    });
  }

  // ── 라이브 파생 데이터 (없으면 데모 데이터로 폴백) ─────────────

  EventParticipant? get myParticipant {
    final uid = _liveUid;
    if (uid == null) {
      return null;
    }
    for (final participant in _liveParticipants) {
      if (participant.uid == uid) {
        return participant;
      }
    }
    return null;
  }

  /// 상단 닉네임 카드 등에서 쓰는 내 프로필.
  DemoParticipantProfile get participantProfile {
    final mine = myParticipant;
    if (mine == null) {
      return _repository.fetchParticipantProfile();
    }
    return DemoParticipantProfile(
      nickname: mine.nickname,
      gender: mine.gender == 'M' ? '남' : (mine.gender == 'F' ? '여' : ''),
      seat: mine.tableId ?? '입장 후 안내',
      keywords: mine.taste,
    );
  }

  /// 선택(투표) 후보. 라이브면 나를 제외한 참가자(성별 정보가 있으면 이성만).
  List<ChoiceCandidate> get choiceCandidates {
    final others = _liveOthers;
    if (others.isEmpty) {
      return _repository.fetchChoiceCandidates();
    }
    return others
        .map((participant) => participant.toChoiceCandidate())
        .toList(growable: false);
  }

  /// 로테이션 카드에 띄울 상대 프로필들 (라이브 전용, 비어 있으면 데모 폴백).
  List<EventParticipant> get rotationProfiles => _liveOthers;

  EventParticipant? liveProfileOf(String nickname) {
    for (final participant in _liveOthers) {
      if (participant.nickname == nickname) {
        return participant;
      }
    }
    return null;
  }

  List<EventParticipant> _liveOthers = const [];

  void _rebuildOthers() {
    final uid = _liveUid;
    if (uid == null) {
      _liveOthers = const [];
      return;
    }
    final myGender = myParticipant?.gender ?? '';
    final others = _liveParticipants
        .where((participant) => participant.uid != uid)
        .toList(growable: false);
    if (myGender.isEmpty) {
      _liveOthers = others;
      return;
    }
    final opposite = others
        .where(
          (participant) =>
              participant.gender.isNotEmpty && participant.gender != myGender,
        )
        .toList(growable: false);
    _liveOthers = opposite.isEmpty ? others : opposite;
  }

  /// 내 테이블 좌석도 (자리배치 단계).
  SeatingTable? get myTable {
    final uid = _liveUid;
    if (uid == null) {
      return null;
    }
    for (final table in _liveSeating) {
      if (table.containsUid(uid)) {
        return table;
      }
    }
    final tableId = myParticipant?.tableId;
    if (tableId == null) {
      return null;
    }
    for (final table in _liveSeating) {
      if (table.tableId == tableId) {
        return table;
      }
    }
    return null;
  }

  SeatEntry? get myPairSeat {
    final uid = _liveUid;
    return uid == null ? null : myTable?.pairOf(uid);
  }

  List<SeatEntry> get myOppositeSeats {
    final uid = _liveUid;
    return uid == null ? const [] : (myTable?.oppositesOf(uid) ?? const []);
  }

  /// 매칭 결과 (matches 는 Functions/운영자가 생성 — 없으면 집계 중).
  EventMatch? get liveMatch => _liveMatch;
  bool get liveMatchPending => isLive && _liveMatch == null;

  String? get matchPartnerUid {
    final uid = _liveUid;
    return uid == null ? null : _liveMatch?.partnerOf(uid);
  }

  String? get matchPartnerNickname {
    final partnerUid = matchPartnerUid;
    if (partnerUid == null) {
      return null;
    }
    return _liveMatch?.nicknames[partnerUid] ?? _nicknameForUid(partnerUid);
  }

  /// 상대가 남긴 편지 (matches.letters — Functions 가 choices 에서 복사).
  String? get matchPartnerLetter {
    final partnerUid = matchPartnerUid;
    return partnerUid == null ? null : _liveMatch?.letters[partnerUid];
  }

  /// 내 케미 리포트 (없으면 null → 화면에서 데모 리포트 폴백).
  ChemistryReport? get liveReport => _liveReport?.toDisplayReport();

  String? _nicknameForUid(String uid) {
    for (final participant in _liveParticipants) {
      if (participant.uid == uid) {
        return participant.nickname;
      }
    }
    return null;
  }

  String? _uidForNickname(String nickname) {
    for (final participant in _liveParticipants) {
      if (participant.nickname == nickname) {
        return participant.uid;
      }
    }
    return null;
  }

  Map<String, String> _nicknameMap(Iterable<String?> uids) {
    final map = <String, String>{};
    for (final uid in uids) {
      if (uid == null) {
        continue;
      }
      final nickname = _nicknameForUid(uid);
      if (nickname != null) {
        map[uid] = nickname;
      }
    }
    return map;
  }

  // ── 플로우 진행 (기존 데모 동작 유지) ──────────────────────────

  double get progress {
    if (steps.length <= 1) {
      return 0;
    }
    return currentIndex / (steps.length - 1);
  }

  ChoicePhase? get currentChoicePhase {
    switch (_currentStep) {
      case DemoFlowStep.firstImpressionChoice:
        return ChoicePhase.firstImpression;
      case DemoFlowStep.middleChoice:
        return ChoicePhase.middle;
      case DemoFlowStep.finalChoice:
        return ChoicePhase.finalChoice;
      case DemoFlowStep.beforeApplication:
      case DemoFlowStep.verificationWaiting:
      case DemoFlowStep.verificationApproved:
      case DemoFlowStep.aiSelectionWaiting:
      case DemoFlowStep.selected:
      case DemoFlowStep.paymentWaiting:
      case DemoFlowStep.confirmed:
      case DemoFlowStep.nicknameCheck:
      case DemoFlowStep.rotationTalk:
      case DemoFlowStep.seatingGuide:
      case DemoFlowStep.pairBaking:
      case DemoFlowStep.matchResult:
      case DemoFlowStep.chemistryReport:
      case DemoFlowStep.review:
        return null;
    }
  }

  String? selectedChoiceFor(ChoicePhase phase) {
    return _selectedChoices[phase];
  }

  void applyForClass(String classId) {
    _selectedClassId = classId;
    _currentStep = DemoFlowStep.verificationWaiting;
    _reviewWritten = false;
    notifyListeners();
  }

  void advance() {
    if (_currentStep == DemoFlowStep.review) {
      reset();
      return;
    }

    final nextIndex = currentIndex + 1;
    if (nextIndex < steps.length) {
      _currentStep = steps[nextIndex];
      _prefillChoiceIfNeeded();
      notifyListeners();
    }
  }

  void back() {
    final previousIndex = currentIndex - 1;
    if (previousIndex >= 0) {
      _currentStep = steps[previousIndex];
      notifyListeners();
    }
  }

  void jumpTo(DemoFlowStep step) {
    _currentStep = step;
    if (step == DemoFlowStep.beforeApplication) {
      _selectedClassId = null;
      _selectedChoices.clear();
      _reviewWritten = false;
      _finalMessage = _defaultFinalMessage;
    }
    _prefillChoiceIfNeeded();
    notifyListeners();
  }

  void selectChoice(ChoicePhase phase, String nickname) {
    _selectedChoices[phase] = nickname;
    notifyListeners();
  }

  void selectRotationPartner(String nickname) {
    _rotationSelection = nickname;
    notifyListeners();
  }

  // 같은 버튼을 다시 누르면 평가를 해제하는 토글 동작.
  void toggleTraitVote(String nickname, String trait, bool like) {
    final key = '$nickname::$trait';
    if (_traitVotes[key] == like) {
      _traitVotes.remove(key);
    } else {
      _traitVotes[key] = like;
    }
    _persistTraitVote(nickname, trait, _traitVotes[key]);
    notifyListeners();
  }

  void selectFinalSecondChoice(String? nickname) {
    _finalSecondChoice = nickname;
    notifyListeners();
  }

  void updateFinalMessage(String message) {
    _finalMessage = message;
    notifyListeners();
  }

  void submitCurrentChoice() {
    _prefillChoiceIfNeeded();
    switch (_currentStep) {
      case DemoFlowStep.firstImpressionChoice:
        _persistChoice(ChoicePhase.firstImpression);
        _currentStep = DemoFlowStep.rotationTalk;
        break;
      case DemoFlowStep.middleChoice:
        _persistChoice(ChoicePhase.middle);
        _currentStep = DemoFlowStep.seatingGuide;
        break;
      case DemoFlowStep.finalChoice:
        _persistChoice(ChoicePhase.finalChoice);
        _currentStep = DemoFlowStep.matchResult;
        break;
      case DemoFlowStep.beforeApplication:
      case DemoFlowStep.verificationWaiting:
      case DemoFlowStep.verificationApproved:
      case DemoFlowStep.aiSelectionWaiting:
      case DemoFlowStep.selected:
      case DemoFlowStep.paymentWaiting:
      case DemoFlowStep.confirmed:
      case DemoFlowStep.nicknameCheck:
      case DemoFlowStep.rotationTalk:
      case DemoFlowStep.seatingGuide:
      case DemoFlowStep.pairBaking:
      case DemoFlowStep.matchResult:
      case DemoFlowStep.chemistryReport:
      case DemoFlowStep.review:
        advance();
        return;
    }
    notifyListeners();
  }

  void syncFromAdmin(DemoFlowStep step) {
    _selectedClassId ??= featuredClass.id;
    if (steps.indexOf(step) > currentIndex) {
      _currentStep = step;
    }
    _prefillChoiceIfNeeded();
    notifyListeners();
  }

  /// 후기 제출. 라이브 모드면 reviews 컬렉션에도 저장한다.
  void submitReview({
    int stars = 5,
    String type = '참여 후기',
    String text = '',
  }) {
    _reviewWritten = true;
    _currentStep = DemoFlowStep.review;
    final sessionId = _liveSessionId;
    final uid = _liveUid;
    if (sessionId != null && uid != null) {
      unawaited(
        _eventFlow
            .submitReview(
              sessionId: sessionId,
              uid: uid,
              stars: stars,
              type: type,
              text: text,
            )
            .catchError(
              (Object error) => debugPrint('[flow] 후기 저장 실패: $error'),
            ),
      );
    }
    notifyListeners();
  }

  void reset() {
    _currentStep = DemoFlowStep.beforeApplication;
    _selectedClassId = null;
    _selectedChoices.clear();
    _reviewWritten = false;
    _finalMessage = _defaultFinalMessage;
    _rotationSelection = '소금빵';
    _traitVotes.clear();
    _finalSecondChoice = null;
    notifyListeners();
  }

  // ── Firestore 저장 (라이브 모드에서만 동작) ────────────────────

  void _persistChoice(ChoicePhase phase) {
    final sessionId = _liveSessionId;
    final uid = _liveUid;
    if (sessionId == null || uid == null) {
      return;
    }
    final picked = _selectedChoices[phase];
    final pickedUid = picked == null ? null : _uidForNickname(picked);
    if (pickedUid == null) {
      debugPrint('[flow] $phase 저장 건너뜀 — 후보($picked)의 uid 를 찾지 못함');
      return;
    }

    Future<void> write;
    switch (phase) {
      case ChoicePhase.firstImpression:
        write = _eventFlow.saveFirstImpression(
          sessionId,
          uid,
          pickedUids: [pickedUid],
          nicknames: _nicknameMap([pickedUid]),
        );
        break;
      case ChoicePhase.middle:
        write = _eventFlow.saveMidChoice(
          sessionId,
          uid,
          pickedUids: [pickedUid],
          nicknames: _nicknameMap([pickedUid]),
        );
        break;
      case ChoicePhase.finalChoice:
        final secondUid = _finalSecondChoice == null
            ? null
            : _uidForNickname(_finalSecondChoice!);
        write = _eventFlow.saveFinalChoice(
          sessionId,
          uid,
          firstUid: pickedUid,
          secondUid: secondUid,
          letter: _finalMessage,
          nicknames: _nicknameMap([pickedUid, secondUid]),
        );
        break;
    }
    unawaited(
      write.catchError(
        (Object error) => debugPrint('[flow] $phase 저장 실패: $error'),
      ),
    );
  }

  void _persistTraitVote(String nickname, String trait, bool? like) {
    final sessionId = _liveSessionId;
    final uid = _liveUid;
    if (sessionId == null || uid == null) {
      return;
    }
    final targetUid = _uidForNickname(nickname);
    if (targetUid == null) {
      return;
    }
    unawaited(
      _eventFlow
          .saveTraitVote(
            sessionId,
            uid,
            targetUid: targetUid,
            trait: trait,
            like: like,
          )
          .catchError(
            (Object error) => debugPrint('[flow] 장점 평가 저장 실패: $error'),
          ),
    );
  }

  /// 선택 단계 진입 시 기본 후보를 미리 채운다 (라이브면 실제 로스터 기준).
  void _prefillChoiceIfNeeded() {
    final phase = currentChoicePhase;
    if (phase == null || _selectedChoices.containsKey(phase)) {
      return;
    }
    final candidates = choiceCandidates;
    if (candidates.isEmpty) {
      return;
    }
    final index = switch (phase) {
      ChoicePhase.firstImpression => 0,
      ChoicePhase.middle => 1,
      ChoicePhase.finalChoice => 0,
    };
    _selectedChoices[phase] = candidates[index % candidates.length].nickname;
  }

  @override
  void dispose() {
    detachLive(notify: false);
    super.dispose();
  }
}
