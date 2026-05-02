import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/demo_models.dart';
import '../../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../../features/event_flow/presentation/widgets/flow_timeline.dart';
import '../../../shared/providers/app_scope.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final modeController = appState.modeController;
    final flow = appState.flowProvider;
    final mode = modeController.mode;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const SectionTitle(
            title: '마이',
            subtitle: '게스트, 사용자, 행사참가자, 관리자 모드를 즉시 전환합니다.',
          ),
          const SizedBox(height: 14),
          AppCard(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(mode.icon, color: AppColors.burgundy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${mode.label} 데모 모드',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatusBadge(label: mode.label),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  mode.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<DemoMode>(
                    segments: [
                      for (final demoMode in DemoMode.values)
                        ButtonSegment<DemoMode>(
                          value: demoMode,
                          icon: Icon(demoMode.icon),
                          label: Text(demoMode.label),
                        ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (selection) {
                      modeController.setMode(selection.first);
                      if (selection.first == DemoMode.participantToday) {
                        flow.jumpTo(DemoFlowStep.eventDay);
                      }
                    },
                    showSelectedIcon: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (modeController.isAdmin)
            const AdminDashboardScreen()
          else ...[
            _ProfileSummary(mode: mode),
            const SizedBox(height: 14),
            _FlowControlCard(flowStep: flow.currentStep),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    title: '내 신청 흐름',
                    subtitle: '탭을 눌러 원하는 검토 단계로 바로 이동할 수 있습니다.',
                  ),
                  const SizedBox(height: 12),
                  FlowTimeline(flow: flow, compact: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.mode});

  final DemoMode mode;

  @override
  Widget build(BuildContext context) {
    final title = switch (mode) {
      DemoMode.guest => '둘러보는 손님',
      DemoMode.user => '신청 준비 중인 사용자',
      DemoMode.participantToday => '오늘의 참가자 바닐라슈',
      DemoMode.admin => '운영 관리자',
    };
    final subtitle = switch (mode) {
      DemoMode.guest => '실제 로그인 없이 회차와 홈 화면을 확인합니다.',
      DemoMode.user => '인증, 선정, 입금, 확정 흐름을 검토합니다.',
      DemoMode.participantToday => '좌석, 선택, 매칭, 리포트 화면을 검토합니다.',
      DemoMode.admin => '관리자 콘솔을 검토합니다.',
    };

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.butter,
              shape: BoxShape.circle,
            ),
            child: Icon(mode.icon, color: AppColors.wine),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowControlCard extends StatelessWidget {
  const _FlowControlCard({required this.flowStep});

  final DemoFlowStep flowStep;

  @override
  Widget build(BuildContext context) {
    final flow = AppScope.of(context).flowProvider;

    return AppCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  flowStep.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusBadge(
                label: '${flow.currentIndex + 1}/${flow.steps.length}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            flowStep.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: flow.reset,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('초기화'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: flow.currentStep == DemoFlowStep.choice
                      ? flow.submitChoices
                      : flow.advance,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('다음 단계'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
