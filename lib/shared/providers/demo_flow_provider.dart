import 'package:flutter/foundation.dart';

import '../../data/models/demo_models.dart';
import '../../data/repositories/mock_chemistry_repository.dart';

class DemoFlowProvider extends ChangeNotifier {
  DemoFlowProvider(this._repository);

  final MockChemistryRepository _repository;

  DemoFlowStep _currentStep = DemoFlowStep.beforeApplication;
  String? _selectedClassId;
  final Map<ChoicePhase, String> _selectedChoices = <ChoicePhase, String>{};
  String _finalMessage = '오늘 대화가 편안해서 조금 더 알아가 보고 싶어요.';
  bool _reviewWritten = false;

  List<DemoFlowStep> get steps => DemoFlowStep.values;
  DemoFlowStep get currentStep => _currentStep;
  int get currentIndex => steps.indexOf(_currentStep);
  bool get reviewWritten => _reviewWritten;
  String get finalMessage => _finalMessage;
  Map<ChoicePhase, String> get selectedChoices =>
      Map.unmodifiable(_selectedChoices);

  ChemistryClass get featuredClass => _repository.fetchFeaturedClass();

  ChemistryClass get selectedClass {
    final classes = _repository.fetchClasses();
    return classes.firstWhere(
      (demoClass) => demoClass.id == _selectedClassId,
      orElse: () => featuredClass,
    );
  }

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
      _finalMessage = '오늘 대화가 편안해서 조금 더 알아가 보고 싶어요.';
    }
    _prefillChoiceIfNeeded();
    notifyListeners();
  }

  void selectChoice(ChoicePhase phase, String nickname) {
    _selectedChoices[phase] = nickname;
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
        _currentStep = DemoFlowStep.rotationTalk;
        break;
      case DemoFlowStep.middleChoice:
        _currentStep = DemoFlowStep.seatingGuide;
        break;
      case DemoFlowStep.finalChoice:
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

  void submitReview() {
    _reviewWritten = true;
    _currentStep = DemoFlowStep.review;
    notifyListeners();
  }

  void reset() {
    _currentStep = DemoFlowStep.beforeApplication;
    _selectedClassId = null;
    _selectedChoices.clear();
    _reviewWritten = false;
    _finalMessage = '오늘 대화가 편안해서 조금 더 알아가 보고 싶어요.';
    notifyListeners();
  }

  void _prefillChoiceIfNeeded() {
    final phase = currentChoicePhase;
    if (phase == null || _selectedChoices.containsKey(phase)) {
      return;
    }
    final candidates = _repository.fetchChoiceCandidates();
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
}
