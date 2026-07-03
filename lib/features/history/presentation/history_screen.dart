import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/demo_models.dart';
import '../../../shared/providers/app_scope.dart';
import '../../../shared/providers/demo_flow_provider.dart';

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
            subtitle: '사용자 화면에는 지금 확인해야 할 상태만 보여줍니다.',
          ),
          const SizedBox(height: 14),
          _CurrentStatusHeader(selectedClass: selectedClass, flow: flow),
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

class _CurrentStatusHeader extends StatelessWidget {
  const _CurrentStatusHeader({required this.selectedClass, required this.flow});

  final ChemistryClass selectedClass;
  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: flow.progress,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation(AppColors.burgundy),
            ),
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
    if (currentStep.isApplicationStage) {
      return _ApplicationStateCard(currentStep: currentStep);
    }

    switch (currentStep) {
      case DemoFlowStep.nicknameCheck:
        return const _NicknameCard();
      case DemoFlowStep.firstImpressionChoice:
      case DemoFlowStep.middleChoice:
      case DemoFlowStep.finalChoice:
        return const _ChoiceStageCard();
      case DemoFlowStep.rotationTalk:
      case DemoFlowStep.seatingGuide:
      case DemoFlowStep.pairBaking:
        return _ApplicationStateCard(currentStep: currentStep);
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

    return _ImageStagePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '신청 상태',
            subtitle: '인증, 선정, 입금, 확정 상태를 현재 단계만 확인합니다.',
          ),
          const SizedBox(height: 14),
          _SoftPanel(
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

class _NicknameCard extends StatelessWidget {
  const _NicknameCard();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final flow = appState.flowProvider;
    final profile = appState.repository.fetchParticipantProfile();

    return _ImageStagePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '닉네임 확인',
            subtitle: 'AI 프롬프트 기반 더미 닉네임과 첫 좌석을 확인합니다.',
          ),
          const SizedBox(height: 14),
          _SoftPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘의 나', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  profile.nickname,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  '${profile.gender} · 시작 좌석 ${profile.seat}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final keyword in profile.keywords)
                      StatusBadge(label: keyword),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: flow.advance,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('첫인상 선택으로 이동'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceStageCard extends StatelessWidget {
  const _ChoiceStageCard();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final flow = appState.flowProvider;
    final phase = flow.currentChoicePhase ?? ChoicePhase.firstImpression;
    final candidates = appState.repository.fetchChoiceCandidates();
    final selected = flow.selectedChoiceFor(phase);
    final isFinal = phase == ChoicePhase.finalChoice;

    return _ImageStagePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: phase.label, subtitle: phase.instruction),
          const SizedBox(height: 14),
          if (phase == ChoicePhase.middle) ...[
            const _SeatPreview(),
            const SizedBox(height: 12),
          ],
          for (final candidate in candidates) ...[
            _ChoiceCandidateTile(
              candidate: candidate,
              selected: selected == candidate.nickname,
              onTap: () => flow.selectChoice(phase, candidate.nickname),
            ),
            const SizedBox(height: 8),
          ],
          if (isFinal) ...[
            const SizedBox(height: 8),
            _LetterPanel(
              selectedNickname: selected ?? candidates.first.nickname,
              message: flow.finalMessage,
              onChanged: flow.updateFinalMessage,
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: flow.submitCurrentChoice,
              icon: const Icon(Icons.favorite),
              label: Text(flow.currentStep.primaryActionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCandidateTile extends StatelessWidget {
  const _ChoiceCandidateTile({
    required this.candidate,
    required this.selected,
    required this.onTap,
  });

  final ChoiceCandidate candidate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.burgundy : AppColors.ivory,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                selected ? Icons.favorite : Icons.favorite_border,
                color: selected ? Colors.white : AppColors.burgundy,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.nickname,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected ? Colors.white : AppColors.cocoa,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${candidate.gender} · ${candidate.keywords.join(' · ')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.78)
                            : AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: '${candidate.chemistryScore}점',
                color: selected ? AppColors.wine : AppColors.burgundy,
                backgroundColor: selected ? AppColors.butter : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeatPreview extends StatelessWidget {
  const _SeatPreview();

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('베이킹 파트너 추천 좌석', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(child: _SeatBox(label: 'A-1', active: true)),
              SizedBox(width: 8),
              Expanded(child: _SeatBox(label: 'A-2', active: false)),
              SizedBox(width: 8),
              Expanded(child: _SeatBox(label: 'B-1', active: false)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeatBox extends StatelessWidget {
  const _SeatBox({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.burgundy : AppColors.ivory,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.burgundy),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppColors.burgundy,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LetterPanel extends StatelessWidget {
  const _LetterPanel({
    required this.selectedNickname,
    required this.message,
    required this.onChanged,
  });

  final String selectedNickname;
  final String message;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To. $selectedNickname',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: message,
            minLines: 3,
            maxLines: 4,
            onChanged: onChanged,
            decoration: const InputDecoration(hintText: '짧은 메시지를 남겨보세요'),
          ),
          const SizedBox(height: 10),
          Text('From. 바닐라슈', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MatchResultCard extends StatelessWidget {
  const _MatchResultCard();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final flow = appState.flowProvider;
    final matches = appState.repository.fetchMatches();
    final admin = appState.adminProvider;

    return _ImageStagePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: '매칭 결과',
            subtitle: admin.matchingApproved
                ? '상호 선택된 매칭만 연락처 공개 대상으로 표시합니다.'
                : '운영자 승인 전 더미 매칭 후보를 확인합니다.',
          ),
          const SizedBox(height: 14),
          _SoftPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내 선택의 흐름',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  [
                    for (final entry in flow.selectedChoices.entries)
                      '${entry.key.label}: ${entry.value}',
                  ].join('\n'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final match in matches) ...[
            _SoftPanel(
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
                      StatusBadge(
                        label: admin.matchingApproved ? '공개' : '대기',
                        color: admin.matchingApproved
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${match.score}점 · ${match.sharedTags.join(' · ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: flow.advance,
              icon: const Icon(Icons.description),
              label: const Text('케미 리포트 보기'),
            ),
          ),
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

    return _ImageStagePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: '케미 리포트',
            subtitle: '행사 1시간 후 발송되는 리포트를 더미로 확인합니다.',
          ),
          const SizedBox(height: 14),
          _SoftPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                for (final item in report.items)
                  _InfoRow(
                    icon: Icons.insights,
                    title: item,
                    description: '선택 흐름과 대화 온도를 바탕으로 구성된 더미 분석입니다.',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: reviewController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(hintText: '후기 설문을 입력해보세요'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  flow.submitReview(text: reviewController.text.trim()),
              icon: const Icon(Icons.rate_review),
              label: const Text('후기 설문 제출'),
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
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  AppAssets.chefMascot,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '후기 작성 완료',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '다음 회차 재참여를 유도하는 완료 화면입니다.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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

class _ImageStagePanel extends StatelessWidget {
  const _ImageStagePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.chemistryFlowBackground,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.ivory.withValues(alpha: 0.82),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
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
