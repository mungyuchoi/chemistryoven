import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../data/models/demo_models.dart';
import '../data/repositories/chemistry_repository.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../shared/providers/app_scope.dart';
import 'main_tab_screen.dart';
import 'theme.dart';

class ChemistryOvenApp extends StatelessWidget {
  const ChemistryOvenApp({this.repository, super.key});

  final ChemistryRepository? repository;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: repository,
      child: MaterialApp(
        title: '케미스트리오븐',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const _RootGate(),
      ),
    );
  }
}

/// 앱 시작 시 로그인 화면을 먼저 보여주고,
/// 로그인(또는 둘러보기) 후 메인 탭으로 전환하는 게이트.
/// 진입 여부는 sessionController.entered 로 관리(로그아웃 시 다시 로그인 화면).
///
/// 운영자 모드는 사용자 스택 위에 쌓지 않고, 이 루트에서 통째로 교체한다.
/// (모드 = 하나의 인스턴스. 뒤로가기로 사용자 화면이 드러나지 않음.)
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    if (!appState.sessionController.entered) {
      return LoginScreen(
        onCompleted: () => appState.sessionController.markEntered(),
      );
    }
    if (appState.modeController.mode == DemoMode.admin) {
      return const _DoubleBackToExit(
        child: Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(child: AdminDashboardScreen()),
        ),
      );
    }
    return const _DoubleBackToExit(child: MainTabScreen());
  }
}

/// 루트 화면에서 뒤로가기를 한 번 누르면 안내 토스트, 3초 이내 한 번 더 누르면 앱 종료.
/// 사용자·운영자 모드 루트 양쪽에 적용된다.
class _DoubleBackToExit extends StatefulWidget {
  const _DoubleBackToExit({required this.child});

  final Widget child;

  @override
  State<_DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<_DoubleBackToExit> {
  DateTime? _lastBackAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackAt != null &&
            now.difference(_lastBackAt!) < const Duration(seconds: 3)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackAt = now;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('한 번 더 누르면 종료됩니다.'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: widget.child,
    );
  }
}
