import '../dummy/dummy_chemistry_data.dart';
import '../models/demo_models.dart';

class MockChemistryRepository {
  const MockChemistryRepository();

  List<ChemistryClass> fetchClasses() {
    return List.unmodifiable(demoClasses);
  }

  ChemistryClass fetchFeaturedClass() {
    return demoClasses.first;
  }

  List<DemoApplicant> fetchApplicants() {
    return demoApplicants.map((applicant) => applicant.copyWith()).toList();
  }

  List<EventRound> fetchEventRounds() {
    return demoRounds.map((round) => round.copyWith()).toList();
  }

  List<SeatAssignment> fetchSeatAssignments() {
    return List.unmodifiable(demoSeatAssignments);
  }

  List<ChoiceSummary> fetchChoiceSummaries() {
    return List.unmodifiable(demoChoiceSummaries);
  }

  List<MatchingPair> fetchMatches() {
    return demoMatches.map((match) => match.copyWith()).toList();
  }

  List<ChemistryReport> fetchReports() {
    return demoReports.map((report) => report.copyWith()).toList();
  }

  DemoParticipantProfile fetchParticipantProfile() {
    return demoParticipantProfile;
  }

  List<ChoiceCandidate> fetchChoiceCandidates() {
    return List.unmodifiable(demoChoiceCandidates);
  }
}
