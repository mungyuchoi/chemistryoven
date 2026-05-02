import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/demo_models.dart';
import '../../../shared/providers/app_scope.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final admin = appState.adminProvider;
    final repository = appState.repository;

    return Column(
      children: [
        AppCard(
          color: AppColors.wine,
          borderColor: AppColors.wine,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '운영자 콘솔',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Firebase 없이 신청자, 선정, 좌석, 라운드, 매칭, 리포트 상태를 더미로 검토합니다.',
                style: TextStyle(color: Color(0xFFFFE8C2), height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    label: '인증 대기',
                    value: admin.pendingVerificationCount,
                  ),
                  _StatChip(label: '선정', value: admin.selectedCount),
                  _StatChip(label: '입금', value: admin.paidCount),
                  _StatChip(label: '리포트', value: admin.sentReportCount),
                ],
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
        ),
        const SizedBox(height: 14),
        _AdminSection(
          title: '인증 승인 / 반려',
          subtitle: '신청자 서류 검토 후 상태를 더미로 변경합니다.',
          action: null,
          children: [
            for (final applicant in admin.applicants.take(4))
              _ApplicantRow(applicant: applicant),
          ],
        ),
        const SizedBox(height: 14),
        _AdminSection(
          title: 'AI 선정 결과',
          subtitle: '점수 기준으로 상위 참가자를 선정한 결과를 표시합니다.',
          action: ElevatedButton.icon(
            onPressed: admin.runAiSelection,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI 선정 실행'),
          ),
          children: [
            if (!admin.aiResultVisible)
              const _EmptyAdminState(
                icon: Icons.auto_awesome_outlined,
                text: 'AI 선정 실행 전입니다.',
              )
            else
              for (final applicant in admin.applicants.where(
                (item) => item.selected,
              ))
                _SimpleAdminRow(
                  icon: Icons.star,
                  title: applicant.nickname,
                  subtitle:
                      '${applicant.gender} · ${applicant.age}세 · '
                      '${applicant.mbti} · ${applicant.score}점',
                  trailing: const StatusBadge(
                    label: '선정',
                    color: AppColors.success,
                  ),
                ),
          ],
        ),
        const SizedBox(height: 14),
        _AdminSection(
          title: '최종 참가자 확정',
          subtitle: 'AI 선정 이후 운영자가 참가자를 수동 확정합니다.',
          action: ElevatedButton.icon(
            onPressed: admin.lockParticipants,
            icon: const Icon(Icons.verified_user),
            label: const Text('최종 확정'),
          ),
          children: [
            _ProgressAdminRow(
              label: '참가자 확정',
              done: admin.participantsLocked,
              description: '${admin.selectedCount}명을 최종 참가자로 표시',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AdminSection(
          title: '입금 확인',
          subtitle: 'PG 연동 없이 운영자 버튼으로 입금 확인 상태를 표시합니다.',
          action: ElevatedButton.icon(
            onPressed: admin.confirmPayments,
            icon: const Icon(Icons.payments),
            label: const Text('입금 일괄 확인'),
          ),
          children: [
            _ProgressAdminRow(
              label: '입금 상태',
              done: admin.paymentsConfirmed,
              description: '${admin.paidCount}/${admin.selectedCount}명 입금 확인',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AdminSection(
          title: '좌석 배치',
          subtitle: '테이블과 오븐 위치를 더미로 배정합니다.',
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
              for (final seat in repository.fetchSeatAssignments())
                _SimpleAdminRow(
                  icon: Icons.table_bar,
                  title: seat.tableName,
                  subtitle: '${seat.participants.join(', ')}\n${seat.note}',
                ),
          ],
        ),
        const SizedBox(height: 14),
        _AdminSection(
          title: '라운드 전환',
          subtitle: '행사 당일 진행 라운드를 운영자가 넘기는 화면입니다.',
          action: ElevatedButton.icon(
            onPressed: admin.nextRound,
            icon: const Icon(Icons.skip_next),
            label: const Text('다음 라운드'),
          ),
          children: [
            for (final round in admin.rounds)
              _SimpleAdminRow(
                icon: round.order == admin.currentRoundIndex
                    ? Icons.play_circle_fill
                    : Icons.circle_outlined,
                title: round.title,
                subtitle: round.description,
                trailing: StatusBadge(
                  label: round.status,
                  color: round.status == '진행 중'
                      ? AppColors.burgundy
                      : AppColors.mutedText,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _AdminSection(
          title: '선택 집계',
          subtitle: '첫인상, 중간, 최종 선택 제출 결과를 더미로 표시합니다.',
          action: ElevatedButton.icon(
            onPressed: admin.aggregateChoices,
            icon: const Icon(Icons.query_stats),
            label: const Text('집계 보기'),
          ),
          children: [
            if (!admin.choicesAggregated)
              const _EmptyAdminState(
                icon: Icons.query_stats,
                text: '선택 집계 전입니다.',
              )
            else
              for (final summary in repository.fetchChoiceSummaries())
                _SimpleAdminRow(
                  icon: Icons.favorite,
                  title: summary.roundName,
                  subtitle:
                      '제출 ${summary.totalChoices}건 · '
                      '상호 ${summary.mutualMatches}건 · '
                      '인기 ${summary.topDessert}',
                ),
          ],
        ),
        const SizedBox(height: 14),
        _AdminSection(
          title: '매칭 승인',
          subtitle: '운영자가 상호 매칭 결과를 최종 승인합니다.',
          action: ElevatedButton.icon(
            onPressed: admin.approveMatching,
            icon: const Icon(Icons.favorite),
            label: const Text('매칭 승인'),
          ),
          children: [
            for (final match in admin.matches)
              _SimpleAdminRow(
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
        ),
        const SizedBox(height: 14),
        _AdminSection(
          title: '리포트 발송 상태',
          subtitle: '케미 리포트 발송 완료 여부를 더미로 변경합니다.',
          action: ElevatedButton.icon(
            onPressed: admin.sendReports,
            icon: const Icon(Icons.send),
            label: const Text('리포트 발송'),
          ),
          children: [
            for (final report in admin.reports)
              _SimpleAdminRow(
                icon: Icons.description_outlined,
                title: report.nickname,
                subtitle: '${report.score}점 · ${report.summary}',
                trailing: StatusBadge(
                  label: report.sent ? '발송 완료' : '대기',
                  color: report.sent ? AppColors.success : AppColors.warning,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AdminSection extends StatelessWidget {
  const _AdminSection({
    required this.title,
    required this.subtitle,
    required this.children,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;
  final List<Widget> children;

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
  const _ApplicantRow({required this.applicant});

  final DemoApplicant applicant;

  @override
  Widget build(BuildContext context) {
    final admin = AppScope.of(context).adminProvider;
    final statusColor = applicant.status == '인증 반려'
        ? AppColors.warning
        : applicant.verified
        ? AppColors.success
        : AppColors.burgundy;

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

class _SimpleAdminRow extends StatelessWidget {
  const _SimpleAdminRow({
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.burgundy, size: 22),
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
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _ProgressAdminRow extends StatelessWidget {
  const _ProgressAdminRow({
    required this.label,
    required this.done,
    required this.description,
  });

  final String label;
  final bool done;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _SimpleAdminRow(
      icon: done ? Icons.check_circle : Icons.radio_button_unchecked,
      title: label,
      subtitle: description,
      trailing: StatusBadge(
        label: done ? '완료' : '대기',
        color: done ? AppColors.success : AppColors.warning,
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.burgundy),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
