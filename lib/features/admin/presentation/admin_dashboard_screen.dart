import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/chemistry_session.dart';
import '../../../data/models/demo_models.dart';
import '../../../data/repositories/application_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../services/firebase_service.dart';
import '../../../services/functions_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/user_service.dart';
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
  int _applicantTab = 0;
  int _selectionPoolMode = 0;
  _AdminScreen _reviewsBackTarget = _AdminScreen.matchResult;
  int _menCount = 4;
  int _womenCount = 4;
  bool _rememberAdminLogin = true;

  // 회차 생성 폼 입력
  final TextEditingController _sessionTitleCtrl = TextEditingController();
  final TextEditingController _sessionDateCtrl = TextEditingController();
  final TextEditingController _sessionTimeCtrl = TextEditingController();
  final TextEditingController _sessionPlaceCtrl = TextEditingController();
  final TextEditingController _sessionPriceCtrl = TextEditingController();
  final TextEditingController _sessionMenuCtrl = TextEditingController();
  bool _publishingSession = false;
  String? _selectedSessionId;
  bool _closingSession = false;
  List<_AdminApplicantData> _realApplicants = [];
  bool _loadingApplicants = false;
  bool _verifyingJob = false;
  bool _writingStatus = false;
  bool _scoringSession = false;
  bool _uploadingCover = false;
  Map<String, _SeatAssignment> _seatAssignments = Map.of(
    _initialSeatAssignments,
  );
  String? _selectedSeatId = 'A1';
  String? _lastSeatSwap;
  int _seatSwapCount = 0;

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
                  child: _screen == _AdminScreen.login
                      ? KeyedSubtree(
                          key: ValueKey(_screen),
                          child: _buildScreen(context, appState),
                        )
                      : ListView(
                          key: ValueKey(_screen),
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
        return _buildSessionList(
          context,
          appState.sessionsController.sessions
              .map((s) => s.toDisplayClass())
              .toList(),
        );
      case _AdminScreen.sessionDetail:
        return _buildSessionDetail(
          context,
          _resolveSelectedClass(appState),
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
    if (screen == _AdminScreen.applicants) {
      _loadApplicants();
    }
  }

  /// D2 — 선택된 회차의 실제 신청자 목록을 Firestore 에서 불러와
  /// 표시용 [_AdminApplicantData] 로 변환.
  Future<void> _loadApplicants() async {
    final sessionId = _selectedSessionId;
    if (sessionId == null) {
      setState(() => _realApplicants = []);
      return;
    }
    setState(() => _loadingApplicants = true);
    try {
      final items = await ApplicationRepository.instance
          .fetchSessionApplicants(sessionId);
      final mapped = items.map(_mapApplicant).toList();
      if (!mounted) return;
      setState(() => _realApplicants = mapped);
    } catch (e) {
      debugPrint('[applicants-load] $e');
      if (!mounted) return;
      setState(() => _realApplicants = []);
    } finally {
      if (mounted) {
        setState(() => _loadingApplicants = false);
      }
    }
  }

  _AdminApplicantData _mapApplicant(Map<String, dynamic> item) {
    final user = (item['user'] as Map?) ?? const {};
    final name =
        (item['displayName'] as String?) ??
        (user['realName'] as String?) ??
        '신청자';
    final initial = name.isNotEmpty ? name.substring(0, 1) : '?';
    final genderRaw =
        (item['gender'] as String?) ?? (user['gender'] as String?);
    final gender = genderRaw == 'M' ? '남' : '여';
    final mbti = (user['mbti'] as String?) ?? '-';
    final heightRaw = user['height'];
    final height = heightRaw != null ? '${heightRaw}cm' : '-';
    final birth = (user['birth'] as String?) ?? '-';
    int age = 0;
    if (birth.length >= 4) {
      final year = int.tryParse(birth.substring(0, 4));
      if (year != null) {
        age = DateTime.now().year - year;
      }
    }
    final job = (user['region'] as String?) ?? '-';
    final character = (item['baseCharacterId'] as String?) ?? '-';
    final statusRaw = (item['status'] as String?) ?? 'applied';
    final status = switch (statusRaw) {
      'selected' => '선정',
      'held' => '보류',
      'rejected' => '탈락',
      _ => '신청',
    };
    final verification = (user['verification'] as Map?) ?? const {};
    final verificationJob = (verification['job'] as String?) ?? 'none';
    return _AdminApplicantData(
      uid: (item['uid'] as String?) ?? '',
      initial: initial,
      name: name,
      gender: gender,
      age: age,
      birth: birth,
      height: height,
      mbti: mbti,
      job: job,
      character: character,
      status: status,
      score: (item['totalScore'] as num?)?.toInt() ?? 0,
      strictScore: (item['strictScore'] as num?)?.toInt() ?? 0,
      objectiveScore: (item['psychologyScore'] as num?)?.toInt() ?? 0,
      note: '',
      selected: statusRaw == 'selected',
      verificationJob: verificationJob,
    );
  }

  /// D4 — 신청 상태 쓰기(탈락/보류/선정) 후 새로고침 + 목록으로 복귀.
  Future<void> _writeApplicantStatus(
    _AdminApplicantData applicant,
    String status,
  ) async {
    final sessionId = _selectedSessionId;
    if (_writingStatus || applicant.uid.isEmpty || sessionId == null) return;
    setState(() => _writingStatus = true);
    final messenger = ScaffoldMessenger.of(context);
    final label = switch (status) {
      'selected' => '선정',
      'held' => '보류',
      'rejected' => '탈락',
      _ => '변경',
    };
    try {
      await ApplicationRepository.instance.updateStatus(
        sessionId,
        applicant.uid,
        status,
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('$label 처리했어요')));
      _go(_AdminScreen.applicants);
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('처리에 실패했어요. 잠시 후 다시 시도해 주세요')),
      );
      debugPrint('[applicant-status] $e');
    } finally {
      if (mounted) {
        setState(() => _writingStatus = false);
      }
    }
  }

  /// D5 — 직장 인증 승인/반려 후 새로고침.
  Future<void> _setJobVerification(
    _AdminApplicantData applicant,
    String status,
  ) async {
    if (_verifyingJob || applicant.uid.isEmpty) return;
    setState(() => _verifyingJob = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await UserService.instance.setJobVerificationStatus(
        applicant.uid,
        status,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(status == 'approved' ? '직장 인증을 승인했어요' : '직장 인증을 반려했어요'),
        ),
      );
      await _loadApplicants();
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('처리에 실패했어요. 잠시 후 다시 시도해 주세요')),
      );
      debugPrint('[job-verify] $e');
    } finally {
      if (mounted) {
        setState(() => _verifyingJob = false);
      }
    }
  }

  String _jobVerificationLabel(String status) {
    return switch (status) {
      'pending' => '대기',
      'approved' => '승인됨',
      'rejected' => '반려됨',
      _ => '미제출',
    };
  }

  @override
  void dispose() {
    _sessionTitleCtrl.dispose();
    _sessionDateCtrl.dispose();
    _sessionTimeCtrl.dispose();
    _sessionPlaceCtrl.dispose();
    _sessionPriceCtrl.dispose();
    _sessionMenuCtrl.dispose();
    super.dispose();
  }

  /// 선택된 회차 id 로 실제 회차를 찾아 표시용 클래스로 변환.
  /// 선택이 없거나 못 찾으면 데모 대표 회차로 폴백.
  ChemistryClass _resolveSelectedClass(AppState appState) {
    final sessions = appState.sessionsController.sessions;
    final id = _selectedSessionId;
    if (id != null) {
      for (final session in sessions) {
        if (session.id == id) {
          return session.toDisplayClass();
        }
      }
    }
    return appState.repository.fetchFeaturedClass();
  }

  /// 회차 게시 → Firestore sessions 에 생성.
  /// [status] 가 'draft' 면 임시저장, 기본은 모집중('recruiting').
  Future<void> _publishSession({String status = 'recruiting'}) async {
    final title = _sessionTitleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회차명을 입력해 주세요')),
      );
      return;
    }
    setState(() => _publishingSession = true);
    final messenger = ScaffoldMessenger.of(context);
    final isDraft = status == 'draft';
    try {
      final session = ChemistrySession(
        id: '',
        title: title,
        dateText: _sessionDateCtrl.text.trim(),
        timeText: _sessionTimeCtrl.text.trim(),
        location: _sessionPlaceCtrl.text.trim(),
        priceText: _sessionPriceCtrl.text.trim(),
        recruitMale: _menCount,
        recruitFemale: _womenCount,
        menuName: _sessionMenuCtrl.text.trim(),
        status: status,
        createdBy: FirebaseService.instance.uid,
      );
      await SessionRepository.instance.createSession(session);
      if (!mounted) return;
      _clearSessionForm();
      messenger.showSnackBar(
        SnackBar(content: Text(isDraft ? '임시저장했어요' : '회차가 게시됐어요')),
      );
      _go(_AdminScreen.sessions);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isDraft ? '임시저장에 실패했어요. 잠시 후 다시 시도해 주세요' : '게시에 실패했어요. 운영자 권한을 확인해 주세요',
          ),
        ),
      );
      debugPrint('[session-create] $error');
    } finally {
      if (mounted) {
        setState(() => _publishingSession = false);
      }
    }
  }

  /// C2 — 회차 마감 (status='closed').
  Future<void> _closeSession(ChemistryClass classData) async {
    if (_closingSession) return;
    setState(() => _closingSession = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SessionRepository.instance.updateStatus(classData.id, 'closed');
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('회차를 마감했어요')),
      );
      _go(_AdminScreen.sessions);
    } catch (error) {
      messenger.showSnackBar(
        const SnackBar(content: Text('마감에 실패했어요. 잠시 후 다시 시도해 주세요')),
      );
      debugPrint('[session-close] $error');
    } finally {
      if (mounted) {
        setState(() => _closingSession = false);
      }
    }
  }

  /// C4 — AI 점수계산 (배포된 Cloud Function 호출).
  Future<void> _runChemistryScoring(ChemistryClass classData) async {
    if (_scoringSession) return;
    setState(() => _scoringSession = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await FunctionsService.instance.computeChemistryScores(
        classData.id,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '점수 계산 완료 · 테이블 ${(res['tables'] as List?)?.length ?? 0}개',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('점수 계산에 실패했어요. 잠시 후 다시 시도해 주세요')),
      );
      debugPrint('[scoring] $e');
    } finally {
      if (mounted) setState(() => _scoringSession = false);
    }
  }

  /// C5 — 세션 커버 이미지 업로드 (선택 → 업로드 → 문서 갱신).
  Future<void> _uploadSessionCover(String sessionId) async {
    if (_uploadingCover) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await StorageService.instance.pickImage();
      if (file == null) return;
      if (!mounted) return;
      setState(() => _uploadingCover = true);
      final url = await StorageService.instance.uploadSessionCover(
        sessionId,
        file,
      );
      await SessionRepository.instance.updateCover(sessionId, url);
      messenger.showSnackBar(
        const SnackBar(content: Text('커버 이미지를 등록했어요')),
      );
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('커버 등록에 실패했어요. 잠시 후 다시 시도해 주세요')),
      );
      debugPrint('[cover-upload] $e');
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  void _clearSessionForm() {
    _sessionTitleCtrl.clear();
    _sessionDateCtrl.clear();
    _sessionTimeCtrl.clear();
    _sessionPlaceCtrl.clear();
    _sessionPriceCtrl.clear();
    _sessionMenuCtrl.clear();
  }

  String get _seatingEditSubtitle {
    if (_lastSeatSwap != null) {
      return '$_lastSeatSwap 변경됨';
    }
    return '${_selectedSeatId ?? '자리'} 선택됨';
  }

  String get _seatingEditScore => _seatSwapCount == 0 ? '84.2' : '82.6 -1.6';

  void _handleSeatTap(String seatId) {
    final selectedSeatId = _selectedSeatId;
    if (selectedSeatId == null || selectedSeatId == seatId) {
      setState(() => _selectedSeatId = seatId);
      return;
    }

    setState(() {
      final updated = Map<String, _SeatAssignment>.of(_seatAssignments);
      final selectedAssignment = updated[selectedSeatId]!;
      updated[selectedSeatId] = updated[seatId]!;
      updated[seatId] = selectedAssignment;
      _seatAssignments = updated;
      _selectedSeatId = seatId;
      _lastSeatSwap = '$selectedSeatId ↔ $seatId';
      _seatSwapCount += 1;
    });
  }

  void _resetSeatAssignments() {
    setState(() {
      _seatAssignments = Map.of(_initialSeatAssignments);
      _selectedSeatId = 'A1';
      _lastSeatSwap = null;
      _seatSwapCount = 0;
    });
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
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AdminMonogram(
                size: 64,
                label: 'C',
                gradient: true,
                radius: 20,
              ),
              const SizedBox(height: 24),
              const _TinyEyebrow('ADMIN · v1.1'),
              const SizedBox(height: 8),
              Text('오늘의 회차를\n준비할 시간이에요.', style: _displayStyle(context, 32)),
              const SizedBox(height: 40),
              const _AdminInput(label: '운영자 이메일', value: 'admin@example.com'),
              const SizedBox(height: 12),
              const _AdminInput(
                label: '비밀번호',
                value: '••••••••••',
                obscure: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _rememberAdminLogin,
                    onChanged: (value) =>
                        setState(() => _rememberAdminLogin = value ?? true),
                    activeColor: AppColors.burgundy,
                    checkColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(color: AppColors.line, width: 1.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이 기기에서 자동 로그인',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.cocoa,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '비밀번호 찾기',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.burgundy,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.cream.withValues(alpha: 0.96),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
              child: Column(
                children: [
                  _WideButton(
                    label: '로그인',
                    onTap: () => _go(_AdminScreen.dashboard),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '운영자 계정 문의 · admin@chemistry-oven.kr',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
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
              _applicantTab = 0;
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
        _HorizontalChipStrip(
          labels: ['전체 ${classes.length}'],
          selectedIndex: 0,
        ),
        const SizedBox(height: 14),
        if (classes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                '아직 등록된 회차가 없어요. 새 회차를 만들어 보세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ),
          )
        else
          for (var i = 0; i < classes.length; i++) ...[
            _SessionListCard(
              number: '${i + 1}기',
              classData: classes[i],
              status: classes[i].statusLabel,
              active: i == 0,
              onTap: () {
                setState(() => _selectedSessionId = classes[i].id);
                _go(_AdminScreen.sessionDetail);
              },
            ),
            if (i != classes.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildSessionDetail(BuildContext context, ChemistryClass classData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '${classData.title} 상세',
          subtitle: classData.statusLabel,
          onBack: () => _go(_AdminScreen.sessions),
          actionIcon: Icons.edit_outlined,
        ),
        const SizedBox(height: 14),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _uploadingCover
              ? null
              : () => _uploadSessionCover(classData.id),
          child: Stack(
            children: [
              const _SessionCoverStrip(),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.burgundy,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _uploadingCover ? '업로드 중...' : '커버 변경',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _InfoLine(
                icon: Icons.calendar_month_outlined,
                label: '일시',
                value: '${classData.dateText} ${classData.timeText}',
              ),
              const _DividerLine(),
              _InfoLine(
                icon: Icons.place_outlined,
                label: '장소',
                value: classData.place,
              ),
              const _DividerLine(),
              _InfoLine(
                icon: Icons.person_outline_rounded,
                label: '모집',
                value: classData.capacityLabel,
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
        _WideButton(
          label: _scoringSession ? '계산 중...' : 'AI 인원 선정 · 점수 계산',
          onTap: () {
            if (!_scoringSession) {
              _runChemistryScoring(classData);
            }
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _WideButton(label: '공지복제', muted: true, onTap: () {}),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WideButton(
                label: _closingSession ? '마감 중...' : '회차마감',
                onTap: () {
                  if (!_closingSession) {
                    _closeSession(classData);
                  }
                },
              ),
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
        _AdminInput(label: '회차 (예: 케미스트리오븐 9기)', controller: _sessionTitleCtrl),
        const SizedBox(height: 10),
        _AdminInput(
          label: '일시 (예: 2026-07-12)',
          icon: Icons.calendar_month_outlined,
          controller: _sessionDateCtrl,
        ),
        const SizedBox(height: 10),
        _AdminInput(
          label: '시간 (예: 오후 2시)',
          icon: Icons.access_time_outlined,
          controller: _sessionTimeCtrl,
        ),
        const SizedBox(height: 10),
        _AdminInput(
          label: '장소',
          icon: Icons.place_outlined,
          controller: _sessionPlaceCtrl,
        ),
        const SizedBox(height: 10),
        _AdminInput(
          label: '참가비',
          icon: Icons.payments_outlined,
          controller: _sessionPriceCtrl,
        ),
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
        _AdminInput(
          label: '메뉴명 (예: 마들렌 · 휘낭시에)',
          icon: Icons.local_dining_outlined,
          controller: _sessionMenuCtrl,
        ),
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
              child: _WideButton(
                label: '임시저장',
                muted: true,
                onTap: () {
                  if (!_publishingSession) {
                    _publishSession(status: 'draft');
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WideButton(
                label: _publishingSession ? '게시 중...' : '회차 게시',
                onTap: () {
                  if (!_publishingSession) {
                    _publishSession(status: 'recruiting');
                  }
                },
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
        if (_selectedSessionId == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                '회차를 먼저 선택해 주세요.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ),
          )
        else if (_loadingApplicants)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (applicants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                '아직 신청자가 없어요.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ),
          )
        else
          for (final applicant in applicants) ...[
            _ApplicantListCard(
              applicant: applicant,
              onTap: () {
                setState(() {
                  _selectedApplicant = applicant;
                  _applicantTab = 0;
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
    final applicants = [..._realApplicants];
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
        if (applicant.uid.isNotEmpty) ...[
          const SizedBox(height: 14),
          AppCard(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '직장 인증',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.cocoa,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _jobVerificationLabel(applicant.verificationJob),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _WideButton(
                        label: '인증 승인',
                        onTap: () =>
                            _setJobVerification(applicant, 'approved'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _WideButton(
                        label: '반려',
                        muted: true,
                        onTap: () =>
                            _setJobVerification(applicant, 'rejected'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AdminChip(
                label: '프로필',
                selected: _applicantTab == 0,
                onTap: () => setState(() => _applicantTab = 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdminChip(
                label: '선호 조건',
                selected: _applicantTab == 1,
                onTap: () => setState(() => _applicantTab = 1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AdminChip(
                label: '답변',
                selected: _applicantTab == 2,
                onTap: () => setState(() => _applicantTab = 2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_applicantTab == 0) ..._applicantProfilePanel(context, applicant),
        if (_applicantTab == 1) ..._applicantPrefPanel(context),
        if (_applicantTab == 2) ..._applicantAnswerPanel(context),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WideButton(
                label: '탈락',
                muted: true,
                onTap: () {
                  if (applicant.uid.isNotEmpty &&
                      _selectedSessionId != null) {
                    _writeApplicantStatus(applicant, 'rejected');
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WideButton(
                label: '보류',
                muted: true,
                onTap: () {
                  if (applicant.uid.isNotEmpty &&
                      _selectedSessionId != null) {
                    _writeApplicantStatus(applicant, 'held');
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WideButton(
                label: '선정',
                onTap: () {
                  if (applicant.uid.isNotEmpty &&
                      _selectedSessionId != null) {
                    _writeApplicantStatus(applicant, 'selected');
                  } else {
                    _go(_AdminScreen.selectionPool);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _applicantProfilePanel(
    BuildContext context,
    _AdminApplicantData applicant,
  ) {
    return [
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
              value: '010-****-0000',
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
    ];
  }

  List<Widget> _applicantPrefPanel(BuildContext context) {
    return [
      _PanelNote(
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              height: 1.55,
              fontSize: 11.5,
            ),
            children: const [
              TextSpan(
                text: 'STRICT 조건',
                style: TextStyle(
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text:
                    ' · 신청자가 직접 입력한 선호값이에요. 흡연·주량·기피직군·나이 불충족 시 '
                    '하드 필터링(매칭 제외) 대상이 돼요. 상대에게는 공개되지 않아요.',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      AppCard(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            _InfoLine(
              icon: Icons.person_outline,
              label: '선호 나이대',
              value: '30 ~ 36세',
            ),
            _DividerLine(),
            _InfoLine(
              icon: Icons.straighten_outlined,
              label: '이상형 키',
              value: '175cm 이상',
            ),
            _DividerLine(),
            _InfoLine(
              icon: Icons.auto_awesome_outlined,
              label: '선호 MBTI',
              value: 'ENFP · ENTJ · ESTP',
            ),
            _DividerLine(),
            _InfoLine(
              icon: Icons.favorite_border_rounded,
              label: '선호 종교',
              value: '무교 · 상관없음',
            ),
            _DividerLine(),
            _InfoLine(
              icon: Icons.shield_outlined,
              label: '기피 직군',
              value: '같은 직군(디자인)',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(
            child: _PrefMatchBox(label: '선호 나이대', value: '충족', tone: 0),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _PrefMatchBox(label: '이상형 키', value: '충족', tone: 0),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(
            child: _PrefMatchBox(label: '선호 MBTI', value: '부분 충족', tone: 1),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _PrefMatchBox(label: '기피 직군', value: '회피 필요', tone: 2),
          ),
        ],
      ),
    ];
  }

  List<Widget> _applicantAnswerPanel(BuildContext context) {
    return [
      _PanelNote(
        child: Text(
          '온보딩 설문에서 신청자가 고른 답변 원본이에요. '
          'PSYCHOLOGY 점수(궁합·가치관·취향·베이킹 리듬) 산출에 사용돼요.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
            height: 1.55,
            fontSize: 11.5,
          ),
        ),
      ),
      const SizedBox(height: 12),
      const _AnswerBlock(
        title: '일상 리듬',
        chips: ['저녁형', '주 2~3회 운동', '집·카페 선호'],
      ),
      const _AnswerBlock(
        title: '취향 케미',
        chips: ['전시·미술관', '플레이리스트 공유', '여행 계획형', '글쓰기'],
      ),
      const _AnswerBlock(
        title: '참여 가능 시간대',
        chips: ['토요일 오후', '일요일 오후'],
      ),
      const _AnswerBlock(
        title: '디저트 · 주량 · 흡연',
        chips: ['까눌레·휘낭시에', '와인 1~2잔', '비흡연'],
      ),
      const _AnswerBlock(
        title: '호감 포인트',
        chips: ['대화의 결', '취향 존중', '말투의 다정함'],
      ),
      const _AnswerBlock(
        title: '불편하게 느끼는 요소',
        chips: ['소비 성향이 너무 다른 것', '예의 없는 말투'],
        warn: true,
      ),
      const _AnswerBlock(
        title: '나와 잘 맞을 것 같은 사람',
        chips: ['웃음 코드가 맞는', '나와 다른 성향'],
      ),
    ];
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
                      '단팥빵 · 지원자 D\n22분 · 22초 경과',
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
        _SeatingTable(
          title: 'A 테이블',
          tableName: 'TABLE A',
          assignments: _seatAssignments,
        ),
        const SizedBox(height: 18),
        _SeatingTable(
          title: 'B 테이블',
          tableName: 'TABLE B',
          flipped: true,
          assignments: _seatAssignments,
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
          subtitle: _seatingEditSubtitle,
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
            children: [
              const Expanded(
                child: _SmallMetric(label: '기본 추천안', value: '84.2'),
              ),
              Expanded(
                child: _SmallMetric(label: '수정본', value: _seatingEditScore),
              ),
              Expanded(
                child: _SmallMetric(label: '변경', value: '$_seatSwapCount명'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _SeatingTable(
          title: 'A 테이블',
          tableName: 'TABLE A',
          assignments: _seatAssignments,
          selectedSeatId: _selectedSeatId,
          editing: true,
          onSeatTap: _handleSeatTap,
        ),
        const SizedBox(height: 18),
        _SeatingTable(
          title: 'B 테이블',
          tableName: 'TABLE B',
          flipped: true,
          assignments: _seatAssignments,
          selectedSeatId: _selectedSeatId,
          editing: true,
          onSeatTap: _handleSeatTap,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _WideButton(
                label: '초기화',
                muted: true,
                onTap: _resetSeatAssignments,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _WideButton(
                label: '다시추천',
                muted: true,
                onTap: _resetSeatAssignments,
              ),
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
          subtitle: '지원자 E·지원자 B',
          score: '91',
        ),
        const SizedBox(height: 10),
        const _MatchPairCard(
          left: '에',
          right: '크',
          title: '에그타르트↔크루아상',
          subtitle: '지원자 F·지원자 A',
          score: '88',
        ),
        const SizedBox(height: 10),
        const _MatchPairCard(
          left: '마',
          right: '에',
          title: '마들렌↔에클레어',
          subtitle: '지원자 G·지원자 C',
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
    this.uid = '',
    this.verificationJob = 'none',
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
  final String uid;
  final String verificationJob;
}

class _SeatAssignment {
  const _SeatAssignment({
    required this.initial,
    required this.character,
    required this.name,
  });

  final String initial;
  final String character;
  final String name;
}

const _initialSeatAssignments = <String, _SeatAssignment>{
  'A1': _SeatAssignment(initial: '크', character: '크루아상', name: '지원자 A'),
  'A2': _SeatAssignment(initial: '티', character: '티라미수', name: '지원자 E'),
  'A3': _SeatAssignment(initial: '소', character: '소금빵', name: '지원자 B'),
  'A4': _SeatAssignment(initial: '에', character: '에그타르트', name: '지원자 F'),
  'B1': _SeatAssignment(initial: '예', character: '에클레어', name: '지원자 C'),
  'B2': _SeatAssignment(initial: '마', character: '마들렌', name: '지원자 G'),
  'B3': _SeatAssignment(initial: '단', character: '단팥빵', name: '지원자 D'),
  'B4': _SeatAssignment(initial: '몽', character: '몽블랑', name: '지원자 H'),
};

const _adminApplicants = <_AdminApplicantData>[
  _AdminApplicantData(
    initial: 'A',
    name: '지원자 A',
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
    initial: 'B',
    name: '지원자 B',
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
    initial: 'C',
    name: '지원자 C',
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
    initial: 'D',
    name: '지원자 D',
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
    initial: 'E',
    name: '지원자 E',
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
    initial: 'F',
    name: '지원자 F',
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
    initial: 'G',
    name: '지원자 G',
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
    initial: 'H',
    name: '지원자 H',
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
          'Chemistry Oven',
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
        borderRadius: BorderRadius.circular(12),
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
  const _AdminMonogram({
    required this.size,
    required this.label,
    this.gradient = false,
    this.radius = 14,
  });

  final double size;
  final String label;
  final bool gradient;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: gradient ? null : AppColors.burgundy,
        gradient: gradient
            ? const LinearGradient(
                colors: [AppColors.wine, AppColors.burgundy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
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
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = _buildChip(context);
    if (onTap == null) return chip;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: chip,
    );
  }

  Widget _buildChip(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 7 : 10,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.burgundy : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? AppColors.burgundy : AppColors.line,
          width: 1.5,
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
            fontWeight: FontWeight.w700,
            fontSize: compact ? 12 : 13,
          ),
        ),
      ),
    );
  }
}

class _PanelNote extends StatelessWidget {
  const _PanelNote({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

class _PrefMatchBox extends StatelessWidget {
  const _PrefMatchBox({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;

  /// 0 = 충족(green), 1 = 부분 충족(neutral), 2 = 경고(orange)
  final int tone;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (tone) {
      case 0:
        bg = const Color(0xFFE3F1E7);
        fg = AppColors.success;
        break;
      case 2:
        bg = const Color(0xFFF8E7D6);
        fg = AppColors.warning;
        break;
      default:
        bg = AppColors.ivory;
        fg = AppColors.mutedText;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({
    required this.title,
    required this.chips,
    this.warn = false,
  });

  final String title;
  final List<String> chips;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final chip in chips)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: warn ? const Color(0xFFF8E7D6) : AppColors.ivory,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: warn ? const Color(0xFFE7C9AE) : AppColors.line,
                    ),
                  ),
                  child: Text(
                    chip,
                    style: TextStyle(
                      color: warn ? AppColors.warning : AppColors.cocoa,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
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

class _HorizontalChipStrip extends StatelessWidget {
  const _HorizontalChipStrip({required this.labels, this.selectedIndex});

  final List<String> labels;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            _AdminChip(
              label: labels[i],
              selected: selectedIndex == i,
              compact: true,
            ),
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
  const _AdminInput({
    required this.label,
    this.icon,
    this.value,
    this.obscure = false,
    this.controller,
  });

  final String label;
  final IconData? icon;
  final String? value;
  final bool obscure;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final displayValue = value;

    // 입력 컨트롤러가 있으면 실제 TextField로 렌더
    if (controller != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.cocoa,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: label,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
            icon: icon == null
                ? null
                : Icon(icon, size: 17, color: AppColors.burgundy),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: displayValue == null ? 50 : 66),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: displayValue == null ? 0 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: displayValue == null
          ? Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: AppColors.burgundy),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayValue,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.cocoa,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: obscure ? 1.6 : 0,
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
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: muted ? AppColors.ivory : AppColors.burgundy,
          foregroundColor: muted ? AppColors.burgundy : Colors.white,
          elevation: muted ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: muted ? AppColors.line : AppColors.burgundy,
            ),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(
        height: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Align(
            alignment: Alignment.center,
            widthFactor: 1,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                height: 1,
              ),
            ),
          ),
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
      decoration: BoxDecoration(
        color: selected
            ? AppColors.burgundy
            : AppColors.pistachio.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(
        height: 22,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.center,
            widthFactor: 1,
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
          ),
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
                      Row(
                        children: [
                          _CandidateCharacterPill(label: applicant.character),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${applicant.mbti} · 예상 평균 케미',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.mutedText),
                            ),
                          ),
                        ],
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

class _CandidateCharacterPill extends StatelessWidget {
  const _CandidateCharacterPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.burgundy,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
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
    required this.assignments,
    this.flipped = false,
    this.editing = false,
    this.selectedSeatId,
    this.onSeatTap,
  });

  final String title;
  final String tableName;
  final Map<String, _SeatAssignment> assignments;
  final bool flipped;
  final bool editing;
  final String? selectedSeatId;
  final ValueChanged<String>? onSeatTap;

  @override
  Widget build(BuildContext context) {
    final top = flipped ? const ['B1', 'B2'] : const ['A1', 'A2'];
    final bottom = flipped ? const ['B3', 'B4'] : const ['A3', 'A4'];

    Widget buildSeat(String seatId) {
      final assignment = assignments[seatId]!;
      return _SeatPerson(
        initial: assignment.initial,
        character: assignment.character,
        name: assignment.name,
        seat: seatId,
        selected: editing && selectedSeatId == seatId,
        onTap: editing ? () => onSeatTap?.call(seatId) : null,
      );
    }

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
                children: [for (final seatId in top) buildSeat(seatId)],
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
                children: [for (final seatId in bottom) buildSeat(seatId)],
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
    this.onTap,
  });

  final String initial;
  final String character;
  final String name;
  final String seat;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: GestureDetector(
        key: ValueKey('seat-$seat'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
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
                      color: selected
                          ? AppColors.burgundy
                          : AppColors.parchment,
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
                key: ValueKey('seat-$seat-character'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.cocoa,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                name,
                key: ValueKey('seat-$seat-name'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
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
