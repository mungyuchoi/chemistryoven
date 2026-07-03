import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/widgets/status_badge.dart';
import '../data/models/chemistry_session.dart';
import '../data/models/demo_models.dart';
import '../data/repositories/application_repository.dart';
import '../features/classes/presentation/classes_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/lab/presentation/chemistry_lab_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/ovening/presentation/ovening_screen.dart';
import '../features/profile/presentation/my_page_screen.dart';
import '../services/firebase_service.dart';
import '../shared/providers/app_scope.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  MainTab _currentTab = MainTab.home;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final isAdminMode = appState.modeController.mode == DemoMode.admin;
    final tabs = MainTab.values;
    final currentIndex = tabs.indexOf(_currentTab);
    final screens = [
      HomeScreen(
        onOpenSchedule: () => _selectTab(MainTab.schedule),
        onOpenLab: () => _selectTab(MainTab.lab),
        onApplyClass: _handleApplication,
      ),
      ClassesScreen(onApplyClass: _handleApplication),
      ChemistryLabScreen(onStartOnboarding: () => _startOnboarding()),
      OveningScreen(
        onStartOnboarding: () => _showSessionGate(context),
        onOpenSchedule: () => _selectTab(MainTab.schedule),
      ),
      MyPageScreen(
        onStartOnboarding: () => _startOnboarding(),
        onOpenOvening: () => _selectTab(MainTab.ovening),
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: isAdminMode
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.ivory,
                border: const Border(top: BorderSide(color: AppColors.line)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wine.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: currentIndex,
                height: 70,
                backgroundColor: AppColors.ivory,
                indicatorColor: AppColors.blush,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: (index) => _selectTab(tabs[index]),
                destinations: [
                  for (final tab in tabs)
                    NavigationDestination(
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.selectedIcon),
                      label: tab.label,
                    ),
                ],
              ),
            ),
    );
  }

  void _selectTab(MainTab tab) {
    final session = AppScope.of(context).sessionController;
    if (tab.requiresSession && session.isGuest) {
      _showSessionGate(
        context,
        title: '오브닝은 선정된 참가자에게 열려요.',
        subtitle: '케미 분석을 완료하면 당일 상태 화면을 볼 수 있어요.',
        onReady: () {
          if (!mounted) {
            return;
          }
          setState(() => _currentTab = tab);
        },
      );
      return;
    }

    setState(() => _currentTab = tab);
  }

  void _handleApplication(ChemistryClass demoClass) {
    final session = AppScope.of(context).sessionController;
    if (session.isGuest) {
      _showSessionGate(
        context,
        title: '신청 전 케미 분석이 필요해요.',
        subtitle: '비회원은 일정 둘러보기가 가능하고, 신청은 간단한 온보딩 뒤 진행돼요.',
        onReady: () => _submitApplication(demoClass),
      );
      return;
    }
    _submitApplication(demoClass);
  }

  void _submitApplication(ChemistryClass demoClass) {
    final appState = AppScope.of(context);
    appState.sessionController.loginAsDemoUser();
    appState.modeController.setMode(DemoMode.user);
    appState.flowProvider.applyForClass(demoClass.id);

    // 실제 Firestore 신청 — 로그인 사용자 + 실제 회차일 때만
    final uid = FirebaseService.instance.uid;
    final isRealSession = appState.sessionsController.sessions.any(
      (session) => session.id == demoClass.id,
    );
    if (uid != null && isRealSession) {
      final profile = appState.currentUserController.profile;
      unawaited(
        ApplicationRepository.instance
            .apply(
              sessionId: demoClass.id,
              uid: uid,
              displayName:
                  profile?.displayName ??
                  appState.sessionController.displayName,
              gender: profile?.gender,
              baseCharacterId: profile?.baseCharacterId,
            )
            .then((_) {
              // 신청 완료 → 오브닝 플로우를 이 회차와 라이브로 동기화
              ChemistrySession? session;
              for (final item in appState.sessionsController.sessions) {
                if (item.id == demoClass.id) {
                  session = item;
                  break;
                }
              }
              appState.flowProvider.attachLive(
                sessionId: demoClass.id,
                uid: uid,
                session: session,
              );
            })
            .catchError((Object error) {
              debugPrint('[apply] 신청 실패: $error');
            }),
      );
    }

    if (!mounted) {
      return;
    }
    _showApplicationThanks(demoClass);
  }

  void _startOnboarding({VoidCallback? onCompleted}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingScreen(
          onCompleted: onCompleted,
          onNavigateAfterCompleted: (tab) {
            if (!mounted) {
              return;
            }
            setState(() => _currentTab = tab);
          },
        ),
      ),
    );
  }

  void _showSessionGate(
    BuildContext context, {
    String title = '게스트로 둘러보는 중이에요.',
    String subtitle = '3분 케미 분석을 완료하면 전체 화면을 확인할 수 있어요.',
    VoidCallback? onReady,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.ivory,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _startOnboarding(onCompleted: onReady);
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('3분 케미 분석 시작'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showApplicationThanks(ChemistryClass demoClass) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.ivory,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusBadge(
                  label: '신청 접수',
                  color: AppColors.brandRed,
                  backgroundColor: AppColors.blush,
                ),
                const SizedBox(height: 12),
                Text(
                  '신청해주셔서 감사합니다.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${demoClass.title} 신청이 접수되었어요. 개인 정보를 바탕으로 운영진 선정 후 알림 및 문자를 보내드립니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      setState(() => _currentTab = MainTab.my);
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('내 신청 현황 보기'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
