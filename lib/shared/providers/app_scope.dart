import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../data/models/demo_models.dart';
import '../../data/repositories/application_repository.dart';
import '../../data/repositories/chemistry_repository.dart';
import '../../data/repositories/mock_chemistry_repository.dart';
import '../../services/fcm_service.dart';
import 'admin_demo_provider.dart';
import 'current_user_controller.dart';
import 'demo_flow_provider.dart';
import 'demo_mode_controller.dart';
import 'demo_session_controller.dart';
import 'sessions_controller.dart';

class AppState extends ChangeNotifier {
  AppState._({
    required this.repository,
    required this.sessionController,
    required this.modeController,
    required this.flowProvider,
    required this.adminProvider,
    required this.currentUserController,
    required this.sessionsController,
  }) {
    sessionController.addListener(_notify);
    modeController.addListener(_notify);
    flowProvider.addListener(_notify);
    adminProvider.addListener(_notify);
    currentUserController.addListener(_notify);
    sessionsController.addListener(_notify);
  }

  factory AppState.create({ChemistryRepository? repository}) {
    final ChemistryRepository repo = repository ?? const MockChemistryRepository();
    final sessionController = DemoSessionController();
    final modeController = DemoModeController();
    final flowProvider = DemoFlowProvider(repo);
    final adminProvider = AdminDemoProvider(repo, flowProvider);
    final currentUserController = CurrentUserController();
    final sessionsController = SessionsController();
    final state = AppState._(
      repository: repo,
      sessionController: sessionController,
      modeController: modeController,
      flowProvider: flowProvider,
      adminProvider: adminProvider,
      currentUserController: currentUserController,
      sessionsController: sessionsController,
    );
    state._bootstrapSession();
    return state;
  }

  /// 앱 시작 시 Firebase 세션이 남아 있으면 로그인 화면을 건너뛰고 자동 진입.
  void _bootstrapSession() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    sessionController.loginAsDemoUser(displayName: user.displayName ?? '참가자');
    sessionController.markEntered();
    modeController.setMode(DemoMode.user);
    currentUserController.load();
    sessionsController.start();
    FcmService.instance.registerForCurrentUser();
    unawaited(connectLiveFlow());
  }

  /// 로그인 사용자가 신청해 둔 회차를 찾아 오브닝 플로우를 라이브 모드로 연결
  /// (sessions/{id}/applications/{uid} 존재 여부로 판단).
  Future<void> connectLiveFlow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || flowProvider.isLive) {
      return;
    }

    // 회차 목록이 로드될 때까지 대기 (최대 8초).
    if (!sessionsController.isLoaded) {
      final completer = Completer<void>();
      void onLoaded() {
        if (sessionsController.isLoaded && !completer.isCompleted) {
          completer.complete();
        }
      }

      sessionsController.addListener(onLoaded);
      try {
        await completer.future.timeout(const Duration(seconds: 8));
      } on TimeoutException {
        return; // 오프라인 등 — 다음 앱 시작/로그인 때 재시도.
      } finally {
        sessionsController.removeListener(onLoaded);
      }
    }

    // 진행 중 > 확정 > 선정 중 > 모집 중 순으로, 같은 상태면 최신 회차부터.
    const priority = ['ongoing', 'confirmed', 'selecting', 'recruiting'];
    final candidates = sessionsController.sessions
        .where((session) => priority.contains(session.status))
        .toList()
      ..sort((a, b) {
        final byStatus =
            priority.indexOf(a.status).compareTo(priority.indexOf(b.status));
        if (byStatus != 0) {
          return byStatus;
        }
        final aTime = a.createdAt ?? DateTime(0);
        final bTime = b.createdAt ?? DateTime(0);
        return bTime.compareTo(aTime);
      });

    for (final session in candidates) {
      try {
        final applied = await ApplicationRepository.instance.hasApplied(
          session.id,
          user.uid,
        );
        if (applied) {
          flowProvider.attachLive(
            sessionId: session.id,
            uid: user.uid,
            session: session,
          );
          return;
        }
      } catch (error) {
        debugPrint('[flow] 신청 회차 확인 실패(${session.id}): $error');
      }
    }
  }

  final ChemistryRepository repository;
  final DemoSessionController sessionController;
  final DemoModeController modeController;
  final DemoFlowProvider flowProvider;
  final AdminDemoProvider adminProvider;
  final CurrentUserController currentUserController;
  final SessionsController sessionsController;

  void _notify() {
    notifyListeners();
  }

  @override
  void dispose() {
    sessionController.removeListener(_notify);
    modeController.removeListener(_notify);
    flowProvider.removeListener(_notify);
    adminProvider.removeListener(_notify);
    currentUserController.removeListener(_notify);
    sessionsController.removeListener(_notify);
    sessionController.dispose();
    modeController.dispose();
    flowProvider.dispose();
    adminProvider.dispose();
    currentUserController.dispose();
    sessionsController.dispose();
    super.dispose();
  }
}

class AppScope extends StatefulWidget {
  const AppScope({required this.child, this.repository, super.key});

  final Widget child;

  /// 앱 시작 시 주입되는 리포지토리. null이면 데모(Mock)로 동작.
  final ChemistryRepository? repository;

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppScopeHost>();
    assert(scope != null, 'AppScope was not found in the widget tree.');
    return scope!.state;
  }

  @override
  State<AppScope> createState() => _AppScopeState();
}

class _AppScopeState extends State<AppScope> {
  late final AppState _state = AppState.create(repository: widget.repository);

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AppScopeHost(state: _state, notifier: _state, child: widget.child);
  }
}

class _AppScopeHost extends InheritedNotifier<AppState> {
  const _AppScopeHost({
    required this.state,
    required super.notifier,
    required super.child,
  });

  final AppState state;

  @override
  bool updateShouldNotify(_AppScopeHost oldWidget) {
    return state != oldWidget.state || super.updateShouldNotify(oldWidget);
  }
}
