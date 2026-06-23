import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/demo_models.dart';
import '../../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../../services/character_seeder.dart';
import '../../../services/firebase_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/user_service.dart';
import '../../../shared/providers/app_scope.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({
    required this.onStartOnboarding,
    required this.onOpenOvening,
    super.key,
  });

  final VoidCallback onStartOnboarding;
  final VoidCallback onOpenOvening;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final session = appState.sessionController;
    final mode = appState.modeController.mode;

    if (mode == DemoMode.admin) {
      return const SafeArea(child: AdminDashboardScreen());
    }

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
                    const _MyTopBar(),
                    const SizedBox(height: 14),
                    if (session.isGuest)
                      _GuestProfile(
                        onStartOnboarding: onStartOnboarding,
                        onDemoLogin: () {
                          appState.sessionController.loginAsDemoUser();
                          appState.modeController.setMode(DemoMode.user);
                        },
                        onAdminPreview: () {
                          appState.sessionController.loginAsDemoUser(
                            displayName: 'sora',
                          );
                          appState.modeController.setMode(DemoMode.admin);
                        },
                      )
                    else ...[
                      const _ProfileHeader(),
                      const SizedBox(height: 24),
                      _ApplicationStatusCard(onOpenOvening: onOpenOvening),
                      const SizedBox(height: 24),
                      const _MenuSection(
                        title: '결제 · 인증',
                        items: [
                          _MenuItem(
                            icon: Icons.credit_card_rounded,
                            title: '결제 내역',
                            value: '1건',
                          ),
                          _MenuItem(
                            icon: Icons.verified_user_outlined,
                            title: '인증 관리',
                            value: '완료',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _MenuSection(
                        title: '활동',
                        items: [
                          _MenuItem(
                            icon: Icons.article_outlined,
                            title: '내가 쓴 후기',
                            value: '3',
                          ),
                          _MenuItem(
                            icon: Icons.favorite_border_rounded,
                            title: '받은 케미 리포트',
                            value: '2',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _MenuSection(
                        title: '설정',
                        items: [
                          _MenuItem(
                            icon: Icons.notifications_none_rounded,
                            title: '알림 설정',
                            value: 'ON',
                          ),
                          _MenuItem(
                            icon: Icons.settings_outlined,
                            title: '앱 설정',
                            value: '',
                          ),
                          _MenuItem(
                            icon: Icons.logout_rounded,
                            title: '로그아웃',
                            value: '',
                            muted: true,
                          ),
                          _MenuItem(
                            icon: Icons.person_remove_alt_1_outlined,
                            title: '회원탈퇴',
                            value: '',
                            muted: true,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (kDebugMode) ...[
                      const _DebugSeedButton(),
                      const SizedBox(height: 12),
                    ],
                    _DemoModeCard(onOpenOvening: onOpenOvening),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyTopBar extends StatelessWidget {
  const _MyTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '마이',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.chocolate,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _SquareIconButton(icon: Icons.notifications_none_rounded, onTap: () {}),
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
          child: Icon(icon, size: 18, color: AppColors.cocoa),
        ),
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile({
    required this.onStartOnboarding,
    required this.onDemoLogin,
    required this.onAdminPreview,
  });

  final VoidCallback onStartOnboarding;
  final VoidCallback onDemoLogin;
  final VoidCallback onAdminPreview;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusBadge(label: 'GUEST'),
          const SizedBox(height: 12),
          Text('둘러보는 손님', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '홈과 일정은 바로 볼 수 있어요. 신청과 오브닝은 케미 분석 또는 검토용 로그인이 필요합니다.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStartOnboarding,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('3분 케미 분석 시작'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDemoLogin,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('사용자 보기'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAdminPreview,
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('관리자'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final session = appState.sessionController;
    final profile = appState.currentUserController.profile;
    final characters = appState.repository.fetchCharacters();

    final displayName = profile?.displayName ?? session.displayName;
    final avatarInitial =
        displayName.isNotEmpty ? displayName.substring(0, 1) : '?';
    final genderKr = profile?.genderKr;
    final baseCharacterId = profile?.baseCharacterId;
    final character = baseCharacterId == null
        ? appState.repository.fetchFeaturedCharacter()
        : characters.firstWhere(
            (item) => item.id == baseCharacterId,
            orElse: appState.repository.fetchFeaturedCharacter,
          );

    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.butter,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brandRed),
                ),
                child: (profile?.photoURL != null)
                    ? Image.network(
                        profile!.photoURL!,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Text(
                          avatarInitial,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.brandRed,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      )
                    : Text(
                        avatarInitial,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.brandRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.cocoa,
                              ),
                            ),
                            if (genderKr != null)
                              TextSpan(
                                text: ' · $genderKr',
                                style: const TextStyle(
                                  color: AppColors.mutedText,
                                ),
                              ),
                          ],
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      const Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _SoftBadge(label: '실명 인증 완료'),
                          _SoftBadge(label: '직장 인증 완료'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                onPressed: () => _changeProfilePhoto(context),
                icon: const Icon(
                  Icons.photo_camera_outlined,
                  size: 17,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 8, 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: AppColors.burgundy,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: '나의 케미 캐릭터 '),
                        TextSpan(
                          text: character.name,
                          style: const TextStyle(
                            color: AppColors.burgundy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.cocoa,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '케미Lab ›',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.brandRed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeProfilePhoto(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final appState = AppScope.of(context);
    final uid = FirebaseService.instance.uid;
    if (uid == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('로그인 후 이용해 주세요')),
      );
      return;
    }

    final file = await StorageService.instance.pickImage();
    if (file == null) {
      return; // 사용자가 취소
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('사진 업로드 중...')),
    );
    try {
      final url = await StorageService.instance.uploadProfilePhoto(uid, file);
      await UserService.instance.updatePhotoURL(uid, url);
      await appState.currentUserController.load();
      messenger.showSnackBar(
        const SnackBar(content: Text('프로필 사진이 변경됐어요')),
      );
    } catch (error) {
      messenger.showSnackBar(
        const SnackBar(content: Text('업로드에 실패했어요. 다시 시도해 주세요')),
      );
      debugPrint('[profile-photo] $error');
    }
  }
}

class _ApplicationStatusCard extends StatelessWidget {
  const _ApplicationStatusCard({required this.onOpenOvening});

  final VoidCallback onOpenOvening;

  @override
  Widget build(BuildContext context) {
    final flow = AppScope.of(context).flowProvider;
    final selectedClass = flow.selectedClass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('신청 현황'),
        const SizedBox(height: 10),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
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
                          selectedClass.title,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.mutedText),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _statusHeadline(flow.currentStep),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.cocoa,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${selectedClass.dateText} · ${selectedClass.timeText}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusBadge(
                    label: flow.currentStep.label,
                    color: _statusColor(flow.currentStep),
                    backgroundColor: _statusColor(
                      flow.currentStep,
                    ).withValues(alpha: 0.14),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _StatusRail(currentStep: flow.currentStep),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: flow.advance,
                      child: const Text('다음 상태'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onOpenOvening,
                      icon: const Icon(
                        Icons.local_fire_department_outlined,
                        size: 18,
                      ),
                      label: const Text('오브닝'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _statusHeadline(DemoFlowStep step) {
    switch (step) {
      case DemoFlowStep.beforeApplication:
        return '아직 신청 전이에요';
      case DemoFlowStep.verificationWaiting:
        return '인증 승인 후 선정이 진행돼요';
      case DemoFlowStep.verificationApproved:
        return 'AI 선정 결과를 기다리고 있어요';
      case DemoFlowStep.aiSelectionWaiting:
        return '인원 구성을 계산하고 있어요';
      case DemoFlowStep.selected:
        return '선정 완료, 입금 안내를 확인해주세요';
      case DemoFlowStep.paymentWaiting:
        return '입금 확인 후 최종 확정됩니다';
      case DemoFlowStep.confirmed:
      case DemoFlowStep.nicknameCheck:
      case DemoFlowStep.firstImpressionChoice:
      case DemoFlowStep.rotationTalk:
      case DemoFlowStep.middleChoice:
      case DemoFlowStep.seatingGuide:
      case DemoFlowStep.pairBaking:
      case DemoFlowStep.finalChoice:
      case DemoFlowStep.matchResult:
      case DemoFlowStep.chemistryReport:
      case DemoFlowStep.review:
        return '최종 참가가 확정되었어요';
    }
  }

  static Color _statusColor(DemoFlowStep step) {
    switch (step) {
      case DemoFlowStep.paymentWaiting:
      case DemoFlowStep.selected:
      case DemoFlowStep.aiSelectionWaiting:
        return AppColors.gold;
      case DemoFlowStep.confirmed:
      case DemoFlowStep.nicknameCheck:
      case DemoFlowStep.firstImpressionChoice:
      case DemoFlowStep.rotationTalk:
      case DemoFlowStep.middleChoice:
      case DemoFlowStep.seatingGuide:
      case DemoFlowStep.pairBaking:
      case DemoFlowStep.finalChoice:
      case DemoFlowStep.matchResult:
      case DemoFlowStep.chemistryReport:
      case DemoFlowStep.review:
        return AppColors.success;
      case DemoFlowStep.beforeApplication:
      case DemoFlowStep.verificationWaiting:
      case DemoFlowStep.verificationApproved:
        return AppColors.burgundy;
    }
  }
}

class _StatusRail extends StatelessWidget {
  const _StatusRail({required this.currentStep});

  final DemoFlowStep currentStep;

  @override
  Widget build(BuildContext context) {
    const steps = [
      (DemoFlowStep.verificationWaiting, '신청'),
      (DemoFlowStep.verificationApproved, '인증'),
      (DemoFlowStep.selected, '선정'),
      (DemoFlowStep.paymentWaiting, '입금'),
      (DemoFlowStep.confirmed, '확정'),
    ];
    final activeIndex = _stageIndex(currentStep);

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: _RailStep(
              label: steps[i].$2,
              completed: i < activeIndex,
              active: i == activeIndex,
            ),
          ),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 24),
                color: i < activeIndex ? AppColors.burgundy : AppColors.line,
              ),
            ),
        ],
      ],
    );
  }

  static int _stageIndex(DemoFlowStep step) {
    switch (step) {
      case DemoFlowStep.beforeApplication:
      case DemoFlowStep.verificationWaiting:
        return 0;
      case DemoFlowStep.verificationApproved:
      case DemoFlowStep.aiSelectionWaiting:
        return 1;
      case DemoFlowStep.selected:
        return 2;
      case DemoFlowStep.paymentWaiting:
        return 3;
      case DemoFlowStep.confirmed:
      case DemoFlowStep.nicknameCheck:
      case DemoFlowStep.firstImpressionChoice:
      case DemoFlowStep.rotationTalk:
      case DemoFlowStep.middleChoice:
      case DemoFlowStep.seatingGuide:
      case DemoFlowStep.pairBaking:
      case DemoFlowStep.finalChoice:
      case DemoFlowStep.matchResult:
      case DemoFlowStep.chemistryReport:
      case DemoFlowStep.review:
        return 4;
    }
  }
}

class _RailStep extends StatelessWidget {
  const _RailStep({
    required this.label,
    required this.completed,
    required this.active,
  });

  final String label;
  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final isDone = completed || active;
    final dotColor = completed
        ? AppColors.burgundy
        : active
        ? AppColors.butter
        : Colors.white;
    final borderColor = isDone ? AppColors.burgundy : AppColors.line;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 23,
          height: 23,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: completed
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : active
              ? Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.burgundy,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDone ? AppColors.cocoa : AppColors.mutedText,
              fontWeight: isDone ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(title),
        const SizedBox(height: 10),
        AppCard(
          color: Colors.white,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _MenuRow(item: items[i]),
                if (i < items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.line,
                    indent: 52,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.value,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool muted;
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final iconColor = item.muted ? AppColors.mutedText : AppColors.brandRed;
    final textColor = item.muted ? AppColors.mutedText : AppColors.cocoa;

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.parchment,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (item.value.isNotEmpty)
              Text(
                item.value,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: item.muted ? AppColors.line : AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoModeCard extends StatelessWidget {
  const _DemoModeCard({required this.onOpenOvening});

  final VoidCallback onOpenOvening;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final modeController = appState.modeController;
    final mode = modeController.mode;

    return AppCard(
      color: Colors.white.withValues(alpha: 0.72),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '검토 모드',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '게스트, 사용자, 당일 참가자, 관리자 화면을 즉시 전환합니다.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<DemoMode>(
              segments: [
                for (final demoMode in DemoMode.values)
                  ButtonSegment<DemoMode>(
                    value: demoMode,
                    icon: Icon(demoMode.icon),
                    label: Text(demoMode.label),
                  ),
              ],
              selected: {mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                final selected = selection.first;
                if (selected == DemoMode.guest) {
                  appState.sessionController.resetGuest();
                  appState.flowProvider.reset();
                } else {
                  appState.sessionController.loginAsDemoUser(
                    displayName: selected == DemoMode.admin ? 'admin' : '참가자 A',
                  );
                }
                modeController.setMode(selected);
                if (selected == DemoMode.participantToday) {
                  appState.flowProvider.jumpTo(DemoFlowStep.nicknameCheck);
                  onOpenOvening();
                }
              },
            ),
          ),
        ],
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
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.success,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 개발용: 캐릭터 20종을 Firestore characters/{id} 에 시드.
/// 쓰기는 운영자(roles: admin)만 가능 — 본인 user 문서 roles 설정 후 사용.
class _DebugSeedButton extends StatefulWidget {
  const _DebugSeedButton();

  @override
  State<_DebugSeedButton> createState() => _DebugSeedButtonState();
}

class _DebugSeedButtonState extends State<_DebugSeedButton> {
  bool _busy = false;

  Future<void> _seed() async {
    setState(() => _busy = true);
    String message;
    try {
      final count = await CharacterSeeder.instance.seedIfEmpty();
      message = count > 0
          ? '캐릭터 $count종 시드 완료'
          : '이미 시드되어 있어요 (변경 없음)';
    } catch (error) {
      message = '시드 실패: 운영자 권한(roles: admin)인지 확인하세요';
      debugPrint('[seed] $error');
    }
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _seed,
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cloud_upload_outlined, size: 18),
        label: const Text('[개발용] 캐릭터 Firestore 시드'),
      ),
    );
  }
}
