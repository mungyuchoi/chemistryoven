import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/demo_models.dart';
import '../../../../shared/providers/demo_flow_provider.dart';

class FlowTimeline extends StatelessWidget {
  const FlowTimeline({required this.flow, this.compact = false, super.key});

  final DemoFlowProvider flow;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visibleSteps = compact
        ? flow.steps.take(flow.currentIndex + 3).toList()
        : flow.steps;

    return Column(
      children: [
        for (final step in visibleSteps)
          _FlowTimelineItem(
            step: step,
            index: flow.steps.indexOf(step),
            currentIndex: flow.currentIndex,
            compact: compact,
            onTap: () => flow.jumpTo(step),
          ),
      ],
    );
  }
}

class _FlowTimelineItem extends StatelessWidget {
  const _FlowTimelineItem({
    required this.step,
    required this.index,
    required this.currentIndex,
    required this.compact,
    required this.onTap,
  });

  final DemoFlowStep step;
  final int index;
  final int currentIndex;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDone = index < currentIndex;
    final isCurrent = index == currentIndex;
    final color = isCurrent
        ? AppColors.burgundy
        : isDone
        ? AppColors.success
        : AppColors.line;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 7 : 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone ? Icons.check : Icons.circle,
                    color: isDone || isCurrent ? Colors.white : AppColors.line,
                    size: isDone ? 14 : 8,
                  ),
                ),
                if (!compact || index < currentIndex + 1)
                  Container(
                    width: 2,
                    height: compact ? 16 : 26,
                    color: AppColors.line,
                  ),
              ],
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
                          step.label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: isCurrent
                                    ? AppColors.burgundy
                                    : AppColors.cocoa,
                              ),
                        ),
                      ),
                      if (isCurrent)
                        const StatusBadge(
                          label: '현재',
                          color: AppColors.burgundy,
                        ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
