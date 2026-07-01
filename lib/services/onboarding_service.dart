import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/demo_models.dart';
import 'firebase_service.dart';

/// 온보딩 결과를 users/{uid}.onboarding 에 저장한다.
/// 스키마는 docs/ARCHITECTURE_PLAN.md §3.2 참고.
class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  /// 온보딩 완료 시 저장. 비로그인(게스트)면 false 반환하고 아무 것도 안 함.
  Future<bool> saveOnboarding({
    required String genderKr, // '남성' | '여성' | ''
    required Map<OnboardingStep, Set<String>> selected,
    required List<double> ageRange, // [start, end]
    required double heightMin,
    required String baseCharacterId,
  }) async {
    final uid = FirebaseService.instance.uid;
    if (uid == null) {
      return false;
    }

    final basic = selected[OnboardingStep.basicInfo] ?? const <String>{};
    final region = basic.firstWhere(
      (value) => value != '남성' && value != '여성',
      orElse: () => '',
    );
    final mbti = _firstMbti(selected[OnboardingStep.conversation]);

    final prefs = selected[OnboardingStep.preferences] ?? const <String>{};
    final preferences = <String, dynamic>{
      'ageRange': [ageRange.first.round(), ageRange.last.round()],
      'heightMin': heightMin.round(),
      'mbti': _stripPrefix(prefs, 'mbti:'),
      'religion': _stripPrefix(prefs, 'religion:'),
      'avoidJobs': _stripPrefix(prefs, 'job:')
          .where((value) => value != '없음')
          .toList(growable: false),
    };

    // 단계별 응답 원본 (PSYCHOLOGY 점수 산출용)
    final answers = <String, dynamic>{};
    selected.forEach((step, values) {
      answers[step.name] = values.toList(growable: false);
    });

    // 설문 원본/선호값/기본 캐릭터는 users 문서에서 분리해
    // users/{uid}/onboarding/current 서브컬렉션에 저장한다.
    await FirebaseService.instance.onboardingDoc(uid).set({
      'completed': true,
      'baseCharacterId': baseCharacterId,
      'answers': answers,
      'preferences': preferences,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // users 문서에는 프로필 표시용 스칼라 필드와 완료 플래그만 남긴다.
    final userPayload = <String, dynamic>{
      'onboardingCompleted': true,
      if (genderKr.isNotEmpty) 'gender': genderKr == '남성' ? 'M' : 'F',
      if (region.isNotEmpty) 'region': region,
      if (mbti.isNotEmpty) 'mbti': mbti,
      'lastActiveAt': FieldValue.serverTimestamp(),
    };

    await FirebaseService.instance
        .userDoc(uid)
        .set(userPayload, SetOptions(merge: true));
    return true;
  }

  static const Set<String> _mbtiTypes = {
    'INTJ', 'INTP', 'ENTJ', 'ENTP', 'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ', 'ISTP', 'ISFP', 'ESTP', 'ESFP',
  };

  String _firstMbti(Set<String>? values) {
    if (values == null) return '';
    for (final value in values) {
      if (_mbtiTypes.contains(value)) return value;
    }
    return '';
  }

  List<String> _stripPrefix(Set<String> values, String prefix) {
    return values
        .where((value) => value.startsWith(prefix))
        .map((value) => value.substring(prefix.length))
        .toList(growable: false);
  }
}

/// 규칙 기반 기본 캐릭터 추천 (임시 — 추후 Gemini로 교체).
///
/// 성별로 캐릭터 풀을 가르고(남=빵·구움과자 forMen=true, 여=디저트 forMen=false),
/// 선택한 취향 키워드와 캐릭터 태그의 겹침이 가장 많은 캐릭터를 고른다.
class CharacterRecommender {
  const CharacterRecommender._();

  static String recommend({
    required String genderKr,
    required Set<String> keywords,
    required List<ChemistryCharacter> characters,
  }) {
    if (characters.isEmpty) return '';

    final forMen = genderKr == '남성';
    var pool = characters.where((c) => c.forMen == forMen).toList();
    if (pool.isEmpty) pool = characters;

    ChemistryCharacter best = pool.first;
    var bestScore = -1;
    for (final character in pool) {
      var score = 0;
      for (final tag in character.tags) {
        for (final keyword in keywords) {
          if (keyword.contains(tag) || tag.contains(keyword)) {
            score++;
          }
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = character;
      }
    }
    return best.id;
  }
}
