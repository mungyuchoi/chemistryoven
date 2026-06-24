import 'package:flutter/foundation.dart';

class DemoSessionController extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _hasCompletedOnboarding = false;
  bool _entered = false;
  String _displayName = '참가자 A';

  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => !_isLoggedIn;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  /// 로그인 화면을 지나 앱(메인 탭)에 진입했는지. 로그아웃 시 false.
  bool get entered => _entered;
  String get displayName => _displayName;
  String get maskedPhone => '010-****-0000';

  /// 로그인/게스트 진입 완료 → 메인 탭 표시.
  void markEntered() {
    _entered = true;
    notifyListeners();
  }

  /// 로그아웃 → 로그인 화면으로.
  void exitToLogin() {
    _entered = false;
    _isLoggedIn = false;
    _hasCompletedOnboarding = false;
    _displayName = '참가자 A';
    notifyListeners();
  }

  void loginAsDemoUser({String displayName = '참가자 A'}) {
    _displayName = displayName;
    _isLoggedIn = true;
    notifyListeners();
  }

  void completeOnboarding() {
    _displayName = '참가자 A';
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
    _displayName = '참가자 A';
    notifyListeners();
  }
}
