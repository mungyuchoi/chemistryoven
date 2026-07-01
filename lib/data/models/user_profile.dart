/// users/{uid} 문서를 읽어 화면에서 쓰는 사용자 프로필 모델.
/// 스키마는 docs/ARCHITECTURE_PLAN.md §3.2 참고.
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoURL,
    this.gender,
    this.mbti,
    this.region,
    this.baseCharacterId,
    this.onboardingCompleted = false,
    this.roles = const [],
    this.provider,
    this.handle,
    this.kakaoVerified = false,
    this.jobVerificationStatus,
    this.photoVerificationStatus,
  });

  final String uid;
  final String displayName;
  final String? email;
  final String? photoURL;
  final String? gender; // 'M' | 'F'
  final String? mbti;
  final String? region;
  final String? baseCharacterId;
  final bool onboardingCompleted;
  final List<String> roles;
  final String? provider; // 'google' | 'apple' | 'kakao'
  final String? handle; // 앱에서 쓸 아이디
  final bool kakaoVerified;

  /// verification.job: 'pending' | 'approved' | 'rejected' | null(미제출)
  final String? jobVerificationStatus;

  /// verification.photo: 'pending' | 'approved' | 'rejected' | null(미제출)
  final String? photoVerificationStatus;

  /// 실명(카카오) 인증 완료 여부.
  /// 프로젝트에서 실명 인증 = 카카오 인증으로 취급한다.
  bool get isRealNameVerified => kakaoVerified;

  /// 직장 인증이 운영진 승인(approved)된 경우에만 true.
  bool get isJobVerified => jobVerificationStatus == 'approved';

  /// 직장 인증 자료 제출 후 운영진 승인 대기 중.
  bool get isJobVerificationPending => jobVerificationStatus == 'pending';

  /// '남성' | '여성' | null
  String? get genderKr => switch (gender) {
    'M' => '남성',
    'F' => '여성',
    _ => null,
  };

  bool get isAdmin => roles.contains('admin');

  /// [data] 는 users/{uid} 문서, [onboardingData] 는
  /// users/{uid}/onboarding/current 서브컬렉션 문서(있으면).
  factory UserProfile.fromMap(
    String uid,
    Map<String, dynamic> data, {
    Map<String, dynamic>? onboardingData,
  }) {
    // 하위 호환: 서브컬렉션 문서가 없으면 구(舊) 임베디드 맵을 사용.
    final onboarding =
        onboardingData ?? (data['onboarding'] as Map<String, dynamic>?) ?? const {};
    final verification =
        (data['verification'] as Map<String, dynamic>?) ?? const {};
    return UserProfile(
      uid: uid,
      displayName: (data['displayName'] as String?) ?? '케미오븐 사용자',
      email: data['email'] as String?,
      photoURL: data['photoURL'] as String?,
      gender: data['gender'] as String?,
      mbti: data['mbti'] as String?,
      region: data['region'] as String?,
      baseCharacterId: onboarding['baseCharacterId'] as String?,
      onboardingCompleted: (data['onboardingCompleted'] as bool?) ??
          (onboarding['completed'] as bool?) ??
          false,
      roles: (data['roles'] as List<dynamic>?)
              ?.map((role) => role.toString())
              .toList(growable: false) ??
          const [],
      provider: data['provider'] as String?,
      handle: data['handle'] as String?,
      kakaoVerified: (data['kakaoVerified'] as bool?) ?? false,
      jobVerificationStatus: verification['job'] as String?,
      photoVerificationStatus: verification['photo'] as String?,
    );
  }
}
