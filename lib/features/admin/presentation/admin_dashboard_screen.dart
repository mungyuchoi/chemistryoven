import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/demo_models.dart';
import '../../../shared/providers/app_scope.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedSection = 0;

  static const _sections = [
    '대시보드',
    '신청자 관리',
    '인원 선정',
    '참가자 관리',
    '캐릭터 배정',
    '투표 관리',
    '자리배치',
    '매칭 결과',
    '후기 관리',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 220,
                child: _SideNav(
                  selected: _selectedSection,
                  onChanged: _changeSection,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _AdminContent(section: _selectedSection)),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopNav(selected: _selectedSection, onChanged: _changeSection),
            const SizedBox(height: 14),
            _AdminContent(section: _selectedSection),
          ],
        );
      },
    );
  }

  void _changeSection(int index) {
    setState(() => _selectedSection = index);
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.adminInk,
      borderColor: AppColors.adminInk,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chemistry Oven',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ADMIN · sora@',
            style: TextStyle(color: AppColors.butter, fontSize: 12),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < _AdminDashboardScreenState._sections.length; i++)
            _NavTile(
              label: _AdminDashboardScreenState._sections[i],
              selected: selected == i,
              onTap: () => onChanged(i),
            ),
        ],
      ),
    );
  }
}

class _TopNav extends StatelessWidget {
  const _TopNav({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (
            var i = 0;
            i < _AdminDashboardScreenState._sections.length;
            i++
          ) ...[
            ChoiceChip(
              label: Text(_AdminDashboardScreenState._sections[i]),
              selected: selected == i,
              onSelected: (_) => onChanged(i),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AppColors.brandRed : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFFFE7DA),
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminContent extends StatelessWidget {
  const _AdminContent({required this.section});

  final int section;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final admin = appState.adminProvider;
    final repository = appState.repository;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminHero(admin: admin),
        const SizedBox(height: 14),
        if (section == 0) ...[
          _DashboardMetrics(admin: admin),
          const SizedBox(height: 14),
          _RoundBoard(admin: admin),
        ] else if (section == 1) ...[
          _ApplicantPanel(admin: admin),
        ] else if (section == 2) ...[
          _SelectionPanel(
            admin: admin,
            scores: repository.fetchAdminScoreRows(),
          ),
        ] else if (section == 3) ...[
          _ParticipantPanel(admin: admin),
        ] else if (section == 4) ...[
          _CharacterPanel(characters: repository.fetchCharacters()),
        ] else if (section == 5) ...[
          _ChoicePanel(
            admin: admin,
            summaries: repository.fetchChoiceSummaries(),
          ),
        ] else if (section == 6) ...[
          _SeatPanel(admin: admin, seats: repository.fetchSeatAssignments()),
        ] else if (section == 7) ...[
          _MatchPanel(admin: admin),
        ] else ...[
          _ReviewPanel(admin: admin),
        ],
      ],
    );
  }
}

class _AdminHero extends StatelessWidget {
  const _AdminHero({required this.admin});

