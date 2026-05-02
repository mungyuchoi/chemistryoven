import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/demo_models.dart';
import '../../../features/event_flow/presentation/widgets/flow_timeline.dart';
import '../../../shared/providers/app_scope.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final flow = appState.flowProvider;
    final selectedClass = flow.selectedClass;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const SectionTitle(
            title: '내역',
            subtitle: '실제 저장 없이 DemoFlowProvider 상태만으로 신청 이후 흐름을 확인합니다.',
          ),
          const SizedBox(height: 14),
          AppCard(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedClass.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    StatusBadge(label: flow.currentStep.label),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${selectedClass.dateText} · ${selectedClass.place}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FlowTimeline(flow: flow),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: flow.back,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('이전'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: flow.currentStep == DemoFlowStep.choice
                            ? flow.submitChoices
                            : flow.advance,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('다음'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _StageBody(
            currentStep: flow.currentStep,
            reviewController: _reviewController,
          ),
        ],
      ),
    );
  }
}

class _StageBody extends StatelessWidget {
  const _StageBody({required this.currentStep, required this.reviewController});

  final DemoFlowStep currentStep;
  final TextEditingController reviewController;

  @override
  Widget build(BuildContext context) {
    if (currentStep.index < DemoFlowStep.eventDay.index) {
      return _ApplicationStateCard(currentStep: currentStep);
    }

    switch (currentStep) {
      case DemoFlowStep.eventDay:
        return const _EventDayCard();
      case DemoFlowStep.choice:
        return const _ChoiceCard();
      case DemoFlowStep.matchResult:
        return const _MatchResultCard();
      case DemoFlowStep.chemistryReport:
        return _ReportCard(reviewController: reviewController);
      case DemoFlowStep.review:
        return _ReviewDoneCard(reviewController: reviewController);
      case DemoFlowStep.beforeApplication:
      case DemoFlowStep.verificationWaiting:
      case DemoFlowStep.verificationApproved:
      case DemoFlowStep.aiSelectionWaiting:
      case DemoFlowStep.selected:
      case DemoFlowStep.paymentWaiting:
      case DemoFlowStep.confirmed:
        return _ApplicationStateCard(currentStep: currentStep);
    }
  }
}

class _ApplicationStateCard extends StatelessWidget {
  const _ApplicationStateCard({required this.currentStep});

  final DemoFlowStep currentStep;

  @override
  Widget build(BuildContext context) {
    final flow = AppScope.of(context).flowProvider;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '신청 상태',
            subtitle: '인증, 선정, 입금, 확정 상태를 버튼으로 넘겨 검토합니다.',
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(label: currentStep.label),
                const SizedBox(height: 10),
                Text(
                  currentStep.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: flow.advance,
              icon: const Icon(Icons.play_arrow),
              label: Text(currentStep.primaryActionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventDayCard extends StatelessWidget {
  const _EventDayCard();

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context).repository;
    final seats = repository.fetchSeatAssignments();
    final rounds = repository.fetchEventRounds();

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                title: '행사 당일',
                subtitle: '입장, 좌석, 라운드 안내를 더미로 표시합니다.',
              ),
              const SizedBox(height: 12),
              for (final seat in seats) ...[
                _InfoRow(
                  icon: Icons.chair_alt,
                  title: seat.tableName,
                  description: '${seat.participants.join(', ')}\n${seat.note}',
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: '오늘의 라운드'),
              const SizedBox(height: 12),
              for (final round in rounds)
                _InfoRow(
                  icon: Icons.timer_outlined,
                  title: round.title,
                  description: round.description,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard();

  @override
  Widget build(BuildContext context) {
    final flow = AppScope.of(context).flowProvider;
    const choices = ['소금빵', '레몬타르트', '크루아상', '마들렌'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '선택 제출',
            subtitle: '첫인상, 중간, 최종 선택 UI를 한 화면에서 검토합니다.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final nickname in choices)
                FilterChip(
                  label: Text(nickname),
                  selected: flow.selectedDesserts.contains(nickname),
                  onSelected: (_) => flow.toggleDessert(nickname),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: flow.submitChoices,
              icon: const Icon(Icons.favorite),
              label: const Text('선택 제출하고 매칭 결과 보기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchResultCard extends StatelessWidget {
  const _MatchResultCard();

  @override
  Widget build(BuildContext context) {
    final repository = AppScope.of(context).repository;
    final matches = repository.fetchMatches();

    return AppCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '매칭 결과',
            subtitle: '상호 선택된 매칭만 연락처 공개 대상으로 표시합니다.',
          ),
          const SizedBox(height: 14),
          for (final match in matches) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${match.leftNickname} ↔ ${match.rightNickname}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      StatusBadge(label: '${match.score}점'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    match.sharedTags.join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.reviewController});

  final TextEditingController reviewController;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final flow = appState.flowProvider;
    final report = appState.repository.fetchReports().first;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '케미 리포트',
            subtitle: '행사 1시간 후 발송되는 리포트 화면을 더미로 구성합니다.',
          ),
          const SizedBox(height: 14),
          Text(report.summary, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          for (final item in report.items)
            _InfoRow(
              icon: Icons.insights,
              title: item,
              description: '리포트 상세 설명 영역',
            ),
          const SizedBox(height: 14),
          TextField(
            controller: reviewController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(hintText: '후기를 입력해보세요'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: flow.submitReview,
              icon: const Icon(Icons.rate_review),
              label: const Text('후기 등록'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDoneCard extends StatelessWidget {
  const _ReviewDoneCard({required this.reviewController});

  final TextEditingController reviewController;

  @override
  Widget build(BuildContext context) {
    final flow = AppScope.of(context).flowProvider;
    final review = reviewController.text.trim().isEmpty
        ? '따뜻한 분위기에서 자연스럽게 대화가 이어졌어요.'
        : reviewController.text.trim();

    return AppCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '후기 작성 완료',
            subtitle: '후기 등록 후 재참여 유도 화면입니다.',
          ),
          const SizedBox(height: 12),
          Text(review, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: flow.reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('처음부터 다시 보기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.burgundy, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
