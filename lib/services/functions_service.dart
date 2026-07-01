import 'package:cloud_functions/cloud_functions.dart';

/// Cloud Functions 호출 (리전: asia-northeast3).
class FunctionsService {
  FunctionsService._();
  static final FunctionsService instance = FunctionsService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  /// 배포/연결 확인용.
  Future<bool> ping() async {
    final result = await _functions.httpsCallable('ping').call();
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['ok'] == true;
  }

  /// 케미 점수 계산 & 인원 선정 (Gemini). 결과 요약을 반환.
  Future<Map<String, dynamic>> computeChemistryScores(String sessionId) async {
    final result = await _functions
        .httpsCallable('computeChemistryScores')
        .call(<String, dynamic>{'sessionId': sessionId});
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// 카카오 OAuth code → Firebase 커스텀 토큰.
  Future<String> createKakaoCustomToken({
    required String code,
    required String redirectUri,
  }) async {
    final result = await _functions
        .httpsCallable('createKakaoCustomToken')
        .call(<String, dynamic>{'code': code, 'redirectUri': redirectUri});
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['firebaseToken'] as String;
  }

  /// 카카오 본인 인증(계정 생성 X) → 현재 유저에 기록. 카카오 닉네임 반환.
  Future<String> verifyKakaoAccount({
    required String code,
    required String redirectUri,
  }) async {
    final result = await _functions
        .httpsCallable('verifyKakaoAccount')
        .call(<String, dynamic>{'code': code, 'redirectUri': redirectUri});
    final data = Map<String, dynamic>.from(result.data as Map);
    return (data['nickname'] ?? '') as String;
  }
}
