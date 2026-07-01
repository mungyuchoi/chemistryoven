import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/demo_models.dart';
import '../../../services/auth_service.dart';
import '../../../services/firebase_service.dart';
import '../../../services/onboarding_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/user_service.dart';
import '../../../shared/providers/app_scope.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    this.onCompleted,
    this.onNavigateAfterCompleted,
    super.key,
  });

  final VoidCallback? onCompleted;
  final ValueChanged<MainTab>? onNavigateAfterCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _index = 0;
  RangeValues _ageRange = const RangeValues(30, 36);
  RangeValues _heightRange = const RangeValues(175, 188);
  final Map<OnboardingStep, Set<String>> _selected = {
    OnboardingStep.account: {'카카오 알림톡 동의', '마케팅 알림 선택'},
    OnboardingStep.basicInfo: {'남성', '서울 강남권'},
    OnboardingStep.rhythm: {'IT/개발', '평일 주간', '토요일 오후', '일요일 오후'},
    OnboardingStep.conversation: {
      '같이 무언가를 만들 때',
      '맛있는 걸 나눠 먹을 때',
      '서로 질문을 주고받을 때',
      '차분하고 따뜻한',
      '맛집·카페 탐방',
      '영화',
      '맛집',
      '요리',
    },
    OnboardingStep.lifestyle: {'크림', '구움과자', '커피 페어링', '가볍게 한 잔', '비흡연'},
    OnboardingStep.keywords: {'다정한', '성실한', '배려 깊은', '천천히 깊어지는 사람'},
    OnboardingStep.preferences: {
      'age:any',
      'height:175 이상',
      'mbti:ENFP',
      'mbti:ENFJ',
      'mbti:INFJ',
      'religion:상관없음',
      'job:없음',
    },
    OnboardingStep.profilePreview: {'공개 프로필 확인', 'AI 문장 보정 완료', '운영진 확인 정보 분리'},
  };

  // 기본 정보 입력값 (아이디/이름/키/생년월일).
  final TextEditingController _handleCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController(text: '신청자 A');
  final TextEditingController _heightCtrl = TextEditingController(text: '164');
  String _birth = '1995-04-18';

  // STEP 1 아이디 중복확인 상태 (true=사용 가능으로 확인됨).
  bool _handleAvailable = false;

  @override
  void dispose() {
    _handleCtrl.dispose();
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _onHandleAvailabilityChanged(bool available) {
    _handleAvailable = available;
  }

  void _onBirthChanged(String birth) {
    _birth = birth;
  }

  List<OnboardingStep> get _steps => OnboardingStep.values;
  OnboardingStep get _step => _steps[_index];
  bool get _isLastStep => _index == _steps.length - 1;
  String get _primaryButtonLabel {
    if (_isLastStep) {
      return '완료하고 앱 보기';
    }
    if (_step == OnboardingStep.verification) {
      return '분석 시작하기';
    }
    return '다음';
  }

  IconData get _primaryButtonIcon {
    if (_isLastStep) {
      return Icons.check;
    }
    if (_step == OnboardingStep.verification) {
      return Icons.auto_awesome;
    }
    return Icons.arrow_forward;
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final choices = appState.repository.fetchOnboardingChoices();
    final character = appState.repository.fetchFeaturedCharacter();
    final isResultStep = _step == OnboardingStep.result;
    final progress = (_index + 1) / _steps.length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: isResultStep
          ? null
          : AppBar(
              title: const Text('Chemistry Oven'),
              actions: [
                TextButton(
                  onPressed: () => _finish(),
                  child: const Text('나중에'),
                ),
              ],
            ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, isResultStep ? 42 : 12, 20, 28),
          children: [
            if (!isResultStep) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  backgroundColor: AppColors.line,
                  valueColor: const AlwaysStoppedAnimation(AppColors.brandRed),
                ),
              ),
              const SizedBox(height: 18),
              StatusBadge(label: _step.stepLabel),
              const SizedBox(height: 12),
              Text(
                _step.title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _step.subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 18),
            ],
            if (_step == OnboardingStep.intro)
              const _IntroStep()
            else if (_step == OnboardingStep.result)
              _ResultStep(character: character)
            else
              _QuestionStep(
                step: _step,
                choices: choices[_step] ?? const [],
                selected: _selected[_step] ?? <String>{},
                onToggle: _toggleChoice,
                ageRange: _ageRange,
                heightRange: _heightRange,
                onAgeRangeChanged: (values) =>
                    setState(() => _ageRange = values),
                onHeightRangeChanged: (values) =>
                    setState(() => _heightRange = values),
                handleController: _handleCtrl,
                onHandleAvailabilityChanged: _onHandleAvailabilityChanged,
                nameController: _nameCtrl,
                heightController: _heightCtrl,
                initialBirth: _birth,
                onBirthChanged: _onBirthChanged,
              ),
            const SizedBox(height: 22),
            if (isResultStep)
              _ResultActionRow(
                onOpenLab: () => _finish(targetTab: MainTab.lab),
                onOpenSchedule: () => _finish(targetTab: MainTab.schedule),
              )
            else
              Row(
                children: [
                  if (_index > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _index -= 1),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('이전'),
                      ),
                    ),
                  if (_index > 0) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isLastStep
                          ? () => _finish()
                          : () => setState(() => _index += 1),
                      icon: Icon(_primaryButtonIcon),
                      label: Text(_primaryButtonLabel),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _toggleChoice(OnboardingStep step, String value) {
    setState(() {
      final values = _selected.putIfAbsent(step, () => <String>{});
      if (step == OnboardingStep.basicInfo &&
          (value == '남성' || value == '여성')) {
        values
          ..remove('남성')
          ..remove('여성')
          ..add(value);
        return;
      }
      if (step == OnboardingStep.lifestyle) {
        const drinking = {'술 거의 안 마심', '가볍게 한 잔'};
        const smoking = {'비흡연', '흡연 상관없음'};
        if (drinking.contains(value)) {
          values
            ..removeAll(drinking)
            ..add(value);
          return;
        }
        if (smoking.contains(value)) {
          values
            ..removeAll(smoking)
            ..add(value);
          return;
        }
      }
      if (step == OnboardingStep.rhythm &&
          const {'평일 주간', '교대근무', '주말근무', '프리랜서형'}.contains(value)) {
        values
          ..remove('평일 주간')
          ..remove('교대근무')
          ..remove('주말근무')
          ..remove('프리랜서형')
          ..add(value);
        return;
      }
      if (step == OnboardingStep.conversation) {
        // ① 가까워지기 좋은 순간 — 최대 3개.
        const closeMoments = {
          '같이 무언가를 만들 때',
          '맛있는 걸 나눠 먹을 때',
          '취향 이야기를 할 때',
          '가벼운 게임을 할 때',
          '산책하거나 움직일 때',
          '웃긴 이야기를 나눌 때',
          '조용히 집중할 때',
          '서로 질문을 주고받을 때',
        };
        // ② 함께하면 편한 분위기 — 하나만 선택.
        const vibes = {
          '차분하고 따뜻한',
          '웃음이 많은',
          '가볍고 편한',
          '진지한 이야기도',
          '함께 집중하는',
          '새로운 경험을',
        };
        // ③ 주말에 가장 끌리는 건 — 하나만 선택.
        const weekend = {
          '맛집·카페 탐방',
          '전시·영화·공연',
          '산책·운동',
          '집에서 휴식',
          '여행·드라이브',
          '원데이 클래스',
        };

        if (closeMoments.contains(value)) {
          if (values.contains(value)) {
            values.remove(value);
          } else if (values.intersection(closeMoments).length < 3) {
            values.add(value);
          }
          return;
        }
        if (vibes.contains(value)) {
          values
            ..removeAll(vibes)
            ..add(value);
          return;
        }
        if (weekend.contains(value)) {
          values
            ..removeAll(weekend)
            ..add(value);
          return;
        }
        // ④ 취향 키워드는 자유 다중 선택 → 아래 기본 add/remove로 처리.
      }
      if (step == OnboardingStep.keywords) {
        const keywords = {
          '다정한',
          '성실한',
          '유쾌한',
          '차분한',
          '배려 깊은',
          '솔직한',
          '책임감 있는',
          '감성적인',
          '현실적인',
          '도전적인',
          '섬세한',
          '긍정적인',
        };
        const selfTypes = {
          '천천히 깊어지는 사람',
          '대화가 잘 통하면 금방 가까워지는 사람',
          '웃음 코드가 중요한 사람',
          '안정감과 신뢰를 중요하게 보는 사람',
          '새로운 경험을 함께하는 걸 좋아하는 사람',
        };

        if (keywords.contains(value) &&
            !values.contains(value) &&
            values.intersection(keywords).length >= 3) {
          values.remove(values.intersection(keywords).first);
        }
        if (selfTypes.contains(value)) {
          values
            ..removeAll(selfTypes)
            ..add(value);
          return;
        }
      }
      if (step == OnboardingStep.preferences) {
        const heightPreferences = {
          'height:크게 상관없음',
          'height:나보다 크면',
          'height:170 이상',
          'height:175 이상',
          'height:180 이상',
          'height:160~170',
          'height:165~175',
        };
        const mbtiPreferences = {
          'mbti:상관없음',
          'mbti:ENFP',
          'mbti:ENFJ',
          'mbti:INFJ',
          'mbti:INFP',
          'mbti:ESTJ',
          'mbti:ISTJ',
          'mbti:ESTP',
        };
        const religionPreferences = {
          'religion:상관없음',
          'religion:무교',
          'religion:기독교',
          'religion:천주교',
          'religion:불교',
          'religion:기타',
        };
        const cautionJobs = {
          'job:없음',
          'job:고위공무',
          'job:같은 직장군',
          'job:영업직',
          'job:자영업',
          'job:프리랜서',
          'job:군인/경찰/소방',
          'job:기타',
        };

        if (value == 'age:any') {
          if (!values.add(value)) {
            values.remove(value);
          }
          return;
        }
        if (heightPreferences.contains(value)) {
          values
            ..removeAll(heightPreferences)
            ..add(value);
          return;
        }
        if (mbtiPreferences.contains(value)) {
          if (value == 'mbti:상관없음') {
            values
              ..removeAll(mbtiPreferences)
              ..add(value);
            return;
          }
          values.remove('mbti:상관없음');
          if (!values.add(value)) {
            values.remove(value);
          }
          return;
        }
        if (religionPreferences.contains(value)) {
          values
            ..removeAll(religionPreferences)
            ..add(value);
          return;
        }
        if (cautionJobs.contains(value)) {
          if (value == 'job:없음') {
            values
              ..removeAll(cautionJobs)
              ..add(value);
            return;
          }
          values.remove('job:없음');
          if (!values.add(value)) {
            values.remove(value);
          }
          return;
        }
      }
      if (!values.add(value)) {
        values.remove(value);
      }
    });
  }

  void _finish({MainTab? targetTab}) {
    final appState = AppScope.of(context);
    // 온보딩 결과를 Firestore에 저장 (로그인 상태일 때만, 비차단)
    _persistOnboarding(appState);
    appState.sessionController.completeOnboarding();
    appState.modeController.setMode(DemoMode.user);
    Navigator.of(context).pop();
    widget.onCompleted?.call();
    if (targetTab != null) {
      widget.onNavigateAfterCompleted?.call(targetTab);
    }
  }

  /// 선택값을 모아 Firestore에 저장. 네비게이션을 막지 않도록 await 하지 않는다.
  void _persistOnboarding(AppState appState) {
    final genderKr = (_selected[OnboardingStep.basicInfo] ?? const <String>{})
        .firstWhere(
          (value) => value == '남성' || value == '여성',
          orElse: () => '',
        );

    // 취향(취향 키워드 포함 conversation)/키워드/라이프스타일 선택을
    // 캐릭터 추천 키워드로 사용
    final keywords = <String>{
      ...?_selected[OnboardingStep.conversation],
      ...?_selected[OnboardingStep.keywords],
      ...?_selected[OnboardingStep.lifestyle],
    };

    final baseCharacterId = CharacterRecommender.recommend(
      genderKr: genderKr,
      keywords: keywords,
      characters: appState.repository.fetchCharacters(),
    );

    // 기본 정보(이름/키/생년월일/아이디) 저장 (비차단, 로그인 시에만).
    final uid = FirebaseService.instance.uid;
    if (uid != null) {
      // 중복확인까지 통과한 유효한 아이디만 저장.
      final handle = _handleCtrl.text.trim();
      final hasHandle = _handleAvailable &&
          RegExp(r'^[A-Za-z0-9_]{4,12}$').hasMatch(handle);

      UserService.instance
          .updateBasicInfo(
            uid: uid,
            name: _nameCtrl.text.trim(),
            birth: _birth,
            height: int.tryParse(_heightCtrl.text.trim()),
            handle: hasHandle ? handle : null,
          )
          .catchError((Object error) {
            debugPrint('[onboarding] 기본 정보 저장 실패: $error');
          });

      // 아이디 소유권 클레임 (handles/{handle} = {uid}).
      if (hasHandle) {
        FirebaseService.instance.handles
            .doc(handle)
            .set(<String, dynamic>{'uid': uid}).catchError((Object error) {
          debugPrint('[onboarding] 아이디 클레임 실패: $error');
        });
      }
    }

    // 비동기 저장 (실패해도 흐름은 진행). 저장 후 사용자 프로필 재로드.
    OnboardingService.instance
        .saveOnboarding(
          genderKr: genderKr,
          selected: _selected,
          ageRange: [_ageRange.start, _ageRange.end],
          heightMin: _heightRange.start,
          baseCharacterId: baseCharacterId,
        )
        .then((saved) {
          if (saved) {
            appState.currentUserController.load();
          }
        })
        .catchError((Object error) {
          debugPrint('[onboarding] 저장 실패: $error');
        });
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 0.82,
              child: Image.asset(
                AppAssets.chemistryFlowBackground,
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(
              child: _TrustPoint(
                icon: Icons.auto_awesome,
                title: 'AI 케미 분석',
                body: '내 케미 캐릭터를 찾아드려요',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _TrustPoint(
                icon: Icons.verified_user_outlined,
                title: '신뢰 우선',
                body: '연락처/직장 인증으로 안전하게',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountStep extends StatefulWidget {
  const _AccountStep({
    required this.selected,
    required this.onToggle,
    required this.handleController,
    required this.onHandleAvailabilityChanged,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final TextEditingController handleController;
  final ValueChanged<bool> onHandleAvailabilityChanged;

  @override
  State<_AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends State<_AccountStep> {
  static final RegExp _handlePattern = RegExp(r'^[A-Za-z0-9_]{4,12}$');

  bool _verifying = false;
  bool _checking = false;
  bool _handleAvailable = false;
  String? _handleMsg;
  // 인증 직후 표시할 닉네임 (프로필 재로드 전에도 즉시 반영).
  String? _verifiedNickname;

  bool _isKakaoVerified(AppState appState) {
    final profile = appState.currentUserController.profile;
    if (profile == null) {
      return false;
    }
    return profile.provider == 'kakao' || profile.kakaoVerified == true;
  }

  String _verifiedDisplayName(AppState appState) {
    final nickname = _verifiedNickname;
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }
    return appState.currentUserController.profile?.displayName ?? '';
  }

  Future<void> _verifyKakao() async {
    if (_verifying) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final appState = AppScope.of(context);
    final uid = FirebaseService.instance.uid;
    if (uid == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('로그인 후 카카오 인증을 진행할 수 있어요.')),
      );
      return;
    }

    setState(() => _verifying = true);
    try {
      final nickname = await AuthService.instance.verifyKakao();
      if (nickname == null) {
        return; // 사용자 취소
      }
      await appState.currentUserController.load();
      if (!mounted) {
        return;
      }
      setState(() => _verifiedNickname = nickname);
      messenger.showSnackBar(
        const SnackBar(content: Text('카카오 인증이 완료됐어요.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('카카오 인증에 실패했어요: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  Future<void> _checkHandle() async {
    if (_checking) {
      return;
    }
    final handle = widget.handleController.text.trim();
    if (!_handlePattern.hasMatch(handle)) {
      setState(() {
        _handleAvailable = false;
        _handleMsg = '영문·숫자 4~12자';
      });
      widget.onHandleAvailabilityChanged(false);
      return;
    }

    setState(() {
      _checking = true;
      _handleMsg = null;
    });
    try {
      final doc = await FirebaseService.instance.handles.doc(handle).get();
      if (!mounted) {
        return;
      }
      final taken = doc.exists;
      setState(() {
        _handleAvailable = !taken;
        _handleMsg = taken ? '이미 사용 중인 아이디예요' : '사용 가능한 아이디예요';
      });
      widget.onHandleAvailabilityChanged(!taken);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _handleAvailable = false;
        _handleMsg = '중복 확인에 실패했어요. 다시 시도해주세요.';
      });
      widget.onHandleAvailabilityChanged(false);
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const accountOptions = ['카카오 알림톡 동의', '마케팅 알림 선택'];
    final appState = AppScope.of(context);
    final verified = _isKakaoVerified(appState) || _verifiedNickname != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _FieldLabel('카카오톡 인증'),
            const Spacer(),
            Text(
              '간편 본인 인증',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (verified)
          AppCard(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE500),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chat_bubble,
                    color: Color(0xFF191600),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '카카오 인증 완료',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.cocoa,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _verifiedDisplayName(appState),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '완료',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: Material(
              color: const Color(0xFFFEE500),
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _verifying ? null : _verifyKakao,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_verifying)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFF191600),
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.chat_bubble,
                          color: Color(0xFF191600),
                          size: 20,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _verifying ? '인증 중...' : '카카오톡으로 인증하기',
                        style: const TextStyle(
                          color: Color(0xFF191600),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 22),
        Row(
          children: [
            const _FieldLabel('앱에서 쓸 아이디'),
            const Spacer(),
            Text(
              '영문·숫자 4~12자',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: widget.handleController,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_handleAvailable || _handleMsg != null) {
                    setState(() {
                      _handleAvailable = false;
                      _handleMsg = null;
                    });
                    widget.onHandleAvailabilityChanged(false);
                  }
                },
                style: const TextStyle(
                  color: AppColors.cocoa,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
                decoration: const InputDecoration(hintText: '예: jiyoon_95'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _checking ? null : _checkHandle,
                child: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('중복확인'),
              ),
            ),
          ],
        ),
        if (_handleMsg != null) ...[
          const SizedBox(height: 8),
          Text(
            _handleMsg!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _handleAvailable ? AppColors.success : AppColors.brandRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in accountOptions)
              _OnboardingPill(
                selected: widget.selected.contains(option),
                label: option,
                onTap: () => widget.onToggle(option),
              ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          color: AppColors.blush.withValues(alpha: 0.72),
          borderColor: AppColors.rose,
          padding: const EdgeInsets.all(14),
          child: Text(
            '카카오톡 인증은 본인 확인용이에요. 매칭 시 연락처는 최종 매칭된 분에게만 공개돼요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cocoa,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionStep extends StatelessWidget {
  const _QuestionStep({
    required this.step,
    required this.choices,
    required this.selected,
    required this.onToggle,
    required this.ageRange,
    required this.heightRange,
    required this.onAgeRangeChanged,
    required this.onHeightRangeChanged,
    required this.handleController,
    required this.onHandleAvailabilityChanged,
    required this.nameController,
    required this.heightController,
    required this.initialBirth,
    required this.onBirthChanged,
  });

  final OnboardingStep step;
  final List<String> choices;
  final Set<String> selected;
  final void Function(OnboardingStep step, String value) onToggle;
  final RangeValues ageRange;
  final RangeValues heightRange;
  final ValueChanged<RangeValues> onAgeRangeChanged;
  final ValueChanged<RangeValues> onHeightRangeChanged;
  final TextEditingController handleController;
  final ValueChanged<bool> onHandleAvailabilityChanged;
  final TextEditingController nameController;
  final TextEditingController heightController;
  final String initialBirth;
  final ValueChanged<String> onBirthChanged;

  @override
  Widget build(BuildContext context) {
    if (step == OnboardingStep.account) {
      return _AccountStep(
        selected: selected,
        onToggle: (value) => onToggle(step, value),
        handleController: handleController,
        onHandleAvailabilityChanged: onHandleAvailabilityChanged,
      );
    }
    if (step == OnboardingStep.basicInfo) {
      return _BasicInfoStep(
        selected: selected,
        onToggle: (value) => onToggle(step, value),
        nameController: nameController,
        heightController: heightController,
        initialBirth: initialBirth,
        onBirthChanged: onBirthChanged,
      );
    }
    if (step == OnboardingStep.rhythm) {
      return _RhythmStep(
        selected: selected,
        onToggle: (value) => onToggle(step, value),
      );
    }
    if (step == OnboardingStep.conversation) {
      return _ConversationStep(
        selected: selected,
        onToggle: (value) => onToggle(step, value),
      );
    }
    if (step == OnboardingStep.lifestyle) {
      return _LifestyleStep(
        selected: selected,
        onToggle: (value) => onToggle(step, value),
      );
    }
    if (step == OnboardingStep.keywords) {
      return _KeywordsStep(
        selected: selected,
        onToggle: (value) => onToggle(step, value),
      );
    }
    if (step == OnboardingStep.preferences) {
      return _PreferenceStep(
        selected: selected,
        onToggle: (value) => onToggle(step, value),
        ageRange: ageRange,
        heightRange: heightRange,
        onAgeRangeChanged: onAgeRangeChanged,
        onHeightRangeChanged: onHeightRangeChanged,
      );
    }
    if (step == OnboardingStep.profilePreview) {
      return _ProfilePreviewStep(
        selected: selected,
        onToggle: (value) => onToggle(step, value),
      );
    }
    if (step == OnboardingStep.verification) {
      return const _VerificationStep();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final choice in choices)
              _OnboardingPill(
                selected: selected.contains(choice),
                label: choice,
                onTap: () => onToggle(step, choice),
              ),
          ],
        ),
      ],
    );
  }
}

class _LifestyleStep extends StatelessWidget {
  const _LifestyleStep({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    const dessertPrefs = ['초콜릿', '과일', '크림', '담백한 빵', '커피 페어링', '구움과자'];
    const drinkPrefs = ['술 거의 안 마심', '가볍게 한 잔'];
    const smokePrefs = ['비흡연', '흡연 상관없음'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('디저트 취향'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pref in dessertPrefs)
              _OnboardingPill(
                selected: selected.contains(pref),
                label: pref,
                onTap: () => onToggle(pref),
              ),
          ],
        ),
        const SizedBox(height: 22),
        const _FieldLabel('주량'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final pref in drinkPrefs) ...[
              Expanded(
                child: _PreferenceCard(
                  label: pref,
                  icon: Icons.local_bar_outlined,
                  selected: selected.contains(pref),
                  onTap: () => onToggle(pref),
                ),
              ),
              if (pref != drinkPrefs.last) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 18),
        const _FieldLabel('흡연'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final pref in smokePrefs) ...[
              Expanded(
                child: _PreferenceCard(
                  label: pref,
                  icon: pref == '비흡연'
                      ? Icons.smoke_free_outlined
                      : Icons.info_outline,
                  selected: selected.contains(pref),
                  onTap: () => onToggle(pref),
                ),
              ),
              if (pref != smokePrefs.last) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 18),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Text(
            '알레르기와 음료 선호는 운영진 확인용으로만 쓰이며, 회차 안내와 베이킹 메뉴 준비에 반영돼요.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.55),
          ),
        ),
      ],
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.burgundy : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? AppColors.gold : AppColors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.butter : AppColors.brandRed,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? Colors.white : AppColors.cocoa,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePreviewStep extends StatelessWidget {
  const _ProfilePreviewStep({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    const checks = [
      '공개 프로필 확인',
      'AI 문장 보정 완료',
      '운영진 확인 정보 분리',
      '오브닝 닉네임 자동 배정',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          color: AppColors.butter.withValues(alpha: 0.62),
          borderColor: AppColors.line,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PUBLIC PREVIEW',
                style: TextStyle(
                  color: AppColors.burgundy,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '천천히 깊어지는 대화를 좋아하는 사람',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.burgundy,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '처음에는 차분하지만 편해지면 취향과 일상 이야기를 자연스럽게 나누는 타입이에요.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.cocoa,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PreviewChip('감성'),
                  _PreviewChip('진중'),
                  _PreviewChip('카페'),
                  _PreviewChip('구움과자'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: const [
              _PreviewRow(label: '상대에게 공개', value: '닉네임 · 나이대 · 직군 · 키워드'),
              Divider(height: 18, color: AppColors.line),
              _PreviewRow(label: '운영진만 확인', value: '실명 · 연락처 · 인증자료 · 선호조건'),
              Divider(height: 18, color: AppColors.line),
              _PreviewRow(
                label: 'AI 분석 사용',
                value: '성향 · 대화스타일 · 취향 · 이상형 키워드',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final check in checks)
              _OnboardingPill(
                selected: selected.contains(check),
                label: check,
                onTap: () => onToggle(check),
              ),
          ],
        ),
      ],
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.burgundy,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.cocoa,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _BasicInfoStep extends StatelessWidget {
  const _BasicInfoStep({
    required this.selected,
    required this.onToggle,
    required this.nameController,
    required this.heightController,
    required this.initialBirth,
    required this.onBirthChanged,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final TextEditingController nameController;
  final TextEditingController heightController;
  final String initialBirth;
  final ValueChanged<String> onBirthChanged;

  @override
  Widget build(BuildContext context) {
    const regions = [
      '서울 강남권',
      '서울 강북권',
      '서울 서남권',
      '서울 동북권',
      '경기 동부',
      '경기 서부',
      '인천',
      '기타',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(label: '프로필 사진 *', note: '신청에 필요해요'),
        const SizedBox(height: 10),
        const _ProfilePhotoRow(),
        const SizedBox(height: 22),
        const _FieldLabel('이름'),
        const SizedBox(height: 8),
        TextFormField(
          controller: nameController,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: AppColors.cocoa,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          decoration: const InputDecoration(hintText: '이름을 입력해주세요'),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('성별'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GenderCard(
                label: '남성',
                icon: Icons.male,
                selected: selected.contains('남성'),
                onTap: () => onToggle('남성'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GenderCard(
                label: '여성',
                icon: Icons.female,
                selected: selected.contains('여성'),
                onTap: () => onToggle('여성'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _FieldLabel('생년월일'),
        const SizedBox(height: 8),
        _BirthDateSpinner(
          initialBirth: initialBirth,
          onChanged: onBirthChanged,
        ),
        const SizedBox(height: 18),
        const _FieldLabel('키'),
        const SizedBox(height: 8),
        TextFormField(
          controller: heightController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            color: AppColors.cocoa,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          decoration: const InputDecoration(
            hintText: '키를 입력해주세요',
            suffixText: 'cm',
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const _FieldLabel('거주 지역'),
            const Spacer(),
            Text(
              '복수 선택 가능',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w400),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final region in regions)
              _OnboardingPill(
                selected: selected.contains(region),
                label: region,
                onTap: () => onToggle(region),
              ),
          ],
        ),
      ],
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.burgundy : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? AppColors.gold : AppColors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.14)
                      : AppColors.blush,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.butter : AppColors.brandRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.cocoa,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check, color: AppColors.butter, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _BirthDateSpinner extends StatefulWidget {
  const _BirthDateSpinner({
    required this.initialBirth,
    required this.onChanged,
  });

  final String initialBirth;
  final ValueChanged<String> onChanged;

  @override
  State<_BirthDateSpinner> createState() => _BirthDateSpinnerState();
}

class _BirthDateSpinnerState extends State<_BirthDateSpinner> {
  static final List<String> _years = List.generate(
    48,
    (index) => '${1978 + index}',
  );
  static final List<String> _months = List.generate(
    12,
    (index) => '${index + 1}'.padLeft(2, '0'),
  );
  static final List<String> _days = List.generate(
    31,
    (index) => '${index + 1}'.padLeft(2, '0'),
  );

  late String _year;
  late String _month;
  late String _day;

  @override
  void initState() {
    super.initState();
    final parts = widget.initialBirth.split('-');
    _year = (parts.isNotEmpty && _years.contains(parts[0])) ? parts[0] : '1995';
    _month = (parts.length > 1 && _months.contains(parts[1])) ? parts[1] : '04';
    _day = (parts.length > 2 && _days.contains(parts[2])) ? parts[2] : '18';
  }

  void _notify() {
    widget.onChanged('$_year-$_month-$_day');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SpinnerColumn(
              values: _years,
              unit: '년',
              initialIndex: _years.indexOf(_year),
              onChanged: (value) {
                _year = value;
                _notify();
              },
            ),
          ),
          const _SpinnerDivider(),
          Expanded(
            child: _SpinnerColumn(
              values: _months,
              unit: '월',
              initialIndex: _months.indexOf(_month),
              onChanged: (value) {
                _month = value;
                _notify();
              },
            ),
          ),
          const _SpinnerDivider(),
          Expanded(
            child: _SpinnerColumn(
              values: _days,
              unit: '일',
              initialIndex: _days.indexOf(_day),
              onChanged: (value) {
                _day = value;
                _notify();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SpinnerColumn extends StatelessWidget {
  const _SpinnerColumn({
    required this.values,
    required this.unit,
    required this.initialIndex,
    this.onChanged,
  });

  final List<String> values;
  final String unit;
  final int initialIndex;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      itemExtent: 34,
      diameterRatio: 1.25,
      squeeze: 1.05,
      scrollController: FixedExtentScrollController(
        initialItem: initialIndex < 0 ? 0 : initialIndex,
      ),
      selectionOverlay: Container(
        decoration: BoxDecoration(
          color: AppColors.blush.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onSelectedItemChanged: (index) {
        if (index >= 0 && index < values.length) {
          onChanged?.call(values[index]);
        }
      },
      children: [
        for (final value in values)
          Center(
            child: Text(
              '$value $unit',
              style: const TextStyle(
                color: AppColors.cocoa,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}

class _SpinnerDivider extends StatelessWidget {
  const _SpinnerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 82, color: AppColors.line);
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.cocoa,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _RhythmStep extends StatelessWidget {
  const _RhythmStep({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    const jobs = [
      '의료/보건',
      'IT/개발',
      '교육',
      '공공기관',
      '금융',
      '디자인/콘텐츠',
      '서비스',
      '자영업/사업',
      '프리랜서',
      '학생',
      '기타',
    ];
    const times = ['평일 저녁', '토요일 오전', '토요일 오후', '토요일 저녁', '일요일 오전', '일요일 오후'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('직업군'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final job in jobs)
              _OnboardingPill(
                label: job,
                selected: selected.contains(job),
                onTap: () => onToggle(job),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const _FieldLabel('직장 / 파트'),
            const Spacer(),
            Text(
              '공개되지 않아요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: '서비스기획팀',
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: AppColors.cocoa,
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
          decoration: const InputDecoration(hintText: '직장 또는 파트를 입력해주세요'),
        ),
        const SizedBox(height: 22),
        const _FieldLabel('근무 패턴'),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.05,
          children: [
            _WorkPatternCard(
              title: '평일 주간',
              subtitle: '9시 - 6시 근무',
              selected: selected.contains('평일 주간'),
              onTap: () => onToggle('평일 주간'),
            ),
            _WorkPatternCard(
              title: '교대근무',
              subtitle: '주야 교대',
              selected: selected.contains('교대근무'),
              onTap: () => onToggle('교대근무'),
            ),
            _WorkPatternCard(
              title: '주말근무',
              subtitle: '평일 휴무형',
              selected: selected.contains('주말근무'),
              onTap: () => onToggle('주말근무'),
            ),
            _WorkPatternCard(
              title: '프리랜서형',
              subtitle: '유연 근무',
              selected: selected.contains('프리랜서형'),
              onTap: () => onToggle('프리랜서형'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const _FieldLabel('가능한 시간대'),
            const Spacer(),
            Text(
              '여러 개 선택',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final time in times)
              _OnboardingPill(
                label: time,
                selected: selected.contains(time),
                onTap: () => onToggle(time),
              ),
          ],
        ),
      ],
    );
  }
}

class _WorkPatternCard extends StatelessWidget {
  const _WorkPatternCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.burgundy : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: selected ? AppColors.gold : AppColors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.14)
                      : AppColors.blush,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule,
                  color: selected ? AppColors.butter : AppColors.brandRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.cocoa,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.76)
                            : AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check, color: AppColors.butter, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPill extends StatelessWidget {
  const _OnboardingPill({
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
      color: selected ? AppColors.burgundy : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.burgundy : AppColors.line,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.cocoa,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// STEP 4 — 취향 기반 케미.
/// ① 가까워지기 좋은 순간(chips, 최대 3) ② 함께하면 편한 분위기(카드)
/// ③ 주말에 가장 끌리는 건(카드) ④ 취향 키워드(chips)
class _ConversationStep extends StatelessWidget {
  const _ConversationStep({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    const closeMoments = [
      '같이 무언가를 만들 때',
      '맛있는 걸 나눠 먹을 때',
      '취향 이야기를 할 때',
      '가벼운 게임을 할 때',
      '산책하거나 움직일 때',
      '웃긴 이야기를 나눌 때',
      '조용히 집중할 때',
      '서로 질문을 주고받을 때',
    ];
    const vibes = <(String, IconData)>[
      ('차분하고 따뜻한', Icons.favorite_border),
      ('웃음이 많은', Icons.auto_awesome),
      ('가볍고 편한', Icons.auto_awesome),
      ('진지한 이야기도', Icons.favorite_border),
      ('함께 집중하는', Icons.science_outlined),
      ('새로운 경험을', Icons.science_outlined),
    ];
    const weekend = <(String, IconData)>[
      ('맛집·카페 탐방', Icons.local_fire_department_outlined),
      ('전시·영화·공연', Icons.auto_awesome),
      ('산책·운동', Icons.favorite_border),
      ('집에서 휴식', Icons.home_outlined),
      ('여행·드라이브', Icons.location_on_outlined),
      ('원데이 클래스', Icons.science_outlined),
    ];
    const tasteKeywords = [
      '영화',
      '음악',
      '전시',
      '여행',
      '맛집',
      '카페',
      '운동',
      '독서',
      '사진',
      '요리',
      '게임',
      '반려동물',
      '패션',
      '자기계발',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _FieldLabel('가까워지기 좋은 순간'),
            const Spacer(),
            Text(
              '최대 3개',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final moment in closeMoments)
              _OnboardingPill(
                label: moment,
                selected: selected.contains(moment),
                onTap: () => onToggle(moment),
              ),
          ],
        ),
        const SizedBox(height: 22),
        const _FieldLabel('함께하면 편한 분위기'),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.05,
          children: [
            for (final item in vibes)
              _LifestyleCard(
                label: item.$1,
                icon: item.$2,
                selected: selected.contains(item.$1),
                onTap: () => onToggle(item.$1),
              ),
          ],
        ),
        const SizedBox(height: 22),
        const _FieldLabel('주말에 가장 끌리는 건'),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.05,
          children: [
            for (final item in weekend)
              _LifestyleCard(
                label: item.$1,
                icon: item.$2,
                selected: selected.contains(item.$1),
                onTap: () => onToggle(item.$1),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const _FieldLabel('취향 키워드'),
            const Spacer(),
            Text(
              '대화가 자연스럽게 시작될 취향',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final keyword in tasteKeywords)
              _OnboardingPill(
                label: keyword,
                selected: selected.contains(keyword),
                onTap: () => onToggle(keyword),
              ),
            _AddPill(onTap: () {}),
          ],
        ),
      ],
    );
  }
}

class _LifestyleCard extends StatelessWidget {
  const _LifestyleCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.burgundy : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: selected ? AppColors.gold : AppColors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.14)
                      : AppColors.blush,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.butter : AppColors.brandRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.cocoa,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check, color: AppColors.butter, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPill extends StatelessWidget {
  const _AddPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 17, color: AppColors.cocoa),
              SizedBox(width: 8),
              Text(
                '직접 입력',
                style: TextStyle(
                  color: AppColors.cocoa,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeywordsStep extends StatelessWidget {
  const _KeywordsStep({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    const keywords = [
      '다정한',
      '성실한',
      '유쾌한',
      '차분한',
      '배려 깊은',
      '솔직한',
      '책임감 있는',
      '감성적인',
      '현실적인',
      '도전적인',
      '섬세한',
      '긍정적인',
    ];
    const selfTypes = [
      ('천천히 깊어지는 사람', Icons.hourglass_empty),
      ('대화가 잘 통하면 금방 가까워지는 사람', Icons.chat_bubble_outline),
      ('웃음 코드가 중요한 사람', Icons.sentiment_satisfied_alt),
      ('안정감과 신뢰를 중요하게 보는 사람', Icons.shield_outlined),
      ('새로운 경험을 함께하는 걸 좋아하는 사람', Icons.explore_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _FieldLabel('키워드'),
            const Spacer(),
            Text(
              '최대 3개',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final keyword in keywords)
              _OnboardingPill(
                label: keyword,
                selected: selected.contains(keyword),
                onTap: () => onToggle(keyword),
              ),
          ],
        ),
        const SizedBox(height: 22),
        const _FieldLabel('나는 이런 사람에 가까워요'),
        const SizedBox(height: 10),
        for (final item in selfTypes) ...[
          _SelfTypeCard(
            label: item.$1,
            icon: item.$2,
            selected: selected.contains(item.$1),
            onTap: () => onToggle(item.$1),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        const _FieldLabel('이상형을 짧게 적어주세요'),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: '대화가 편안하고 웃음 코드가 맞는 사람',
          minLines: 2,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(
            color: AppColors.cocoa,
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
          decoration: const InputDecoration(
            hintText: '예: 대화가 편안하고 웃음 코드가 맞는 사람',
          ),
        ),
      ],
    );
  }
}

class _PreferenceStep extends StatelessWidget {
  const _PreferenceStep({
    required this.selected,
    required this.onToggle,
    required this.ageRange,
    required this.heightRange,
    required this.onAgeRangeChanged,
    required this.onHeightRangeChanged,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final RangeValues ageRange;
  final RangeValues heightRange;
  final ValueChanged<RangeValues> onAgeRangeChanged;
  final ValueChanged<RangeValues> onHeightRangeChanged;

  @override
  Widget build(BuildContext context) {
    const mbtiOptions = [
      ('상관없음', 'mbti:상관없음'),
      ('ENFP', 'mbti:ENFP'),
      ('ENFJ', 'mbti:ENFJ'),
      ('INFJ', 'mbti:INFJ'),
      ('INFP', 'mbti:INFP'),
      ('ESTJ', 'mbti:ESTJ'),
      ('ISTJ', 'mbti:ISTJ'),
      ('ESTP', 'mbti:ESTP'),
    ];
    const religionOptions = [
      ('상관없음', 'religion:상관없음'),
      ('무교', 'religion:무교'),
      ('기독교', 'religion:기독교'),
      ('천주교', 'religion:천주교'),
      ('불교', 'religion:불교'),
      ('기타', 'religion:기타'),
    ];
    const cautionJobOptions = [
      ('없음', 'job:없음'),
      ('고위공무', 'job:고위공무'),
      ('같은 직장군', 'job:같은 직장군'),
      ('영업직', 'job:영업직'),
      ('자영업', 'job:자영업'),
      ('프리랜서', 'job:프리랜서'),
      ('군인/경찰/소방', 'job:군인/경찰/소방'),
      ('기타', 'job:기타'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _FieldLabel('선호 나이대'),
            const Spacer(),
            Text(
              '범위',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PreferenceAgeCard(
          range: ageRange,
          onChanged: onAgeRangeChanged,
          selected: selected.contains('age:any'),
          onTap: () => onToggle('age:any'),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const _FieldLabel('상대 이상형 키'),
            const Spacer(),
            Text(
              '범위',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PreferenceHeightCard(
          range: heightRange,
          onChanged: onHeightRangeChanged,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const _FieldLabel('선호 MBTI'),
            const Spacer(),
            Text(
              '여러 개 / 상관없음',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _PreferencePillWrap(
          options: mbtiOptions,
          selected: selected,
          onToggle: onToggle,
        ),
        const SizedBox(height: 22),
        const _FieldLabel('선호 종교'),
        const SizedBox(height: 10),
        _PreferencePillWrap(
          options: religionOptions,
          selected: selected,
          onToggle: onToggle,
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const _FieldLabel('조심했으면 하는 직군'),
            const Spacer(),
            Flexible(
              child: Text(
                '미팅 시 조심했으면 하는 조건',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _PreferencePillWrap(
          options: cautionJobOptions,
          selected: selected,
          onToggle: onToggle,
        ),
        const SizedBox(height: 24),
        const _PreferencePrivacyNotice(),
      ],
    );
  }
}

class _PreferencePillWrap extends StatelessWidget {
  const _PreferencePillWrap({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final List<(String, String)> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        for (final option in options)
          _OnboardingPill(
            label: option.$1,
            selected: selected.contains(option.$2),
            onTap: () => onToggle(option.$2),
          ),
      ],
    );
  }
}

class _PreferenceAgeCard extends StatelessWidget {
  const _PreferenceAgeCard({
    required this.range,
    required this.onChanged,
    required this.selected,
    required this.onTap,
  });

  final RangeValues range;
  final ValueChanged<RangeValues> onChanged;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${range.start.round()} 세',
                style: const TextStyle(
                  color: AppColors.burgundy,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Text(
                '${range.end.round()} 세',
                style: const TextStyle(
                  color: AppColors.burgundy,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.burgundy,
              inactiveTrackColor: AppColors.line,
              thumbColor: Colors.white,
              overlayColor: AppColors.burgundy.withValues(alpha: 0.12),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 11,
              ),
            ),
            child: RangeSlider(
              values: range,
              min: 24,
              max: 42,
              divisions: 18,
              onChanged: onChanged,
            ),
          ),
          const Row(
            children: [
              Text(
                '24 세',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Spacer(),
              Text(
                '42 세',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  '크게 상관없어요',
                  style: TextStyle(
                    color: selected ? AppColors.burgundy : AppColors.mutedText,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    decoration: selected
                        ? TextDecoration.underline
                        : TextDecoration.none,
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

class _PreferenceHeightCard extends StatelessWidget {
  const _PreferenceHeightCard({required this.range, required this.onChanged});

  final RangeValues range;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${range.start.round()} cm',
                style: const TextStyle(
                  color: AppColors.burgundy,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Text(
                '${range.end.round()} cm',
                style: const TextStyle(
                  color: AppColors.burgundy,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.burgundy,
              inactiveTrackColor: AppColors.line,
              thumbColor: Colors.white,
              overlayColor: AppColors.burgundy.withValues(alpha: 0.12),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 11,
              ),
            ),
            child: RangeSlider(
              values: range,
              min: 155,
              max: 195,
              divisions: 40,
              onChanged: onChanged,
            ),
          ),
          const Row(
            children: [
              Text(
                '155 cm',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Spacer(),
              Text(
                '195 cm',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreferencePrivacyNotice extends StatelessWidget {
  const _PreferencePrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: AppColors.burgundy, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '선호 조건은 상대방에게 공개되지 않아요. 회차 추천과 인원 구성 참고용으로만 사용됩니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfTypeCard extends StatelessWidget {
  const _SelfTypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.burgundy : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? AppColors.gold : AppColors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.14)
                      : AppColors.blush,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.butter : AppColors.brandRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.cocoa,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check, color: AppColors.butter, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultStep extends StatelessWidget {
  const _ResultStep({required this.character});

  final ChemistryCharacter character;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.burgundy, size: 16),
            SizedBox(width: 8),
            Text(
              'CHEMISTRY ANALYSIS',
              style: TextStyle(
                color: AppColors.burgundy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          '케미 분석이 완료되었어요.',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          '내 성향을 가장 잘 닮은 케미 캐릭터를 찾았어요.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),
        _ChemistryResultCard(character: character),
        const SizedBox(height: 16),
        const _CharacterNoticeCard(),
      ],
    );
  }
}

class _ChemistryResultCard extends StatelessWidget {
  const _ChemistryResultCard({required this.character});

  final ChemistryCharacter character;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B0920), AppColors.wine],
        ),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR CHEMISTRY',
                style: TextStyle(
                  color: AppColors.butter,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.butter.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Text(
                      character.initial,
                      style: const TextStyle(
                        color: AppColors.butter,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${character.englishName} · ${character.summary}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.74),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                character.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in character.tags.take(4))
                    _ResultTag(label: tag),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultTag extends StatelessWidget {
  const _ResultTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.butter,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.wine,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CharacterNoticeCard extends StatelessWidget {
  const _CharacterNoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.burgundy, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '이 캐릭터는 나의 기본 케미 캐릭터예요. 회차 참여 시에는 오브닝 전용 닉네임이 새롭게 배정될 수 있어요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                height: 1.55,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultActionRow extends StatelessWidget {
  const _ResultActionRow({
    required this.onOpenLab,
    required this.onOpenSchedule,
  });

  final VoidCallback onOpenLab;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onOpenLab,
            child: const Text('케미Lab'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: onOpenSchedule,
            child: const Text('일정 보러가기'),
          ),
        ),
      ],
    );
  }
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandRed),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _VerificationStep extends StatefulWidget {
  const _VerificationStep();

  @override
  State<_VerificationStep> createState() => _VerificationStepState();
}

enum _JobType { company, self, freelance, employed, jobseeker }

class _VerificationStepState extends State<_VerificationStep> {
  static const List<({_JobType type, IconData icon, String label})> _jobTypes =
      [
    (type: _JobType.company, icon: Icons.credit_card_outlined, label: '회사원'),
    (
      type: _JobType.self,
      icon: Icons.local_fire_department_outlined,
      label: '자영업'
    ),
    (type: _JobType.freelance, icon: Icons.science_outlined, label: '프리랜서'),
    (type: _JobType.employed, icon: Icons.check_circle_outline, label: '재직중'),
    (type: _JobType.jobseeker, icon: Icons.schedule_outlined, label: '취업준비중'),
  ];

  _JobType _jobType = _JobType.company;
  bool _checkAgreed = false;

  // 제출 완료된 인증 자료 (label 기준).
  final Set<String> _submittedDocs = {};
  // 업로드 진행 중인 인증 자료 (label 기준).
  final Set<String> _uploadingDocs = {};

  // 카카오 인증 진행 중 여부.
  bool _verifyingKakao = false;

  // 유형별 입력 컨트롤러.
  final TextEditingController _companyCtrl = TextEditingController();
  final TextEditingController _positionCtrl = TextEditingController();
  final TextEditingController _storeCtrl = TextEditingController();
  final TextEditingController _activityCtrl = TextEditingController();

  @override
  void dispose() {
    _companyCtrl.dispose();
    _positionCtrl.dispose();
    _storeCtrl.dispose();
    _activityCtrl.dispose();
    super.dispose();
  }

  bool _isKakaoVerified(AppState appState) {
    final profile = appState.currentUserController.profile;
    if (profile == null) return false;
    return profile.provider == 'kakao' || profile.kakaoVerified == true;
  }

  Future<void> _verifyKakao() async {
    if (_verifyingKakao) return;
    final messenger = ScaffoldMessenger.of(context);
    final appState = AppScope.of(context);
    final uid = FirebaseService.instance.uid;
    if (uid == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('로그인 후 카카오 인증을 진행할 수 있어요.')),
      );
      return;
    }

    setState(() => _verifyingKakao = true);
    try {
      final nickname = await AuthService.instance.verifyKakao();
      if (nickname == null) return; // 사용자 취소
      await appState.currentUserController.load();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('카카오 인증이 완료됐어요.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('카카오 인증에 실패했어요: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _verifyingKakao = false);
      }
    }
  }

  Future<void> _submitDocument(String label) async {
    if (_uploadingDocs.contains(label) || _submittedDocs.contains(label)) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final uid = FirebaseService.instance.uid;
    if (uid == null) {
      messenger.showSnackBar(const SnackBar(content: Text('로그인 후 제출할 수 있어요')));
      return;
    }
    final file = await StorageService.instance.pickImage();
    if (file == null) return;

    if (!mounted) return;
    setState(() => _uploadingDocs.add(label));
    try {
      final url = await StorageService.instance.uploadJobVerification(
        uid,
        file,
      );
      await UserService.instance.submitJobVerification(uid, url);
      if (!mounted) return;
      setState(() {
        _uploadingDocs.remove(label);
        _submittedDocs.add(label);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingDocs.remove(label));
      messenger.showSnackBar(
        const SnackBar(content: Text('제출에 실패했어요. 잠시 후 다시 시도해주세요.')),
      );
    }
  }

  Widget _uploadRow(String label) {
    return _VerificationDocumentCard(
      icon: Icons.camera_alt_outlined,
      title: label,
      submitted: _submittedDocs.contains(label),
      uploading: _uploadingDocs.contains(label),
      onTap: () => _submitDocument(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final kakaoVerified = _isKakaoVerified(appState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 카카오톡 · 실명 인증 ──────────────────────────────
        const _SectionHeader(label: '카카오톡 · 실명 인증', note: '본인 확인'),
        const SizedBox(height: 10),
        if (kakaoVerified)
          _KakaoVerifiedCard(
            name: appState.currentUserController.profile?.displayName ?? '',
          )
        else
          SizedBox(
            width: double.infinity,
            child: Material(
              color: const Color(0xFFFEE500),
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _verifyingKakao ? null : _verifyKakao,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_verifyingKakao)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFF191600),
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.chat_bubble,
                          color: Color(0xFF191600),
                          size: 20,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _verifyingKakao ? '인증 중...' : '카카오톡으로 인증하기',
                        style: const TextStyle(
                          color: Color(0xFF191600),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // ── 직업 유형 ────────────────────────────────────────
        const SizedBox(height: 24),
        const _SectionHeader(label: '직업 유형', note: '해당하는 유형 선택'),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            for (final item in _jobTypes)
              _JobTypeCard(
                label: item.label,
                icon: item.icon,
                selected: _jobType == item.type,
                onTap: () => setState(() => _jobType = item.type),
              ),
          ],
        ),

        // ── 유형별 입력 영역 ─────────────────────────────────
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.blush.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: _buildTypeSection(context),
        ),

        // ── 하단 안내 ────────────────────────────────────────
        const SizedBox(height: 16),
        AppCard(
          color: AppColors.blush.withValues(alpha: 0.72),
          borderColor: AppColors.rose,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppColors.brandRed,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '운영진이 직접 확인 후 승인해요. 인증 자료는 검수 목적으로만 사용되고 곧 폐기돼요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.cocoa,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSection(BuildContext context) {
    switch (_jobType) {
      case _JobType.company:
        return _typeColumn(
          context,
          title: '회사원 · 재직 인증',
          desc: '회사명(또는 사업자명)과 직급을 적어주세요. 인증은 아래 한 가지만 하면 돼요.',
          children: [
            _typeField(_companyCtrl, '회사명 또는 사업자명 (예: ○○주식회사)'),
            const SizedBox(height: 8),
            _typeField(_positionCtrl, '직급 / 직책 (예: 대리 · 백엔드 개발)'),
            const SizedBox(height: 10),
            _uploadRow('명함 · 사원증 · 재직증명서 중 1장'),
            const _OrDivider(),
            _uploadRow('회사 이메일로 인증 코드 받기'),
          ],
        );
      case _JobType.self:
        return _typeColumn(
          context,
          title: '자영업자 인증',
          desc: '사업자등록증 또는 활동 증빙 사진 중 하나면 돼요.',
          children: [
            _typeField(_storeCtrl, '가게 / 사업장 이름'),
            const SizedBox(height: 10),
            _uploadRow('사업자 등록증 사진'),
            const _OrDivider(),
            _uploadRow('활동 증빙 사진 (영업 현장 · 간판 등)'),
          ],
        );
      case _JobType.freelance:
        return _typeColumn(
          context,
          title: '프리랜서 인증',
          desc: '강의명 또는 온라인 활동(블로그·인스타 등) 중 하나면 돼요.',
          children: [
            _typeField(_activityCtrl, '강의명 / 주요 활동 (예: ○○ 클래스 · ○○ 채널)'),
            const SizedBox(height: 10),
            _uploadRow('강의 페이지 · 블로그 · 인스타 스크린샷'),
            const _OrDivider(),
            _uploadRow('사업자 등록증 사진 (있는 경우)'),
          ],
        );
      case _JobType.employed:
      case _JobType.jobseeker:
        final isEmployed = _jobType == _JobType.employed;
        return _typeColumn(
          context,
          title: '${isEmployed ? '재직중' : '취업준비중'} · 간편 확인',
          desc: '서류 제출 없이 체크만 하고 넘어갈 수 있어요. 필요 시 운영진이 추가 확인을 요청할 수 있어요.',
          children: [
            const SizedBox(height: 4),
            _CheckConfirmButton(
              label: isEmployed ? '현재 재직 중이 맞아요.' : '현재 취업 준비 중이 맞아요.',
              checked: _checkAgreed,
              onTap: () => setState(() => _checkAgreed = !_checkAgreed),
            ),
          ],
        );
    }
  }

  Widget _typeColumn(
    BuildContext context, {
    required String title,
    required String desc,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.cocoa,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _typeField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: AppColors.cocoa,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(hintText: hint),
    );
  }
}

/// 카카오 인증 완료 카드 (초록 체크).
class _KakaoVerifiedCard extends StatelessWidget {
  const _KakaoVerifiedCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check, color: AppColors.success, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '카카오 인증 완료',
                  style: TextStyle(
                    color: AppColors.cocoa,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name.isEmpty ? '카카오톡 · 실명 확인됨' : '$name · 실명 확인됨',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '완료',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 직업 유형 선택 카드 (3열 그리드).
class _JobTypeCard extends StatelessWidget {
  const _JobTypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.burgundy : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.gold : AppColors.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.butter : AppColors.burgundy,
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.cocoa,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// '또는' 구분선.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.line, height: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '또는',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.line, height: 1)),
        ],
      ),
    );
  }
}

/// 재직중/취업준비중 확인용 체크박스형 버튼.
class _CheckConfirmButton extends StatelessWidget {
  const _CheckConfirmButton({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: checked ? AppColors.burgundy : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: checked ? AppColors.gold : AppColors.line,
          width: checked ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: checked ? AppColors.gold : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: checked
                      ? null
                      : Border.all(color: AppColors.line),
                ),
                child: checked
                    ? const Icon(
                        Icons.check,
                        color: AppColors.burgundy,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: checked ? Colors.white : AppColors.cocoa,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.note});

  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _FieldLabel(label),
        const Spacer(),
        Flexible(
          child: Text(
            note,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

/// 기본 정보(STEP 2) 프로필 사진 업로드 행: 대표 + 추가 2칸.
/// 대표(slot 0)는 users/{uid}.photoURL, 나머지는 photos 배열에 저장.
class _ProfilePhotoRow extends StatefulWidget {
  const _ProfilePhotoRow();

  @override
  State<_ProfilePhotoRow> createState() => _ProfilePhotoRowState();
}

class _ProfilePhotoRowState extends State<_ProfilePhotoRow> {
  final Map<int, String> _photoUrls = {};
  final Set<int> _uploading = {};

  @override
  void initState() {
    super.initState();
    // 이미 업로드된 대표 사진이 있으면 첫 칸에 반영.
    final photoURL = FirebaseService.instance.currentUser?.photoURL;
    if (photoURL != null && photoURL.isNotEmpty) {
      _photoUrls[0] = photoURL;
    }
  }

  Future<void> _upload(int slot) async {
    if (_uploading.contains(slot)) return;
    final messenger = ScaffoldMessenger.of(context);
    final uid = FirebaseService.instance.uid;
    if (uid == null) {
      messenger.showSnackBar(const SnackBar(content: Text('로그인 후 업로드할 수 있어요')));
      return;
    }
    final file = await StorageService.instance.pickImage();
    if (file == null) return;

    if (!mounted) return;
    setState(() => _uploading.add(slot));
    try {
      final url = await StorageService.instance.uploadProfilePhoto(uid, file);
      if (slot == 0) {
        await UserService.instance.updatePhotoURL(uid, url);
      } else {
        await UserService.instance.addProfilePhoto(uid, url);
      }
      if (!mounted) return;
      AppScope.of(context).currentUserController.load();
      setState(() {
        _uploading.remove(slot);
        _photoUrls[slot] = url;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploading.remove(slot));
      messenger.showSnackBar(
        const SnackBar(content: Text('업로드에 실패했어요. 잠시 후 다시 시도해주세요.')),
      );
    }
  }

  Widget _slot(int slot, {IconData? icon, String? label}) {
    return _PhotoUploadSlot(
      icon: icon ?? Icons.add,
      label: label,
      imageUrl: _photoUrls[slot],
      uploading: _uploading.contains(slot),
      onTap: () => _upload(slot),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _slot(0, icon: Icons.camera_alt_outlined, label: '대표 *'),
        ),
        const SizedBox(width: 10),
        Expanded(child: _slot(1, label: '추가')),
        const SizedBox(width: 10),
        Expanded(child: _slot(2, label: '추가')),
      ],
    );
  }
}

class _PhotoUploadSlot extends StatelessWidget {
  const _PhotoUploadSlot({
    this.icon = Icons.add,
    this.label,
    this.imageUrl,
    this.uploading = false,
    this.onTap,
  });

  final IconData icon;
  final String? label;
  final String? imageUrl;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final selected = hasImage;

    Widget content;
    if (hasImage) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.mutedText,
              size: 26,
            ),
          ),
        ),
      );
    } else if (uploading) {
      content = const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.burgundy),
          ),
        ),
      );
    } else {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.mutedText, size: 28),
            if (label != null) ...[
              const SizedBox(height: 8),
              Text(
                label!,
                style: const TextStyle(
                  color: AppColors.cocoa,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: hasImage
            ? content
            : CustomPaint(
                painter: _DashedRoundedBorderPainter(
                  color: selected
                      ? AppColors.line
                      : AppColors.line.withValues(alpha: 0.9),
                  fillColor: Colors.white.withValues(alpha: 0.56),
                ),
                child: content,
              ),
      ),
    );
  }
}

class _VerificationDocumentCard extends StatelessWidget {
  const _VerificationDocumentCard({
    required this.icon,
    required this.title,
    this.submitted = false,
    this.uploading = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool submitted;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final selected = submitted;
    final String subtitle;
    if (uploading) {
      subtitle = '제출 중…';
    } else if (submitted) {
      subtitle = '제출됨 — 운영진 확인 대기';
    } else {
      subtitle = '탭하여 자료 제출';
    }

    return Material(
      color: selected ? AppColors.burgundy : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: uploading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.line,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.14)
                      : AppColors.blush,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.butter : AppColors.burgundy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.cocoa,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.74)
                            : AppColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (uploading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.burgundy),
                  ),
                )
              else if (submitted)
                const Icon(Icons.check, color: AppColors.butter, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.fillColor,
  });

  final Color color;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    final path = Path()..addRRect(rrect.deflate(0.5));
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 5.0;
    const gap = 5.0;
    var distance = 0.0;
    while (distance < metric.length) {
      final next = distance + dash;
      canvas.drawPath(
        metric.extractPath(
          distance,
          next > metric.length ? metric.length : next,
        ),
        paint,
      );
      distance = next + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.fillColor != fillColor;
  }
}
