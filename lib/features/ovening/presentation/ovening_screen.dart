import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/demo_models.dart';
import '../../../shared/providers/app_scope.dart';
import '../../../shared/providers/demo_flow_provider.dart';
import '../../report/presentation/chemistry_report_screen.dart';
import '../../social/presentation/couple_board_screen.dart';
import '../../social/presentation/ovening_lounge_screen.dart';
import '../../social/presentation/review_gate_screen.dart';

class OveningScreen extends StatelessWidget {
  const OveningScreen({
    required this.onStartOnboarding,
    required this.onOpenSchedule,
    super.key,
  });

  final VoidCallback onStartOnboarding;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final session = appState.sessionController;
    final flow = appState.flowProvider;

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: session.isGuest
                    ? _NoOveningStage(onOpenSchedule: onOpenSchedule)
                    : _StageBody(
                        flow: flow,
                        onOpenSchedule: onOpenSchedule,
                        onStartOnboarding: onStartOnboarding,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageBody extends StatelessWidget {
  const _StageBody({
    required this.flow,
    required this.onOpenSchedule,
    required this.onStartOnboarding,
  });

  final DemoFlowProvider flow;
  final VoidCallback onOpenSchedule;
  final VoidCallback onStartOnboarding;

  @override
  Widget build(BuildContext context) {
    final currentStep = flow.currentStep;

    if (currentStep == DemoFlowStep.beforeApplication) {
      return _NoOveningStage(onOpenSchedule: onOpenSchedule);
    }
    if (currentStep.isApplicationStage &&
        currentStep != DemoFlowStep.confirmed) {
      return _OpenWaitingStage(flow: flow);
    }

    switch (currentStep) {
      case DemoFlowStep.confirmed:
      case DemoFlowStep.nicknameCheck:
        return _OpenWaitingStage(flow: flow);
      case DemoFlowStep.firstImpressionChoice:
        return _VotingStage(flow: flow);
      case DemoFlowStep.rotationTalk:
        return _RotationStage(flow: flow);
      case DemoFlowStep.middleChoice:
        return _VotingStage(flow: flow);
      case DemoFlowStep.seatingGuide:
        return _SeatReadyStage(flow: flow);
      case DemoFlowStep.pairBaking:
        return _PairBakingStage(flow: flow);
      case DemoFlowStep.finalChoice:
        return _VotingStage(flow: flow);
      case DemoFlowStep.matchResult:
        return _MatchResultStage(flow: flow);
      case DemoFlowStep.chemistryReport:
        return _ReportStage(flow: flow);
      case DemoFlowStep.review:
        return _ReviewStage(flow: flow);
      case DemoFlowStep.beforeApplication:
      case DemoFlowStep.verificationWaiting:
      case DemoFlowStep.verificationApproved:
      case DemoFlowStep.aiSelectionWaiting:
      case DemoFlowStep.selected:
      case DemoFlowStep.paymentWaiting:
        return _OpenWaitingStage(flow: flow);
    }
  }
}

class _NoOveningStage extends StatelessWidget {
  const _NoOveningStage({required this.onOpenSchedule});

  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StageBadge(label: 'OVENING'),
        const SizedBox(height: 12),
        Text(
          '아직 열려 있는 오브닝이 없어요.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.burgundy,
            fontSize: 27,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.ivory,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.blush.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: AppColors.brandRed,
                  size: 24,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '일정에서 참여할 회차를 신청해보세요. 선정되면 오브닝이 열려요.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        const _SectionLabel('오브닝에서는 어떤 일이 일어나나요?'),
        const SizedBox(height: 14),
        const _InfoRows(
          items: [
            _InfoRowData(
              icon: Icons.person_outline_rounded,
              title: '캐릭터 닉네임 공개',
              subtitle: '회차 내 익명으로 진행돼요',
            ),
            _InfoRowData(
              icon: Icons.chair_alt_outlined,
              title: '좌석 안내',
              subtitle: 'AI 자동 자리배치로 자연스러운 첫 만남',
            ),
            _InfoRowData(
              icon: Icons.favorite_border_rounded,
              title: '매칭 결과 & 케미 리포트',
              subtitle: '상호 선택 시 연락처 공개',
            ),
          ],
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onOpenSchedule,
            child: const Text('일정 보러가기'),
          ),
        ),
      ],
    );
  }
}

