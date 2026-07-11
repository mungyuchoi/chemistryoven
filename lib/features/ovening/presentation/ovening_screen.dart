import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/demo_models.dart';
import '../../../data/models/event_flow_models.dart';
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
    final appState = AppScope.of(context);
    final selectedClass = flow.selectedClass;
    // 라이브면 participants/{uid} 의 회차 닉네임, 아니면 데모 프로필.
    final profile = flow.participantProfile;
    // 라이브 모드에서 단계 진행은 운영자 전용 — 일반 사용자는
    // 운영자가 신청 상태/eventStage 를 바꿔야 자동으로 넘어간다.
    final isAdmin =
        appState.currentUserController.profile?.isAdmin ?? false;
    final canAdvance = !flow.isLive || isAdmin;
    final dateValue = [
      selectedClass.dateText,
      selectedClass.timeText,
    ].where((text) => text.isNotEmpty).join('\n');
    final placeValue = selectedClass.place;

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
                value: dateValue.isNotEmpty ? dateValue : '2026. 6. 14 (토) 오후\n2:00',
              ),
              const Divider(height: 1, color: AppColors.line),
              _DetailRow(
                icon: Icons.place_outlined,
                label: '장소',
                value: placeValue.isNotEmpty ? placeValue : '성수 베이킹 스튜디오\n1F',
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
        if (canAdvance)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: flow.advance,
              child: Text(flow.currentStep.primaryActionLabel),
            ),
          )
        else
          Center(
            child: Text(
              '진행 상태는 운영진 확인 후 자동으로 업데이트돼요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
              ),
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
    final phase = flow.currentChoicePhase ?? ChoicePhase.firstImpression;
    // 라이브면 participants 로스터 그대로, 데모면 시연용 4인 구성으로 가공.
    final candidates = flow.isLive
        ? flow.choiceCandidates
        : _displayCandidates(flow.choiceCandidates);
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
          const SizedBox(height: 18),
          const _SectionLabel('나의 선택'),
          const SizedBox(height: 10),
          _FinalSlot(
            rank: '1순위',
            sub: '서로 선택하면 연락처가 공개돼요',
            value: selected ?? candidates.first.nickname,
            accent: true,
          ),
          const SizedBox(height: 10),
          _FinalSlot(
            rank: '2순위',
            sub: '하루 동안 메시지를 보낼 수 있어요',
            value: flow.finalSecondChoice,
            accent: false,
            onTap: () => _pickSecondChoice(context, candidates),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '마음을 담은 편지 한 통',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.cocoa,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '선택 · 최대 60자',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            minLines: 2,
            maxLines: 3,
            maxLength: 60,
            controller: TextEditingController(text: flow.finalMessage)
              ..selection = TextSelection.collapsed(
                offset: flow.finalMessage.length,
              ),
            onChanged: flow.updateFinalMessage,
            decoration: const InputDecoration(
              hintText: '예) 오늘 반죽 치대며 나눈 대화가 참 편안했어요 :)',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '편지는 내가 선택한 분에게 편지봉투로 전해져요. 매칭 여부와 관계없이 마음을 전할 수 있어요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              height: 1.5,
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 14),
        const _VoteNoticeCard(),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _handleSubmit(context, phase),
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

  // 제출 시 첫인상/중간 선택은 결과 알림 모달을 먼저 띄운 뒤 진행한다.
  Future<void> _handleSubmit(BuildContext context, ChoicePhase phase) async {
    if (phase == ChoicePhase.firstImpression) {
      await showDialog<void>(
        context: context,
        barrierColor: AppColors.wine.withValues(alpha: 0.55),
        builder: (_) => const _ResultAlertDialog(
          matched: true,
          votes: 3,
          icon: Icons.favorite,
          title: '케미가 통했군요~!',
          body: '서로 첫인상을 선택했어요. 로테이션 대화에서 더 가까워져 봐요.',
          voteLabel: '이번 첫인상에서',
        ),
      );
    } else if (phase == ChoicePhase.middle) {
      await showDialog<void>(
        context: context,
        barrierColor: AppColors.wine.withValues(alpha: 0.55),
        builder: (_) => const _ResultAlertDialog(
          matched: true,
          votes: 2,
          icon: Icons.bakery_dining_outlined,
          title: '페어가 되었어요!',
          body: '내가 고른 분도 나를 골랐어요. 베이킹 옆자리 페어로 함께 앉아요.',
          voteLabel: '이번 중간 선택에서',
          footnote: '누가 누구를 선택했는지는 공개되지 않아요.',
        ),
      );
    }
    flow.submitCurrentChoice();
  }

  Future<void> _pickSecondChoice(
    BuildContext context,
    List<ChoiceCandidate> candidates,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: _SectionLabel('2순위로 마음을 전할 분'),
              ),
              for (final candidate in candidates)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.parchment,
                    child: Text(
                      candidate.nickname.characters.first,
                      style: const TextStyle(
                        color: AppColors.burgundy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(candidate.nickname),
                  subtitle: Text(candidate.keywords.take(2).join(' · ')),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(candidate.nickname),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      flow.selectFinalSecondChoice(picked);
    }
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

/// 최종 선택의 1순위/2순위 슬롯.
class _FinalSlot extends StatelessWidget {
  const _FinalSlot({
    required this.rank,
    required this.sub,
    required this.value,
    required this.accent,
    this.onTap,
  });

  final String rank;
  final String sub;
  final String? value;
  final bool accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Material(
      color: AppColors.ivory,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: accent ? AppColors.gold : AppColors.line,
          width: accent ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent
                          ? AppColors.burgundy
                          : AppColors.parchment,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      rank,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent ? AppColors.butter : AppColors.cocoa,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sub,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.parchment,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      hasValue ? value!.characters.first : '+',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: AppColors.burgundy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasValue ? value! : '탭하여 선택',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: hasValue
                                    ? AppColors.cocoa
                                    : AppColors.mutedText,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasValue ? '탭하여 변경' : '선택하지 않아도 돼요',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.mutedText,
                                fontSize: 11.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.mutedText,
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

/// 첫인상/중간 선택 제출 후 뜨는 결과 알림 모달.
class _ResultAlertDialog extends StatelessWidget {
  const _ResultAlertDialog({
    required this.matched,
    required this.votes,
    required this.icon,
    required this.title,
    required this.body,
    required this.voteLabel,
    this.footnote,
  });

  final bool matched;
  final int votes;
  final IconData icon;
  final String title;
  final String body;
  final String voteLabel;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: matched ? AppColors.wine : AppColors.parchment,
                shape: BoxShape.circle,
                border: matched
                    ? null
                    : Border.all(color: AppColors.mutedText, width: 1.5),
              ),
              child: Icon(
                icon,
                size: 34,
                color: matched ? AppColors.gold : AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.burgundy,
                fontSize: 25,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: AppColors.parchment,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    matched ? Icons.favorite : Icons.auto_awesome_rounded,
                    size: 16,
                    color: AppColors.burgundy,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.cocoa,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(text: '$voteLabel '),
                          TextSpan(
                            text: '$votes표',
                            style: const TextStyle(
                              color: AppColors.burgundy,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const TextSpan(text: '를 받았어요'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (footnote != null) ...[
              const SizedBox(height: 10),
              Text(
                footnote!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 로테이션/자리배치 단계에서 사용하는 캐릭터 프로필.
class _OveningProfile {
  const _OveningProfile({
    required this.nickname,
    required this.mark,
    required this.age,
    required this.job,
    required this.region,
    required this.intro,
    required this.taste,
    required this.dessert,
    required this.drink,
    required this.smoke,
    required this.good,
  });

  final String nickname;
  final String mark;
  final int age;
  final String job;
  final String region;
  final String intro;
  final List<String> taste;
  final List<String> dessert;
  final String drink;
  final String smoke;
  final List<String> good;
}

/// 라이브 참가자 문서(participants/{uid}.profile) → 로테이션 프로필 카드 변환.
_OveningProfile _profileFromParticipant(EventParticipant participant) {
  return _OveningProfile(
    nickname: participant.nickname,
    mark: participant.displayMark,
    age: participant.age ?? 0,
    job: participant.job,
    region: participant.region,
    intro: participant.intro,
    taste: participant.taste,
    dessert: participant.dessert,
    drink: participant.drink,
    smoke: participant.smoke,
    good: participant.good,
  );
}

const Map<String, _OveningProfile> _oveningProfiles = {
  '소금빵': _OveningProfile(
    nickname: '소금빵',
    mark: 'S',
    age: 33,
    job: 'IT/개발',
    region: '서울',
    intro: '편해지면 농담이 늘어요. 함께 새로운 걸 해보는 시간을 좋아합니다.',
    taste: ['맛집', '영화', '러닝'],
    dessert: ['담백한 빵', '커피와 잘 맞는'],
    drink: '분위기상 한두 잔',
    smoke: '비흡연',
    good: ['말이 잘 통해요', '배려가 자연스러워요', '웃음 코드가 맞아요', '취향이 비슷해요'],
  ),
  '마들렌': _OveningProfile(
    nickname: '마들렌',
    mark: 'M',
    age: 30,
    job: '디자인/콘텐츠',
    region: '경기',
    intro: '차분한 편이지만 한 주제로 깊이 이야기하는 걸 좋아해요.',
    taste: ['전시', '카페', '독서'],
    dessert: ['초콜릿', '너무 달지 않은'],
    drink: '거의 안 마셔요',
    smoke: '비흡연',
    good: ['차분해서 편해요', '대화가 깊어져요', '다정해요', '안정감을 줘요'],
  ),
  '크렘브륄레': _OveningProfile(
    nickname: '크렘브륄레',
    mark: 'C',
    age: 31,
    job: '서비스',
    region: '서울',
    intro: '새로운 경험을 좋아하고 분위기를 편하게 만드는 편이에요.',
    taste: ['여행', '맛집', '게임'],
    dessert: ['크림', '과일'],
    drink: '가볍게 즐기는 편',
    smoke: '가끔',
    good: ['유쾌해요', '센스가 있어요', '분위기를 편하게 해요'],
  ),
};

class _RotationStage extends StatelessWidget {
  const _RotationStage({required this.flow});

  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    // 라이브면 participants 로스터로 프로필 카드를 구성, 아니면 데모 프로필.
    final liveProfiles = <String, _OveningProfile>{
      for (final participant in flow.rotationProfiles)
        participant.nickname: _profileFromParticipant(participant),
    };
    final profiles = liveProfiles.isNotEmpty ? liveProfiles : _oveningProfiles;
    final names = profiles.keys.toList();
    final selected = profiles.containsKey(flow.rotationSelection)
        ? flow.rotationSelection
        : names.first;
    final profile = profiles[selected]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _StageBadge(label: 'ROTATION'),
            const SizedBox(width: 10),
            Text(
              '3 / 5 · 02:48 남음',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '옆에 앉은 분의\n닉네임을 눌러보세요.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.burgundy,
            fontSize: 25,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '대화하면서 휴대폰으로 상대 정보를 볼 수 있어요.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.cocoa, height: 1.5),
        ),
        const SizedBox(height: 18),
        // 닉네임 로스터 (가로 스크롤 칩)
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: names.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final name = names[index];
              return _RosterChip(
                name: name,
                selected: name == selected,
                onTap: () => flow.selectRotationPartner(name),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        AppCard(
          color: AppColors.ivory,
          padding: const EdgeInsets.all(18),
          child: _ProfileBody(profile: profile, flow: flow),
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

class _RosterChip extends StatelessWidget {
  const _RosterChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.burgundy : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? AppColors.burgundy : AppColors.line,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.butter.withValues(alpha: 0.25)
                      : AppColors.parchment,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name.characters.first,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: selected ? AppColors.butter : AppColors.burgundy,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.cocoa,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile, required this.flow});

  final _OveningProfile profile;
  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.parchment,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                profile.mark,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: AppColors.burgundy,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.nickname,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.burgundy,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${profile.age} · ${profile.job} · ${profile.region}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '“${profile.intro}”',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cocoa,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _KVChips(label: '취향', items: profile.taste),
        const SizedBox(height: 10),
        _KVChips(label: '디저트', items: profile.dessert),
        const SizedBox(height: 10),
        _KVChips(label: '주량·흡연', items: [profile.drink, profile.smoke]),
        const SizedBox(height: 18),
        Text(
          '이 분의 장점, 어떠세요?',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.cocoa,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final trait in profile.good) ...[
          _TraitCheck(
            label: trait,
            vote: flow.traitVote(profile.nickname, trait),
            onLike: () =>
                flow.toggleTraitVote(profile.nickname, trait, true),
            onDislike: () =>
                flow.toggleTraitVote(profile.nickname, trait, false),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _KVChips extends StatelessWidget {
  const _KVChips({required this.label, required this.items});

  final String label;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in items)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.cocoa,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TraitCheck extends StatelessWidget {
  const _TraitCheck({
    required this.label,
    required this.vote,
    required this.onLike,
    required this.onDislike,
  });

  final String label;
  final bool? vote;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  @override
  Widget build(BuildContext context) {
    final liked = vote == true;
    final disliked = vote == false;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.cocoa,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _TraitButton(
            icon: Icons.favorite,
            label: '좋아요',
            active: liked,
            activeColor: AppColors.burgundy,
            activeTextColor: Colors.white,
            onTap: onLike,
          ),
          const SizedBox(width: 6),
          _TraitButton(
            label: '싫어요',
            active: disliked,
            activeColor: const Color(0xFFEBDDD0),
            activeTextColor: AppColors.cocoa,
            onTap: onDislike,
          ),
        ],
      ),
    );
  }
}

class _TraitButton extends StatelessWidget {
  const _TraitButton({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.activeTextColor,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final Color activeTextColor;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = active ? activeTextColor : AppColors.mutedText;
    return Material(
      color: active ? activeColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: active ? activeColor : AppColors.line,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeatReadyStage extends StatelessWidget {
  const _SeatReadyStage({required this.flow});

  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    // 라이브면 seating/{tableId} 좌석도, 아니면 데모 좌석.
    final myNickname = flow.participantProfile.nickname;
    final tableLabel = flow.myTable?.tableId ?? 'B 테이블';
    final pairName = flow.myPairSeat?.nickname ?? '소금빵';
    final opposites = flow.myOppositeSeats;
    final oppositeLeft = opposites.isNotEmpty ? opposites.first.nickname : '마들렌';
    final oppositeRight = opposites.length > 1 ? opposites[1].nickname : '크렘브륄레';
    final myMark = myNickname.isNotEmpty ? myNickname[0] : '티';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _StageBadge(label: 'OVENING'),
            const SizedBox(width: 10),
            Text(
              '자리 분석 완료',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.burgundy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '당신의 페어와\n자리가 정해졌어요.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.burgundy,
            fontSize: 27,
            fontWeight: FontWeight.w500,
            height: 1.18,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '내 테이블만 보여드려요. 같은 테이블이 누구인지는 공개되지 않고, 내 옆자리 페어만 알려드려요.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.cocoa, height: 1.6),
        ),
        const SizedBox(height: 22),
        // YOUR TABLE 배지
        AppCard(
          color: AppColors.butter,
          borderColor: AppColors.butter,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR TABLE',
                style: TextStyle(
                  color: AppColors.wine,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tableLabel,
                style: const TextStyle(
                  color: AppColors.wine,
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '4명이 함께 앉아요 · 내 옆자리 페어는 $pairName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.wine,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 사각 테이블 — 4자리
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SeatSpot(label: '맞은편', name: oppositeLeft),
                    const SizedBox(width: 40),
                    _SeatSpot(label: '맞은편', name: oppositeRight),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  width: 200,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.mutedText, width: 1.5),
                  ),
                  child: Text(
                    tableLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SeatSpot(label: '내 자리', name: myMark, mine: true),
                    const SizedBox(width: 40),
                    _SeatSpot(label: '옆자리 페어', name: pairName, pair: true),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 6,
                  children: const [
                    _SeatLegend(color: AppColors.burgundy, label: '나'),
                    _SeatLegend(color: AppColors.gold, label: '옆자리 페어'),
                    _SeatLegend(
                      color: Colors.transparent,
                      label: '비공개',
                      dashed: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const _SectionLabel('자리는 중간 선택으로 정해져요'),
        const SizedBox(height: 10),
        const _PriorityCard(
          rank: '1순위',
          rankColor: AppColors.gold,
          title: '중간 선택 쌍방 매칭',
          body: '중간 선택에서 서로를 고른 두 분은 옆자리 페어로 배치돼요.',
        ),
        const SizedBox(height: 10),
        const _PriorityCard(
          rank: '2순위 · AI 배치',
          rankColor: AppColors.burgundy,
          title: '케미 점수 + 첫인상 선택',
          body:
              '쌍방 매칭이 없으면 AI가 케미 점수와 첫인상 선택을 바탕으로 가장 잘 어울리는 자리를 배치해요.',
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: flow.advance,
            child: const Text('자리를 확인했어요'),
          ),
        ),
      ],
    );
  }
}

/// 사각 테이블의 한 자리. 나/옆자리 페어만 닉네임이 공개되고 나머지는 비공개.
class _SeatSpot extends StatelessWidget {
  const _SeatSpot({
    required this.label,
    required this.name,
    this.mine = false,
    this.pair = false,
  });

  final String label;
  final String name;
  final bool mine;
  final bool pair;

  @override
  Widget build(BuildContext context) {
    final revealed = mine || pair;
    final Color seatColor = mine
        ? AppColors.burgundy
        : pair
            ? AppColors.gold
            : Colors.white;
    final Color markColor = mine
        ? AppColors.butter
        : pair
            ? AppColors.wine
            : AppColors.mutedText;
    final Color nameColor = mine
        ? AppColors.burgundy
        : pair
            ? AppColors.gold
            : AppColors.mutedText;

    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: seatColor,
            borderRadius: BorderRadius.circular(18),
            border: revealed
                ? null
                : Border.all(
                    color: AppColors.mutedText,
                    width: 1.5,
                  ),
          ),
          child: Text(
            revealed ? name.characters.first : '?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: markColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          mine ? '나' : revealed ? name : '비공개',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: revealed ? FontWeight.w700 : FontWeight.w500,
            color: nameColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9.5, color: AppColors.mutedText),
        ),
      ],
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        dashed ? AppColors.mutedText : (color == AppColors.gold
            ? AppColors.gold
            : AppColors.burgundy);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: dashed
                ? Border.all(color: AppColors.mutedText, width: 1.5)
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({
    required this.rank,
    required this.rankColor,
    required this.title,
    required this.body,
  });

  final String rank;
  final Color rankColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rank,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: rankColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.cocoa,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
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
        Builder(builder: (context) {
          // 라이브면 내 닉네임 + 좌석 페어, 아니면 데모 페어.
          final me = flow.isLive && flow.participantProfile.nickname.isNotEmpty
              ? flow.participantProfile.nickname
              : '티라미수';
          final pair = flow.myPairSeat?.nickname ?? '소금빵';
          return AppCard(
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
                children: [
                  _ResultAvatar(label: me[0]),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.close_rounded, color: AppColors.butter),
                  ),
                  _ResultAvatar(label: pair.isNotEmpty ? pair[0] : '소'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '$me × $pair',
                style: const TextStyle(
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
          );
        }),
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

class _MatchResultStage extends StatefulWidget {
  const _MatchResultStage({required this.flow});

  final DemoFlowProvider flow;

  @override
  State<_MatchResultStage> createState() => _MatchResultStageState();
}

class _MatchResultStageState extends State<_MatchResultStage> {
  // 편지를 열어야 누가 보냈는지, 매칭 여부를 알 수 있다.
  bool _letterOpened = false;

  // 데모 폴백 값. 라이브면 matches 문서(운영자/Functions 산출)를 사용한다.
  static const String _demoPick = '소금빵';
  static const String _demoLetterFrom = '소금빵';
  static const String _demoLetterMessage =
      '오늘 반죽 치대면서 나눈 대화가 참 편안했어요. 달지 않아도 오래 기억에 남는, 그런 사람 같았어요. 다음엔 천천히 커피 한잔 해요 :)';

  String get _myPick =>
      widget.flow.selectedChoiceFor(ChoicePhase.finalChoice) ?? _demoPick;

  String get _letterFrom =>
      widget.flow.matchPartnerNickname ??
      (widget.flow.isLive ? _myPick : _demoLetterFrom);

  String get _letterMessage {
    final live = widget.flow.matchPartnerLetter;
    return (live == null || live.isEmpty) ? _demoLetterMessage : live;
  }

  bool get _matched =>
      widget.flow.isLive ? !widget.flow.liveMatchPending : _myPick == _letterFrom;

  Future<void> _openLetter() async {
    setState(() => _letterOpened = true);
    if (_matched) {
      await showDialog<void>(
        context: context,
        barrierColor: AppColors.wine.withValues(alpha: 0.6),
        builder: (_) => _MatchCongratsDialog(character: _letterFrom),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.flow;

    // 라이브인데 아직 매칭 산출 전이면 집계 중 안내.
    if (flow.isLive && flow.liveMatchPending) {
      return _MatchPendingBody(flow: flow);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StageBadge(label: 'CHEMISTRY RESULT'),
        const SizedBox(height: 12),
        Text(
          '오늘의 케미 결과가\n편지로 도착했어요.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.burgundy,
            fontSize: 27,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '편지를 열어야 누가 보냈는지, 매칭이 되었는지 알 수 있어요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 22),
        _EnvelopeLetter(
          opened: _letterOpened,
          from: _letterFrom,
          matched: _matched,
          message: _letterMessage,
          onOpen: _openLetter,
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
                    Builder(builder: (context) {
                      final me =
                          flow.isLive && flow.participantProfile.nickname.isNotEmpty
                              ? flow.participantProfile.nickname
                              : '티라미수';
                      final partner = _letterFrom;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _ResultAvatar(label: me[0]),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(
                                  Icons.favorite_border_rounded,
                                  color: AppColors.butter,
                                  size: 20,
                                ),
                              ),
                              _ResultAvatar(
                                label: partner.isNotEmpty ? partner[0] : 'S',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '$me↔$partner',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      );
                    }),
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

/// 탭하여 여는 편지봉투 → 편지지. 매칭 결과를 전달한다.
/// 라이브 모드에서 matches 문서가 아직 없을 때(집계 중) 보여주는 대기 화면.
class _MatchPendingBody extends StatelessWidget {
  const _MatchPendingBody({required this.flow});

  final DemoFlowProvider flow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StageBadge(label: 'CHEMISTRY RESULT'),
        const SizedBox(height: 12),
        Text(
          '케미 결과를\n집계하고 있어요.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.burgundy,
            fontSize: 27,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '모두의 최종 선택이 모이면 편지로 알려드려요. 잠시만 기다려주세요.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 26),
        AppCard(
          color: AppColors.ivory,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                color: AppColors.burgundy,
                size: 34,
              ),
              const SizedBox(height: 14),
              Text(
                '결과가 나오면 이 화면이 자동으로 바뀌어요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.cocoa,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EnvelopeLetter extends StatelessWidget {
  const _EnvelopeLetter({
    required this.opened,
    required this.from,
    required this.matched,
    required this.message,
    required this.onOpen,
  });

  final bool opened;
  final String from;
  final bool matched;
  final String message;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.mail_outline, size: 15, color: AppColors.burgundy),
            const SizedBox(width: 6),
            Text(
              '도착한 편지',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.burgundy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!opened)
          _ClosedEnvelope(onTap: onOpen)
        else
          _OpenLetter(from: from, matched: matched, message: message),
      ],
    );
  }
}

class _ClosedEnvelope extends StatelessWidget {
  const _ClosedEnvelope({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.parchment, Color(0xFFEBD9BE)],
          ),
          border: Border.all(color: AppColors.mutedText),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 봉투 덮개 (삼각형)
            Align(
              alignment: Alignment.topCenter,
              child: ClipPath(
                clipper: _EnvelopeFlapClipper(),
                child: Container(
                  height: 112,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFEFDCC0), Color(0xFFE3CDA8)],
                    ),
                  ),
                ),
              ),
            ),
            // 봉인 (왁스 씰)
            Positioned(
              top: 80,
              child: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    colors: [AppColors.burgundy, AppColors.wine],
                  ),
                  border: Border.all(
                    color: AppColors.butter.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Text(
                  'C·O',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Column(
                children: [
                  Text(
                    '한 통의 편지가 도착했어요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.wine,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '탭하여 누가 보냈는지 확인하기',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.cocoa,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnvelopeFlapClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _OpenLetter extends StatelessWidget {
  const _OpenLetter({
    required this.from,
    required this.matched,
    required this.message,
  });

  final String from;
  final bool matched;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.burgundy,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  from.characters.first,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '보낸 사람',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  Text(
                    from,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.cocoa,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (matched)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '쌍방 매칭',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.wine,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'To. 티라미수님께',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"$message"',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.wine,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.75,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'From. $from',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.cocoa,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 쌍방 매칭 시 편지를 열면 뜨는 축하 모달.
class _MatchCongratsDialog extends StatelessWidget {
  const _MatchCongratsDialog({required this.character});

  final String character;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.wine,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite,
                size: 40,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'CONGRATULATIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: AppColors.burgundy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '매칭되었어요!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.burgundy,
                fontSize: 30,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.mutedText,
                  height: 1.65,
                ),
                children: [
                  const TextSpan(text: '내가 선택한 '),
                  TextSpan(
                    text: character,
                    style: const TextStyle(
                      color: AppColors.burgundy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: '님도\n나를 선택했어요. 이제 이름과 연락처가 공개돼요.'),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('연락처 확인하기'),
              ),
            ),
          ],
        ),
      ),
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
    // 라이브면 reports/{id}(Functions 산출) 리포트, 아니면 데모 리포트.
    final report =
        flow.liveReport ?? AppScope.of(context).repository.fetchReports().first;

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
                  builder: (_) => ReviewGateScreen(
                    onReviewSubmitted: (stars, type, text) =>
                        flow.submitReview(stars: stars, type: type, text: text),
                  ),
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
