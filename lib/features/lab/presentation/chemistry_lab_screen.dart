import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/demo_models.dart';
import '../../../shared/providers/app_scope.dart';

class ChemistryLabScreen extends StatelessWidget {
  const ChemistryLabScreen({required this.onStartOnboarding, super.key});

  final VoidCallback onStartOnboarding;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final characters = appState.repository.fetchCharacters();
    final reports = appState.repository.fetchReports();

    // 온보딩으로 추천된 내 기본 캐릭터를 우선 표시 (없으면 데모 featured)
    final baseCharacterId =
        appState.currentUserController.profile?.baseCharacterId;
    final featured = baseCharacterId == null
        ? appState.repository.fetchFeaturedCharacter()
        : characters.firstWhere(
            (character) => character.id == baseCharacterId,
            orElse: appState.repository.fetchFeaturedCharacter,
          );

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
                      '케미Lab',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.chocolate,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI가 나의 성향과 케미 포인트를 분석해요.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    _LabHero(character: featured),
                    const SizedBox(height: 26),
                    const _SectionLabel('둘러보기'),
                    const SizedBox(height: 10),
                    _LabMenuGrid(
                      onStartOnboarding: onStartOnboarding,
                      onOpenCharacter: () => _openCharacterDetail(
                        context,
                        featured,
                        onStartOnboarding,
                      ),
                      onOpenBook: () => _openCharacterBook(
                        context,
                        characters,
                        onStartOnboarding,
                      ),
                      onOpenCriteria: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const _SelectionCriteriaScreen(),
                        ),
                      ),
                      onOpenNickname: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const _NicknameInfoScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const _SectionLabel('최근 리포트'),
                    const SizedBox(height: 10),
                    _RecentReportTile(report: reports.first),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCharacterBook(
    BuildContext context,
    List<ChemistryCharacter> characters,
    VoidCallback onStartOnboarding,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CharacterBookScreen(
          characters: characters,
          onStartOnboarding: onStartOnboarding,
        ),
      ),
    );
  }

  void _openCharacterDetail(
    BuildContext context,
    ChemistryCharacter character,
    VoidCallback onStartOnboarding,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CharacterDetailScreen(
          character: character,
          onStartOnboarding: onStartOnboarding,
        ),
      ),
    );
  }
}

class _LabHero extends StatelessWidget {
  const _LabHero({required this.character});

  final ChemistryCharacter character;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.butter.withValues(alpha: 0.52),
      borderColor: AppColors.line,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned(
            top: -22,
            right: -12,
            child: _RingMark(size: 112, color: AppColors.gold),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR CHEMISTRY',
                  style: TextStyle(
                    color: AppColors.burgundy,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  character.name,
                  style: const TextStyle(
                    color: AppColors.burgundy,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 282),
                  child: Text(
                    character.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.cocoa,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in character.tags)
                      _MiniChip(label: tag, filled: false),
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

class _LabMenuGrid extends StatelessWidget {
  const _LabMenuGrid({
    required this.onStartOnboarding,
    required this.onOpenCharacter,
    required this.onOpenBook,
    required this.onOpenCriteria,
    required this.onOpenNickname,
  });

  final VoidCallback onStartOnboarding;
  final VoidCallback onOpenCharacter;
  final VoidCallback onOpenBook;
  final VoidCallback onOpenCriteria;
  final VoidCallback onOpenNickname;

  @override
  Widget build(BuildContext context) {
    final items = [
      _LabMenuItem(
        icon: Icons.auto_awesome_rounded,
        title: '내 성향 분석',
        subtitle: '5분 케미 진단',
        active: true,
        onTap: onStartOnboarding,
      ),
      _LabMenuItem(
        icon: Icons.person_outline_rounded,
        title: '내 캐릭터',
        subtitle: '내 케미 캐릭터 정보',
        onTap: onOpenCharacter,
      ),
      _LabMenuItem(
        icon: Icons.icecream_outlined,
        title: '캐릭터 도감',
        subtitle: '20종 케미 캐릭터',
        onTap: onOpenBook,
      ),
      _LabMenuItem(
        icon: Icons.favorite_border_rounded,
        title: 'AI 케미 분석',
        subtitle: '나와 잘 맞는 케미',
        onTap: onStartOnboarding,
      ),
      _LabMenuItem(
        icon: Icons.filter_alt_outlined,
        title: '선정 기준',
        subtitle: '회차 인원이 선정되는 방식',
        onTap: onOpenCriteria,
      ),
      _LabMenuItem(
        icon: Icons.science_outlined,
        title: '닉네임 설명',
        subtitle: '오브닝 닉네임 시스템',
        onTap: onOpenNickname,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.12,
      ),
      itemBuilder: (context, index) => _LabMenuCard(item: items[index]),
    );
  }
}

class _LabMenuItem {
  const _LabMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool active;
}

class _LabMenuCard extends StatelessWidget {
  const _LabMenuCard({required this.item});

  final _LabMenuItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.active ? AppColors.burgundy : Colors.white;
    final titleColor = item.active ? Colors.white : AppColors.cocoa;
    final subtitleColor = item.active ? AppColors.butter : AppColors.mutedText;
    final iconColor = item.active ? AppColors.butter : AppColors.brandRed;

    return AppCard(
      onTap: item.onTap,
      color: color,
      borderColor: item.active ? AppColors.burgundy : AppColors.line,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: iconColor, size: 20),
          const Spacer(),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: titleColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: subtitleColor, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RecentReportTile extends StatelessWidget {
  const _RecentReportTile({required this.report});

  final ChemistryReport report;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7기 케미 리포트',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 4),
                Text(
                  report.summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.cocoa,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '2026. 5. 24',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.article_outlined, color: AppColors.brandRed),
        ],
      ),
    );
  }
}

