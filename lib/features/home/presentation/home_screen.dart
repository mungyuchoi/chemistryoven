import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/demo_models.dart';
import '../../../shared/providers/app_scope.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final flow = appState.flowProvider;
    final mode = appState.modeController.mode;
    final featuredClass = appState.repository.fetchFeaturedClass();
    final classes = appState.repository.fetchClasses();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            sliver: SliverList.list(
              children: [
                _HomeHeader(mode: mode),
                const SizedBox(height: 16),
                const _BrandImageBanner(),
                const SizedBox(height: 14),
                _FeaturedClassCard(
                  demoClass: featuredClass,
                  onApply: () => flow.applyForClass(featuredClass.id),
                ),
                const SizedBox(height: 14),
                _StatusPreview(flowStep: flow.currentStep),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: flow.back,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('이전 단계'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: flow.currentStep.isChoiceStage
                            ? flow.submitCurrentChoice
                            : flow.advance,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(flow.currentStep.primaryActionLabel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const SectionTitle(
                  title: '이번 달 회차',
                  subtitle: '캘린더에서 가장 가까운 신청 가능 회차를 확인합니다.',
                ),
                const SizedBox(height: 12),
                _MonthPreview(
                  classes: classes,
                  onApply: (demoClass) => flow.applyForClass(demoClass.id),
                ),
                const SizedBox(height: 24),
                const SectionTitle(
                  title: '케미 레시피',
                  subtitle: '신청부터 리포트까지 오늘의 흐름을 한눈에 봅니다.',
                ),
                const SizedBox(height: 12),
                const _RecipeGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.mode});

  final DemoMode mode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 42,
            height: 42,
            color: AppColors.wine,
            child: Image.asset(AppAssets.patisserieSLogo, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('케미스트리오븐', style: Theme.of(context).textTheme.titleLarge),
              Text(
                '디저트처럼 자연스럽게 익어가는 만남',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        StatusBadge(label: mode.label),
      ],
    );
  }
}

class _BrandImageBanner extends StatelessWidget {
  const _BrandImageBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 1.78,
        child: ColoredBox(
          color: AppColors.wine,
          child: Image.asset(
            AppAssets.chemistrySloganWood,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _FeaturedClassCard extends StatelessWidget {
  const _FeaturedClassCard({required this.demoClass, required this.onApply});

  final ChemistryClass demoClass;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusBadge(
                label: '모집 중',
                color: AppColors.wine,
                backgroundColor: AppColors.butter,
              ),
              const Spacer(),
              Text(
                demoClass.priceText,
                style: const TextStyle(
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            demoClass.subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            demoClass.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          _DetailLine(
            icon: Icons.schedule,
            text: '${demoClass.dateText}  ${demoClass.timeText}',
          ),
          _DetailLine(icon: Icons.place, text: demoClass.place),
          _DetailLine(icon: Icons.auto_awesome, text: 'AI 케미 분석 + 베이킹 + 대화'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in demoClass.tags) StatusBadge(label: tag),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.favorite),
              label: const Text('신청하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPreview extends StatelessWidget {
  const _StatusPreview({required this.flowStep});

  final DemoFlowStep flowStep;

  @override
  Widget build(BuildContext context) {
    final progress = AppScope.of(context).flowProvider.progress;

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
                color: AppColors.ivory.withValues(alpha: 0.78),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline, color: AppColors.burgundy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '현재 신청 현황',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    StatusBadge(label: flowStep.label),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.7),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.burgundy,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  flowStep.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthPreview extends StatefulWidget {
  _MonthPreview({required this.classes, required this.onApply})
    : assert(classes.isNotEmpty);

  final List<ChemistryClass> classes;
  final ValueChanged<ChemistryClass> onApply;

  @override
  State<_MonthPreview> createState() => _MonthPreviewState();
}

class _MonthPreviewState extends State<_MonthPreview> {
  late ChemistryClass _selectedClass;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _selectedClass = _initialClass(widget.classes);
    _visibleMonth = _monthOf(_selectedClass);
  }

  @override
  void didUpdateWidget(covariant _MonthPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedStillExists = widget.classes.any(
      (demoClass) => demoClass.id == _selectedClass.id,
    );
    if (!selectedStillExists) {
      _selectedClass = _initialClass(widget.classes);
      _visibleMonth = _monthOf(_selectedClass);
      return;
    }
    _selectedClass = widget.classes.firstWhere(
      (demoClass) => demoClass.id == _selectedClass.id,
    );
  }

  ChemistryClass _initialClass(List<ChemistryClass> classes) {
    return classes.firstWhere(
      (demoClass) => demoClass.isOpen,
      orElse: () => classes.first,
    );
  }

  List<DateTime> get _eventMonths {
    final uniqueMonths = <String, DateTime>{};
    for (final demoClass in widget.classes) {
      final month = _monthOf(demoClass);
      uniqueMonths['${month.year}-${month.month}'] = month;
    }
    return uniqueMonths.values.toList()..sort((a, b) => a.compareTo(b));
  }

  List<ChemistryClass> _classesInMonth(DateTime month) {
    return widget.classes
        .where((demoClass) => _isSameMonth(_monthOf(demoClass), month))
        .toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  int _visibleMonthIndex(List<DateTime> months) {
    return months.indexWhere((month) => _isSameMonth(month, _visibleMonth));
  }

  void _changeMonth(int delta) {
    final months = _eventMonths;
    final currentIndex = _visibleMonthIndex(months);
    if (currentIndex == -1) {
      return;
    }

    final nextIndex = (currentIndex + delta)
        .clamp(0, months.length - 1)
        .toInt();
    final nextMonth = months[nextIndex];
    final nextMonthClasses = _classesInMonth(nextMonth);
    setState(() {
      _visibleMonth = nextMonth;
      if (!nextMonthClasses.any(
        (demoClass) => demoClass.id == _selectedClass.id,
      )) {
        _selectedClass = nextMonthClasses.first;
      }
    });
  }

  void _selectClass(ChemistryClass demoClass) {
    setState(() {
      _selectedClass = demoClass;
      _visibleMonth = _monthOf(demoClass);
    });
  }

  void _selectDay(int day) {
    final dayClasses = _classesInMonth(
      _visibleMonth,
    ).where((demoClass) => demoClass.eventDay == day).toList();
    if (dayClasses.isEmpty) {
      return;
    }
    _selectClass(dayClasses.first);
  }

  @override
  Widget build(BuildContext context) {
    final months = _eventMonths;
    final monthIndex = _visibleMonthIndex(months);
    final visibleClasses = _classesInMonth(_visibleMonth);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final calendar = _ClassCalendar(
          classes: visibleClasses,
          selectedClass: _selectedClass,
          visibleMonth: _visibleMonth,
          onPrevious: monthIndex > 0 ? () => _changeMonth(-1) : null,
          onNext: monthIndex < months.length - 1 ? () => _changeMonth(1) : null,
          onDaySelected: _selectDay,
        );
        final panel = _MonthClassPanel(
          selectedClass: _selectedClass,
          monthClasses: visibleClasses,
          onSelect: _selectClass,
          onApply: widget.onApply,
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 330, child: calendar),
              const SizedBox(width: 14),
              Expanded(child: panel),
            ],
          );
        }

        return Column(children: [calendar, const SizedBox(height: 12), panel]);
      },
    );
  }
}

class _ClassCalendar extends StatelessWidget {
  const _ClassCalendar({
    required this.classes,
    required this.selectedClass,
    required this.visibleMonth,
    required this.onDaySelected,
    this.onPrevious,
    this.onNext,
  });

