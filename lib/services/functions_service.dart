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
}
