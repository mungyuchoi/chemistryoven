import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/demo_models.dart';
import '../../../shared/providers/app_scope.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onOpenSchedule,
    required this.onOpenLab,
    required this.onApplyClass,
    super.key,
  });

  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenLab;
  final ValueChanged<ChemistryClass> onApplyClass;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    // Firestore 실데이터만 표시 (데모 폴백 없음)
    final realSessions = appState.sessionsController.sessions
        .map((session) => session.toDisplayClass())
        .toList();
    final ChemistryClass? featuredClass = realSessions.isNotEmpty
        ? realSessions.first
        : null;
    final classes = realSessions;
    final character = appState.repository.fetchFeaturedCharacter();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _HomeHeader(),
                      const SizedBox(height: 12),
                      const _HomeHeroImage(),
                      const SizedBox(height: 22),
                      const _HomeSlogan(),
                      const SizedBox(height: 38),
                      if (featuredClass != null)
                        _FeaturedApplicationCard(
                          demoClass: featuredClass,
                          onApply: () => onApplyClass(featuredClass),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(
                            '아직 열린 회차가 없어요. 곧 새로운 회차가 열릴 거예요.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ),
                      const SizedBox(height: 22),
                      Text(
                        '케미스트리오븐은 이렇게 진행돼요',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.chocolate,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const _ProcessStrip(),
                      const SizedBox(height: 30),
                      SectionTitle(
                        title: '추천 회차',
                        subtitle: '캘린더에서 참여 가능한 회차를 확인해보세요.',
                        trailing: TextButton(
                          onPressed: onOpenSchedule,
                          child: const Text('전체 보기'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (classes.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            '아직 추천할 회차가 없어요.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        )
                      else
                        for (final demoClass in classes.take(2)) ...[
                          _ClassPreviewCard(
                            demoClass: demoClass,
                            onApply: () => onApplyClass(demoClass),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 14),
                      _LabTeaser(character: character, onOpenLab: onOpenLab),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.blush,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.line),
          ),
          child: const Icon(
            Icons.home_outlined,
            size: 13,
            color: AppColors.brandRed,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Chemistry Oven',
            style: TextStyle(
              color: AppColors.burgundy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.notifications_none),
          tooltip: '알림',
        ),
        IconButton(
          onPressed: () {},
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.search),
          tooltip: '검색',
        ),
      ],
    );
  }
}

class _HomeHeroImage extends StatelessWidget {
  const _HomeHeroImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.parchment.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: AspectRatio(
          aspectRatio: 1.64,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.ivory),
            child: Image.asset(
              AppAssets.chemistryFlowBackground,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSlogan extends StatelessWidget {
  const _HomeSlogan();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '디저트보다 더 달콤한 순간.',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 25,
            height: 1.18,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          '사람과 사람이 만날 때 피어나는 케미. AI가 연결하고, 베이킹이 가깝게 만듭니다.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.cocoa,
            fontSize: 10,
            height: 1.55,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _FeaturedApplicationCard extends StatelessWidget {
  const _FeaturedApplicationCard({
    required this.demoClass,
    required this.onApply,
  });

  final ChemistryClass demoClass;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            color: AppColors.burgundy.withValues(alpha: 0.82),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TinyBadge(
                      label: '신청가능',
                      color: AppColors.success,
                      backgroundColor: Color(0xFFE9F6E8),
                    ),
                    _TinyBadge(
                      label: 'D-12',
                      color: Colors.white,
                      backgroundColor: Color(0x33FFFFFF),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  demoClass.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  demoClass.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ClassInfoLine(
                        icon: Icons.calendar_month_outlined,
                        text: '6월 14일 (토)',
                      ),
                    ),
                    Expanded(
                      child: _ClassInfoLine(
                        icon: Icons.schedule,
                        text: demoClass.timeText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: _ClassInfoLine(
                        icon: Icons.place_outlined,
                        text: demoClass.place,
                      ),
                    ),
                    Expanded(
                      child: _ClassInfoLine(
                        icon: Icons.confirmation_number_outlined,
                        text: demoClass.priceText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onApply,
                    child: const Text('8기 신청하기'),
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

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ClassInfoLine extends StatelessWidget {
  const _ClassInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.burgundy),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cocoa,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProcessStep {
  const _ProcessStep(this.n, this.title, this.desc, this.long);

  final String n;
  final String title;
  final String desc;
  final String long;
}

const _processSteps = [
  _ProcessStep(
    '01',
    '신청',
    '간단한 성향 질문',
    '카카오톡 인증 후, 취향·생활 리듬·선호 조건을 카드와 슬라이더로 가볍게 골라요. '
        '프로필 사진과 직업 인증을 함께 제출하면 신청이 완성돼요.',
  ),
  _ProcessStep(
    '02',
    'AI 케미 분석',
    '캐릭터 추천',
    'AI가 입력한 취향을 분석해 20종의 디저트 케미 캐릭터 중 나와 가장 가까운 캐릭터를 찾아드려요. '
        '잘 맞는 상대 유형도 함께 알려드려요.',
  ),
  _ProcessStep(
    '03',
    '선정',
    '회차 인원 확정',
    '운영진이 케미 점수와 성비 균형을 고려해 회차 인원을 직접 선정해요. '
        '사진·직업 인증이 확인된 분만 선정되고, 입금이 확인되면 최종 확정돼요.',
  ),
  _ProcessStep(
    '04',
    '오브닝 참여',
    '베이킹 & 대화',
    '회차 당일, 첫인상 선택 → 로테이션 대화 → 중간 선택 → 페어 베이킹 → 최종 선택 순으로 진행돼요. '
        '회차 내에서는 캐릭터 닉네임으로 만나요.',
  ),
  _ProcessStep(
    '05',
    '매칭 결과',
    '케미 리포트',
    '쌍방으로 선택하면 이름과 연락처가 공개돼요. 회차가 끝나면 AI가 그날의 선택과 베이킹 자리를 분석한 '
        '개인 케미 리포트를 보내드려요.',
  ),
];

class _ProcessStrip extends StatefulWidget {
  const _ProcessStrip();

  @override
  State<_ProcessStrip> createState() => _ProcessStripState();
}

class _ProcessStripState extends State<_ProcessStrip> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final cur = _processSteps[_selected];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 18),
            itemCount: _processSteps.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = _processSteps[index];
              final on = index == _selected;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selected = index),
                child: SizedBox(
                  width: 110,
                  child: AppCard(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                    color: on
                        ? AppColors.burgundy
                        : Colors.white.withValues(alpha: 0.82),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.n,
                          style: TextStyle(
                            color: on ? AppColors.gold : AppColors.burgundy,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: on ? Colors.white : AppColors.chocolate,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: on
                                ? Colors.white.withValues(alpha: 0.74)
                                : AppColors.mutedText,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          color: AppColors.ivory,
          padding: const EdgeInsets.all(16),
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
                      color: AppColors.burgundy,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'STEP ${cur.n}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cur.title,
                    style: const TextStyle(
                      color: AppColors.cocoa,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                cur.long,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                  height: 1.65,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClassPreviewCard extends StatelessWidget {
  const _ClassPreviewCard({required this.demoClass, required this.onApply});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.blush,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${demoClass.eventDay}',
                  style: const TextStyle(
                    color: AppColors.brandRed,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            demoClass.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusBadge(
                          label: demoClass.statusLabel,
                          color: demoClass.isOpen
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${demoClass.dateText} · ${demoClass.place}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${demoClass.applicationCount}명 신청 · ${demoClass.capacityLabel}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: demoClass.isOpen ? onApply : null,
                          child: Text(demoClass.isOpen ? '신청' : '대기'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabTeaser extends StatelessWidget {
  const _LabTeaser({required this.character, required this.onOpenLab});

  final ChemistryCharacter character;
  final VoidCallback onOpenLab;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.wine,
      borderColor: AppColors.wine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 케미Lab',
            style: TextStyle(
              color: AppColors.butter,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  character.initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      character.description,
                      style: const TextStyle(
                        color: Color(0xFFFFE7DA),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenLab,
              icon: const Icon(Icons.science_outlined),
              label: const Text('케미Lab 둘러보기'),
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
