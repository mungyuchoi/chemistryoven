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
                  onTap: (demoClass) => demoClass.isOpen
                      ? () => flow.applyForClass(demoClass.id)
                      : null,
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
        child: Image.asset(AppAssets.chemistrySloganWood, fit: BoxFit.cover),
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

class _MonthPreview extends StatelessWidget {
  const _MonthPreview({required this.classes, required this.onTap});

  final List<ChemistryClass> classes;
  final VoidCallback? Function(ChemistryClass demoClass) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final calendar = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            AppAssets.chemistryCalendarPreview,
            fit: BoxFit.cover,
            height: wide ? 180 : 150,
            width: wide ? 170 : double.infinity,
          ),
        );
        final list = Column(
          children: [
            for (final demoClass in classes) ...[
              _ClassPreviewCard(demoClass: demoClass, onTap: onTap(demoClass)),
              if (demoClass != classes.last) const SizedBox(height: 10),
            ],
          ],
        );

        return AppCard(
          color: Colors.white,
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    calendar,
                    const SizedBox(width: 14),
                    Expanded(child: list),
                  ],
                )
              : Column(children: [calendar, const SizedBox(height: 14), list]),
        );
      },
    );
  }
}

class _ClassPreviewCard extends StatelessWidget {
  const _ClassPreviewCard({required this.demoClass, required this.onTap});

  final ChemistryClass demoClass;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: demoClass.isOpen ? AppColors.butter : AppColors.line,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  demoClass.isOpen ? Icons.local_dining : Icons.lock_clock,
                  color: AppColors.wine,
                ),
              ),
              const SizedBox(width: 12),
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
              StatusBadge(
                label: demoClass.statusLabel,
                color: demoClass.isOpen ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
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
