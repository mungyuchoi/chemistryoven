import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/demo_models.dart';
import '../../../shared/providers/app_scope.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({required this.onApplyClass, super.key});

  final ValueChanged<ChemistryClass> onApplyClass;

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  int _selectedDay = 14;

  @override
  Widget build(BuildContext context) {
    final classes = AppScope.of(context).sessionsController.sessions
        .map((s) => s.toDisplayClass())
        .toList();
    final selectedClasses = classes
        .where((demoClass) => demoClass.eventDay == _selectedDay)
        .toList();
    final upcomingClasses = classes
        .where((demoClass) => demoClass.eventDay != _selectedDay)
        .toList();

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '일정',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.chocolate,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '참여 가능한 회차를 달력에서 확인해보세요.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _MonthHeader(),
                    const SizedBox(height: 12),
                    _CalendarCard(
                      classes: classes,
                      selectedDay: _selectedDay,
                      onDaySelected: (day) =>
                          setState(() => _selectedDay = day),
                    ),
                    const SizedBox(height: 24),
                    _SelectedDateSection(
                      selectedDay: _selectedDay,
                      selectedClasses: selectedClasses,
                      onOpenDetail: (demoClass) =>
                          _showClassDetail(context, demoClass),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '앞으로의 회차',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.chocolate,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (classes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            '곧 새로운 회차가 열릴 거예요.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ),
                      )
                    else
                      for (final demoClass in upcomingClasses) ...[
                        _UpcomingClassCard(
                          demoClass: demoClass,
                          onTap: () {
                            setState(() => _selectedDay = demoClass.eventDay);
                            _showClassDetail(context, demoClass);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClassDetail(BuildContext context, ChemistryClass demoClass) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ClassDetailScreen(
          demoClass: demoClass,
          onApply: () => widget.onApplyClass(demoClass),
        ),
      ),
    );
  }
}

class _ClassDetailScreen extends StatelessWidget {
  const _ClassDetailScreen({required this.demoClass, required this.onApply});

  final ChemistryClass demoClass;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _ClassDetailTopBar(),
                          const SizedBox(height: 10),
                          _ClassDetailHero(demoClass: demoClass),
                          const SizedBox(height: 14),
                          _ClassInfoCard(demoClass: demoClass),
                          const SizedBox(height: 20),
                          const _DetailSectionLabel('진행 방식'),
                          const SizedBox(height: 10),
                          const _DetailProgramCard(),
                          const SizedBox(height: 20),
                          const _DetailSectionLabel('신청 조건'),
                          const SizedBox(height: 10),
                          const _ApplicationConditionCard(),
                          const SizedBox(height: 20),
                          const _DetailSectionLabel(
                            '오늘의 베이킹 품목',
                            sub: '운영진이 회차마다 등록해요',
                          ),
                          const SizedBox(height: 10),
                          const _BakingItemCard(),
                          const SizedBox(height: 20),
                          const _DetailSectionLabel(
                            '함께할 분들',
                            sub: '3:3 모집이 완료되면 공개돼요',
                          ),
                          const SizedBox(height: 10),
                          const _ApplicantRevealCard(),
                          const SizedBox(height: 20),
                          const _DetailSectionLabel('유의사항 · 환불 규정'),
                          const SizedBox(height: 10),
                          const _RefundPolicyCard(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _ClassDetailBottomBar(
              enabled: demoClass.isOpen,
              onApply: () {
                Navigator.of(context).pop();
                onApply();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassDetailTopBar extends StatelessWidget {
  const _ClassDetailTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareIconButton(
          icon: Icons.chevron_left,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Expanded(
          child: Text(
            '회차 상세',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.chocolate,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _SquareIconButton(icon: Icons.favorite_border, onTap: () {}),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: AppColors.cocoa, size: 18),
        ),
      ),
    );
  }
}

class _ClassDetailHero extends StatelessWidget {
  const _ClassDetailHero({required this.demoClass});

  final ChemistryClass demoClass;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      decoration: const BoxDecoration(color: Color(0xFFA53B48)),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const StatusBadge(
                  label: '신청가능',
                  color: AppColors.success,
                  backgroundColor: Color(0xFFE4F5E8),
                ),
                const SizedBox(width: 68),
                Container(
                  width: 106,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ivory.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'SESSION KEY VISUAL',
                    style: TextStyle(
                      color: AppColors.burgundy,
                      fontSize: 7,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              demoClass.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              demoClass.subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassInfoCard extends StatelessWidget {
  const _ClassInfoCard({required this.demoClass});

  final ChemistryClass demoClass;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white.withValues(alpha: 0.76),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          _ClassInfoRow(
            icon: Icons.calendar_month_outlined,
            label: '일시',
            value: _detailDateTimeText(demoClass),
          ),
          const _InfoDivider(),
          _ClassInfoRow(
            icon: Icons.place_outlined,
            label: '장소',
            value: _detailPlaceText(demoClass),
          ),
          const _InfoDivider(),
          _ClassInfoRow(
            icon: Icons.person_outline,
            label: '모집',
            value: _detailCapacityText(demoClass),
          ),
          const _InfoDivider(),
          _ClassInfoRow(
            icon: Icons.confirmation_number_outlined,
            label: '참가비',
            value: _detailFeeText(demoClass),
          ),
        ],
      ),
    );
  }

  static String _detailDateTimeText(ChemistryClass demoClass) {
    if (demoClass.id == 'class-8') {
      return '2026. 6. 14 (토) 오후 3:00 - 6:00';
    }
    return '${demoClass.dateText} ${demoClass.timeText}';
  }

  static String _detailPlaceText(ChemistryClass demoClass) {
    if (demoClass.id == 'class-8') {
      return '서울 베이킹 스튜디오 · 서울 송파';
    }
    return demoClass.place;
  }

  static String _detailCapacityText(ChemistryClass demoClass) {
    if (demoClass.id == 'class-8') {
      return '남 5명 / 여 5명 (총 10명)';
    }
    return demoClass.capacityLabel;
  }

  static String _detailFeeText(ChemistryClass demoClass) {
    if (demoClass.id == 'class-8') {
      return '60,000원';
    }
    return demoClass.priceText;
  }
}

class _ClassInfoRow extends StatelessWidget {
  const _ClassInfoRow({
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.burgundy, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: AppColors.chocolate,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.line);
  }
}

class _DetailSectionLabel extends StatelessWidget {
  const _DetailSectionLabel(this.label, {this.sub});

  final String label;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.chocolate,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(
            sub!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailProgramCard extends StatelessWidget {
  const _DetailProgramCard();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'AI 케미 분석', '성향 질문지를 기반으로 케미 캐릭터 매칭'),
      ('2', '소셜 베이킹', '함께 디저트를 만들며 자연스러운 첫 만남'),
      ('3', '대화 & 게임', '캐릭터 닉네임으로 라운드별 대화'),
      ('4', '선택', '첫인상 · 중간 · 최종 라운드 선택'),
      ('5', '매칭 결과', '상호 선택 시 연락처 공개 · 케미 리포트'),
    ];

    return AppCard(
      color: Colors.white.withValues(alpha: 0.72),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          for (final step in steps)
            _DetailProgramStep(index: step.$1, title: step.$2, body: step.$3),
        ],
      ),
    );
  }
}

