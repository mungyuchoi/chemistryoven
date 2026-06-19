import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/firebase_service.dart';
import '../models/demo_models.dart';
import 'chemistry_repository.dart';
import 'mock_chemistry_repository.dart';

/// 실데이터 리포지토리.
///
/// 현재 단계(Phase 3)에서는 **캐릭터(도감 20종)만 Firestore**에서 읽고,
/// 나머지(회차/신청/리포트 등)는 아직 [MockChemistryRepository]에 위임한다.
/// 이후 Phase에서 하나씩 Firestore 구현으로 교체한다.
///
/// 동기 UI를 유지하기 위해 앱 시작 시 [warmUp]에서 캐릭터를 미리 캐시한다.
/// Firestore가 비어 있거나(시드 전) 오류가 나면 더미 데이터로 폴백한다.
class FirestoreChemistryRepository implements ChemistryRepository {
  FirestoreChemistryRepository();

  final MockChemistryRepository _mock = const MockChemistryRepository();
  List<ChemistryCharacter>? _charactersCache;

  /// 앱 시작 시 1회 호출. 캐릭터를 미리 로드한다(실패 시 폴백).
  Future<void> warmUp() async {
    try {
      final snapshot = await FirebaseService.instance.characters
          .orderBy('order')
          .get();
      if (snapshot.docs.isNotEmpty) {
        _charactersCache =
            snapshot.docs.map(characterFromDoc).toList(growable: false);
      }
    } catch (_) {
      // 권한/네트워크/시드 전 등 — 더미로 폴백
      _charactersCache = null;
    }
  }

  // ── 캐릭터: Firestore (폴백: Mock) ───────────────────────────
  @override
  List<ChemistryCharacter> fetchCharacters() {
    final cache = _charactersCache;
    if (cache != null && cache.isNotEmpty) {
      return List.unmodifiable(cache);
    }
    return _mock.fetchCharacters();
  }

  @override
  ChemistryCharacter fetchFeaturedCharacter() {
    final cache = _charactersCache;
    if (cache != null && cache.isNotEmpty) {
      return cache.firstWhere(
        (character) => !character.forMen,
        orElse: () => cache.first,
      );
    }
    return _mock.fetchFeaturedCharacter();
  }

  // ── 나머지: 아직 Mock 위임 ───────────────────────────────────
  @override
  List<ChemistryClass> fetchClasses() => _mock.fetchClasses();
  @override
  ChemistryClass fetchFeaturedClass() => _mock.fetchFeaturedClass();
  @override
  List<DemoApplicant> fetchApplicants() => _mock.fetchApplicants();
  @override
  List<EventRound> fetchEventRounds() => _mock.fetchEventRounds();
  @override
  List<SeatAssignment> fetchSeatAssignments() => _mock.fetchSeatAssignments();
  @override
  List<ChoiceSummary> fetchChoiceSummaries() => _mock.fetchChoiceSummaries();
  @override
  List<MatchingPair> fetchMatches() => _mock.fetchMatches();
  @override
  List<ChemistryReport> fetchReports() => _mock.fetchReports();
  @override
  DemoParticipantProfile fetchParticipantProfile() =>
      _mock.fetchParticipantProfile();
  @override
  List<ChoiceCandidate> fetchChoiceCandidates() =>
      _mock.fetchChoiceCandidates();
  @override
  Map<OnboardingStep, List<String>> fetchOnboardingChoices() =>
      _mock.fetchOnboardingChoices();
  @override
  List<AdminScoreRow> fetchAdminScoreRows() => _mock.fetchAdminScoreRows();
}

// ── Firestore <-> 모델 매핑 (시더와 공유) ──────────────────────
Map<String, dynamic> characterToMap(ChemistryCharacter character, int order) {
  return {
    'id': character.id,
    'initial': character.initial,
    'name': character.name,
    'englishName': character.englishName,
    'summary': character.summary,
    'description': character.description,
    'tags': character.tags,
    'matchHint': character.matchHint,
    'forMen': character.forMen,
    'order': order,
  };
}

ChemistryCharacter characterFromDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();
  return ChemistryCharacter(
    id: (data['id'] as String?) ?? doc.id,
    initial: (data['initial'] as String?) ?? '',
    name: (data['name'] as String?) ?? '',
    englishName: (data['englishName'] as String?) ?? '',
    summary: (data['summary'] as String?) ?? '',
    description: (data['description'] as String?) ?? '',
    tags: ((data['tags'] as List<dynamic>?) ?? const <dynamic>[])
        .map((tag) => tag.toString())
        .toList(growable: false),
    matchHint: (data['matchHint'] as String?) ?? '',
    forMen: (data['forMen'] as bool?) ?? false,
  );
}