class _OpenWaitingStage extends StatelessWidget {
  const _OpenWaitingStage({required this.flow});

  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    final selectedClass = flow.selectedClass;
    final profile = AppScope.of(context).repository.fetchParticipantProfile();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _StageBadge(label: 'OVENING'),
            const SizedBox(width: 8),
            Text(
              flow.currentStep.index < DemoFlowStep.confirmed.index
                  ? 'D-3'
                  : '오늘 오픈',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '곧 오브닝이 열려요.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.burgundy,
            fontSize: 27,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 28),
        _NicknameCard(nickname: profile.nickname),
        const SizedBox(height: 24),
        const _SectionLabel('당일 안내'),
        const SizedBox(height: 10),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.article_outlined,
                label: '회차',
                value: selectedClass.title,
              ),
              const Divider(height: 1, color: AppColors.line),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: '일시',
                value: '2026. 6. 14 (토) 오후\n2:00',
              ),
              const Divider(height: 1, color: AppColors.line),
              const _DetailRow(
                icon: Icons.place_outlined,
                label: '장소',
                value: '성수 베이킹 스튜디오\n1F',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Text(
            '편하게 음식을 다룰 수 있는 복장 · 베이킹은 모두 현장에서 진행돼요. 알레르기/음료 선호는 신청 정보에서 다시 확인해주세요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cocoa,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: flow.advance,
            child: Text(flow.currentStep.primaryActionLabel),
          ),
        ),
      ],
    );
  }
}

class _VotingStage extends StatelessWidget {
  const _VotingStage({required this.flow});

  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final phase = flow.currentChoicePhase ?? ChoicePhase.firstImpression;
    final candidates = _displayCandidates(
      appState.repository.fetchChoiceCandidates(),
    );
    final selected = flow.selectedChoiceFor(phase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StageBadge(label: _roundLabel(phase)),
            const SizedBox(width: 10),
            Text(
              '02:14 남음',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    phase == ChoicePhase.firstImpression
                        ? '최대 한 명 선택'
                        : '수정 가능',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.burgundy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _questionFor(phase),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.burgundy,
            fontSize: 27,
            fontWeight: FontWeight.w500,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          phase == ChoicePhase.firstImpression
              ? '1명을 선택해주세요. 중간에 한 번 더 수정할 수 있어요.'
              : phase.instruction,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.cocoa, height: 1.55),
        ),
        const SizedBox(height: 22),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.08,
          children: [
            for (final candidate in candidates)
              _CandidateCard(
                candidate: candidate,
                selected: selected == candidate.nickname,
                onTap: () => flow.selectChoice(phase, candidate.nickname),
              ),
          ],
        ),
        if (phase == ChoicePhase.finalChoice) ...[
          const SizedBox(height: 14),
          TextField(
            minLines: 2,
            maxLines: 3,
            controller: TextEditingController(text: flow.finalMessage)
              ..selection = TextSelection.collapsed(
                offset: flow.finalMessage.length,
              ),
            onChanged: flow.updateFinalMessage,
            decoration: const InputDecoration(labelText: '짧은 메시지'),
          ),
        ],
        const SizedBox(height: 14),
        const _VoteNoticeCard(),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: flow.submitCurrentChoice,
            child: Text(_submitLabel(phase)),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            '제출 후에도 중간 선택 전까지 변경 가능',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  static String _roundLabel(ChoicePhase phase) {
    switch (phase) {
      case ChoicePhase.firstImpression:
        return 'ROUND 1';
      case ChoicePhase.middle:
        return 'ROUND 2';
      case ChoicePhase.finalChoice:
        return 'FINAL';
    }
  }

  static String _questionFor(ChoicePhase phase) {
    switch (phase) {
      case ChoicePhase.firstImpression:
        return '첫인상이 가장 인상 깊었던 분은?';
      case ChoicePhase.middle:
        return '다시 이야기해보고 싶은 분은?';
      case ChoicePhase.finalChoice:
        return '마지막으로 마음을 전할 분은?';
    }
  }

  static String _submitLabel(ChoicePhase phase) {
    switch (phase) {
      case ChoicePhase.firstImpression:
        return '첫인상 선택 제출하기';
      case ChoicePhase.middle:
        return '중간 선택 제출';
      case ChoicePhase.finalChoice:
        return '최종 선택 제출';
    }
  }

  static List<ChoiceCandidate> _displayCandidates(
    List<ChoiceCandidate> candidates,
  ) {
    ChoiceCandidate byName(String name, ChoiceCandidate fallback) {
      return candidates.firstWhere(
        (candidate) => candidate.nickname == name,
        orElse: () => fallback,
      );
    }

    const redbean = ChoiceCandidate(
      nickname: '단팥빵',
      gender: '남성',
      keywords: ['든든', '한결같음'],
      chemistryScore: 90,
    );

    return [
      byName('크루아상', candidates.first),
      byName('소금빵', candidates.first),
      redbean,
      byName('에클레어', candidates.last),
    ];
  }
}

