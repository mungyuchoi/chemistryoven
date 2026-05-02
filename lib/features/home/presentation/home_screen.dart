import 'package:flutter/material.dart';

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
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.burgundy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bakery_dining,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '케미스트리오븐',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '디저트처럼 자연스럽게 익어가는 만남',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(label: mode.label),
                  ],
                ),
                const SizedBox(height: 18),
                _HeroPanel(
                  demoClass: featuredClass,
                  onApply: () => flow.applyForClass(featuredClass.id),
                ),
                const SizedBox(height: 18),
                _FlowCard(flowStep: flow.currentStep),
                const SizedBox(height: 18),
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
                        onPressed: flow.currentStep == DemoFlowStep.choice
                            ? flow.submitChoices
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
                  subtitle: '사장님 검토용 더미 회차 카드입니다.',
                ),
                const SizedBox(height: 12),
                for (final demoClass in classes) ...[
                  _ClassPreviewCard(
                    demoClass: demoClass,
                    onTap: demoClass.isOpen
                        ? () => flow.applyForClass(demoClass.id)
                        : null,
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 14),
                const SectionTitle(
                  title: '케미 레시피',
                  subtitle: '첫 검토에서는 설명보다 화면 흐름이 보이도록 구성합니다.',
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.demoClass, required this.onApply});

  final ChemistryClass demoClass;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.wine,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.wine.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusBadge(
                label: '검토용 UI',
                color: AppColors.wine,
                backgroundColor: AppColors.butter,
              ),
              const Spacer(),
              Text(
                demoClass.priceText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            demoClass.subtitle,
            style: const TextStyle(
              color: AppColors.butter,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            demoClass.title,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            '${demoClass.dateText} · ${demoClass.timeText}\n${demoClass.place}',
            style: const TextStyle(color: Color(0xFFFFE8C2), height: 1.45),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in demoClass.tags)
                StatusBadge(
                  label: tag,
                  color: AppColors.wine,
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.favorite),
              label: const Text('8기 신청 흐름 시작'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({required this.flowStep});

  final DemoFlowStep flowStep;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final flow = appState.flowProvider;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: AppColors.burgundy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '현재 데모 흐름',
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
              value: flow.progress,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation(AppColors.burgundy),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            flowStep.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ClassPreviewCard extends StatelessWidget {
  const _ClassPreviewCard({required this.demoClass, required this.onTap});

  final ChemistryClass demoClass;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: demoClass.isOpen ? AppColors.butter : AppColors.line,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              demoClass.isOpen ? Icons.local_dining : Icons.lock_clock,
              color: AppColors.wine,
            ),
          ),
          const SizedBox(width: 14),
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
      ('당일', Icons.chair_alt, '좌석과 라운드 진행'),
      ('매칭', Icons.favorite, '상호 선택과 리포트'),
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