class _CharacterBookScreen extends StatefulWidget {
  const _CharacterBookScreen({
    required this.characters,
    required this.onStartOnboarding,
  });

  final List<ChemistryCharacter> characters;
  final VoidCallback onStartOnboarding;

  @override
  State<_CharacterBookScreen> createState() => _CharacterBookScreenState();
}

class _CharacterBookScreenState extends State<_CharacterBookScreen> {
  String _filter = '전체';

  @override
  Widget build(BuildContext context) {
    final characters = _filteredCharacters;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _BookTopBar(),
                      const SizedBox(height: 18),
                      Text(
                        '케미 캐릭터 20',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.burgundy,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'AI가 디저트의 결을 빌려, 사람의 결을 표현해요.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      _BookFilters(
                        selected: _filter,
                        onChanged: (value) => setState(() => _filter = value),
                      ),
                      const SizedBox(height: 18),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: characters.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.03,
                            ),
                        itemBuilder: (context, index) {
                          final character = characters[index];
                          return _BookCharacterCard(
                            character: character,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => _CharacterDetailScreen(
                                  character: character,
                                  onStartOnboarding: widget.onStartOnboarding,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ChemistryCharacter> get _filteredCharacters {
    final sorted = widget.characters.toList()
      ..sort((a, b) {
        if (a.forMen != b.forMen) {
          return a.forMen ? -1 : 1;
        }
        if (a.id == 'tiramisu') {
          return 1;
        }
        if (b.id == 'tiramisu') {
          return -1;
        }
        return 0;
      });

    switch (_filter) {
      case '남성':
        return sorted.where((character) => character.forMen).toList();
      case '여성':
        return sorted.where((character) => !character.forMen).toList();
      case '잘 맞는':
        return sorted
            .where(
              (character) => const {
                'croissant',
                'salt-bread',
                'canele',
                'madeleine',
              }.contains(character.id),
            )
            .toList();
      case '전체':
      default:
        return sorted;
    }
  }
}

class _BookTopBar extends StatelessWidget {
  const _BookTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SmallIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Text(
            '캐릭터 도감',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.chocolate,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _SmallIconButton(icon: Icons.search_rounded, onTap: () {}),
      ],
    );
  }
}

class _BookFilters extends StatelessWidget {
  const _BookFilters({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = ['전체', '남성', '여성', '잘 맞는'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in filters)
          _FilterChipButton(
            label: filter,
            selected: selected == filter,
            onTap: () => onChanged(filter),
          ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.burgundy : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.cocoa,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookCharacterCard extends StatelessWidget {
  const _BookCharacterCard({required this.character, required this.onTap});

  final ChemistryCharacter character;
  final VoidCallback onTap;

  bool get _isMine => character.id == 'tiramisu';

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  character.initial,
                  style: const TextStyle(
                    color: AppColors.brandRed,
                    fontSize: 21,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (_isMine)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.butter,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'MY',
                    style: TextStyle(
                      color: AppColors.burgundy,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            character.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.cocoa,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            character.summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterDetailScreen extends StatelessWidget {
  const _CharacterDetailScreen({
    required this.character,
    required this.onStartOnboarding,
  });

  final ChemistryCharacter character;
  final VoidCallback onStartOnboarding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('도감 둘러보기'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onStartOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('다시 분석하기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailTopBar(title: '내 캐릭터'),
                      const SizedBox(height: 16),
                      _DetailHero(character: character),
                      const SizedBox(height: 24),
                      const _SectionLabel('성향 키워드'),
                      const SizedBox(height: 10),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniChip(label: '감성적'),
                          _MiniChip(label: '진중함'),
                          _MiniChip(label: '따뜻함'),
                          _MiniChip(label: '조용한 깊이'),
                          _MiniChip(label: '은은한 유머'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('주로 나오는 MBTI'),
                      const SizedBox(height: 10),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MbtiBadge(label: 'INFJ'),
                          _MbtiBadge(label: 'INFP'),
                          _MbtiBadge(label: 'ENFJ'),
                          _MbtiBadge(label: 'ISFJ'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('이런 캐릭터를 닮았어요'),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Expanded(
                            child: _LookalikeCard(
                              initial: '하',
                              name: '하울',
                              work: '하울의 움직이는 성',
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _LookalikeCard(
                              initial: '아',
                              name: '아앙',
                              work: '아바타 아앙의 전설',
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _LookalikeCard(
                              initial: '하',
                              name: '하쿠',
                              work: '센과 치히로',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('잘맞는 대화 스타일'),
                      const SizedBox(height: 10),
                      const _TextPanel(
                        text:
                            '가벼운 농담보다, 한 가지 주제로 깊이 들어가는 대화에서 빛납니다. 상대의 작은 표현에도 의미를 발견하는 편이에요.',
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('잘맞는 케미 캐릭터'),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Expanded(
                            child: _MatchCharacterCard(
                              initial: '크',
                              name: '크루아상',
                              summary: '겹겹속 신사',
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _MatchCharacterCard(
                              initial: '소',
                              name: '소금빵',
                              summary: '담백한 다정',
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _MatchCharacterCard(
                              initial: '까',
                              name: '까눌레',
                              summary: '깊은 향의 사람',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('주의하면 좋은 포인트'),
                      const SizedBox(height: 10),
                      const _TextPanel(
                        text:
                            '서두르지 않는 편이라, 처음엔 거리감이 있어 보일 수 있어요. 상대의 반응을 살피기보다 먼저 한 발 다가가는 시도가 도움이 됩니다.',
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('디자인 무드'),
                      const SizedBox(height: 10),
                      const _DesignMoodPanel(
                        swatch: AppColors.brandRed,
                        text: '버터 브라운 + 크림색 / 여러 겹의 레이어 / 부드러운 곡선형 카드',
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SmallIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.chocolate,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _SmallIconButton(icon: Icons.auto_awesome_rounded, onTap: () {}),
      ],
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({required this.icon, required this.onTap});

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
          child: Icon(icon, size: 18, color: AppColors.cocoa),
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.character});

  final ChemistryCharacter character;

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
            right: -18,
            child: _RingMark(size: 124, color: AppColors.butter),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR CHEMISTRY',
                  style: TextStyle(
                    color: AppColors.butter,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.butter.withValues(alpha: 0.36),
                        ),
                      ),
                      child: Text(
                        character.initial,
                        style: const TextStyle(
                          color: AppColors.butter,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            character.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${character.englishName} · ${character.forMen ? '남성' : '여성'} 캐릭터',
                            style: const TextStyle(
                              color: AppColors.butter,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  character.description,
                  style: const TextStyle(
                    color: Color(0xFFFFE9DE),
                    fontSize: 13,
                    height: 1.55,
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

class _TextPanel extends StatelessWidget {
  const _TextPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.cocoa, height: 1.65),
      ),
    );
  }
}

class _MatchCharacterCard extends StatelessWidget {
  const _MatchCharacterCard({
    required this.initial,
    required this.name,
    required this.summary,
  });

  final String initial;
  final String name;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.cocoa,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _MbtiBadge extends StatelessWidget {
  const _MbtiBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.wine,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LookalikeCard extends StatelessWidget {
  const _LookalikeCard({
    required this.initial,
    required this.name,
    required this.work,
  });

  final String initial;
  final String name;
  final String work;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.burgundy,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.cocoa,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            work,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _DesignMoodPanel extends StatelessWidget {
  const _DesignMoodPanel({required this.swatch, required this.text});

  final Color swatch;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.parchment,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: swatch,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.cocoa,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: filled ? AppColors.burgundy : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : AppColors.cocoa,
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
      ..color = color.withValues(alpha: 0.28);
    canvas.drawCircle(center, size.width * 0.48, paint);
    canvas.drawCircle(center, size.width * 0.32, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _InfoStepRow extends StatelessWidget {
  const _InfoStepRow({
    required this.icon,
    required this.title,
    required this.desc,
    this.topBorder = true,
  });

  final IconData icon;
  final String title;
  final String desc;
  final bool topBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: topBorder
            ? const Border(top: BorderSide(color: AppColors.line))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.ivory,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(icon, size: 18, color: AppColors.burgundy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cocoa,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.5,
                    fontSize: 12,
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

class _LabInfoHeadline extends StatelessWidget {
  const _LabInfoHeadline({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.burgundy,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.wine,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _NicknameInfoScreen extends StatelessWidget {
  const _NicknameInfoScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _DetailTopBar(title: '닉네임 설명'),
                      const SizedBox(height: 16),
                      const _LabInfoHeadline(
                        eyebrow: 'NICKNAME SYSTEM',
                        title: '오브닝에서는\n디저트 이름으로 만나요.',
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '회차 안에서는 실명 대신 디저트 캐릭터 닉네임으로 서로를 불러요. '
                        '외모나 직업 같은 정보보다, 대화와 케미 그 자체에 집중할 수 있게요.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.cocoa,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        color: AppColors.wine,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '나의 회차 닉네임',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.gold.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'T',
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '티라미수',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '내 기본 케미 캐릭터에서 배정돼요',
                                      style: TextStyle(
                                        color: AppColors.gold.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('닉네임은 이렇게 정해져요'),
                      const SizedBox(height: 4),
                      const _InfoStepRow(
                        icon: Icons.auto_awesome_outlined,
                        title: '기본 캐릭터에서 출발',
                        desc: '케미 분석으로 받은 내 기본 캐릭터(예: 티라미수)가 회차 닉네임의 기준이 돼요.',
                        topBorder: false,
                      ),
                      const _InfoStepRow(
                        icon: Icons.lock_outline_rounded,
                        title: '회차마다 중복 없이',
                        desc: '같은 회차에 같은 닉네임이 겹치지 않도록 운영진이 확정해요. 다른 회차에선 닉네임이 바뀔 수 있어요.',
                      ),
                      const _InfoStepRow(
                        icon: Icons.person_outline_rounded,
                        title: '실명은 매칭 후에만',
                        desc: '이름과 연락처는 최종 쌍방 매칭된 분에게만 공개돼요.',
                      ),
                      const SizedBox(height: 16),
                      const _TextPanel(
                        text:
                            '남성은 빵·구움과자 계열, 여성은 디저트 계열에서 닉네임을 받아요. '
                            '도감에서 20종 캐릭터를 모두 볼 수 있어요.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCriteriaScreen extends StatelessWidget {
  const _SelectionCriteriaScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _DetailTopBar(title: '선정 기준'),
                      const SizedBox(height: 16),
                      const _LabInfoHeadline(
                        eyebrow: 'SELECTION',
                        title: '회차 인원은\n케미 점수로 선정돼요.',
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'AI가 모든 신청자의 케미 점수를 계산하고, 운영진이 성비와 균형을 고려해 '
                        '최종 회차 인원을 확정해요.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.cocoa,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        color: AppColors.wine,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '케미 점수 공식',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const [
                                Expanded(
                                  child: _ScoreFormulaBox(
                                    top: 'STRICT',
                                    mid: '조건 · 선호 충족',
                                    sub: '100점 만점',
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  child: Center(
                                    child: Text(
                                      '+',
                                      style: TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _ScoreFormulaBox(
                                    top: 'PSYCHOLOGY',
                                    mid: '심리 · 과학 케미',
                                    sub: '100점 만점',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '= 최종 매칭 시너지',
                                    style: TextStyle(
                                      color: AppColors.gold.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '케미 점수',
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('이렇게 선정해요'),
                      const SizedBox(height: 4),
                      const _InfoStepRow(
                        icon: Icons.shield_outlined,
                        title: '꼭 맞아야 하는 조건부터',
                        desc: '나이 · 흡연 · 주량 · 기피 직군처럼 꼭 맞아야 하는 조건이 어긋나는 쌍은 매칭에서 제외돼요.',
                        topBorder: false,
                      ),
                      const _InfoStepRow(
                        icon: Icons.auto_awesome_outlined,
                        title: '성향 케미 분석',
                        desc: 'MBTI 궁합 · 가치관 · 취향 · 가까워지는 순간을 AI가 분석해 잘 맞는 정도를 계산해요.',
                      ),
                      const _InfoStepRow(
                        icon: Icons.event_seat_outlined,
                        title: '테이블 구성',
                        desc: '케미가 좋은 4명(남2 · 여2)씩 한 테이블이 되도록 구성하고, 운영진이 최종 확정해요.',
                      ),
                      const SizedBox(height: 16),
                      const _TextPanel(
                        text:
                            '외모 · 재산 · 학벌은 보지 않아요. 점수는 운영 참고용으로만 쓰이고 상대에게 공개되지 않아요.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreFormulaBox extends StatelessWidget {
  const _ScoreFormulaBox({
    required this.top,
    required this.mid,
    required this.sub,
  });

  final String top;
  final String mid;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            top,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$mid\n$sub',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
