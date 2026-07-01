import 'package:flutter/foundation.dart';

import '../../data/models/user_profile.dart';
import '../../services/firebase_service.dart';

/// 로그인 사용자(users/{uid})를 로드해 화면에 제공한다.
/// 로그인 직후, 온보딩 완료 후 [load] 를 호출한다.
class CurrentUserController extends ChangeNotifier {
  UserProfile? _profile;
  bool _loading = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _loading;

  Future<void> load() async {
    final uid = FirebaseService.instance.uid;
    if (uid == null) {
      _profile = null;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseService.instance.userDoc(uid).get();
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        // 온보딩 설문 결과는 서브컬렉션(users/{uid}/onboarding/current)에서 읽는다.
        final onboardingSnap =
            await FirebaseService.instance.onboardingDoc(uid).get();
        _profile = UserProfile.fromMap(
          uid,
          data,
          onboardingData: onboardingSnap.data(),
        );
      } else {
        _profile = null;
      }
    } catch (_) {
      _profile = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _profile = null;
    notifyListeners();
  }
}