class _RotationStage extends StatelessWidget {
  const _RotationStage({required this.flow});

  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _StageBadge(label: 'ROTATION'),
            const SizedBox(width: 10),
            Text(
              '03:00 남음',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '2 / 4',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.burgundy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '옆자리 대화를 시작해요.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.burgundy,
            fontSize: 27,
            fontWeight: FontWeight.w500,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '모든 참가자와 짧게 1:1 대화해보고 중간 선택 전에 대화 온도를 확인합니다.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.cocoa, height: 1.55),
        ),
        const SizedBox(height: 24),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('현재 대화 상대'),
              const SizedBox(height: 14),
              Row(
                children: const [
                  _ResultAvatar(label: '소'),
                  SizedBox(width: 12),
                  Expanded(child: _RotationProfile()),
                ],
              ),
              const Divider(height: 28, color: AppColors.line),
              const _InfoRow(
                data: _InfoRowData(
                  icon: Icons.work_outline,
                  title: '서비스 기획자 · 33',
                  subtitle: '차분하지만 유머가 은은한 타입',
                ),
              ),
              const Divider(height: 1, color: AppColors.line, indent: 52),
              const _InfoRow(
                data: _InfoRowData(
                  icon: Icons.chat_bubble_outline,
                  title: '추천 질문',
                  subtitle: '최근 가장 좋았던 카페나 디저트는?',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          color: AppColors.blush.withValues(alpha: 0.76),
          borderColor: AppColors.rose,
          padding: const EdgeInsets.all(14),
          child: Text(
            '라운드가 끝나면 자리 이동 안내가 뜨고, 모든 로테이션이 끝난 뒤 중간 선택이 열려요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cocoa,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: flow.advance,
            child: Text(flow.currentStep.primaryActionLabel),
          ),
        ),
      ],
    );
  }
}

