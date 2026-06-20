import 'package:flutter/widgets.dart';

import '../../data/repositories/chemistry_repository.dart';
import '../../data/repositories/mock_chemistry_repository.dart';
import 'admin_demo_provider.dart';
import 'current_user_controller.dart';
import 'demo_flow_provider.dart';
import 'demo_mode_controller.dart';
import 'demo_session_controller.dart';

class AppState extends ChangeNotifier {
  AppState._({
    required this.repository,
    required this.sessionController,
    required this.modeController,
    required this.flowProvider,
    required this.adminProvider,
    required this.currentUserController,
  }) {
    sessionController.addListener(_notify);
    modeController.addListener(_notify);
    flowProvider.addListener(_notify);
    adminProvider.addListener(_notify);
    currentUserController.addListener(_notify);
  }

  factory AppState.create({ChemistryRepository? repository}) {
    final ChemistryRepository repo = repository ?? const MockChemistryRepository();
    final sessionController = DemoSessionController();
    final modeController = DemoModeController();
    final flowProvider = DemoFlowProvider(repo);
    final adminProvider = AdminDemoProvider(repo, flowProvider);
    final currentUserController = CurrentUserController();
    return AppState._(
      repository: repo,
      sessionController: sessionController,
      modeController: modeController,
      flowProvider: flowProvider,
      adminProvider: adminProvider,
      currentUserController: currentUserController,
    );
  }

  final ChemistryRepository repository;
  final DemoSessionController sessionController;
  final DemoModeController modeController;
  final DemoFlowProvider flowProvider;
  final AdminDemoProvider adminProvider;
  final CurrentUserController currentUserController;

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
    sessionController.dispose();
    modeController.dispose();
    flowProvider.dispose();
    adminProvider.dispose();
    currentUserController.dispose();
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
