import 'package:flutter/foundation.dart';

import '../../data/models/demo_models.dart';

class DemoModeController extends ChangeNotifier {
  DemoMode _mode = DemoMode.guest;

  DemoMode get mode => _mode;
  bool get isGuest => _mode == DemoMode.guest;
  bool get isUser => _mode == DemoMode.user;
  bool get isParticipantToday => _mode == DemoMode.participantToday;
  bool get isAdmin => _mode == DemoMode.admin;

  void setMode(DemoMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    notifyListeners();
  }
}