class _DetailProgramStep extends StatelessWidget {
  const _DetailProgramStep({
    required this.index,
    required this.title,
    required this.body,
  });

  final String index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blush,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              index,
              style: const TextStyle(
                color: AppColors.burgundy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.chocolate,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
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

class _ApplicationConditionCard extends StatelessWidget {
  const _ApplicationConditionCard();

  @override
  Widget build(BuildContext context) {
    const conditions = [
      '만 25세 - 39세',
      '실명 / 직장 인증이 가능하신 분',
      '오브닝 진행 규칙에 동의하시는 분',
    ];

    return AppCard(
      color: Colors.white.withValues(alpha: 0.72),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final condition in conditions) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '·',
                  style: TextStyle(
                    color: AppColors.chocolate,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    condition,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.chocolate,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            if (condition != conditions.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ClassDetailBottomBar extends StatelessWidget {
  const _ClassDetailBottomBar({required this.enabled, required this.onApply});

  final bool enabled;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cream,
        boxShadow: [
          BoxShadow(
            color: AppColors.wine.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enabled ? onApply : null,
                child: Text(enabled ? '신청하기' : '오픈 알림 받기'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.classes,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<ChemistryClass> classes;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final eventDays = {
      for (final demoClass in classes) demoClass.eventDay: demoClass,
    };
    final days =
        List<int?>.filled(1, null) + List.generate(30, (index) => index + 1);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              _Weekday('일', weekend: true),
              _Weekday('월'),
              _Weekday('화'),
              _Weekday('수'),
              _Weekday('목'),
              _Weekday('금'),
              _Weekday('토', weekend: true),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 12,
              crossAxisSpacing: 4,
              childAspectRatio: 0.92,
            ),
            itemCount: 35,
            itemBuilder: (context, index) {
              final day = index < days.length ? days[index] : null;
              if (day == null) {
                return const SizedBox.shrink();
              }
              final demoClass = eventDays[day];
              final selected = selectedDay == day;
              final hasEvent = demoClass != null;

              return _CalendarDayCell(
                day: day,
                selected: selected,
                hasEvent: hasEvent,
                onTap: () => onDaySelected(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '2026. 06',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.burgundy,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 18),
        Text(
          'June',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        _MonthNavButton(icon: Icons.chevron_left),
        const SizedBox(width: 8),
        _MonthNavButton(icon: Icons.chevron_right),
      ],
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Icon(icon, size: 18, color: AppColors.cocoa),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.selected,
    required this.hasEvent,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool hasEvent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('calendar-day-$day'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Center(
        child: Container(
          width: selected ? 46 : 40,
          height: selected ? 52 : 44,
          decoration: BoxDecoration(
            color: selected ? AppColors.burgundy : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.chocolate,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: hasEvent
                      ? selected
                            ? AppColors.butter
                            : AppColors.gold
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDateSection extends StatelessWidget {
  const _SelectedDateSection({
    required this.selectedDay,
    required this.selectedClasses,
    required this.onOpenDetail,
  });

  final int selectedDay;
  final List<ChemistryClass> selectedClasses;
  final ValueChanged<ChemistryClass> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '6월 $selectedDay일 (${_weekdayLabel(selectedDay)})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.chocolate,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          selectedClasses.isEmpty ? '이 날 열리는 회차가 없어요' : '이 날 열리는 회차',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 12),
        if (selectedClasses.isEmpty)
          _EmptyDateCard(day: selectedDay)
        else ...[
          for (final demoClass in selectedClasses) ...[
            _SelectedClassCard(
              demoClass: demoClass,
              onTap: () => onOpenDetail(demoClass),
            ),
            const SizedBox(height: 10),
          ],
          const _SpecialLabCard(),
        ],
      ],
    );
  }

  String _weekdayLabel(int day) {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    return labels[DateTime(2026, 6, day).weekday % 7];
  }
}

class _SelectedClassCard extends StatelessWidget {
  const _SelectedClassCard({required this.demoClass, required this.onTap});

  final ChemistryClass demoClass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _DateTile(day: demoClass.eventDay),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        demoClass.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.chocolate,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: demoClass.statusLabel,
                      color: AppColors.success,
                      backgroundColor: const Color(0xFFE4F5E8),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${demoClass.subtitle} · ${demoClass.place}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '모집 ${demoClass.applicationCount}명',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      demoClass.priceText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.cocoa,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'JUN',
            style: TextStyle(
              color: AppColors.burgundy,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$day',
            style: const TextStyle(
              color: AppColors.burgundy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialLabCard extends StatelessWidget {
  const _SpecialLabCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white.withValues(alpha: 0.84),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.parchment.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.article_outlined,
              color: AppColors.cocoa,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '스페셜 - 디저트 LAB Day',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.chocolate,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '오후 7시 · 한정동',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const StatusBadge(
            label: '기획중',
            color: AppColors.cocoa,
            backgroundColor: AppColors.parchment,
          ),
        ],
      ),
    );
  }
}

class _UpcomingClassCard extends StatelessWidget {
  const _UpcomingClassCard({required this.demoClass, required this.onTap});

  final ChemistryClass demoClass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  demoClass.title,
                  style: const TextStyle(
                    color: AppColors.chocolate,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${demoClass.dateText} · ${demoClass.place}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 5),
                Text(
                  '${demoClass.capacityLabel} · ${demoClass.priceText}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusBadge(
            label: demoClass.statusLabel,
            color: demoClass.isOpen ? AppColors.success : AppColors.warning,
            backgroundColor: demoClass.isOpen
                ? const Color(0xFFE4F5E8)
                : AppColors.parchment,
          ),
        ],
      ),
    );
  }
}

class _EmptyDateCard extends StatelessWidget {
  const _EmptyDateCard({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            color: AppColors.brandRed,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            '6월 $day일에는 아직 확정된 일정이 없어요.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '신청 가능 상태의 회차만 신청 버튼이 열립니다.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday(this.label, {this.weekend = false});

  final String label;
  final bool weekend;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: weekend ? AppColors.burgundy : AppColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _BakingItemCard extends StatelessWidget {
  const _BakingItemCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white.withValues(alpha: 0.72),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 130,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.parchment),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.ivory.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'BAKING ITEM PHOTO · 운영진 업로드',
                style: TextStyle(
                  color: AppColors.burgundy,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '마들렌 · 휘낭시에',
                  style: TextStyle(
                    color: AppColors.cocoa,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '페어와 함께 두 가지를 구워요 · 재료·도구 모두 현장 준비',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
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

class _ApplicantRevealCard extends StatelessWidget {
  const _ApplicantRevealCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 모집 4 : 4',
                      style: TextStyle(
                        color: AppColors.cocoa,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '3:3 완료 · 신청 현황 공개됨',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F5E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '공개',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              color: AppColors.parchment.withValues(alpha: 0.7),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.8,
                child: Container(color: AppColors.burgundy),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최소 3:3',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Text(
                '기본 5:5',
                style: TextStyle(
                  color: AppColors.burgundy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '최대 10:10',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _AgeDotPlot(
            min: 26,
            max: 40,
            male: [31, 33, 34, 36],
            female: [28, 29, 31, 32],
          ),
          const SizedBox(height: 12),
          Text(
            '상세 프로필은 회차 당일 캐릭터 닉네임으로 공개돼요. 신청은 접수 순서에 맞춰 진행돼요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              fontSize: 11,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgeDotPlot extends StatelessWidget {
  const _AgeDotPlot({
    required this.min,
    required this.max,
    required this.male,
    required this.female,
  });

  final int min;
  final int max;
  final List<int> male;
  final List<int> female;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AgeDotRow(
          label: '남',
          color: AppColors.burgundy,
          min: min,
          max: max,
          ages: male,
        ),
        const SizedBox(height: 8),
        _AgeDotRow(
          label: '여',
          color: AppColors.caramel,
          min: min,
          max: max,
          ages: female,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '만 $min세',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '만 $max세',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AgeDotRow extends StatelessWidget {
  const _AgeDotRow({
    required this.label,
    required this.color,
    required this.min,
    required this.max,
    required this.ages,
  });

  final String label;
  final Color color;
  final int min;
  final int max;
  final List<int> ages;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dotSize = 10.0;
              final span = (max - min).clamp(1, 999);
              final track = constraints.maxWidth - dotSize;
              return SizedBox(
                height: dotSize,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 2,
                        color: AppColors.line,
                      ),
                    ),
                    for (final age in ages)
                      Positioned(
                        left:
                            ((age - min).clamp(0, span) / span) * track,
                        top: 0,
                        child: Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RefundPolicyCard extends StatelessWidget {
  const _RefundPolicyCard();

  @override
  Widget build(BuildContext context) {
    const lines = [
      '선정 발표 후 24시간 내 입금이 확인되어야 최종 확정됩니다.',
      '행사 7일 전까지: 전액 환불 / 3일 전: 50% / 이후: 환불 불가',
      '견과류 · 글루텐 알레르기는 신청서에 반드시 표기 부탁드려요.',
    ];

    return AppCard(
      color: Colors.white.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '·',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    height: 1.7,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      height: 1.7,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            if (line != lines.last) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