class _RotationProfile extends StatelessWidget {
  const _RotationProfile();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '소금빵',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.cocoa,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '다정 · 은은한 매력 · INTJ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}

class _SeatReadyStage extends StatelessWidget {
  const _SeatReadyStage({required this.flow});

  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _StageBadge(label: 'OVENING'),
            const SizedBox(width: 10),
            Text(
              '자리배치',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.burgundy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Text('다음 라운드 준비', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '다음 자리가 준비되었어요.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.burgundy,
            fontSize: 27,
            fontWeight: FontWeight.w500,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '중간 선택 결과를 바탕으로 새로운 대화 자리가 배정되었어요. 잠시 후 안내에 따라 자리를 옮겨주세요.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.cocoa, height: 1.55),
        ),
        const SizedBox(height: 26),
        AppCard(
          color: AppColors.butter.withValues(alpha: 0.75),
          borderColor: AppColors.butter,
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              const Positioned(
                right: -18,
                top: -16,
                child: _RingMark(size: 116, color: AppColors.gold),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR BAKING SEAT',
                      style: TextStyle(
                        color: AppColors.burgundy,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'C - 2',
                      style: TextStyle(
                        color: AppColors.burgundy,
                        fontSize: 34,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'C 테이블 두 번째 자리예요',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.cocoa),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('이번 테이블에 함께 앉아요'),
        const SizedBox(height: 10),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: const [
              Row(
                children: [
                  Expanded(
                    child: _TableMate(initial: '크', label: '크루아상'),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _TableMate(initial: '소', label: '소금빵'),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TableMate(initial: '딸', label: '딸기쇼트'),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _TableMate(initial: '마', label: '마들렌'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '같은 테이블의 다른 캐릭터와도 자유롭게 대화를 나눌 수 있어요. 자리 이동은 운영진의 안내를 따라 진행됩니다.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.55),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: flow.advance,
            child: Text(flow.currentStep.primaryActionLabel),
          ),
        ),
      ],
    );
  }
}

class _PairBakingStage extends StatelessWidget {
  const _PairBakingStage({required this.flow});

  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _StageBadge(label: 'PAIR BAKING'),
            const SizedBox(width: 10),
            Text(
              '35:00 남음',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '함께 만들며 케미를 확인해요.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.burgundy,
            fontSize: 27,
            fontWeight: FontWeight.w500,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '말로만 보는 소개팅이 아니라, 같이 움직이고 배려하는 방식까지 확인하는 시간이에요.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.cocoa, height: 1.55),
        ),
        const SizedBox(height: 22),
        AppCard(
          color: AppColors.wine,
          borderColor: AppColors.wine,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TODAY PAIR',
                style: TextStyle(
                  color: AppColors.butter,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  _ResultAvatar(label: 'T'),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.close_rounded, color: AppColors.butter),
                  ),
                  _ResultAvatar(label: '소'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '티라미수 × 소금빵',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '딸기 타르트 크림 짜기 · 포장 마무리',
                style: TextStyle(color: Color(0xFFFFE7DA), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SectionLabel('베이킹 체크리스트'),
        const SizedBox(height: 10),
        const _InfoRows(
          items: [
            _InfoRowData(
              icon: Icons.restaurant_menu_outlined,
              title: '레시피 카드 확인',
              subtitle: '반죽 · 크림 · 장식 순서대로 진행',
            ),
            _InfoRowData(
              icon: Icons.favorite_border,
              title: '케미 포인트',
              subtitle: '역할 나누기, 작은 배려, 리액션을 자연스럽게 보기',
            ),
            _InfoRowData(
              icon: Icons.timer_outlined,
              title: '다음 단계',
              subtitle: '완성 후 최종 선택 라운드가 열려요',
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: flow.advance,
            child: Text(flow.currentStep.primaryActionLabel),
          ),
        ),
      ],
    );
  }
}

class _MatchResultStage extends StatelessWidget {
  const _MatchResultStage({required this.flow});

  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StageBadge(label: 'CHEMISTRY RESULT'),
        const SizedBox(height: 12),
        Text(
          '오늘의 케미 결과가 도착했어요.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.burgundy,
            fontSize: 27,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '상호 선택된 캐릭터의 실명과 연락처가 공개돼요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 22),
        AppCard(
          color: AppColors.wine,
          borderColor: AppColors.wine,
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              const Positioned(
                top: -30,
                right: -18,
                child: _RingMark(size: 132, color: AppColors.butter),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MUTUAL MATCH',
                      style: TextStyle(
                        color: AppColors.butter,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: const [
                        _ResultAvatar(label: 'T'),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.favorite_border_rounded,
                            color: AppColors.butter,
                            size: 20,
                          ),
                        ),
                        _ResultAvatar(label: 'S'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '티라미수↔소금빵',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '두 분 모두 서로를 선택했어요.',
                      style: TextStyle(color: Color(0xFFFFE7DA), fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    const _MatchContactPanel(),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionLabel('단방향 선택'),
        const SizedBox(height: 10),
        const _OneWaySelectionCard(),
        const SizedBox(height: 22),
        const _SectionLabel('오늘의 케미 기록'),
        const SizedBox(height: 10),
        _ChemistryRecordCard(onTap: flow.advance),
        const SizedBox(height: 22),
        const _SectionLabel('오브닝 라운지'),
        const SizedBox(height: 10),
        const _LoungeEntryCard(),
      ],
    );
  }
}

class _MatchContactPanel extends StatelessWidget {
  const _MatchContactPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이름',
            style: TextStyle(color: AppColors.butter, fontSize: 10),
          ),
          const SizedBox(height: 5),
          const Text(
            '지원자 B (30대)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '010-****-0000',
            style: TextStyle(color: Color(0xFFFFE7DA), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandRed,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('연락처 복사'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandRed,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('카톡안내 받기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OneWaySelectionCard extends StatelessWidget {
  const _OneWaySelectionCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'C',
              style: TextStyle(
                color: AppColors.brandRed,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '크루아상님이 회원님을 선택했어요\n회원님은 다른 분을 선택하셔서 연결지는 공개되지 않아요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.cocoa,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChemistryRecordCard extends StatelessWidget {
  const _ChemistryRecordCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.article_outlined, color: AppColors.brandRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '8기 케미 리포트',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.cocoa,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '대화 패턴, 선택의 흐름, 케미 키워드를 정리한 개인 리포트를 받아보세요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('리포트 받기'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportStage extends StatelessWidget {
  const _ReportStage({required this.flow});

  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    final report = AppScope.of(context).repository.fetchReports().first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StageBadge(label: 'CHEMISTRY REPORT'),
        const SizedBox(height: 12),
        Text(
          '오늘의 케미 분석',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.burgundy,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.summary,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              for (final item in report.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '후기를 남기면 AI가 작성한 전체 케미 리포트가 열려요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ReviewGateScreen(onReviewSubmitted: flow.submitReview),
                ),
              );
            },
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: const Text('후기 남기고 리포트 열기'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChemistryReportScreen(),
                ),
              );
            },
            icon: const Icon(Icons.article_outlined, size: 18),
            label: const Text('전체 리포트 미리 보기 (검토용)'),
          ),
        ),
      ],
    );
  }
}

class _ReviewStage extends StatelessWidget {
  const _ReviewStage({required this.flow});

  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      child: Column(
        children: [
          const Icon(Icons.favorite, color: AppColors.brandRed, size: 34),
          const SizedBox(height: 12),
          Text(
            '후기가 저장되었어요.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '다음 회차 재참여와 운영 개선에 반영됩니다.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OveningLoungeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: const Text('오브닝 라운지 입장하기'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CoupleBoardScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.favorite_border, size: 18),
              label: const Text('커플 인증 게시판 보기'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: flow.reset,
              child: const Text('프로토타입 다시 시작'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NicknameCard extends StatelessWidget {
  const _NicknameCard({required this.nickname});

  final String nickname;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.wine,
      borderColor: AppColors.wine,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned(
            top: -30,
            right: -20,
            child: _RingMark(size: 120, color: AppColors.butter),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.butter.withValues(alpha: 0.34),
                    ),
                  ),
                  child: const Text(
                    'T',
                    style: TextStyle(
                      color: AppColors.butter,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'D-1 · 나의 캐릭터 닉네임',
                        style: TextStyle(
                          color: AppColors.butter,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        nickname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '오늘만의 이름이에요.',
                        style: TextStyle(
                          color: Color(0xFFFFE7DA),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
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
      color: selected ? AppColors.burgundy : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? AppColors.butter : AppColors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              if (selected)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.butter,
                    child: Icon(
                      Icons.check,
                      color: AppColors.burgundy,
                      size: 14,
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.parchment,
                      borderRadius: BorderRadius.circular(12),
                      border: selected
                          ? Border.all(
                              color: AppColors.butter.withValues(alpha: 0.55),
                            )
                          : null,
                    ),
                    child: Text(
                      candidate.nickname.characters.first,
                      style: TextStyle(
                        color: selected ? AppColors.butter : AppColors.brandRed,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    candidate.nickname,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected ? Colors.white : AppColors.cocoa,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    candidate.keywords.take(2).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected ? AppColors.butter : AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoteNoticeCard extends StatelessWidget {
  const _VoteNoticeCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.brandRed,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '상대 캐릭터는 회차 내에서만 사용되는 이름이에요. 실명은 매칭 결과 단계에서만 공개됩니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.cocoa,
                height: 1.5,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRows extends StatelessWidget {
  const _InfoRows({required this.items});

  final List<_InfoRowData> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _InfoRow(data: items[i]),
            if (i < items.length - 1)
              const Divider(height: 1, color: AppColors.line, indent: 52),
          ],
        ],
      ),
    );
  }
}

class _InfoRowData {
  const _InfoRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.data});

  final _InfoRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: AppColors.brandRed, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.cocoa,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandRed, size: 17),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.chocolate,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableMate extends StatelessWidget {
  const _TableMate({required this.initial, required this.label});

  final String initial;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.parchment,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.brandRed,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cocoa,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultAvatar extends StatelessWidget {
  const _ResultAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.butter.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.butter,
          fontSize: 23,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.wine,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.chocolate,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _RingMark extends StatelessWidget {
  const _RingMark({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _RingPainter(color: color)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.25);
    canvas.drawCircle(center, size.width * 0.48, paint);
    canvas.drawCircle(center, size.width * 0.32, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// 매칭 결과 화면에서 진입하는 오브닝 라운지 카드.
class _LoungeEntryCard extends StatelessWidget {
  const _LoungeEntryCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const OveningLoungeScreen(),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.forum_outlined, color: AppColors.brandRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '오브닝 라운지',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.cocoa,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.butter,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'OPEN · 12시간',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.wine,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '매칭 여부와 상관없이 오늘 함께한 모든 분과 하루 동안 대화할 수 있어요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.mutedText,
            size: 20,
          ),
        ],
      ),
    );
  }
}
