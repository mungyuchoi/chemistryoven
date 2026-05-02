import 'package:flutter/foundation.dart';

import '../../data/models/demo_models.dart';
import '../../data/repositories/mock_chemistry_repository.dart';

class DemoFlowProvider extends ChangeNotifier {
  DemoFlowProvider(this._repository);

  final MockChemistryRepository _repository;

  DemoFlowStep _currentStep = DemoFlowStep.beforeApplication;
  String? _selectedClassId;
  final Set<String> _selectedDesserts = <String>{};
  bool _reviewWritten = false;

  List<DemoFlowStep> get steps => DemoFlowStep.values;
  DemoFlowStep get currentStep => _currentStep;
  int get currentIndex => steps.indexOf(_currentStep);
  bool get reviewWritten => _reviewWritten;
  Set<String> get selectedDesserts => Set.unmodifiable(_selectedDesserts);

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
      if (_currentStep == DemoFlowStep.choice && _selectedDesserts.isEmpty) {
        _selectedDesserts.add('소금빵');
      }
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
      _selectedDesserts.clear();
      _reviewWritten = false;
    }
    notifyListeners();
  }

  void toggleDessert(String nickname) {
    if (_selectedDesserts.contains(nickname)) {
      _selectedDesserts.remove(nickname);
    } else {
      _selectedDesserts.add(nickname);
    }
    notifyListeners();
  }

  void submitChoices() {
    _currentStep = DemoFlowStep.matchResult;
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
    _selectedDesserts.clear();
    _reviewWritten = false;
    notifyListeners();
  }
}
