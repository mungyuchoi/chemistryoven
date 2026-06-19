import '../models/demo_models.dart';

/// 앱이 사용하는 데이터 접근 인터페이스.
///
/// 구현체:
/// - [MockChemistryRepository] : 데모(더미) 데이터
/// - [FirestoreChemistryRepository] : 실데이터(현재는 캐릭터만 Firestore, 나머지는 Mock 위임)
///
/// 전환 설계는 docs/ARCHITECTURE_PLAN.md §2 참고.
abstract class ChemistryRepository {
  List<ChemistryClass> fetchClasses();
  ChemistryClass fetchFeaturedClass();
  List<DemoApplicant> fetchApplicants();
  List<EventRound> fetchEventRounds();
  List<SeatAssignment> fetchSeatAssignments();
  List<ChoiceSummary> fetchChoiceSummaries();
  List<MatchingPair> fetchMatches();
  List<ChemistryReport> fetchReports();
  DemoParticipantProfile fetchParticipantProfile();
  List<ChoiceCandidate> fetchChoiceCandidates();
  List<ChemistryCharacter> fetchCharacters();
  ChemistryCharacter fetchFeaturedCharacter();
  Map<OnboardingStep, List<String>> fetchOnboardingChoices();
  List<AdminScoreRow> fetchAdminScoreRows();
}