  final dynamic admin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.adminInk,
      borderColor: AppColors.adminInk,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusBadge(
            label: 'ADMIN',
            color: AppColors.wine,
            backgroundColor: AppColors.butter,
          ),
          const SizedBox(height: 12),
          const Text(
            '관리자 · 대시보드',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '신청자 · 성비 · 투표 · 후기 통합 운영 콘솔',
            style: TextStyle(color: Color(0xFFFFE7DA), height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: admin.reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('관리자 더미 상태 초기화'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMetrics extends StatelessWidget {
  const _DashboardMetrics({required this.admin});

  final dynamic admin;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('신청자', '${admin.applicants.length}', '+6'),
      ('인증 대기', '${admin.pendingVerificationCount}', '대기'),
      ('선정', '${admin.selectedCount}', 'AI'),
      ('입금', '${admin.paidCount}', '확인'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.65,
      children: [
        for (final metric in metrics)
          AppCard(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(metric.$1, style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      metric.$2,
                      style: const TextStyle(
                        color: AppColors.wine,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(label: metric.$3),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ApplicantPanel extends StatelessWidget {
  const _ApplicantPanel({required this.admin});

  final dynamic admin;

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      title: '신청자 관리',
      subtitle: '인증 승인/반려와 신청자 메모를 한 화면에서 확인합니다.',
      action: ElevatedButton.icon(
        onPressed: admin.runAiSelection,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI 선정 실행'),
      ),
      children: [
        for (final applicant in admin.applicants)
          _ApplicantRow(applicant: applicant, admin: admin),
      ],
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({required this.admin, required this.scores});

  final dynamic admin;
  final List<AdminScoreRow> scores;

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      title: '인원 선정 · 케미스트리오븐 8기',
      subtitle: 'STRICT 50 · 객관 50 기준의 AI 추천 점수표입니다.',
      action: ElevatedButton.icon(
        onPressed: admin.runAiSelection,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('선정 실행'),
      ),
      children: [
        for (final row in scores)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
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
                        '${row.name} · ${row.gender}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    StatusBadge(label: '${row.chemistryScore}점'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'STRICT ${row.strictScore} · 객관 ${row.objectiveScore}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(row.summary, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _ParticipantPanel extends StatelessWidget {
  const _ParticipantPanel({required this.admin});

  final dynamic admin;

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      title: '참가자 관리',
      subtitle: '최종 참가자 확정과 입금 확인 상태를 더미 버튼으로 전환합니다.',
      action: ElevatedButton.icon(
        onPressed: admin.lockParticipants,
        icon: const Icon(Icons.verified_user),
        label: const Text('최종 확정'),
      ),
      children: [
        _ProgressRow(label: '최종 참가자 확정', done: admin.participantsLocked),
        const SizedBox(height: 10),
        _ProgressRow(label: '입금 확인', done: admin.paymentsConfirmed),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: admin.confirmPayments,
            icon: const Icon(Icons.payments),
            label: const Text('입금 일괄 확인'),
          ),
        ),
      ],
    );
  }
}

class _CharacterPanel extends StatelessWidget {
  const _CharacterPanel({required this.characters});

  final List<ChemistryCharacter> characters;

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      title: '캐릭터 배정',
      subtitle: '남녀 캐릭터 풀과 회차 전용 닉네임을 검토합니다.',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final character in characters.take(12))
              Chip(
                avatar: CircleAvatar(child: Text(character.initial)),
                label: Text(character.name),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChoicePanel extends StatelessWidget {
  const _ChoicePanel({required this.admin, required this.summaries});

  final dynamic admin;
  final List<ChoiceSummary> summaries;

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      title: '투표 관리',
      subtitle: '첫인상, 중간, 최종 선택 제출 결과를 집계합니다.',
      action: ElevatedButton.icon(
        onPressed: admin.aggregateChoices,
        icon: const Icon(Icons.query_stats),
        label: const Text('집계 보기'),
      ),
      children: [
        if (!admin.choicesAggregated)
          const _EmptyAdminState(icon: Icons.query_stats, text: '선택 집계 전입니다.')
        else
          for (final summary in summaries)
            _SimpleRow(
              icon: Icons.favorite,
              title: summary.roundName,
              subtitle:
                  '제출 ${summary.totalChoices}건 · 상호 ${summary.mutualMatches}건 · 인기 ${summary.topDessert}',
            ),
      ],
    );
  }
}

class _SeatPanel extends StatelessWidget {
  const _SeatPanel({required this.admin, required this.seats});

  final dynamic admin;
  final List<SeatAssignment> seats;

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      title: '자리배치',
      subtitle: '테이블별 참석자와 운영 메모를 확인합니다.',
      action: ElevatedButton.icon(
        onPressed: admin.assignSeats,
        icon: const Icon(Icons.chair_alt),
        label: const Text('좌석 배치'),
      ),
      children: [
        if (!admin.seatsAssigned)
          const _EmptyAdminState(
            icon: Icons.chair_alt_outlined,
            text: '좌석 배치 전입니다.',
          )
        else
          for (final seat in seats)
            _SimpleRow(
              icon: Icons.table_bar,
              title: seat.tableName,
              subtitle: '${seat.participants.join(', ')}\n${seat.note}',
            ),
      ],
    );
  }
}

class _MatchPanel extends StatelessWidget {
  const _MatchPanel({required this.admin});

  final dynamic admin;

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      title: '매칭 결과',
      subtitle: '상호 매칭 결과를 승인하면 사용자에게 연락처 공개 상태가 열립니다.',
      action: ElevatedButton.icon(
        onPressed: admin.approveMatching,
        icon: const Icon(Icons.favorite),
        label: const Text('매칭 승인'),
      ),
      children: [
        for (final match in admin.matches)
          _SimpleRow(
            icon: Icons.favorite_border,
            title: '${match.leftNickname} ↔ ${match.rightNickname}',
            subtitle: '${match.score}점 · ${match.sharedTags.join(' · ')}',
            trailing: StatusBadge(
              label: admin.matchingApproved ? '승인' : match.status,
              color: admin.matchingApproved
                  ? AppColors.success
                  : AppColors.warning,
            ),
          ),
      ],
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({required this.admin});

  final dynamic admin;

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      title: '후기 관리',
      subtitle: '케미 리포트 발송과 후기 수집 상태를 관리합니다.',
      action: ElevatedButton.icon(
        onPressed: admin.sendReports,
        icon: const Icon(Icons.send),
        label: const Text('리포트 발송'),
      ),
      children: [
        for (final report in admin.reports)
          _SimpleRow(
            icon: Icons.description_outlined,
            title: report.nickname,
            subtitle: '${report.score}점 · ${report.summary}',
            trailing: StatusBadge(
              label: report.sent ? '발송 완료' : '대기',
              color: report.sent ? AppColors.success : AppColors.warning,
            ),
          ),
      ],
    );
  }
}

class _RoundBoard extends StatelessWidget {
  const _RoundBoard({required this.admin});

  final dynamic admin;

  @override
  Widget build(BuildContext context) {
    return _AdminPanel(
      title: '라운드 전환',
      subtitle: '운영자가 당일 라운드를 넘기면 참가자 오브닝 화면도 같이 이동합니다.',
      action: ElevatedButton.icon(
        onPressed: admin.nextRound,
        icon: const Icon(Icons.skip_next),
        label: const Text('다음 라운드'),
      ),
      children: [
        for (final round in admin.rounds)
          _SimpleRow(
            icon: round.order == admin.currentRoundIndex
                ? Icons.play_circle_fill
                : Icons.circle_outlined,
            title: round.title,
            subtitle: round.description,
            trailing: StatusBadge(
              label: round.status,
              color: round.status == '진행 중'
                  ? AppColors.brandRed
                  : AppColors.mutedText,
            ),
          ),
      ],
    );
  }
}

class _AdminPanel extends StatelessWidget {
  const _AdminPanel({
    required this.title,
    required this.subtitle,
    required this.children,
    this.action,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: title, subtitle: subtitle, trailing: action),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ApplicantRow extends StatelessWidget {
  const _ApplicantRow({required this.applicant, required this.admin});

  final DemoApplicant applicant;
  final dynamic admin;

  @override
  Widget build(BuildContext context) {
    final statusColor = applicant.status == '인증 반려'
        ? AppColors.warning
        : applicant.verified
        ? AppColors.success
        : AppColors.brandRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
                  '${applicant.nickname} · ${applicant.gender} · ${applicant.age}세',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusBadge(label: applicant.status, color: statusColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${applicant.job} · ${applicant.mbti}\n${applicant.memo}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => admin.rejectVerification(applicant.id),
                  icon: const Icon(Icons.close),
                  label: const Text('반려'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => admin.approveVerification(applicant.id),
                  icon: const Icon(Icons.check),
                  label: const Text('승인'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleRow extends StatelessWidget {
  const _SimpleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandRed),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppColors.success : AppColors.line,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        StatusBadge(
          label: done ? '완료' : '대기',
          color: done ? AppColors.success : AppColors.warning,
        ),
      ],
    );
  }
}

class _EmptyAdminState extends StatelessWidget {
  const _EmptyAdminState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.brandRed, size: 32),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
