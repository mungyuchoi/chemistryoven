import 'package:flutter/foundation.dart';

class DemoSessionController extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;
  String _displayName = '지윤';

  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => !_isLoggedIn;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String get displayName => _displayName;
  String get maskedPhone => '010-****-2398';

  void loginAsDemoUser({String displayName = '지윤'}) {
    _displayName = displayName;
    _isLoggedIn = true;
    notifyListeners();
  }

  void completeOnboarding() {
    _displayName = '지윤';
    _isLoggedIn = true;
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  void signOut() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void resetGuest() {
    _isLoggedIn = false;
    _hasCompletedOnboarding = false;
    _displayName = '지윤';
    notifyListeners();
  }
}
