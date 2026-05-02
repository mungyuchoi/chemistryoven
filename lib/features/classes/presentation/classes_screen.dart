import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_title.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/demo_models.dart';
import '../../../shared/providers/app_scope.dart';

class ClassesScreen extends StatelessWidget {
  const ClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final classes = appState.repository.fetchClasses();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const SectionTitle(
            title: '회차',
            subtitle: '사장님 검토용으로 신청 가능, 예정, 기획 중 상태를 더미로 표시합니다.',
          ),
          const SizedBox(height: 14),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: '회차, 날짜, 장소 검색',
              suffixIcon: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.tune),
                tooltip: '필터',
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              StatusBadge(label: '전체'),
              StatusBadge(label: '신청 가능', color: AppColors.success),
              StatusBadge(label: '오픈 예정', color: AppColors.warning),
              StatusBadge(label: '4:4'),
            ],
          ),
          const SizedBox(height: 18),
          for (final demoClass in classes) ...[
            _ClassCard(
              demoClass: demoClass,
              onTap: () => _showClassDetail(context, demoClass),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _showClassDetail(BuildContext context, ChemistryClass demoClass) {
    final flow = AppScope.of(context).flowProvider;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.ivory,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      demoClass.title,
                      style: Theme.of(context).textTheme.headlineMedium,
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
              const SizedBox(height: 8),
              Text(
                demoClass.subtitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              _DetailLine(icon: Icons.calendar_month, text: demoClass.dateText),
              _DetailLine(icon: Icons.schedule, text: demoClass.timeText),
              _DetailLine(icon: Icons.place, text: demoClass.place),
              _DetailLine(icon: Icons.group, text: demoClass.capacityLabel),
              _DetailLine(icon: Icons.payments, text: demoClass.priceText),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in demoClass.tags) StatusBadge(label: tag),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: demoClass.isOpen
                      ? () {
                          flow.applyForClass(demoClass.id);
                          Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.favorite_border),
                  label: Text(demoClass.isOpen ? '신청 흐름 시작' : '오픈 예정'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.demoClass, required this.onTap});

  final ChemistryClass demoClass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: Colors.white,
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
                    Text(
                      demoClass.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demoClass.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
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
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _DetailLine(
                  icon: Icons.calendar_month,
                  text: demoClass.dateText,
                ),
                _DetailLine(icon: Icons.schedule, text: demoClass.timeText),
                _DetailLine(icon: Icons.place, text: demoClass.place),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${demoClass.applicationCount}명 신청 · ${demoClass.capacityLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                demoClass.priceText,
                style: const TextStyle(
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
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
