import 'package:flutter/foundation.dart';

import '../../data/models/demo_models.dart';
import '../../data/repositories/chemistry_repository.dart';
import 'demo_flow_provider.dart';

class AdminDemoProvider extends ChangeNotifier {
  AdminDemoProvider(this._repository, this._flowProvider) {
    reset();
  }

  final ChemistryRepository _repository;
  final DemoFlowProvider _flowProvider;

  late List<DemoApplicant> _applicants;
  late List<EventRound> _rounds;
  late List<MatchingPair> _matches;
  late List<ChemistryReport> _reports;

  bool _aiResultVisible = false;
  bool _participantsLocked = false;
  bool _paymentsConfirmed = false;
  bool _seatsAssigned = false;
  bool _choicesAggregated = false;
  bool _matchingApproved = false;
  int _currentRoundIndex = 0;

  List<DemoApplicant> get applicants => List.unmodifiable(_applicants);
  List<EventRound> get rounds => List.unmodifiable(_rounds);
  List<MatchingPair> get matches => List.unmodifiable(_matches);
  List<ChemistryReport> get reports => List.unmodifiable(_reports);

  bool get aiResultVisible => _aiResultVisible;
  bool get participantsLocked => _participantsLocked;
  bool get paymentsConfirmed => _paymentsConfirmed;
  bool get seatsAssigned => _seatsAssigned;
  bool get choicesAggregated => _choicesAggregated;
  bool get matchingApproved => _matchingApproved;
  int get currentRoundIndex => _currentRoundIndex;

  int get pendingVerificationCount =>
      _applicants.where((applicant) => !applicant.verified).length;
  int get selectedCount =>
      _applicants.where((applicant) => applicant.selected).length;
  int get paidCount => _applicants.where((applicant) => applicant.paid).length;
  int get sentReportCount => _reports.where((report) => report.sent).length;

  void approveVerification(String applicantId) {
    _updateApplicant(
      applicantId,
      (applicant) => applicant.copyWith(verified: true, status: '인증 승인'),
    );
  }

  void rejectVerification(String applicantId) {
    _updateApplicant(
      applicantId,
      (applicant) => applicant.copyWith(verified: false, status: '인증 반려'),
    );
  }

  void runAiSelection() {
    _aiResultVisible = true;
    final sorted = [..._applicants]..sort((a, b) => b.score.compareTo(a.score));
    final selectedIds = sorted.take(4).map((applicant) => applicant.id).toSet();
    _applicants = _applicants.map((applicant) {
      final selected = selectedIds.contains(applicant.id);
      return applicant.copyWith(
        selected: selected,
        status: selected ? 'AI 선정' : applicant.status,
      );
    }).toList();
    _flowProvider.syncFromAdmin(DemoFlowStep.selected);
    notifyListeners();
  }

  void lockParticipants() {
    _participantsLocked = true;
    _applicants = _applicants.map((applicant) {
      if (!applicant.selected) {
        return applicant;
      }
      return applicant.copyWith(status: '최종 참가자');
    }).toList();
    _flowProvider.syncFromAdmin(DemoFlowStep.paymentWaiting);
    notifyListeners();
  }

  void confirmPayments() {
    _paymentsConfirmed = true;
    _applicants = _applicants.map((applicant) {
      if (!applicant.selected) {
        return applicant;
      }
      return applicant.copyWith(paid: true, status: '입금 확인');
    }).toList();
    _flowProvider.syncFromAdmin(DemoFlowStep.confirmed);
    notifyListeners();
  }

  void assignSeats() {
    _seatsAssigned = true;
    const seats = ['A-1', 'A-2', 'B-1', 'B-2'];
    var seatIndex = 0;
    _applicants = _applicants.map((applicant) {
      if (!applicant.selected) {
        return applicant;
      }
      final seat = seats[seatIndex % seats.length];
      seatIndex += 1;
      return applicant.copyWith(seat: seat);
    }).toList();
    _flowProvider.syncFromAdmin(DemoFlowStep.nicknameCheck);
    notifyListeners();
  }

  void nextRound() {
    if (_currentRoundIndex >= _rounds.length - 1) {
      return;
    }
    _rounds = _rounds.asMap().entries.map((entry) {
      if (entry.key < _currentRoundIndex) {
        return entry.value.copyWith(status: '완료');
      }
      if (entry.key == _currentRoundIndex) {
        return entry.value.copyWith(status: '완료');
      }
      if (entry.key == _currentRoundIndex + 1) {
        return entry.value.copyWith(status: '진행 중');
      }
      return entry.value;
    }).toList();
    _currentRoundIndex += 1;
    switch (_currentRoundIndex) {
      case 1:
        _flowProvider.syncFromAdmin(DemoFlowStep.firstImpressionChoice);
        break;
      case 2:
        _flowProvider.syncFromAdmin(DemoFlowStep.rotationTalk);
        break;
      case 3:
        _flowProvider.syncFromAdmin(DemoFlowStep.middleChoice);
        break;
      case 4:
        _flowProvider.syncFromAdmin(DemoFlowStep.seatingGuide);
        break;
      case 5:
        _flowProvider.syncFromAdmin(DemoFlowStep.pairBaking);
        break;
      case 6:
        _flowProvider.syncFromAdmin(DemoFlowStep.finalChoice);
        break;
      case 7:
        _flowProvider.syncFromAdmin(DemoFlowStep.matchResult);
        break;
    }
    notifyListeners();
  }

  void aggregateChoices() {
    _choicesAggregated = true;
    _flowProvider.syncFromAdmin(DemoFlowStep.matchResult);
    notifyListeners();
  }

  void approveMatching() {
    _matchingApproved = true;
    _matches = _matches
        .map((match) => match.copyWith(status: '운영자 승인'))
        .toList();
    _flowProvider.syncFromAdmin(DemoFlowStep.matchResult);
    notifyListeners();
  }

  void sendReports() {
    _reports = _reports.map((report) => report.copyWith(sent: true)).toList();
    _flowProvider.syncFromAdmin(DemoFlowStep.chemistryReport);
    notifyListeners();
  }

  void reset() {
    _applicants = _repository.fetchApplicants();
    _rounds = _repository.fetchEventRounds();
    if (_rounds.isNotEmpty) {
      _rounds[0] = _rounds[0].copyWith(status: '진행 중');
    }
    _matches = _repository.fetchMatches();
    _reports = _repository.fetchReports();
    _aiResultVisible = false;
    _participantsLocked = false;
    _paymentsConfirmed = false;
    _seatsAssigned = false;
    _choicesAggregated = false;
    _matchingApproved = false;
    _currentRoundIndex = 0;
    notifyListeners();
  }

  void _updateApplicant(
    String applicantId,
    DemoApplicant Function(DemoApplicant applicant) update,
  ) {
    _applicants = _applicants.map((applicant) {
      if (applicant.id != applicantId) {
        return applicant;
      }
      return update(applicant);
    }).toList();
    notifyListeners();
  }
}
