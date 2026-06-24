import 'package:flutter/material.dart';

import '../data/repositories/chemistry_repository.dart';
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
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final entered = AppScope.of(context).sessionController.entered;
    if (!entered) {
      return LoginScreen(
        onCompleted: () =>
            AppScope.of(context).sessionController.markEntered(),
      );
    }
    return const MainTabScreen();
  }
}