  final List<ChemistryClass> classes;
  final ChemistryClass selectedClass;
  final DateTime visibleMonth;
  final ValueChanged<int> onDaySelected;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final cells = _calendarCells(visibleMonth);
    final rowCount = cells.length ~/ 7;
    final classesByDay = <int, List<ChemistryClass>>{};
    for (final demoClass in classes) {
      classesByDay.putIfAbsent(demoClass.eventDay, () => []).add(demoClass);
    }

    return AppCard(
      color: AppColors.ivory,
      borderColor: AppColors.butter,
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 46,
            child: Icon(
              Icons.favorite,
              size: 18,
              color: AppColors.rose.withValues(alpha: 0.72),
            ),
          ),
          Positioned(
            top: 70,
            left: 10,
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: AppColors.caramel.withValues(alpha: 0.52),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 18,
            child: Icon(
              Icons.auto_awesome,
              size: 14,
              color: AppColors.caramel.withValues(alpha: 0.55),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: '이전 달',
                  ),
                  Expanded(
                    child: Text(
                      '${visibleMonth.month}월 ${visibleMonth.year}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: onNext,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: '다음 달',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _CalendarWeekHeader(),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.cream.withValues(alpha: 0.86),
                    border: Border.all(
                      color: AppColors.caramel.withValues(alpha: 0.54),
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 7 / rowCount,
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                          ),
                      itemCount: cells.length,
                      itemBuilder: (context, index) {
                        final day = cells[index];
                        final dayClasses = day == null
                            ? const <ChemistryClass>[]
                            : classesByDay[day] ?? const <ChemistryClass>[];
                        return _CalendarDayCell(
                          day: day,
                          classes: dayClasses,
                          selected: dayClasses.any(
                            (demoClass) => demoClass.id == selectedClass.id,
                          ),
                          onTap: dayClasses.isEmpty || day == null
                              ? null
                              : () => onDaySelected(day),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarWeekHeader extends StatelessWidget {
  const _CalendarWeekHeader();

  @override
  Widget build(BuildContext context) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return Row(
      children: [
        for (final weekday in weekdays)
          Expanded(
            child: Text(
              weekday,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.wine,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.classes,
    required this.selected,
    required this.onTap,
  });

  final int? day;
  final List<ChemistryClass> classes;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasClass = classes.isNotEmpty;
    final hasOpenClass = classes.any((demoClass) => demoClass.isOpen);
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: selected
          ? Colors.white
          : day == null
          ? Colors.transparent
          : AppColors.wine,
      fontWeight: FontWeight.w900,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: AppColors.caramel.withValues(alpha: 0.42),
              ),
              bottom: BorderSide(
                color: AppColors.caramel.withValues(alpha: 0.42),
              ),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (hasClass && !selected)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(
                    hasOpenClass ? Icons.favorite : Icons.lock_clock,
                    size: 12,
                    color: hasOpenClass
                        ? AppColors.caramel
                        : AppColors.mutedText.withValues(alpha: 0.58),
                  ),
                ),
              if (selected)
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD94D43),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.wine.withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              Text(day?.toString() ?? '', style: textStyle),
              if (hasClass && classes.length > 1)
                Positioned(
                  bottom: 5,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : AppColors.burgundy,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthClassPanel extends StatelessWidget {
  const _MonthClassPanel({
    required this.selectedClass,
    required this.monthClasses,
    required this.onSelect,
    required this.onApply,
  });

  final ChemistryClass selectedClass;
  final List<ChemistryClass> monthClasses;
  final ValueChanged<ChemistryClass> onSelect;
  final ValueChanged<ChemistryClass> onApply;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey(selectedClass.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const StatusBadge(
                      label: '선택 회차',
                      color: AppColors.wine,
                      backgroundColor: AppColors.butter,
                    ),
                    const Spacer(),
                    StatusBadge(
                      label: selectedClass.statusLabel,
                      color: selectedClass.isOpen
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  selectedClass.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  selectedClass.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                _DetailLine(
                  icon: Icons.calendar_month,
                  text: '${selectedClass.dateText}  ${selectedClass.timeText}',
                ),
                _DetailLine(icon: Icons.place, text: selectedClass.place),
                _DetailLine(
                  icon: Icons.group,
                  text: selectedClass.capacityLabel,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in selectedClass.tags)
                      StatusBadge(label: tag),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: selectedClass.isOpen
                        ? () => onApply(selectedClass)
                        : null,
                    icon: Icon(
                      selectedClass.isOpen
                          ? Icons.favorite
                          : Icons.notifications_none,
                    ),
                    label: Text(
                      selectedClass.isOpen ? '이 회차 신청하기' : '오픈 알림 대기',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('이 달의 회차', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final demoClass in monthClasses) ...[
            _ClassPreviewCard(
              demoClass: demoClass,
              selected: demoClass.id == selectedClass.id,
              onTap: () => onSelect(demoClass),
            ),
            if (demoClass != monthClasses.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ClassPreviewCard extends StatelessWidget {
  const _ClassPreviewCard({
    required this.demoClass,
    required this.selected,
    required this.onTap,
  });

  final ChemistryClass demoClass;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.butter.withValues(alpha: 0.7)
          : AppColors.cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? AppColors.burgundy : AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: demoClass.isOpen ? AppColors.butter : AppColors.line,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  selected
                      ? Icons.calendar_month
                      : demoClass.isOpen
                      ? Icons.local_dining
                      : Icons.lock_clock,
                  color: AppColors.wine,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      demoClass.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${demoClass.dateText} · ${demoClass.capacityLabel}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.chevron_right,
                color: selected ? AppColors.success : AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

DateTime _monthOf(ChemistryClass demoClass) {
  return DateTime(demoClass.eventYear, demoClass.eventMonth);
}

bool _isSameMonth(DateTime left, DateTime right) {
  return left.year == right.year && left.month == right.month;
}

List<int?> _calendarCells(DateTime month) {
  final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
  final firstWeekdayOffset = DateTime(month.year, month.month).weekday % 7;
  final cellCount = ((firstWeekdayOffset + daysInMonth + 6) ~/ 7) * 7;

  return List<int?>.generate(cellCount, (index) {
    final day = index - firstWeekdayOffset + 1;
    if (day < 1 || day > daysInMonth) {
      return null;
    }
    return day;
  });
}

class _RecipeGrid extends StatelessWidget {
  const _RecipeGrid();

  @override
  Widget build(BuildContext context) {
    const recipes = [
      ('신청', Icons.edit_note, '정보 입력과 인증 대기'),
      ('선정', Icons.auto_awesome, 'AI 선정 결과 확인'),
      ('당일', Icons.chair_alt, '닉네임과 선택 제출'),
      ('리포트', Icons.description, '매칭 결과와 후기 설문'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.28,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final recipe in recipes)
          AppCard(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(recipe.$2, color: AppColors.burgundy),
                const Spacer(),
                Text(recipe.$1, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(recipe.$3, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: AppColors.burgundy, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
