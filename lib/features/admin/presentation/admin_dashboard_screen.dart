import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/demo_models.dart';
import '../../../shared/providers/app_scope.dart';

enum _AdminScreen {
  login,
  dashboard,
  notifications,
  sessions,
  sessionDetail,
  sessionCreate,
  applicants,
  applicantDetail,
  selectionPool,
  chemistryCombo,
  participants,
  characterAssign,
  voting,
  seatingAuto,
  seatingEdit,
  matchResult,
  reviews,
}

enum _AdminTab { dash, sessions, applicants, matching, more }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _AdminScreen _screen = _AdminScreen.login;
  _AdminApplicantData _selectedApplicant = _adminApplicants[4];
  int _applicantStatusFilter = 0;
  int _applicantSort = 0;
  int _selectionPoolMode = 0;
  _AdminScreen _reviewsBackTarget = _AdminScreen.matchResult;
  int _menCount = 4;
  int _womenCount = 4;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    return ColoredBox(
      color: AppColors.cream,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: ListView(
                    key: ValueKey(_screen),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      18,
                      20,
                      _screen == _AdminScreen.login ? 28 : 18,
                    ),
                    children: [_buildScreen(context, appState)],
                  ),
                ),
              ),
              if (_screen != _AdminScreen.login)
                _AdminBottomNav(
                  selected: _tabForScreen(_screen),
                  onChanged: (tab) => _go(_screenForTab(tab)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(BuildContext context, AppState appState) {
    switch (_screen) {
      case _AdminScreen.login:
        return _buildLogin(context);
      case _AdminScreen.dashboard:
        return _buildDashboard(context, appState);
      case _AdminScreen.notifications:
        return _buildNotifications(context);
      case _AdminScreen.sessions:
        return _buildSessionList(context, appState.repository.fetchClasses());
      case _AdminScreen.sessionDetail:
        return _buildSessionDetail(
          context,
          appState.repository.fetchFeaturedClass(),
        );
      case _AdminScreen.sessionCreate:
        return _buildSessionCreate(context);
      case _AdminScreen.applicants:
        return _buildApplicantList(context);
      case _AdminScreen.applicantDetail:
        return _buildApplicantDetail(context, _selectedApplicant);
      case _AdminScreen.selectionPool:
        return _buildSelectionPool(context);
      case _AdminScreen.chemistryCombo:
        return _buildChemistryCombo(context);
      case _AdminScreen.participants:
        return _buildParticipants(context);
      case _AdminScreen.characterAssign:
        return _buildCharacterAssign(context);
      case _AdminScreen.voting:
        return _buildVoting(context);
      case _AdminScreen.seatingAuto:
        return _buildSeatingAuto(context);
      case _AdminScreen.seatingEdit:
        return _buildSeatingEdit(context);
      case _AdminScreen.matchResult:
        return _buildMatchResult(context);
      case _AdminScreen.reviews:
        return _buildReviews(context);
    }
  }

  void _go(_AdminScreen screen) {
    setState(() => _screen = screen);
  }

  _AdminTab _tabForScreen(_AdminScreen screen) {
    switch (screen) {
      case _AdminScreen.dashboard:
        return _AdminTab.dash;
      case _AdminScreen.sessions:
      case _AdminScreen.sessionDetail:
      case _AdminScreen.sessionCreate:
        return _AdminTab.sessions;
      case _AdminScreen.applicants:
      case _AdminScreen.applicantDetail:
      case _AdminScreen.participants:
      case _AdminScreen.characterAssign:
        return _AdminTab.applicants;
      case _AdminScreen.selectionPool:
      case _AdminScreen.chemistryCombo:
      case _AdminScreen.voting:
      case _AdminScreen.seatingAuto:
      case _AdminScreen.seatingEdit:
      case _AdminScreen.matchResult:
        return _AdminTab.matching;
      case _AdminScreen.notifications:
      case _AdminScreen.reviews:
      case _AdminScreen.login:
        return _AdminTab.more;
    }
  }

  _AdminScreen _screenForTab(_AdminTab tab) {
    switch (tab) {
      case _AdminTab.dash:
        return _AdminScreen.dashboard;
      case _AdminTab.sessions:
        return _AdminScreen.sessions;
      case _AdminTab.applicants:
        return _AdminScreen.applicants;
      case _AdminTab.matching:
        return _AdminScreen.selectionPool;
      case _AdminTab.more:
        return _AdminScreen.notifications;
    }
  }

  Widget _buildLogin(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 56),
        const _AdminMonogram(size: 60, label: 'C'),
        const SizedBox(height: 32),
        const _TinyEyebrow('ADMIN · v1.1'),
        const SizedBox(height: 8),
        Text('오늘의 회차를 준비할 시간이에요.', style: _displayStyle(context, 29)),
        const SizedBox(height: 56),
        const _AdminInput(label: '운영자 이메일'),
        const SizedBox(height: 10),
        const _AdminInput(label: '비밀번호'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '이 기기에서 자동 로그인',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.cocoa),
              ),
            ),
            Text(
              '비밀번호 찾기',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.burgundy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 220),
        _WideButton(label: '로그인', onTap: () => _go(_AdminScreen.dashboard)),
        const SizedBox(height: 10),
        Center(
          child: Text(
            '운영자 계정 문의 · admin@chemistry-oven.kr',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(BuildContext context, AppState appState) {
    final admin = appState.adminProvider;
    final featured = appState.repository.fetchFeaturedClass();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminBrandBar(
          showAdmin: true,
          actionIcon: Icons.notifications_none_rounded,
          onAction: () => _go(_AdminScreen.notifications),
        ),
        const SizedBox(height: 20),
        Text(
          '안녕하세요, 운영자님',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
        const SizedBox(height: 4),
        Text('오늘은 5/22 (금)', style: _displayStyle(context, 30)),
        const SizedBox(height: 16),
        _AdminEventSummary(
          title: featured.title,
          subtitle: '${featured.dateText} · ${featured.place}',
          stats: [
            _StatData('신청', '34', '+6'),
            _StatData('인증', '${admin.pendingVerificationCount}', '대기'),
            _StatData('입금', '${admin.paidCount + 6}', '48h'),
            _StatData('확정', '2/8', ''),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.add_rounded,
                label: '새 회차',
                active: true,
                onTap: () => _go(_AdminScreen.sessionCreate),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.person_outline_rounded,
                label: '신청자',
                onTap: () => _go(_AdminScreen.applicants),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.auto_awesome_outlined,
                label: '인원 선정',
                onTap: () => _go(_AdminScreen.selectionPool),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.chair_alt_outlined,
                label: '자리배치',
                onTap: () => _go(_AdminScreen.seatingAuto),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: '8기 성비 & 인원', trailing: '목표 4:4'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  children: [
                    Expanded(
                      flex: 17,
                      child: Container(height: 10, color: AppColors.pistachio),
                    ),
                    Expanded(
                      flex: 17,
                      child: Container(height: 10, color: AppColors.burgundy),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '현재 확정 남 1 / 여 1. 선정 후 캐릭터 배정을 진행하세요.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _RecentApplicantsCard(
          onOpenAll: () => _go(_AdminScreen.applicants),
          onOpenApplicant: (applicant) {
            setState(() {
              _selectedApplicant = applicant;
              _screen = _AdminScreen.applicantDetail;
            });
          },
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(title: '오늘 투표 라운드', trailing: 'LIVE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  const _AdminMonogram(size: 42, label: '첫'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '첫인상 선택',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.cocoa,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '7/8 제출 · 남은 시간 00:38',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                  _MiniButton(
                    label: '열기',
                    onTap: () => _go(_AdminScreen.voting),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotifications(BuildContext context) {
    const items = [
      _NotificationData(
        icon: Icons.auto_awesome_rounded,
        category: '인원 선정',
        title: '8기 신청자 6명 인증 완료',
        body: '인원 선정 단계로 진행하세요',
        time: '12분 전',
        urgent: true,
      ),
      _NotificationData(
        icon: Icons.payments_outlined,
        category: '결제',
        title: '8기 입금 대기 6건',
        body: '48시간 내 미입금 시 자동 미선정 처리',
        time: '1시간 전',
        urgent: true,
      ),
      _NotificationData(
        icon: Icons.shopping_bag_outlined,
        category: '운영',
        title: '7기 첫인상 라운드가 정상 종료되었어요',
        body: '중간 선택 라운드를 열 수 있어요',
        time: '3시간 전',
      ),
      _NotificationData(
        icon: Icons.article_outlined,
        category: '후기',
        title: '7기 후기 3건 승인 대기',
        body: '후기 노출 전 검토가 필요해요',
        time: '어제',
      ),
      _NotificationData(
        icon: Icons.shield_outlined,
        category: '시스템',
        title: '월간 운영 리포트가 준비되었어요',
        body: '이번 달 신청 전환을 확인하세요',
        time: '어제',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '알림',
          subtitle: '새 알림 4건',
          onBack: () => _go(_AdminScreen.dashboard),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const _AdminChip(label: '전체', selected: true),
            const _AdminChip(label: '운영'),
            const _AdminChip(label: '결제'),
            const _AdminChip(label: '시스템'),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => _openReviewsFrom(_AdminScreen.notifications),
              child: const _AdminChip(label: '후기'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final item in items) ...[
          _NotificationCard(
            item: item,
            onTap: item.category == '후기'
                ? () => _openReviewsFrom(_AdminScreen.notifications)
                : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  void _openReviewsFrom(_AdminScreen backTarget) {
    setState(() {
      _reviewsBackTarget = backTarget;
      _screen = _AdminScreen.reviews;
    });
  }

  Widget _buildSessionList(BuildContext context, List<ChemistryClass> classes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminBrandBar(
          showAdmin: true,
          actionIcon: Icons.add_rounded,
          onAction: () => _go(_AdminScreen.sessionCreate),
        ),
        const SizedBox(height: 18),
        Text('회차 관리', style: _displayStyle(context, 29)),
        const SizedBox(height: 6),
        Text(
          '회차 생성·수정·마감·종료',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: _AdminChip(label: '전체 6', selected: true, compact: true),
            ),
            SizedBox(width: 6),
            Expanded(child: _AdminChip(label: '모집중 2', compact: true)),
            SizedBox(width: 6),
            Expanded(child: _AdminChip(label: '선정중 1', compact: true)),
            SizedBox(width: 6),
            Expanded(child: _AdminChip(label: '확정 2', compact: true)),
            SizedBox(width: 6),
            Expanded(child: _AdminChip(label: '종료 1', compact: true)),
          ],
        ),
        const SizedBox(height: 14),
        _SessionListCard(
          number: '8기',
          classData: classes[0],
          status: '모집중',
          active: true,
          onTap: () => _go(_AdminScreen.sessionDetail),
        ),
        const SizedBox(height: 12),
        _SessionListCard(
          number: '9기',
          classData: classes[1],
          status: '오픈예정',
          onTap: () => _go(_AdminScreen.sessionDetail),
        ),
        const SizedBox(height: 12),
        _SessionListCard(
          number: '10기',
          classData: classes[2],
          status: '기획중',
          empty: true,
          onTap: () => _go(_AdminScreen.sessionDetail),
        ),
      ],
    );
  }

  Widget _buildSessionDetail(BuildContext context, ChemistryClass classData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '8기 상세',
          subtitle: '모집중 · D-23',
          onBack: () => _go(_AdminScreen.sessions),
          actionIcon: Icons.edit_outlined,
        ),
        const SizedBox(height: 14),
        const _SessionCoverStrip(),
        const SizedBox(height: 12),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _InfoLine(
                icon: Icons.calendar_month_outlined,
                label: '일시',
                value: '${classData.dateText} 14:00 - 18:00',
              ),
              const _DividerLine(),
              _InfoLine(
                icon: Icons.place_outlined,
                label: '장소',
                value: classData.place,
              ),
              const _DividerLine(),
              const _InfoLine(
                icon: Icons.person_outline_rounded,
                label: '모집',
                value: '남 4 / 여 4 (총 8명)',
              ),
              const _DividerLine(),
              _InfoLine(
                icon: Icons.payments_outlined,
                label: '참가비',
                value: classData.priceText,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(title: '운영 진행', trailing: ''),
              const SizedBox(height: 12),
              _ProgressStep(
                title: '모집',
                subtitle: '신청 34명 · 인증 29',
                done: true,
              ),
              _ProgressStep(
                title: '인원 선정',
                subtitle: '대기 8명 · 검토 중',
                active: true,
                actionLabel: '이어서',
                onAction: () => _go(_AdminScreen.selectionPool),
              ),
              const _ProgressStep(title: '참가자 관리', subtitle: '미시작'),
              const _ProgressStep(title: '캐릭터 배정', subtitle: '미시작'),
              const _ProgressStep(title: '자리배치', subtitle: '미시작'),
              const _ProgressStep(title: '투표 라운드', subtitle: '미시작'),
              const _ProgressStep(title: '매칭 결과', subtitle: '미시작'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _WideButton(label: '공지복제', muted: true, onTap: () {}),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WideButton(label: '회차마감', onTap: () {}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionCreate(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '새 회차 만들기',
          subtitle: '9기',
          onBack: () => _go(_AdminScreen.sessions),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 20),
        const _TinyEyebrow('01  기본 정보'),
        const SizedBox(height: 10),
        const _AdminInput(label: '회차'),
        const SizedBox(height: 10),
        const _AdminInput(label: '일시', icon: Icons.calendar_month_outlined),
        const SizedBox(height: 10),
        const _AdminInput(label: '시간', icon: Icons.access_time_outlined),
        const SizedBox(height: 10),
        const _AdminInput(label: '장소', icon: Icons.place_outlined),
        const SizedBox(height: 10),
        const _AdminInput(label: '참가비', icon: Icons.payments_outlined),
        const SizedBox(height: 20),
        const _TinyEyebrow('02  모집 인원'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CountBox(
                label: '남',
                count: _menCount,
                onMinus: () => setState(
                  () => _menCount = (_menCount - 1).clamp(1, 8).toInt(),
                ),
                onPlus: () => setState(
                  () => _menCount = (_menCount + 1).clamp(1, 8).toInt(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CountBox(
                label: '여',
                count: _womenCount,
                onMinus: () => setState(
                  () => _womenCount = (_womenCount - 1).clamp(1, 8).toInt(),
                ),
                onPlus: () => setState(
                  () => _womenCount = (_womenCount + 1).clamp(1, 8).toInt(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _TinyEyebrow('03  베이킹 클래스 메뉴 · 회원에게 노출'),
        const SizedBox(height: 10),
        const _AdminInput(label: '메뉴명', icon: Icons.local_dining_outlined),
        const SizedBox(height: 10),
        const _HorizontalChipStrip(
          labels: ['알레르기 견과 함유', '글루텐 함유', '계란 함유', '유제품 함유'],
        ),
        const SizedBox(height: 20),
        const _TinyEyebrow('04  제품 사진 업로드 · 회차 카드 · 상세 노출'),
        const SizedBox(height: 10),
        AppCard(
          color: AppColors.parchment,
          borderColor: AppColors.rose,
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            height: 124,
            child: Stack(
              children: [
                const Center(
                  child: _AdminChip(label: 'SESSION COVER', selected: false),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.burgundy,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '대표',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WideButton(label: '임시저장', muted: true, onTap: () {}),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WideButton(
                label: '회차 게시',
                onTap: () => _go(_AdminScreen.sessions),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApplicantList(BuildContext context) {
    final applicants = _sortedApplicants();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminBrandBar(
          showAdmin: true,
          actionIcon: Icons.filter_alt_outlined,
          secondaryActionIcon: Icons.search_rounded,
          onAction: () {},
        ),
        const SizedBox(height: 18),
        Text('신청자', style: _displayStyle(context, 29)),
        const SizedBox(height: 6),
        Text(
          '8기 · 34명 · 인증 29',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
        const SizedBox(height: 14),
        _HorizontalSelectableChipStrip(
          labels: const [
            '전체 34',
            '신규 6',
            '인증 대기 5',
            '인증 완료 29',
            '보류 2',
            '탈락 1',
          ],
          selectedIndex: _applicantStatusFilter,
          onSelected: (index) => setState(() => _applicantStatusFilter = index),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              '정렬',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HorizontalSelectableChipStrip(
                labels: const ['최신순', '케미 높은순'],
                selectedIndex: _applicantSort,
                onSelected: (index) => setState(() => _applicantSort = index),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final applicant in applicants) ...[
          _ApplicantListCard(
            applicant: applicant,
            onTap: () {
              setState(() {
                _selectedApplicant = applicant;
                _screen = _AdminScreen.applicantDetail;
              });
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  List<_AdminApplicantData> _sortedApplicants() {
    final applicants = [..._adminApplicants];
    if (_applicantSort == 1) {
      applicants.sort((a, b) => b.score.compareTo(a.score));
    }
    return applicants;
  }

  Widget _buildApplicantDetail(
    BuildContext context,
    _AdminApplicantData applicant,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: applicant.name,
          subtitle: '${applicant.gender} · ${applicant.age} · 인증 완료',
          onBack: () => _go(_AdminScreen.applicants),
          actionIcon: Icons.edit_outlined,
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _ApplicantAvatar(applicant: applicant, size: 74),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${applicant.name} · ${applicant.birth}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.cocoa,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${applicant.height} · ${applicant.mbti} · ${applicant.job}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: const [
                        _ApplicantStatusBadge(label: '인증 완료'),
                        _ApplicantStatusBadge(label: '선정 후보', selected: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(title: '케미 분석 (운영 전용)', trailing: ''),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ScoreBox(
                      label: 'STRICT',
                      value: applicant.strictScore,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ScoreBox(
                      label: '객관',
                      value: applicant.objectiveScore,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ScoreBox(label: '케미', value: applicant.score),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'AI 요약 · ${applicant.note}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(child: _AdminChip(label: '프로필', selected: true)),
            SizedBox(width: 8),
            Expanded(child: _AdminChip(label: '선호 조건')),
            SizedBox(width: 8),
            Expanded(child: _AdminChip(label: '답변')),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _InfoLine(
                icon: Icons.person_outline,
                label: '이름',
                value: applicant.name,
              ),
              const _DividerLine(),
              const _InfoLine(
                icon: Icons.phone_iphone_outlined,
                label: '연락처',
                value: '010-****-2398',
              ),
              const _DividerLine(),
              const _InfoLine(
                icon: Icons.place_outlined,
                label: '지역',
                value: '서울 강남권',
              ),
              const _DividerLine(),
              const _InfoLine(
                icon: Icons.favorite_border_rounded,
                label: '종교',
                value: '무교',
              ),
              const _DividerLine(),
              _InfoLine(
                icon: Icons.auto_awesome_outlined,
                label: '기본 캐릭터',
                value: applicant.character,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          color: AppColors.ivory,
          padding: const EdgeInsets.all(14),
          child: Text(
            '운영 메모\n7기 미선정, 8기는 디자인 동종 풀의 균형 후보로 도움 가능.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cocoa,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WideButton(label: '탈락', muted: true, onTap: () {}),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WideButton(label: '보류', muted: true, onTap: () {}),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WideButton(
                label: '선정',
                onTap: () => _go(_AdminScreen.selectionPool),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionPool(BuildContext context) {
    final men = _adminApplicants.where((item) => item.gender == '남').toList();
    final women = _adminApplicants.where((item) => item.gender == '여').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '인원 선정',
          subtitle: '8기 · 케미 기반 추천',
          onBack: () => _go(_AdminScreen.sessions),
          actionText: '가중치',
        ),
        const SizedBox(height: 14),
        AppCard(
          color: AppColors.burgundy,
          borderColor: AppColors.burgundy,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '현재 선정',
                      style: TextStyle(
                        color: AppColors.butter,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '4 : 4 목표',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.butter),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '2 / 8',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(
                    child: _DarkMetric(label: '조합 평균', value: '82.4'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _DarkMetric(label: '시너지', value: '안정'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _DarkMetric(label: '위험 쌍', value: '0'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _HorizontalSelectableChipStrip(
          labels: const ['후보 풀', '케미 조합', '밸런스'],
          selectedIndex: _selectionPoolMode,
          onSelected: (index) => setState(() => _selectionPoolMode = index),
        ),
        const SizedBox(height: 16),
        _CandidateGroup(title: '남성 후보', applicants: men),
        const SizedBox(height: 12),
        _CandidateGroup(title: '여성 후보', applicants: women),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WideButton(label: '다시 추천', muted: true, onTap: () {}),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WideButton(
                label: '케미 조합보기',
                onTap: () {
                  setState(() {
                    _selectedApplicant = women.firstWhere(
                      (applicant) => applicant.selected,
                      orElse: () => women.first,
                    );
                    _screen = _AdminScreen.chemistryCombo;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChemistryCombo(BuildContext context) {
    final pivot = _selectedApplicant;
    final counterpartGender = pivot.gender == '남' ? '여성' : '남성';
    final candidates = _adminApplicants
        .where((item) => item.gender != pivot.gender)
        .take(4)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '케미 조합',
          subtitle: '1:1 케미 점수 기반',
          onBack: () => _go(_AdminScreen.selectionPool),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          borderColor: AppColors.burgundy,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _ApplicantAvatar(applicant: pivot, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TinyEyebrow('PIVOT'),
                    const SizedBox(height: 6),
                    Text(
                      pivot.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.cocoa,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${pivot.age} · ${pivot.mbti} · ${pivot.job}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _PivotSelectedBadge(),
                  ],
                ),
              ),
              _MiniButton(label: '변경', onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '이 분과 1:1로 잘 맞는 $counterpartGender 후보예요. 케미점수는 상호 관계로 계산돼요.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        _SectionHeader(
          title: '잘 맞는 $counterpartGender Top 4',
          trailing: '조합 시너지 순',
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < candidates.length; i++) ...[
          _ComboCandidateCard(
            applicant: candidates[i],
            best: i == 0,
            score: [91, 84, 79, 62][i],
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _WideButton(label: '초기화', muted: true, onTap: () {}),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WideButton(
                label: '최종 선정 저장',
                onTap: () => _go(_AdminScreen.participants),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParticipants(BuildContext context) {
    final confirmed = _adminApplicants.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '참가자 관리',
          subtitle: '8기 · 6명',
          onBack: () => _go(_AdminScreen.chemistryCombo),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: const [
              Expanded(
                child: _SmallMetric(label: '확정', value: '4/8'),
              ),
              Expanded(
                child: _SmallMetric(label: '입금 대기', value: '2'),
              ),
              Expanded(
                child: _SmallMetric(label: '참석 확인', value: '2'),
              ),
              Expanded(
                child: _SmallMetric(label: '미연락', value: '1'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _SectionHeader(title: '확정 참가자', trailing: '6명'),
        const SizedBox(height: 10),
        for (var i = 0; i < confirmed.length; i++) ...[
          _ParticipantCard(
            applicant: confirmed[i],
            paymentLabel: i < 3 ? '입금완료' : '입금대기',
            attendLabel: i == 0 || i == 1 ? '참석확정' : '미확신',
            waitingLabel: i == 4 ? '48h 내' : null,
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _WideButton(label: '일괄 알림', muted: true, onTap: () {}),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WideButton(
                label: '캐릭터 배정으로',
                onTap: () => _go(_AdminScreen.characterAssign),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCharacterAssign(BuildContext context) {
    final men = _adminApplicants.where((item) => item.gender == '남').toList();
    final women = _adminApplicants.where((item) => item.gender == '여').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '캐릭터 배정',
          subtitle: '회차 전용 닉네임',
          onBack: () => _go(_AdminScreen.participants),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                color: AppColors.burgundy,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '기본 캐릭터를 우선 배정했어요. 중복이 없도록 운영자가 최종 확정해주세요.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.cocoa,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _ActionPill(label: '자동 재배정'),
                        _ActionPill(label: '전체 잠금'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const _SectionHeader(title: '남성', trailing: '크루아상 / 소금빵 / 에클레어 / 단팥빵'),
        const SizedBox(height: 10),
        for (var i = 0; i < men.length; i++) ...[
          _CharacterAssignRow(
            applicant: men[i],
            assigned: ['크루아상', '소금빵', '에클레어', '단팥빵'][i],
            locked: i < 2,
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        const _SectionHeader(title: '여성', trailing: '티라미수 / 에그타르트 / 마들렌 / 몽블랑'),
        const SizedBox(height: 10),
        for (var i = 0; i < women.length; i++) ...[
          _CharacterAssignRow(
            applicant: women[i],
            assigned: ['티라미수', '에그타르트', '마들렌', '몽블랑'][i],
            locked: i < 2,
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WideButton(label: '초기화', muted: true, onTap: () {}),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WideButton(
                label: '배정 확정',
                onTap: () => _go(_AdminScreen.voting),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoting(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '투표 관리',
          subtitle: '8기 · 회차 진행 중',
          onBack: () => _go(_AdminScreen.characterAssign),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        AppCard(
          color: AppColors.burgundy,
          borderColor: AppColors.burgundy,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIVE · 라운드 1',
                style: TextStyle(
                  color: AppColors.butter,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '첫인상 선택',
                style: _displayStyle(context, 27).copyWith(color: Colors.white),
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: _DarkMetric(label: '응답', value: '7/8'),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: _DarkMetric(label: '남은 시간', value: '00:38'),
                  ),
                  const SizedBox(width: 8),
                  _MiniButton(label: '지금닫기', onTap: () {}),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const _AdminMonogram(size: 44, label: '단'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(title: '미응답자', trailing: '1명'),
                    const SizedBox(height: 4),
                    Text(
                      '단팥빵 · 오지훈\n22분 · 22초 경과',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              _MiniButton(label: '알림 보내기', onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _SectionHeader(title: '라운드 상태', trailing: '3 단계'),
        const SizedBox(height: 10),
        const _RoundStatusCard(
          number: '1',
          title: '첫인상선택',
          subtitle: '응답 7 / 8',
          progress: 0.88,
          active: true,
        ),
        const SizedBox(height: 10),
        const _RoundStatusCard(
          number: '2',
          title: '중간선택',
          subtitle: '응답 0 / 8',
        ),
        const SizedBox(height: 10),
        const _RoundStatusCard(
          number: '3',
          title: '최종선택',
          subtitle: '응답 0 / 8',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WideButton(
                label: '자리배치 보기',
                muted: true,
                onTap: () => _go(_AdminScreen.seatingAuto),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WideButton(
                label: '매칭 결과',
                onTap: () => _go(_AdminScreen.matchResult),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeatingAuto(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '자리배치',
          subtitle: '자동 추천 · 8기',
          onBack: () => _go(_AdminScreen.voting),
          actionText: '자동',
        ),
        const SizedBox(height: 14),
        AppCard(
          color: AppColors.burgundy,
          borderColor: AppColors.burgundy,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AUTO RECOMMEND',
                style: TextStyle(
                  color: AppColors.butter,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '케미·성비 균형 우선',
                style: _displayStyle(context, 24).copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(
                    child: _DarkMetric(label: '조합 평균', value: '84.2'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _DarkMetric(label: '성비 균형', value: '50:50'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _DarkMetric(label: '흐름 점수', value: '좋음'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MiniButton(label: '다시추천', onTap: () {}),
            const SizedBox(width: 8),
            _MiniButton(label: '초기화', onTap: () {}),
            const Spacer(),
            Text(
              '비교 모드',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.burgundy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SeatingTable(title: 'A 테이블', tableName: 'TABLE A'),
        const SizedBox(height: 18),
        const _SeatingTable(
          title: 'B 테이블',
          tableName: 'TABLE B',
          flipped: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WideButton(
                label: '수동 편집',
                muted: true,
                onTap: () => _go(_AdminScreen.seatingEdit),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WideButton(
                label: '이 배치로 저장',
                onTap: () => _go(_AdminScreen.matchResult),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeatingEdit(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '자리 수동 편집',
          subtitle: 'A1 ↔ B3 변경됨',
          onBack: () => _go(_AdminScreen.seatingAuto),
          actionText: '수정',
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Icons.edit_outlined,
                color: AppColors.burgundy,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '편집 모드 · 자리를 탭하고 다른 자리를 탭하면 자동 교체됩니다.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.cocoa),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: const [
              Expanded(
                child: _SmallMetric(label: '기본 추천안', value: '84.2'),
              ),
              Expanded(
                child: _SmallMetric(label: '수정본', value: '82.6 -1.6'),
              ),
              Expanded(
                child: _SmallMetric(label: '변경', value: '1명'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _SeatingTable(
          title: 'A 테이블',
          tableName: 'TABLE A',
          editing: true,
        ),
        const SizedBox(height: 18),
        const _SeatingTable(
          title: 'B 테이블',
          tableName: 'TABLE B',
          flipped: true,
          editing: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WideButton(label: '초기화', muted: true, onTap: () {}),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WideButton(label: '다시추천', muted: true, onTap: () {}),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WideButton(
                label: '변경 저장',
                onTap: () => _go(_AdminScreen.matchResult),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchResult(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '매칭 결과',
          subtitle: '8기 종료 · 24분 전',
          onBack: () => _go(_AdminScreen.voting),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        AppCard(
          color: AppColors.burgundy,
          borderColor: AppColors.burgundy,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FINAL RESULT',
                style: TextStyle(
                  color: AppColors.butter,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '커플 3쌍',
                style: _displayStyle(context, 27).copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Expanded(
                    child: _DarkMetric(label: '상호 선택', value: '3'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _DarkMetric(label: '단방향', value: '4'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _DarkMetric(label: '회차 만족', value: '92%'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _SectionHeader(title: '상호 매칭', trailing: '3쌍 · 연락처 공개됨'),
        const SizedBox(height: 10),
        const _MatchPairCard(
          left: '티',
          right: '소',
          title: '티라미수↔소금빵',
          subtitle: '이지윤·박서준',
          score: '91',
        ),
        const SizedBox(height: 10),
        const _MatchPairCard(
          left: '에',
          right: '크',
          title: '에그타르트↔크루아상',
          subtitle: '최예린·김도현',
          score: '88',
        ),
        const SizedBox(height: 10),
        const _MatchPairCard(
          left: '마',
          right: '에',
          title: '마들렌↔에클레어',
          subtitle: '한소영·정민호',
          score: '79',
        ),
        const SizedBox(height: 20),
        const _SectionHeader(title: '단방향 선택', trailing: '4건 · 비공개'),
        const SizedBox(height: 10),
        const _OneWayRow(left: '단팥빵', right: '몽블랑'),
        const _OneWayRow(left: '에클레어', right: '티라미수'),
        const _OneWayRow(left: '크루아상', right: '마들렌'),
        const _OneWayRow(left: '소금빵', right: '에그타르트'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WideButton(label: '요약공유', muted: true, onTap: () {}),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WideButton(
                label: '케미 리포트 발송',
                onTap: () => _openReviewsFrom(_AdminScreen.matchResult),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviews(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '후기 관리',
          subtitle: '대기 3 · 승인 12 · 숨김 1',
          onBack: () => _go(_reviewsBackTarget),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _AdminChip(label: '대기 3', selected: true),
            _AdminChip(label: '승인 12'),
            _AdminChip(label: '보류 1'),
            _AdminChip(label: '숨김 1'),
          ],
        ),
        const SizedBox(height: 14),
        const _ReviewCard(
          initial: '몽',
          name: '몽블랑',
          badge: '커플 인증',
          text: '오븐 앞에서 시작된 대화가 카페까지 이어졌어요. 자연스러운 흐름이 좋았어요.',
          images: 2,
        ),
        const SizedBox(height: 12),
        const _ReviewCard(
          initial: '소',
          name: '소금빵',
          badge: '데이트 후기',
          text: '두 번째 만남에서 더 가까워졌어요. 진중한 분위라 편안했어요.',
        ),
        const SizedBox(height: 12),
        const _ReviewCard(
          initial: '에',
          name: '에그타르트',
          badge: '참여 후기',
          text: '베이킹이 어색함을 풀어줘서 좋았어요. 다음 회차도 신청할게요.',
          images: 2,
        ),
        const SizedBox(height: 12),
        const _ReviewCard(
          initial: '티',
          name: '티라미수',
          badge: '참여 후기',
          text: '운영자분들이 친절했어요. 첫인상과 최종 선택이 같아서 신기했어요.',
          approved: true,
        ),
      ],
    );
  }
}

class _AdminApplicantData {
  const _AdminApplicantData({
    required this.initial,
    required this.name,
    required this.gender,
    required this.age,
    required this.birth,
    required this.height,
    required this.mbti,
    required this.job,
    required this.character,
    required this.status,
    required this.score,
    required this.strictScore,
    required this.objectiveScore,
    required this.note,
    required this.selected,
  });

  final String initial;
  final String name;
  final String gender;
  final int age;
  final String birth;
  final String height;
  final String mbti;
  final String job;
  final String character;
  final String status;
  final int score;
  final int strictScore;
  final int objectiveScore;
  final String note;
  final bool selected;
}

const _adminApplicants = <_AdminApplicantData>[
  _AdminApplicantData(
    initial: '김',
    name: '김도현',
    gender: '남',
    age: 30,
    birth: '1996.02',
    height: '178cm',
    mbti: 'INFJ',
    job: 'IT/개발',
    character: '크루아상',
    status: '인증대기',
    score: 90,
    strictScore: 88,
    objectiveScore: 91,
    note: '차분한 대화와 안정적인 직군. 첫 만남 긴장은 낮은 편.',
    selected: true,
  ),
  _AdminApplicantData(
    initial: '박',
    name: '박서준',
    gender: '남',
    age: 32,
    birth: '1994.09',
    height: '175cm',
    mbti: 'ISTJ',
    job: '금융',
    character: '소금빵',
    status: '입금대기',
    score: 84,
    strictScore: 79,
    objectiveScore: 75,
    note: '성실하고 관계 속도를 천천히 가져가는 편.',
    selected: true,
  ),
  _AdminApplicantData(
    initial: '정',
    name: '정민호',
    gender: '남',
    age: 29,
    birth: '1997.01',
    height: '180cm',
    mbti: 'ENTP',
    job: '디자인',
    character: '단팥빵',
    status: '인증완료',
    score: 78,
    strictScore: 84,
    objectiveScore: 82,
    note: '대화 순발력이 좋고 활동형 취향이 강함.',
    selected: false,
  ),
  _AdminApplicantData(
    initial: '오',
    name: '오지훈',
    gender: '남',
    age: 28,
    birth: '1998.06',
    height: '172cm',
    mbti: 'ESFP',
    job: '서비스',
    character: '스콘',
    status: '인증완료',
    score: 70,
    strictScore: 76,
    objectiveScore: 73,
    note: '활발하지만 깊은 대화 지속성은 낮게 예측됨.',
    selected: false,
  ),
  _AdminApplicantData(
    initial: '이',
    name: '이지윤',
    gender: '여',
    age: 28,
    birth: '1998.04',
    height: '167cm',
    mbti: 'INFP',
    job: '디자인/콘텐츠',
    character: '티라미수',
    status: '인증완료',
    score: 89,
    strictScore: 88,
    objectiveScore: 91,
    note: '차분하고 감성이 깊어요. 대화 깊이와 같은 직장군 회피 권장.',
    selected: true,
  ),
  _AdminApplicantData(
    initial: '최',
    name: '최예린',
    gender: '여',
    age: 27,
    birth: '1999.03',
    height: '165cm',
    mbti: 'ENFP',
    job: '교육',
    character: '에그타르트',
    status: '인증완료',
    score: 84,
    strictScore: 83,
    objectiveScore: 86,
    note: '밝은 호응과 취향 대화가 자연스럽게 이어짐.',
    selected: true,
  ),
  _AdminApplicantData(
    initial: '한',
    name: '한소영',
    gender: '여',
    age: 30,
    birth: '1996.11',
    height: '163cm',
    mbti: 'ISFJ',
    job: '의료/보건',
    character: '마들렌',
    status: '보류',
    score: 77,
    strictScore: 81,
    objectiveScore: 79,
    note: '배려형이지만 선호 시간대가 회차와 살짝 어긋남.',
    selected: false,
  ),
  _AdminApplicantData(
    initial: '윤',
    name: '윤예진',
    gender: '여',
    age: 31,
    birth: '1995.08',
    height: '168cm',
    mbti: 'ENFJ',
    job: '공공기관',
    character: '푸딩',
    status: '신규',
    score: 66,
    strictScore: 72,
    objectiveScore: 70,
    note: '기본 조건은 좋지만 응답 데이터가 아직 부족함.',
    selected: false,
  ),
];

class _StatData {
  const _StatData(this.label, this.value, this.caption);

  final String label;
  final String value;
  final String caption;
}

class _NotificationData {
  const _NotificationData({
    required this.icon,
    required this.category,
    required this.title,
    required this.body,
    required this.time,
    this.urgent = false,
  });

  final IconData icon;
  final String category;
  final String title;
  final String body;
  final String time;
  final bool urgent;
}

TextStyle _displayStyle(BuildContext context, double size) {
  return Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: AppColors.wine,
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.15,
        letterSpacing: 0,
      ) ??
      TextStyle(
        color: AppColors.wine,
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.15,
      );
}

class _AdminBrandBar extends StatelessWidget {
  const _AdminBrandBar({
    required this.showAdmin,
    this.actionIcon,
    this.secondaryActionIcon,
    this.onAction,
  });

  final bool showAdmin;
  final IconData? actionIcon;
  final IconData? secondaryActionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showAdmin) ...[
          const _AdminTag(label: 'ADMIN'),
          const SizedBox(width: 8),
        ],
        Text(
          'ChemistryOven',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.wine,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (secondaryActionIcon != null) ...[
          _SquareIconButton(icon: secondaryActionIcon!, onTap: () {}),
          const SizedBox(width: 8),
        ],
        if (actionIcon != null)
          _SquareIconButton(icon: actionIcon!, onTap: onAction ?? () {}),
      ],
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
    this.actionIcon,
    this.actionText,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final IconData? actionIcon;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareIconButton(icon: Icons.chevron_left_rounded, onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.chocolate,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (actionText != null)
          Text(
            '$actionText⌄',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.burgundy,
              fontWeight: FontWeight.w800,
            ),
          )
        else if (actionIcon != null)
          _SquareIconButton(icon: actionIcon!, onTap: () {}),
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
          width: 36,
          height: 36,
          child: Icon(icon, color: AppColors.cocoa, size: 18),
        ),
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav({required this.selected, required this.onChanged});

  final _AdminTab selected;
  final ValueChanged<_AdminTab> onChanged;

  static const _tabs = [
    (_AdminTab.dash, Icons.home_outlined, Icons.home, '대시'),
    (
      _AdminTab.sessions,
      Icons.calendar_month_outlined,
      Icons.calendar_month,
      '회차',
    ),
    (_AdminTab.applicants, Icons.person_outline, Icons.person, '신청자'),
    (_AdminTab.matching, Icons.favorite_border_rounded, Icons.favorite, '매칭'),
    (_AdminTab.more, Icons.filter_alt_outlined, Icons.filter_alt, '더보기'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ivory,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: AppColors.wine.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (final tab in _tabs)
                Expanded(
                  child: InkWell(
                    onTap: () => onChanged(tab.$1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected == tab.$1 ? tab.$3 : tab.$2,
                          size: 22,
                          color: selected == tab.$1
                              ? AppColors.burgundy
                              : AppColors.mutedText,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.$4,
                          style: TextStyle(
                            color: selected == tab.$1
                                ? AppColors.burgundy
                                : AppColors.mutedText,
                            fontSize: 11,
                            fontWeight: selected == tab.$1
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
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

class _AdminMonogram extends StatelessWidget {
  const _AdminMonogram({required this.size, required this.label});

  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.burgundy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.butter,
          fontSize: size * 0.44,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TinyEyebrow extends StatelessWidget {
  const _TinyEyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.brandRed,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _AdminTag extends StatelessWidget {
  const _AdminTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.burgundy,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _AdminChip extends StatelessWidget {
  const _AdminChip({
    required this.label,
    this.selected = false,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 14,
        vertical: compact ? 6 : 9,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.burgundy : AppColors.ivory,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? AppColors.burgundy : AppColors.line,
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? Colors.white : AppColors.cocoa,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 11 : null,
          ),
        ),
      ),
    );
  }
}

class _HorizontalChipStrip extends StatelessWidget {
  const _HorizontalChipStrip({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            _AdminChip(label: labels[i], compact: true),
            if (i != labels.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _HorizontalSelectableChipStrip extends StatelessWidget {
  const _HorizontalSelectableChipStrip({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelected(i),
              child: _AdminChip(
                label: labels[i],
                selected: selectedIndex == i,
                compact: true,
              ),
            ),
            if (i != labels.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _AdminInput extends StatelessWidget {
  const _AdminInput({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: AppColors.burgundy),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
          ),
        ],
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: muted ? AppColors.ivory : AppColors.brandRed,
          foregroundColor: muted ? AppColors.burgundy : Colors.white,
          elevation: muted ? 0 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: muted ? AppColors.line : AppColors.brandRed,
            ),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.burgundy,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.cocoa,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing.isNotEmpty)
          Text(
            trailing,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.burgundy,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _AdminEventSummary extends StatelessWidget {
  const _AdminEventSummary({
    required this.title,
    required this.subtitle,
    required this.stats,
  });

  final String title;
  final String subtitle;
  final List<_StatData> stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.burgundy,
      borderColor: AppColors.burgundy,
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -12,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.butter.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'D-23 · 다음 회차',
                style: TextStyle(
                  color: AppColors.butter,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    Expanded(child: _AdminStat(stat: stats[i])),
                    if (i != stats.length - 1) const SizedBox(width: 10),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  const _AdminStat({required this.stat});

  final _StatData stat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.butter,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat.value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (stat.caption.isNotEmpty)
          Text(
            stat.caption,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 10,
            ),
          ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: active ? AppColors.burgundy : Colors.white,
      borderColor: active ? AppColors.burgundy : AppColors.line,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          Icon(
            icon,
            color: active ? Colors.white : AppColors.burgundy,
            size: 22,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: active ? Colors.white : AppColors.cocoa,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkMetric extends StatelessWidget {
  const _DarkMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.wine.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.butter,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentApplicantsCard extends StatelessWidget {
  const _RecentApplicantsCard({
    required this.onOpenAll,
    required this.onOpenApplicant,
  });

  final VoidCallback onOpenAll;
  final ValueChanged<_AdminApplicantData> onOpenApplicant;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: '최근 신청자', trailing: '전체 보기 ›'),
          const SizedBox(height: 10),
          for (final applicant in _adminApplicants.take(4)) ...[
            InkWell(
              onTap: () => onOpenApplicant(applicant),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    _ApplicantAvatar(applicant: applicant, size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${applicant.name} · ${applicant.age} · ${applicant.mbti}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.cocoa,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _StatusPill(label: applicant.status),
                  ],
                ),
              ),
            ),
            if (applicant != _adminApplicants.take(4).last)
              const _DividerLine(),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpenAll,
              child: const Text('신청자 목록'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final waiting = label.contains('대기');
    final openSoon = label.contains('오픈예정');
    final planning = label.contains('기획중');
    final closed = label.contains('종료');
    final Color backgroundColor;
    final Color textColor;

    if (openSoon) {
      backgroundColor = AppColors.butter;
      textColor = AppColors.warning;
    } else if (planning || closed) {
      backgroundColor = AppColors.line;
      textColor = AppColors.mutedText;
    } else if (waiting) {
      backgroundColor = AppColors.butter;
      textColor = AppColors.cocoa;
    } else {
      backgroundColor = AppColors.pistachio.withValues(alpha: 0.35);
      textColor = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ApplicantStatusBadge extends StatelessWidget {
  const _ApplicantStatusBadge({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('applicant-status-$label'),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.burgundy
            : AppColors.pistachio.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: selected ? Colors.white : AppColors.success,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, this.onTap});

  final _NotificationData item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.urgent ? AppColors.burgundy : AppColors.parchment,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: item.urgent ? AppColors.butter : AppColors.burgundy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      item.category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.burgundy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (item.urgent) const _AdminTag(label: '긴급'),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.cocoa,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.cocoa),
                ),
                const SizedBox(height: 6),
                Text(
                  item.time,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.burgundy,
              size: 22,
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionListCard extends StatelessWidget {
  const _SessionListCard({
    required this.number,
    required this.classData,
    required this.status,
    required this.onTap,
    this.active = false,
    this.empty = false,
  });

  final String number;
  final ChemistryClass classData;
  final String status;
  final VoidCallback onTap;
  final bool active;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: Colors.white,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 102,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: empty ? AppColors.ivory : AppColors.parchment,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: empty
                ? Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.mutedText.withValues(alpha: 0.65),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _StatusPill(label: status),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      for (final label in ['파블로바', '휘낭시에', '쿠키']) ...[
                        Expanded(child: _MenuThumb(label: label)),
                        const SizedBox(width: 8),
                      ],
                      _StatusPill(label: status),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.wine,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${classData.eventMonth}/${classData.eventDay} (토) 14:00',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.cocoa,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        classData.place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in classData.tags.take(3))
                            _AdminChip(label: tag, compact: true),
                        ],
                      ),
                    ],
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

class _SessionCoverStrip extends StatelessWidget {
  const _SessionCoverStrip();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.parchment,
      borderColor: AppColors.parchment,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        children: [
          Row(
            children: [
              for (final label in ['파블로바', '휘낭시에', '쿠키', '푸딩']) ...[
                Expanded(child: _MenuThumb(label: label)),
                if (label != '푸딩') const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.mutedText,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '4개 메뉴 · 12장',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuThumb extends StatelessWidget {
  const _MenuThumb({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.rose.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.article_outlined,
            color: AppColors.burgundy,
            size: 18,
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.burgundy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
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
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, color: AppColors.burgundy, size: 18),
          const SizedBox(width: 12),
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.cocoa,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.line);
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.title,
    required this.subtitle,
    this.done = false,
    this.active = false,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool active;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.burgundy
                  : active
                  ? AppColors.butter
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
            ),
            child: done
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.cocoa,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            _MiniButton(label: actionLabel!, onTap: onAction ?? () {}),
        ],
      ),
    );
  }
}

class _CountBox extends StatelessWidget {
  const _CountBox({
    required this.label,
    required this.count,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int count;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _AdminChip(label: label, compact: true),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$count',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(text: ' 명'),
                ],
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.cocoa),
            ),
          ),
          _SmallRoundButton(icon: Icons.remove, onTap: onMinus),
          const SizedBox(width: 6),
          _SmallRoundButton(icon: Icons.add, onTap: onPlus, active: true),
        ],
      ),
    );
  }
}

class _SmallRoundButton extends StatelessWidget {
  const _SmallRoundButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.burgundy : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            icon,
            color: active ? Colors.white : AppColors.cocoa,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _ApplicantListCard extends StatelessWidget {
  const _ApplicantListCard({required this.applicant, required this.onTap});

  final _AdminApplicantData applicant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _ApplicantAvatar(applicant: applicant, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        applicant.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.cocoa,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _GenderBadge(gender: applicant.gender),
                    const SizedBox(width: 4),
                    Text(
                      '${applicant.age}세 · ${applicant.height}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${applicant.mbti} · ${applicant.job} · ${applicant.character}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: applicant.score / 100,
                          minHeight: 4,
                          backgroundColor: AppColors.line,
                          color: AppColors.burgundy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${applicant.score}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.burgundy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
        ],
      ),
    );
  }
}

class _ApplicantAvatar extends StatelessWidget {
  const _ApplicantAvatar({required this.applicant, required this.size});

  final _AdminApplicantData applicant;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Text(
        applicant.initial,
        style: TextStyle(
          color: AppColors.burgundy,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _GenderBadge extends StatelessWidget {
  const _GenderBadge({required this.gender});

  final String gender;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        gender,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.burgundy,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.burgundy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateGroup extends StatelessWidget {
  const _CandidateGroup({required this.title, required this.applicants});

  final String title;
  final List<_AdminApplicantData> applicants;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, trailing: '17명 · 1 선정'),
        const SizedBox(height: 10),
        for (final applicant in applicants) ...[
          AppCard(
            color: Colors.white,
            borderColor: applicant.selected
                ? AppColors.burgundy
                : AppColors.line,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _ApplicantAvatar(applicant: applicant, size: 46),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${applicant.name} · ${applicant.age}-${applicant.height.replaceAll('cm', '')}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.cocoa,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${applicant.mbti} · 예상 평균 케미',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${applicant.score}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.burgundy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: applicant.selected
                        ? AppColors.burgundy
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: applicant.selected
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ComboCandidateCard extends StatelessWidget {
  const _ComboCandidateCard({
    required this.applicant,
    required this.score,
    this.best = false,
  });

  final _AdminApplicantData applicant;
  final int score;
  final bool best;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ApplicantAvatar(applicant: applicant, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            applicant.name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.cocoa,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        if (best) ...[
                          const SizedBox(width: 6),
                          const _AdminChip(label: 'BEST', compact: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${applicant.age} · ${applicant.mbti} · ${applicant.job}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$score',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: _ComboMetric(label: '1:1 케미', value: '91'),
                ),
                Expanded(
                  child: _ComboMetric(label: '대화 적합', value: '88'),
                ),
                Expanded(
                  child: _ComboMetric(label: '조합 시너지', value: '대화 깊이 ↑'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WideButton(label: '상세보기', muted: true, onTap: () {}),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WideButton(
                  label: best ? '최종 선정' : '추가하기',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PivotSelectedBadge extends StatelessWidget {
  const _PivotSelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      widthFactor: 1,
      heightFactor: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.burgundy,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '선정됨',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ComboMetric extends StatelessWidget {
  const _ComboMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.mutedText,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.burgundy,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.mutedText,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.wine,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brandRed,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.applicant,
    required this.paymentLabel,
    required this.attendLabel,
    this.waitingLabel,
  });

  final _AdminApplicantData applicant;
  final String paymentLabel;
  final String attendLabel;
  final String? waitingLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              _ApplicantAvatar(applicant: applicant, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${applicant.name} · ${applicant.character}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.cocoa,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _SoftStatePill(label: paymentLabel),
                        _SoftStatePill(
                          label: attendLabel,
                          warning: attendLabel.contains('미'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _SquareIconButton(icon: Icons.edit_outlined, onTap: () {}),
            ],
          ),
          if (waitingLabel != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                waitingLabel!,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoftStatePill extends StatelessWidget {
  const _SoftStatePill({required this.label, this.warning = false});

  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: warning
            ? AppColors.parchment
            : AppColors.pistachio.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: warning ? AppColors.warning : AppColors.success,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _CharacterAssignRow extends StatelessWidget {
  const _CharacterAssignRow({
    required this.applicant,
    required this.assigned,
    required this.locked,
  });

  final _AdminApplicantData applicant;
  final String assigned;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _ApplicantAvatar(applicant: applicant, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  applicant.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.cocoa,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '기본:${applicant.character}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: locked ? AppColors.burgundy : AppColors.blush,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${assigned.characters.first}  $assigned',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: locked ? Colors.white : AppColors.burgundy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  locked ? Icons.lock_outline : Icons.lock_open_outlined,
                  size: 13,
                  color: locked ? AppColors.butter : AppColors.burgundy,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SquareIconButton(icon: Icons.edit_outlined, onTap: () {}),
        ],
      ),
    );
  }
}

class _RoundStatusCard extends StatelessWidget {
  const _RoundStatusCard({
    required this.number,
    required this.title,
    required this.subtitle,
    this.progress = 0,
    this.active = false,
  });

  final String number;
  final String title;
  final String subtitle;
  final double progress;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      borderColor: active ? AppColors.burgundy : AppColors.line,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.burgundy : AppColors.parchment,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: active ? Colors.white : AppColors.burgundy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.cocoa,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
                ),
                if (active) ...[
                  const SizedBox(height: 9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      color: AppColors.burgundy,
                      backgroundColor: AppColors.line,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _MiniButton(label: active ? '닫기' : '열기', onTap: () {}),
        ],
      ),
    );
  }
}

class _SeatingTable extends StatelessWidget {
  const _SeatingTable({
    required this.title,
    required this.tableName,
    this.flipped = false,
    this.editing = false,
  });

  final String title;
  final String tableName;
  final bool flipped;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final top = flipped
        ? const [('예', '에클레어', '정민호', 'B1'), ('마', '마들렌', '한소영', 'B2')]
        : const [('크', '크루아상', '김도현', 'A1'), ('티', '티라미수', '이지윤', 'A2')];
    final bottom = flipped
        ? const [('크', '크루아상', '김도현', 'B3'), ('몽', '몽블랑', '윤예진', 'B4')]
        : const [('소', '소금빵', '박서준', 'A3'), ('에', '에그타르트', '최예린', 'A4')];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, trailing: '베이킹 · 4인'),
        const SizedBox(height: 8),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < top.length; i++)
                    _SeatPerson(
                      initial: top[i].$1,
                      character: top[i].$2,
                      name: top[i].$3,
                      seat: top[i].$4,
                      selected: editing && i == 0,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 74,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      size: 18,
                      color: AppColors.burgundy,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tableName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.burgundy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < bottom.length; i++)
                    _SeatPerson(
                      initial: bottom[i].$1,
                      character: bottom[i].$2,
                      name: bottom[i].$3,
                      seat: bottom[i].$4,
                      selected: editing && flipped && i == 0,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeatPerson extends StatelessWidget {
  const _SeatPerson({
    required this.initial,
    required this.character,
    required this.name,
    required this.seat,
    this.selected = false,
  });

  final String initial;
  final String character;
  final String name;
  final String seat;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.burgundy : AppColors.parchment,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.gold : AppColors.line,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  initial,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: selected ? AppColors.butter : AppColors.burgundy,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                right: -4,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    seat,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.cocoa,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  right: -7,
                  bottom: -5,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.butter,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 11,
                      color: AppColors.burgundy,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            character,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.cocoa,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedText,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchPairCard extends StatelessWidget {
  const _MatchPairCard({
    required this.left,
    required this.right,
    required this.title,
    required this.subtitle,
    required this.score,
  });

  final String left;
  final String right;
  final String title;
  final String subtitle;
  final String score;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _TinyAvatar(label: left),
          const SizedBox(width: 5),
          const Icon(
            Icons.favorite_border_rounded,
            color: AppColors.burgundy,
            size: 15,
          ),
          const SizedBox(width: 5),
          _TinyAvatar(label: right),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.cocoa,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          Text(
            score,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.burgundy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '케미',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedText,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyAvatar extends StatelessWidget {
  const _TinyAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.burgundy,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _OneWayRow extends StatelessWidget {
  const _OneWayRow({required this.left, required this.right});

  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                left,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.cocoa,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
            Expanded(
              child: Text(
                right,
                textAlign: TextAlign.right,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '비공개',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.mutedText,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.initial,
    required this.name,
    required this.badge,
    required this.text,
    this.images = 0,
    this.approved = false,
  });

  final String initial;
  final String name;
  final String badge;
  final String text;
  final int images;
  final bool approved;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TinyAvatar(label: initial),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name · 7기',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.cocoa,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '5/20 09:42 작성',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              _SoftStatePill(label: badge, warning: !approved),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cocoa,
              height: 1.45,
            ),
          ),
          if (images > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < images; i++) ...[
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.parchment,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 18,
                      color: AppColors.burgundy,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (approved)
            Row(
              children: [
                const _SoftStatePill(label: '승인됨'),
                const Spacer(),
                _MiniButton(label: '대표 후기 지정', onTap: () {}),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _WideButton(label: '숨김', muted: true, onTap: () {}),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _WideButton(label: '보류', muted: true, onTap: () {}),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _WideButton(label: '승인', onTap: () {}),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
