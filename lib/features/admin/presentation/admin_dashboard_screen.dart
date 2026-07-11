import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/chemistry_session.dart';
import '../../../data/models/demo_models.dart';
import '../../../data/models/event_flow_models.dart';
import '../../../data/repositories/admin_event_repository.dart';
import '../../../data/repositories/application_repository.dart';
import '../../../data/repositories/event_flow_repository.dart';
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
  // 운영자 모드 진입은 이미 profile.isAdmin 으로 게이팅되므로 바로 대시보드로 시작.
  _AdminScreen _screen = _AdminScreen.dashboard;
  _AdminApplicantData _selectedApplicant = _emptyApplicant;
  int _applicantStatusFilter = 0;
  int _applicantSort = 0;
  int _applicantTab = 0;
  _AdminScreen _reviewsBackTarget = _AdminScreen.matchResult;
  int _menCount = 4;
  int _womenCount = 4;
  bool _rememberAdminLogin = true;

  // 회차 생성/편집 폼 입력
  final TextEditingController _sessionTitleCtrl = TextEditingController();
  final TextEditingController _sessionPlaceCtrl = TextEditingController();
  final TextEditingController _sessionPriceCtrl = TextEditingController();
  final TextEditingController _sessionMenuCtrl = TextEditingController();
  DateTime? _sessionDate;
  TimeOfDay? _sessionStartTime;
  TimeOfDay? _sessionEndTime;
  XFile? _pendingCover; // 게시/저장 시 업로드할 커버 이미지
  String? _editingSessionId; // null 이면 새 회차, 있으면 편집 모드
  String _editingTimeText = ''; // 편집 시 기존 시간 문구 보존
  String? _editingCoverUrl; // 편집 시 기존 커버
  bool _publishingSession = false;
  String? _selectedSessionId;
  bool _closingSession = false;
  List<_AdminApplicantData> _realApplicants = [];
  bool _loadingApplicants = false;
  bool _verifyingJob = false;
  bool _writingStatus = false;
  bool _scoringSession = false;
  bool _uploadingCover = false;

  // 매칭 탭(당일 운영) 상태
  bool _confirmingParticipants = false;
  bool _reassigningNicknames = false;
  bool _autoSeatingBusy = false;
  bool _creatingMatches = false;
  bool _generatingReports = false;
  // FutureBuilder 강제 새로고침용 틱
  int _adminRefreshTick = 0;
  // 자리 수동 편집: 첫 번째로 선택한 좌석 (테이블/좌석 번호)
  String? _seatPickTable;
  int? _seatPickPos;

  AdminEventRepository get _adminRepo => AdminEventRepository.instance;

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

  // ── 당일 운영(매칭 탭) Firestore 액션 ─────────────────────────

  /// 공통 실행기: busy 플래그 + 스낵바 + 화면 새로고침.
  Future<void> _runAdminAction({
    required bool busy,
    required void Function(bool value) setBusy,
    required Future<String> Function() action,
  }) async {
    final sessionId = _selectedSessionId;
    if (busy) return;
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회차 탭에서 운영할 회차를 먼저 선택해주세요')),
      );
      return;
    }
    setState(() => setBusy(true));
    final messenger = ScaffoldMessenger.of(context);
    try {
      final message = await action();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(message)));
      setState(() => _adminRefreshTick += 1);
    } catch (e) {
      debugPrint('[admin-action] $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('처리에 실패했어요. 잠시 후 다시 시도해 주세요')),
      );
    } finally {
      if (mounted) {
        setState(() => setBusy(false));
      }
    }
  }

  Future<void> _confirmParticipants() => _runAdminAction(
        busy: _confirmingParticipants,
        setBusy: (value) => _confirmingParticipants = value,
        action: () async {
          final count =
              await _adminRepo.confirmParticipants(_selectedSessionId!);
          return count > 0
              ? '$count명을 참가자로 확정하고 닉네임을 배정했어요'
              : '새로 확정할 신청자가 없어요 (기존 참가자는 유지)';
        },
      );

  Future<void> _reassignNicknames() => _runAdminAction(
        busy: _reassigningNicknames,
        setBusy: (value) => _reassigningNicknames = value,
        action: () async {
          final count =
              await _adminRepo.reassignNicknames(_selectedSessionId!);
          return count > 0 ? '$count명의 닉네임을 다시 배정했어요' : '참가자가 없어요';
        },
      );

  Future<void> _setEventStage(String stage) async {
    final sessionId = _selectedSessionId;
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회차 탭에서 운영할 회차를 먼저 선택해주세요')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _adminRepo.setEventStage(sessionId, stage);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '단계 변경: ${AdminEventRepository.eventStageLabels[stage] ?? stage}'
            ' — 참가자 화면이 실시간 이동합니다',
          ),
        ),
      );
      setState(() => _adminRefreshTick += 1);
    } catch (e) {
      debugPrint('[event-stage] $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('단계 변경에 실패했어요')),
      );
    }
  }

  Future<void> _runAutoSeating() => _runAdminAction(
        busy: _autoSeatingBusy,
        setBusy: (value) => _autoSeatingBusy = value,
        action: () async {
          final tables =
              await _adminRepo.autoAssignSeating(_selectedSessionId!);
          return tables > 0
              ? '$tables개 테이블 자리배치를 완료했어요'
              : '배치할 참가자가 부족해요 (2명 이상 필요)';
        },
      );

  Future<void> _createMatches() => _runAdminAction(
        busy: _creatingMatches,
        setBusy: (value) => _creatingMatches = value,
        action: () async {
          final count = await _adminRepo.createMatches(_selectedSessionId!);
          return count > 0
              ? '쌍방 매칭 $count건을 생성했어요 (참가자에게 편지 공개)'
              : '새로 생성할 쌍방 매칭이 없어요';
        },
      );

  Future<void> _generateReports() => _runAdminAction(
        busy: _generatingReports,
        setBusy: (value) => _generatingReports = value,
        action: () async {
          final count =
              await _adminRepo.generateBasicReports(_selectedSessionId!);
          return count > 0
              ? '케미 리포트 $count건을 생성했어요'
              : '새로 생성할 리포트가 없어요';
        },
      );

  /// 자리 수동 편집: 좌석 두 개를 차례로 탭하면 교체.
  Future<void> _handleSeatTap(String tableId, int seatPos) async {
    final sessionId = _selectedSessionId;
    if (sessionId == null) return;
    final pickedTable = _seatPickTable;
    final pickedPos = _seatPickPos;
    if (pickedTable == null || pickedPos == null) {
      setState(() {
        _seatPickTable = tableId;
        _seatPickPos = seatPos;
      });
      return;
    }
    if (pickedTable == tableId && pickedPos == seatPos) {
      setState(() {
        _seatPickTable = null;
        _seatPickPos = null;
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _adminRepo.swapSeats(
        sessionId,
        tableIdA: pickedTable,
        seatPosA: pickedPos,
        tableIdB: tableId,
        seatPosB: seatPos,
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('두 좌석을 교체했어요')));
    } catch (e) {
      debugPrint('[seat-swap] $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('좌석 교체에 실패했어요')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _seatPickTable = null;
          _seatPickPos = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _sessionTitleCtrl.dispose();
    _sessionPlaceCtrl.dispose();
    _sessionPriceCtrl.dispose();
    _sessionMenuCtrl.dispose();
    super.dispose();
  }

  /// 선택된 회차 id 로 실제(Firestore) 회차를 찾아 표시용 클래스로 변환.
  /// 선택이 없거나 못 찾으면 빈 회차로 폴백(더미 데이터 아님).
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
    if (sessions.isNotEmpty) {
      return sessions.first.toDisplayClass();
    }
    return const ChemistrySession(id: '', title: '회차').toDisplayClass();
  }

  /// 회차 게시 → Firestore sessions 에 생성.
  /// [status] 가 'draft' 면 임시저장, 기본은 모집중('recruiting').
  // ── 회차 폼: 날짜/시간/커버 선택 ──────────────────────────────

  String get _sessionDateText {
    final date = _sessionDate;
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    final period = time.period == DayPeriod.am ? '오전' : '오후';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }

  /// 시작~끝 시간 문구. 피커 미사용(편집 진입 직후)이면 기존 문구 유지.
  String get _sessionTimeText {
    final start = _sessionStartTime;
    if (start == null) return _editingTimeText;
    final end = _sessionEndTime;
    final startText = _formatTimeOfDay(start);
    return end == null ? startText : '$startText ~ ${_formatTimeOfDay(end)}';
  }

  Future<void> _pickSessionDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      setState(() => _sessionDate = picked);
    }
  }

  Future<void> _pickSessionTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _sessionStartTime : _sessionEndTime) ??
          const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _sessionStartTime = picked;
      } else {
        _sessionEndTime = picked;
      }
    });
  }

  /// 세션 커버 선택 — 갤러리/카메라 바텀시트.
  Future<void> _pickSessionCoverImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final file = await StorageService.instance.pickImageFrom(source);
      if (file != null && mounted) {
        setState(() => _pendingCover = file);
      }
    } catch (e) {
      debugPrint('[cover-pick] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 불러오지 못했어요')),
        );
      }
    }
  }

  /// 회차 편집 진입 — 기존 값 프리필.
  void _openSessionEditor(ChemistrySession session) {
    _sessionTitleCtrl.text = session.title;
    _sessionPlaceCtrl.text = session.location;
    _sessionPriceCtrl.text = session.priceText;
    _sessionMenuCtrl.text = session.menuName;
    final match = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})')
        .firstMatch(session.dateText);
    setState(() {
      _editingSessionId = session.id;
      _editingTimeText = session.timeText;
      _editingCoverUrl = session.keyVisualUrl;
      _sessionDate = match == null
          ? null
          : DateTime(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
            );
      _sessionStartTime = null;
      _sessionEndTime = null;
      _pendingCover = null;
      _menCount = session.recruitMale;
      _womenCount = session.recruitFemale;
    });
    _go(_AdminScreen.sessionCreate);
  }

  void _openSessionEditorById(String sessionId, AppState appState) {
    for (final session in appState.sessionsController.sessions) {
      if (session.id == sessionId) {
        _openSessionEditor(session);
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('회차 정보를 찾지 못했어요')),
    );
  }

  /// 회차 게시/저장. [status] 가 null 이면 편집 모드(상태 유지)로 저장.
  Future<void> _publishSession({String? status = 'recruiting'}) async {
    final title = _sessionTitleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회차명을 입력해 주세요')),
      );
      return;
    }
    setState(() => _publishingSession = true);
    final messenger = ScaffoldMessenger.of(context);
    final editingId = _editingSessionId;
    final isEdit = editingId != null;
    final isDraft = status == 'draft';
    try {
      String sessionId;
      if (isEdit) {
        await SessionRepository.instance.updateSession(editingId, {
          'title': title,
          // 비어 있으면 기존 값 유지 (merge)
          if (_sessionDateText.isNotEmpty) 'dateText': _sessionDateText,
          if (_sessionTimeText.isNotEmpty) 'timeText': _sessionTimeText,
          'location': _sessionPlaceCtrl.text.trim(),
          'priceText': _sessionPriceCtrl.text.trim(),
          'recruit': {'male': _menCount, 'female': _womenCount},
          'menuName': _sessionMenuCtrl.text.trim(),
          if (status != null) 'status': status,
        });
        sessionId = editingId;
      } else {
        final session = ChemistrySession(
          id: '',
          title: title,
          dateText: _sessionDateText,
          timeText: _sessionTimeText,
          location: _sessionPlaceCtrl.text.trim(),
          priceText: _sessionPriceCtrl.text.trim(),
          recruitMale: _menCount,
          recruitFemale: _womenCount,
          menuName: _sessionMenuCtrl.text.trim(),
          status: status ?? 'recruiting',
          createdBy: FirebaseService.instance.uid,
        );
        sessionId = await SessionRepository.instance.createSession(session);
      }

      // 커버 이미지가 선택돼 있으면 업로드 후 URL 저장.
      final cover = _pendingCover;
      if (cover != null) {
        final url = await StorageService.instance.uploadSessionCover(
          sessionId,
          cover,
        );
        await SessionRepository.instance.updateCover(sessionId, url);
      }

      if (!mounted) return;
      _clearSessionForm();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? '변경사항을 저장했어요' : (isDraft ? '임시저장했어요' : '회차가 게시됐어요'),
          ),
        ),
      );
      _go(_AdminScreen.sessions);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? '저장에 실패했어요. 잠시 후 다시 시도해 주세요'
                : (isDraft
                    ? '임시저장에 실패했어요. 잠시 후 다시 시도해 주세요'
                    : '게시에 실패했어요. 운영자 권한을 확인해 주세요'),
          ),
        ),
      );
      debugPrint('[session-save] $error');
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
    _sessionPlaceCtrl.clear();
    _sessionPriceCtrl.clear();
    _sessionMenuCtrl.clear();
    _sessionDate = null;
    _sessionStartTime = null;
    _sessionEndTime = null;
    _pendingCover = null;
    _editingSessionId = null;
    _editingTimeText = '';
    _editingCoverUrl = null;
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

  /// 대시보드에 노출할 대표 회차: 선택된 회차 → 모집중 → 첫 회차 순으로 폴백.
  /// 서버(Firestore) 회차가 하나도 없으면 null.
  ChemistrySession? _dashboardSession(AppState appState) {
    final sessions = appState.sessionsController.sessions;
    if (sessions.isEmpty) return null;
    final id = _selectedSessionId;
    if (id != null) {
      for (final session in sessions) {
        if (session.id == id) return session;
      }
    }
    for (final session in sessions) {
      if (session.status == 'recruiting') return session;
    }
    return sessions.first;
  }

  Widget _buildDashboard(BuildContext context, AppState appState) {
    final session = _dashboardSession(appState);
    final now = DateTime.now();
    const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final todayText =
        '오늘은 ${now.month}/${now.day} (${weekdayLabels[now.weekday - 1]})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminBrandBar(
          showAdmin: true,
          secondaryActionIcon: Icons.people_alt_outlined,
          onSecondaryAction: () =>
              appState.modeController.setMode(DemoMode.user),
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
        Text(todayText, style: _displayStyle(context, 30)),
        const SizedBox(height: 16),
        if (session == null)
          _DashboardEmptyState(
            title: '아직 등록된 회차가 없어요',
            body: '새 회차를 만들면 신청·인증 현황이 여기에 표시돼요.',
            actionLabel: '새 회차 만들기',
            onAction: () => _go(_AdminScreen.sessionCreate),
          )
        else
          _AdminEventSummary(
            eyebrow: '${session.statusLabel} · 대표 회차',
            title: session.title,
            subtitle: [
              if (session.dateText.isNotEmpty) session.dateText,
              if (session.location.isNotEmpty) session.location,
            ].join(' · '),
            stats: [
              _StatData('신청', '${session.applicationCount}', ''),
              _StatData('상태', session.statusLabel, ''),
              _StatData(
                '모집',
                '${session.recruitMale + session.recruitFemale}',
                '남 ${session.recruitMale}·여 ${session.recruitFemale}',
              ),
              _StatData('확정', '-', ''),
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
        if (session != null) ...[
          AppCard(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: '성비 & 인원',
                  trailing:
                      '목표 ${session.recruitMale}:${session.recruitFemale}',
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Row(
                    children: [
                      Expanded(
                        flex: session.recruitMale,
                        child: Container(
                          height: 10,
                          color: AppColors.pistachio,
                        ),
                      ),
                      Expanded(
                        flex: session.recruitFemale,
                        child: Container(
                          height: 10,
                          color: AppColors.burgundy,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '신청 ${session.applicationCount}명. 인원 선정을 진행하면 확정 인원이 여기에 표시돼요.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildNotifications(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '알림',
          subtitle: '운영 알림',
          onBack: () => _go(_AdminScreen.dashboard),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const _AdminChip(label: '전체', selected: true),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => _openReviewsFrom(_AdminScreen.notifications),
              child: const _AdminChip(label: '후기'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _ScreenEmptyState(
          icon: Icons.notifications_none_rounded,
          title: '새 알림이 없어요',
          body: '신청·인증·결제 등 운영 알림이 도착하면 여기에 표시됩니다.',
        ),
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
              onEdit: () {
                setState(() => _selectedSessionId = classes[i].id);
                _openSessionEditorById(classes[i].id, AppScope.of(context));
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
          onAction: () =>
              _openSessionEditorById(classData.id, AppScope.of(context)),
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
                subtitle: '신청 ${classData.applicationCount}명',
                done: classData.applicationCount > 0,
              ),
              _ProgressStep(
                title: '인원 선정',
                subtitle: '점수 계산 후 진행',
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
    final isEdit = _editingSessionId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: isEdit ? '회차 편집' : '새 회차 만들기',
          subtitle: isEdit ? _sessionTitleCtrl.text : '새 회차',
          onBack: () {
            _clearSessionForm();
            _go(_AdminScreen.sessions);
          },
        ),
        const SizedBox(height: 20),
        const _TinyEyebrow('01  기본 정보'),
        const SizedBox(height: 10),
        _AdminInput(label: '회차 (예: 케미스트리오븐 9기)', controller: _sessionTitleCtrl),
        const SizedBox(height: 10),
        _PickerField(
          label: '날짜',
          icon: Icons.calendar_month_outlined,
          value: _sessionDateText.isEmpty ? null : _sessionDateText,
          placeholder: '날짜 선택',
          onTap: _pickSessionDate,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PickerField(
                label: '시작 시간',
                icon: Icons.access_time_outlined,
                value: _sessionStartTime == null
                    ? null
                    : _formatTimeOfDay(_sessionStartTime!),
                placeholder: _editingTimeText.isEmpty ? '시작 시간' : _editingTimeText,
                onTap: () => _pickSessionTime(isStart: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PickerField(
                label: '끝 시간',
                icon: Icons.access_time_filled_outlined,
                value: _sessionEndTime == null
                    ? null
                    : _formatTimeOfDay(_sessionEndTime!),
                placeholder: '끝 시간',
                onTap: () => _pickSessionTime(isStart: false),
              ),
            ),
          ],
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
        const _TinyEyebrow('04  세션 커버 · 회차 카드 · 상세 노출'),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _pickSessionCoverImage,
          child: AppCard(
            color: AppColors.parchment,
            borderColor: AppColors.rose,
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: 124,
              child: Stack(
                children: [
                  if (_pendingCover != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_pendingCover!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else if (_editingCoverUrl != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _editingCoverUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.burgundy,
                          ),
                          SizedBox(height: 8),
                          _AdminChip(label: 'SESSION COVER', selected: false),
                        ],
                      ),
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
                      child: Text(
                        _pendingCover != null
                            ? '변경됨'
                            : (_editingCoverUrl != null ? '기존 커버' : '탭하여 업로드'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '탭하면 갤러리 또는 카메라에서 커버 이미지를 선택할 수 있어요.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.mutedText, fontSize: 11),
        ),
        const SizedBox(height: 16),
        if (isEdit)
          _WideButton(
            label: _publishingSession ? '저장 중...' : '변경사항 저장',
            onTap: () {
              if (!_publishingSession) {
                _publishSession(status: null);
              }
            },
          )
        else
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
    final total = _realApplicants.length;
    final verifiedCount = _realApplicants
        .where((a) => a.verificationJob == 'approved')
        .length;
    final heldCount = _realApplicants.where((a) => a.status == '보류').length;
    final rejectedCount = _realApplicants.where((a) => a.status == '탈락').length;
    final selectedCount = _realApplicants.where((a) => a.selected).length;

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
          _selectedSessionId == null
              ? '회차를 먼저 선택해 주세요'
              : '전체 $total명 · 직장인증 $verifiedCount',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
        const SizedBox(height: 14),
        _HorizontalSelectableChipStrip(
          labels: [
            '전체 $total',
            '선정 $selectedCount',
            '직장인증 $verifiedCount',
            '보류 $heldCount',
            '탈락 $rejectedCount',
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
          subtitle: '${applicant.gender} · ${applicant.age} · ${applicant.status}',
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
                      children: [
                        _ApplicantStatusBadge(
                          label: _jobVerificationLabel(
                            applicant.verificationJob,
                          ),
                        ),
                        _ApplicantStatusBadge(
                          label: applicant.status,
                          selected: applicant.selected,
                        ),
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
            _InfoLine(
              icon: Icons.cake_outlined,
              label: '생년',
              value: applicant.birth,
            ),
            const _DividerLine(),
            _InfoLine(
              icon: Icons.straighten_outlined,
              label: '키',
              value: applicant.height,
            ),
            const _DividerLine(),
            _InfoLine(
              icon: Icons.auto_awesome_outlined,
              label: 'MBTI',
              value: applicant.mbti,
            ),
            const _DividerLine(),
            _InfoLine(
              icon: Icons.place_outlined,
              label: '지역',
              value: applicant.job,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _applicantPrefPanel(BuildContext context) {
    return const [
      _PanelEmptyState(
        icon: Icons.tune_rounded,
        message: '선호 조건 데이터가 아직 연동되지 않았어요.\n신청서 선호값 파이프라인이 준비되면 표시됩니다.',
      ),
    ];
  }

  List<Widget> _applicantAnswerPanel(BuildContext context) {
    return const [
      _PanelEmptyState(
        icon: Icons.quiz_outlined,
        message: '설문 답변 데이터가 아직 연동되지 않았어요.\n온보딩 설문 응답 파이프라인이 준비되면 표시됩니다.',
      ),
    ];
  }

  Widget _buildSelectionPool(BuildContext context) {
    final sessionId = _selectedSessionId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '인원 선정',
          subtitle: '케미 점수 기반',
          onBack: () => _go(_AdminScreen.sessions),
        ),
        const SizedBox(height: 14),
        if (sessionId == null)
          _sessionRequiredNotice()
        else ...[
          FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('pool-$_adminRefreshTick'),
            future: ApplicationRepository.instance
                .fetchSessionApplicants(sessionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _PanelEmptyState(
                  icon: Icons.hourglass_top_rounded,
                  message: '신청자를 불러오는 중...',
                );
              }
              final applicants =
                  (snapshot.data ?? const <Map<String, dynamic>>[])
                      .map(_mapApplicant)
                      .toList()
                    ..sort((a, b) => b.score.compareTo(a.score));
              if (applicants.isEmpty) {
                return const _ScreenEmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: '신청자가 없어요',
                  body: '신청이 들어오고 회차 상세에서 AI 점수 계산을 실행하면 점수순 추천이 표시됩니다.',
                );
              }
              return Column(
                children: [
                  for (final applicant in applicants) ...[
                    AppCard(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _ApplicantAvatar(applicant: applicant, size: 40),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${applicant.name} · ${applicant.gender}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '케미 ${applicant.score}점 · ${applicant.status}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.mutedText),
                                ),
                              ],
                            ),
                          ),
                          if (applicant.selected)
                            const _AdminTag(label: '선정')
                          else
                            _MiniButton(
                              label: '선정',
                              onTap: () =>
                                  _writeApplicantStatus(applicant, 'selected'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _WideButton(
            label: _confirmingParticipants
                ? '확정 중...'
                : '선정 인원 → 참가자 확정 + 닉네임 배정',
            onTap: () async {
              await _confirmParticipants();
              if (mounted) _go(_AdminScreen.participants);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildChemistryCombo(BuildContext context) {
    final sessionId = _selectedSessionId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '케미 조합',
          subtitle: '중간 선택 · 케미 점수 기반 페어',
          onBack: () => _go(_AdminScreen.selectionPool),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        if (sessionId == null)
          _sessionRequiredNotice()
        else ...[
          Text(
            '페어(케미 조합)는 자리배치와 함께 생성돼요. 중간 선택 쌍방이 1순위, 나머지는 케미 점수순으로 짝지어집니다.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.mutedText, height: 1.5),
          ),
          const SizedBox(height: 12),
          _seatingTables(context, sessionId, editable: false),
          const SizedBox(height: 12),
          _WideButton(
            label: _autoSeatingBusy ? '생성 중...' : '케미 조합 · 자리배치 자동 생성',
            onTap: _runAutoSeating,
          ),
        ],
      ],
    );
  }

  Widget _buildParticipants(BuildContext context) {
    final sessionId = _selectedSessionId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '참가자 관리',
          subtitle: '확정 참가자 · 회차 닉네임',
          onBack: () => _go(_AdminScreen.chemistryCombo),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        if (sessionId == null)
          _sessionRequiredNotice()
        else ...[
          StreamBuilder<List<EventParticipant>>(
            stream: EventFlowRepository.instance.watchParticipants(sessionId),
            builder: (context, snapshot) {
              final participants = snapshot.data ?? const <EventParticipant>[];
              if (participants.isEmpty) {
                return const _ScreenEmptyState(
                  icon: Icons.groups_outlined,
                  title: '확정 참가자가 없어요',
                  body: '아래 버튼으로 선정/입금 완료 신청자를 참가자로 확정하면 명단이 표시됩니다.',
                );
              }
              return Column(
                children: [
                  for (final participant in participants) ...[
                    _participantTile(context, participant),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _WideButton(
            label: _confirmingParticipants
                ? '확정 중...'
                : '선정 인원 → 참가자 확정 + 닉네임 배정',
            onTap: _confirmParticipants,
          ),
          const SizedBox(height: 8),
          _WideButton(
            label: '캐릭터(닉네임) 배정 관리',
            muted: true,
            onTap: () => _go(_AdminScreen.characterAssign),
          ),
        ],
      ],
    );
  }

  Widget _buildCharacterAssign(BuildContext context) {
    final sessionId = _selectedSessionId;
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
        if (sessionId == null)
          _sessionRequiredNotice()
        else ...[
          StreamBuilder<List<EventParticipant>>(
            stream: EventFlowRepository.instance.watchParticipants(sessionId),
            builder: (context, snapshot) {
              final participants = snapshot.data ?? const <EventParticipant>[];
              if (participants.isEmpty) {
                return const _ScreenEmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: '배정할 참가자가 없어요',
                  body: '참가자 관리에서 확정을 진행하면 회차 전용 닉네임 배정을 여기에서 관리합니다.',
                );
              }
              return Column(
                children: [
                  for (final participant in participants) ...[
                    _participantTile(context, participant),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          _WideButton(
            label: _reassigningNicknames ? '재배정 중...' : '닉네임 전체 재배정 (셔플)',
            onTap: _reassignNicknames,
          ),
        ],
      ],
    );
  }

  Widget _buildVoting(BuildContext context) {
    final sessionId = _selectedSessionId;
    final appState = AppScope.of(context);
    String? currentStage;
    if (sessionId != null) {
      for (final session in appState.sessionsController.sessions) {
        if (session.id == sessionId) {
          currentStage = session.eventStage;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '당일 진행 관리',
          subtitle: '단계 제어 · 선택 제출 현황',
          onBack: () => _go(_AdminScreen.characterAssign),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        if (sessionId == null)
          _sessionRequiredNotice()
        else ...[
          _SectionHeader(
            title: '진행 단계',
            trailing: currentStage == null
                ? '시작 전'
                : (AdminEventRepository.eventStageLabels[currentStage] ??
                    currentStage),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final stage in AdminEventRepository.eventStages)
                _AdminChip(
                  label:
                      AdminEventRepository.eventStageLabels[stage] ?? stage,
                  selected: stage == currentStage,
                  onTap: () => _setEventStage(stage),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '단계를 누르면 모든 참가자 화면이 해당 단계로 실시간 이동해요 (앞 단계로는 이동하지 않음).',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.mutedText, height: 1.5),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: '선택 제출 현황', trailing: '첫인상 · 중간 · 최종'),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('choices-$_adminRefreshTick'),
            future: _adminRepo.fetchChoiceStatus(sessionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _PanelEmptyState(
                  icon: Icons.hourglass_top_rounded,
                  message: '제출 현황을 불러오는 중...',
                );
              }
              final rows = snapshot.data ?? const <Map<String, dynamic>>[];
              if (rows.isEmpty) {
                return const _PanelEmptyState(
                  icon: Icons.how_to_vote_outlined,
                  message: '확정 참가자가 없어요. 참가자 확정 후 현황이 표시됩니다.',
                );
              }
              return AppCard(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (final row in rows) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (row['participant'] as EventParticipant)
                                  .nickname,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          _choiceDot(row['hasFirst'] as bool),
                          const SizedBox(width: 10),
                          _choiceDot(row['hasMid'] as bool),
                          const SizedBox(width: 10),
                          _choiceDot(row['hasFinal'] as bool),
                        ],
                      ),
                      if (row != rows.last)
                        const Divider(height: 16, color: AppColors.line),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _MiniButton(
            label: '현황 새로고침',
            onTap: () => setState(() => _adminRefreshTick += 1),
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
      ],
    );
  }

  Widget _buildSeatingAuto(BuildContext context) {
    final sessionId = _selectedSessionId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '자리배치',
          subtitle: '자동 추천 (중간 선택 쌍방 우선)',
          onBack: () => _go(_AdminScreen.voting),
        ),
        const SizedBox(height: 14),
        if (sessionId == null)
          _sessionRequiredNotice()
        else ...[
          _seatingTables(context, sessionId, editable: false),
          const SizedBox(height: 12),
          _WideButton(
            label: _autoSeatingBusy ? '배치 중...' : '자동 자리배치 실행 (기존 배치 대체)',
            onTap: _runAutoSeating,
          ),
          const SizedBox(height: 8),
          _WideButton(
            label: '자리 수동 편집',
            muted: true,
            onTap: () => _go(_AdminScreen.seatingEdit),
          ),
        ],
      ],
    );
  }

  Widget _buildSeatingEdit(BuildContext context) {
    final sessionId = _selectedSessionId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '자리 수동 편집',
          subtitle: '좌석 두 개를 차례로 탭하면 교체',
          onBack: () => _go(_AdminScreen.seatingAuto),
        ),
        const SizedBox(height: 14),
        if (sessionId == null)
          _sessionRequiredNotice()
        else ...[
          if (_seatPickTable != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '선택됨: $_seatPickTable ${(_seatPickPos ?? 0) + 1}번 좌석 — 교체할 좌석을 탭하세요',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          _seatingTables(context, sessionId, editable: true),
        ],
      ],
    );
  }

  /// 테이블 좌석도 목록 (seating 컬렉션 실시간).
  /// [editable] 이면 좌석 탭 → 교체 모드.
  Widget _seatingTables(
    BuildContext context,
    String sessionId, {
    required bool editable,
  }) {
    return StreamBuilder<List<SeatingTable>>(
      stream: EventFlowRepository.instance.watchSeating(sessionId),
      builder: (context, snapshot) {
        final tables = snapshot.data ?? const <SeatingTable>[];
        if (tables.isEmpty) {
          return const _ScreenEmptyState(
            icon: Icons.chair_alt_outlined,
            title: '자리배치안이 아직 없어요',
            body: '참가자 확정 후 자동 자리배치를 실행하면 테이블 좌석도가 여기에 표시됩니다.',
          );
        }
        return Column(
          children: [
            for (final table in tables) ...[
              AppCard(
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: table.tableId,
                      trailing: '${table.seats.length}명',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final seat in table.seats)
                          _AdminChip(
                            label:
                                '${(seat.seatPos ?? 0) + 1}. ${seat.nickname}',
                            selected: editable &&
                                _seatPickTable == table.tableId &&
                                _seatPickPos == seat.seatPos,
                            onTap: editable && seat.seatPos != null
                                ? () => _handleSeatTap(
                                      table.tableId,
                                      seat.seatPos!,
                                    )
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '1·2번 = 옆자리 페어, 3·4번 = 맞은편 페어',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.mutedText, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMatchResult(BuildContext context) {
    final sessionId = _selectedSessionId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '매칭 결과',
          subtitle: '최종 선택 집계',
          onBack: () => _go(_AdminScreen.voting),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        if (sessionId == null)
          _sessionRequiredNotice()
        else ...[
          FutureBuilder<Map<String, dynamic>>(
            key: ValueKey('agg-$_adminRefreshTick'),
            future: _adminRepo.aggregateFinalChoices(sessionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _PanelEmptyState(
                  icon: Icons.hourglass_top_rounded,
                  message: '최종 선택을 집계하는 중...',
                );
              }
              final aggregate =
                  snapshot.data ?? const <String, dynamic>{};
              final mutual =
                  (aggregate['mutual'] as List<List<String>>?) ?? const [];
              final oneWay =
                  (aggregate['oneWay'] as List<Map<String, String>>?) ??
                      const [];
              final nicknames =
                  (aggregate['nicknames'] as Map<String, String>?) ??
                      const {};
              String nick(String? uid) =>
                  uid == null ? '?' : (nicknames[uid] ?? uid);

              if (mutual.isEmpty && oneWay.isEmpty) {
                return const _ScreenEmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: '아직 집계할 최종 선택이 없어요',
                  body: '참가자들이 최종 선택을 제출하면 상호 매칭·단방향 결과가 여기에 표시됩니다.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: '상호 매칭', trailing: '${mutual.length}쌍'),
                  const SizedBox(height: 8),
                  if (mutual.isEmpty)
                    const _PanelEmptyState(
                      icon: Icons.favorite_border_rounded,
                      message: '상호 매칭이 아직 없어요',
                    )
                  else
                    for (final pair in mutual) ...[
                      AppCard(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: AppColors.brandRed,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${nick(pair[0])} ↔ ${nick(pair[1])}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 8),
                  _SectionHeader(title: '단방향 선택', trailing: '${oneWay.length}건'),
                  const SizedBox(height: 8),
                  for (final entry in oneWay) ...[
                    AppCard(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.mutedText,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${nick(entry['from'])} → ${nick(entry['to'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _WideButton(
            label: _creatingMatches
                ? '생성 중...'
                : '쌍방 매칭 확정 · 생성 (참가자에게 편지 공개)',
            onTap: _createMatches,
          ),
          const SizedBox(height: 8),
          _WideButton(
            label: _generatingReports ? '생성 중...' : '케미 리포트 생성 (전 참가자)',
            muted: true,
            onTap: _generateReports,
          ),
          const SizedBox(height: 8),
          _WideButton(
            label: '후기 관리',
            muted: true,
            onTap: () => _openReviewsFrom(_AdminScreen.matchResult),
          ),
        ],
      ],
    );
  }

  Widget _buildReviews(BuildContext context) {
    final sessionId = _selectedSessionId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AdminTopBar(
          title: '후기 관리',
          subtitle: '회차 후기',
          onBack: () => _go(_reviewsBackTarget),
          actionIcon: Icons.notifications_none_rounded,
        ),
        const SizedBox(height: 14),
        if (sessionId == null)
          _sessionRequiredNotice()
        else
          FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('reviews-$_adminRefreshTick'),
            future: _adminRepo.fetchReviews(sessionId),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _PanelEmptyState(
                  icon: Icons.hourglass_top_rounded,
                  message: '후기를 불러오는 중...',
                );
              }
              final reviews = snapshot.data ?? const <Map<String, dynamic>>[];
              if (reviews.isEmpty) {
                return const _ScreenEmptyState(
                  icon: Icons.rate_review_outlined,
                  title: '검토할 후기가 없어요',
                  body: '참가자가 후기를 남기면 여기에 표시됩니다.',
                );
              }
              return Column(
                children: [
                  for (final review in reviews) ...[
                    AppCard(
                      color: Colors.white,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              for (var star = 0;
                                  star < ((review['stars'] as num?)?.toInt() ?? 0);
                                  star++)
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                              const SizedBox(width: 8),
                              _AdminTag(
                                label:
                                    (review['type'] as String?) ?? '참여 후기',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ((review['text'] as String?) ?? '').isEmpty
                                ? '(내용 없음)'
                                : (review['text'] as String),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }

  // ── 매칭 탭 공용 위젯 ─────────────────────────────────────────

  Widget _sessionRequiredNotice() {
    return _DashboardEmptyState(
      title: '회차를 먼저 선택해주세요',
      body: '회차 탭에서 운영할 회차를 선택하면 여기에서 당일 진행을 관리할 수 있어요.',
      actionLabel: '회차 목록으로',
      onAction: () => _go(_AdminScreen.sessions),
    );
  }

  Widget _participantTile(BuildContext context, EventParticipant participant) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blush.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              participant.displayMark,
              style: const TextStyle(
                color: AppColors.burgundy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.nickname,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    participant.gender == 'M' ? '남' : '여',
                    if (participant.tableId != null) participant.tableId!,
                    if (participant.chemistryScore != null)
                      '케미 ${participant.chemistryScore}점',
                  ].join(' · '),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceDot(bool done) {
    return Icon(
      done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
      size: 16,
      color: done ? AppColors.success : AppColors.line,
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

/// 선택된 신청자가 없을 때의 안전한 기본값(더미 데이터 아님).
const _emptyApplicant = _AdminApplicantData(
  initial: '?',
  name: '신청자',
  gender: '-',
  age: 0,
  birth: '-',
  height: '-',
  mbti: '-',
  job: '-',
  character: '-',
  status: '신청',
  score: 0,
  strictScore: 0,
  objectiveScore: 0,
  note: '',
  selected: false,
);

/// 서버 데이터가 아직 없는 영역에 표시하는 큰 빈 상태 카드.
class _ScreenEmptyState extends StatelessWidget {
  const _ScreenEmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.burgundy, size: 34),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.cocoa,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 대시보드 히어로 자리에 회차가 없을 때 노출하는 빈 상태 카드.
class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.burgundy,
      borderColor: AppColors.burgundy,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _MiniButton(label: actionLabel, onTap: onAction),
        ],
      ),
    );
  }
}

/// 신청자 상세 탭 안에서 데이터가 없을 때의 작은 빈 상태.
class _PanelEmptyState extends StatelessWidget {
  const _PanelEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Column(
        children: [
          Icon(icon, color: AppColors.mutedText, size: 28),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.caption);

  final String label;
  final String value;
  final String caption;
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
    this.onSecondaryAction,
  });

  final bool showAdmin;
  final IconData? actionIcon;
  final IconData? secondaryActionIcon;
  final VoidCallback? onAction;
  final VoidCallback? onSecondaryAction;

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
          _SquareIconButton(
            icon: secondaryActionIcon!,
            onTap: onSecondaryAction ?? () {},
          ),
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
    this.onAction,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final IconData? actionIcon;
  final String? actionText;
  final VoidCallback? onAction;

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
          _SquareIconButton(icon: actionIcon!, onTap: onAction ?? () {}),
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

/// 탭하면 피커(캘린더/시간 등)가 열리는 읽기 전용 입력 필드.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.onTap,
    this.icon,
    this.value,
    this.placeholder,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final String? value; // 선택된 값 (없으면 placeholder 표시)
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                hasValue ? value! : (placeholder ?? label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: hasValue ? AppColors.cocoa : AppColors.mutedText,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            const Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: AppColors.mutedText,
            ),
          ],
        ),
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
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.stats,
  });

  final String eyebrow;
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
              Text(
                eyebrow,
                style: const TextStyle(
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

class _SessionListCard extends StatelessWidget {
  const _SessionListCard({
    required this.number,
    required this.classData,
    required this.status,
    required this.onTap,
    this.onEdit,
    this.active = false,
    this.empty = false,
  });

  final String number;
  final ChemistryClass classData;
  final String status;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
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
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  _SquareIconButton(
                    icon: Icons.edit_outlined,
                    onTap: onEdit!,
                  ),
                ],
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
