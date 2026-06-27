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

  /// '남성' | '여성' | null
  String? get genderKr => switch (gender) {
    'M' => '남성',
    'F' => '여성',
    _ => null,
  };

  bool get isAdmin => roles.contains('admin');

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    final onboarding =
        (data['onboarding'] as Map<String, dynamic>?) ?? const {};
    return UserProfile(
      uid: uid,
      displayName: (data['displayName'] as String?) ?? '케미오븐 사용자',
      email: data['email'] as String?,
      photoURL: data['photoURL'] as String?,
      gender: data['gender'] as String?,
      mbti: data['mbti'] as String?,
      region: data['region'] as String?,
      baseCharacterId: onboarding['baseCharacterId'] as String?,
      onboardingCompleted: (onboarding['completed'] as bool?) ?? false,
      roles: (data['roles'] as List<dynamic>?)
              ?.map((role) => role.toString())
              .toList(growable: false) ??
          const [],
    );
  }
}
