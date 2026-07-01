/// 카카오 로그인(REST OAuth) 설정.
///
/// - REST API 키: authorize URL 의 client_id (클라이언트 노출됨 — OAuth public client).
/// - 콜백 스킴: flutter_web_auth_2 가 잡는 커스텀 URL 스킴.
/// - 리다이렉트 URI: 카카오가 코드를 보내는 Cloud Function 브리지 (https).
///   → 카카오 콘솔의 "카카오 로그인 리다이렉트 URI"에 동일 값 등록 필요.
const String kakaoRestApiKey = '03ff296af2069a31d9b28ddbd87f1515';
const String kakaoAuthCallbackScheme = 'chemistryovenoauth';
const String kakaoRedirectUri =
    'https://asia-northeast3-chemistryoven.cloudfunctions.net/kakaoOauthBridge';
