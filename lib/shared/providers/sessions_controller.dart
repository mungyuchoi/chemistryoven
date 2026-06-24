import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/chemistry_session.dart';
import '../../data/repositories/session_repository.dart';

/// Firestore 회차(sessions)를 실시간으로 로드해 화면에 제공한다.
/// 로그인 직후 [start] 를 호출한다(읽기에 인증 필요).
class SessionsController extends ChangeNotifier {
  final List<ChemistrySession> _sessions = [];
  bool _loaded = false;
  StreamSubscription<List<ChemistrySession>>? _sub;

  List<ChemistrySession> get sessions => List.unmodifiable(_sessions);
  bool get isLoaded => _loaded;
  bool get isEmpty => _loaded && _sessions.isEmpty;

  /// 회차 스트림 구독 시작(중복 호출 안전).
  void start() {
    if (_sub != null) {
      return;
    }
    _sub = SessionRepository.instance.watchSessions().listen(
      (list) {
        _sessions
          ..clear()
          ..addAll(list);
        _loaded = true;
        notifyListeners();
      },
      onError: (Object error) {
        // 로그인 전/권한 등으로 실패할 수 있음 — 무시
        debugPrint('[sessions] 구독 오류: $error');
      },
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
