# Chemistry Oven · 백엔드/아키텍처 설계 문서

> 본 문서는 케미스트리오븐 앱을 **Flutter + Firebase(Firestore / Storage / Auth / Functions)** 로 구축하기 위한 전체 아키텍처 설계서입니다.
> 기존 운영 중인 **`mileage_thief`** 프로젝트의 검증된 패턴을 레퍼런스로 삼아, 케미스트리오븐 도메인에 맞게 재설계했습니다.
> 현재 앱은 데모(목업) 데이터로 동작하며, **케미스트리오븐용 Firebase 인스턴스는 아직 생성 전**입니다. 본 문서의 Phase 순서대로 연결합니다.
>
> 관련 문서: AI 프롬프트 원본은 `docs/gemini_prompts.md` 참고.

---

## 0. 설계 원칙

1. **검증된 패턴 재사용** — `mileage_thief`의 인증(소셜 로그인 + 동의 게이트), `users/{uid}` get-then-merge, Storage 업로드 규칙을 그대로 차용.
2. **데모 → 실데이터 점진 전환** — 현재 `lib/data/repositories/mock_chemistry_repository.dart` 의 인터페이스를 유지한 채, Firestore 구현체로 교체(Repository 추상화).
3. **AI는 서버(Cloud Functions)에서** — Gemini API 키를 클라이언트에 노출하지 않음. 점수계산/자리배치/리포트는 Functions에서 호출.
4. **운영자(Admin)와 사용자(User) 분리** — 같은 Firestore를 보지만 권한(roles)과 화면이 다름. 보안 규칙으로 강제.
5. **닉네임 기반 프라이버시** — 회차 진행 중에는 실명/연락처 비공개, 최종 쌍방 매칭 시에만 공개(보안 규칙 + 데이터 분리).

---

## 1. 기술 스택 결정

`mileage_thief` 분석 결과를 토대로 한 케미스트리오븐 채택안:

| 영역 | mileage_thief | 케미스트리오븐 채택안 | 비고 |
|---|---|---|---|
| Firebase Core | firebase_core ^3.x | 동일 | FlutterFire CLI로 `firebase_options.dart` 생성 |
| DB | Firestore(+ 일부 RTDB 레거시) | **Firestore 단일** | RTDB 미사용 |
| 파일 | firebase_storage ^12.x | 동일 | 프로필/회차/베이킹 이미지 |
| 인증 | firebase_auth ^5.x | 동일 | 소셜 로그인 → Firebase Auth uid |
| 서버 로직 | cloud_functions ^5.x | 동일 | Gemini 호출, 카카오 커스텀 토큰 |
| 푸시 | firebase_messaging | 동일 | 선정/매칭 알림 |
| 소셜 로그인 | google_sign_in, sign_in_with_apple, flutter_web_auth_2 | 동일 | 카카오/애플/구글 (네이버는 미도입) |
| 상태관리 | 없음(setState) | **Provider 권장**(경량 DI/테스트성) | 현재 앱은 `AppScope` InheritedWidget 사용 중 → Provider로 확장 가능 |
| 이미지 | image_picker + flutter_image_compress | 동일 | 업로드 전 압축 |

> **상태관리 메모**: 현재 케미스트리오븐은 `lib/shared/providers/app_scope.dart`(InheritedWidget) + 컨트롤러 패턴으로 이미 구조화되어 있음. mileage_thief처럼 순수 setState로 가도 되지만, Firestore 스트림 연동이 늘어나므로 `provider` 패키지 도입을 권장.

### 로그인 제공자 (플랫폼별) — 확정 요구사항

| 플랫폼 | 제공자 |
|---|---|
| **Android** | 구글, 카카오 |
| **iOS** | 구글, 애플, 카카오 |

- 에셋(구글/애플/카카오 로그인 버튼 이미지)은 본 프로젝트에 이미 존재하므로 재사용.
- 로그인 진입 전 **이용약관/개인정보 동의 체크(필수)** 게이트 필수 (mileage_thief `_showAgreementDialog` 패턴).

---

## 2. 폴더 구조 (현행 유지 + 확장)

케미스트리오븐은 이미 **feature-first** 구조라 mileage_thief(layer-first)보다 깔끔함. 유지하고 data 레이어만 확장:

```
lib/
  app/                      # app, main_tab_screen, theme
  core/                     # constants(colors/assets), widgets
  data/
    models/                 # 도메인 모델 (+ fromFirestore/toMap 추가)
    repositories/
      chemistry_repository.dart        # 추상 인터페이스 (신규)
      mock_chemistry_repository.dart   # 데모 구현 (현행)
      firestore_chemistry_repository.dart  # 실데이터 구현 (신규)
    dummy/                  # 데모 데이터 (Phase 후반 제거)
  features/                 # auth, onboarding, home, classes, ovening, lab, report, social, admin ...
  services/                 # 신규: auth_service, user_service, storage_service, gemini_service(Functions 호출)
  shared/providers/         # app_scope + provider 확장
```

신규 추가:
- `lib/services/` — mileage_thief의 서비스 레이어 차용(단, 정적 메서드 대신 인스턴스 + Provider 주입 권장).
- `data/repositories/chemistry_repository.dart` — Mock/Firestore 교체를 위한 추상화.
- `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` — Phase 1에서 생성.

---

## 3. Firestore 데이터 모델

### 3.1 설계 개요

핵심 컬렉션: `users`, `characters`(도감 20종 정적), `sessions`(회차), `applications`(신청), `events`(회차 당일 진행/선택), `matches`(매칭 결과), `reports`(케미 리포트), `admin_*`.

```
users/{uid}                                  # 사용자 프로필 + 온보딩 결과
  └─ (subcol) notifications/{nid}

characters/{characterId}                     # 케미 캐릭터 20종 (정적 마스터)

sessions/{sessionId}                         # 회차 (운영자 생성)
  ├─ (subcol) applications/{uid}             # 이 회차 신청자
  ├─ (subcol) participants/{uid}             # 선정/확정 인원 (닉네임 배정)
  ├─ (subcol) seating/{tableId}             # AI 자리배치 결과
  └─ (subcol) choices/{uid}                  # 첫인상/중간/최종 선택

matches/{matchId}                            # 쌍방 매칭(실명·연락처 공개 단위)
reports/{reportId}                           # 개인 케미 리포트 (Gemini 산출물)

config/app                                   # 전역 설정 (약관 URL, 버전 등)
prompts/{promptVersion}                      # Gemini 기본 프롬프트 버전 관리
```

### 3.2 `users/{uid}` — 사용자 문서

```jsonc
{
  "uid": "string",
  "provider": "google | apple | kakao",
  "email": "string|null",
  "displayName": "string",          // 실명/표시명 (회차 외 노출)
  "photoURL": "string|null",
  "phone": "string|null",           // 매칭 시에만 상대에게 공개
  "gender": "M | F",
  "birth": "1996-02",               // 생년월
  "height": 178,
  "job": "IT/개발",
  "region": "서울 강남권",
  "religion": "무교",
  "mbti": "INFJ",

  "onboardingCompleted": true,      // 온보딩 완료 플래그(빠른 게이팅용)
  // ⚠️ 온보딩 설문 원본/선호값/기본 캐릭터는 users 문서에 직접 넣지 않고
  //    users/{uid}/onboarding/current 서브컬렉션에 분리 저장(§3.2.1).

  // 인증/상태
  "verification": {
    "photo": "pending | approved | rejected",
    "job": "pending | approved | rejected"
  },
  "roles": ["user"],                // ["user"] | ["user","admin"]
  "isBanned": false,

  // 동의 기록 (로그인 게이트 통과 시 기록 권장)
  "consent": {
    "termsAgreedAt": "ts",
    "privacyAgreedAt": "ts",
    "policyVersion": "2026-06"
  },

  "fcmToken": "string",
  "createdAt": "ts", "lastLoginAt": "ts", "lastActiveAt": "ts"
}
```

> 쓰기 규칙: 로그인 시 `set(merge:true)` 로 `lastLoginAt/fcmToken`만 갱신, 신규면 전체 기본 문서 생성 (mileage_thief `saveUserToFirestore` 패턴).

#### 3.2.1 `users/{uid}/onboarding/current` — 온보딩 설문 결과 (서브컬렉션)

설문 원본과 선호값은 크기가 크고 users 문서를 비대하게 만들므로 서브컬렉션으로 분리한다.

```jsonc
{
  "completed": true,
  "baseCharacterId": "tiramisu",   // AI 추천 기본 캐릭터
  "answers": { /* 단계별 설문 원본 (PSYCHOLOGY 산출용) */ },
  "preferences": {                 // STRICT 산출용 선호값
    "ageRange": [30, 36],
    "heightMin": 175,
    "mbti": ["ENFP", "ENTJ", "ESTP"],
    "religion": ["무교", "any"],
    "avoidJobs": ["디자인"]
  },
  "updatedAt": "ts"
}
```

> 보안 규칙: `users/{uid}` 의 재귀 매치(`match /{document=**}`)가 소유자·운영자 읽기/쓰기를 이미 커버. 읽기는 `CurrentUserController` 가 users 문서와 함께 로드해 `UserProfile.baseCharacterId/onboardingCompleted` 로 노출.

### 3.3 `characters/{characterId}` — 케미 캐릭터 마스터 (도감 20종)

```jsonc
{
  "id": "tiramisu",
  "name": "티라미수",
  "gender": "F",                  // 남=빵·구움과자 계열, 여=디저트 계열
  "tagline": "당당한 티라미수",
  "description": "차분한 깊이와 은은한 유머...",
  "tags": ["감성적", "진중함", "따뜻함"],
  "mbtiTypes": ["INFJ", "INFP", "ENFJ", "ISFJ"],
  "lookalikes": [ {"name":"하울","work":"하울의 움직이는 성"} ],
  "designMood": { "swatch": "#9B0D27", "text": "..." },
  "order": 1
}
```
정적 데이터이므로 1회 시드(seed) 후 거의 변하지 않음. 현재 `dummy_chemistry_data.dart` 내용을 그대로 업로드.

### 3.4 `sessions/{sessionId}` — 회차

```jsonc
{
  "id": "session-8",
  "title": "케미스트리오븐 8기",
  "date": "2026-07-12",
  "time": "오후",
  "location": "서울 강남 베이킹스튜디오",
  "bakingItems": ["마들렌", "휘낭시에"],
  "keyVisualUrl": "gs://.../sessions/session-8/cover.jpg",
  "capacity": { "min": 3, "default": 5, "max": 10 },  // n:n
  "recruit": { "male": 4, "female": 4 },
  "status": "draft | recruiting | selecting | confirmed | ongoing | closed",
  "notice": "유의사항 · 환불 규정 텍스트",
  "createdBy": "adminUid", "createdAt": "ts"
}
```

#### 서브컬렉션
- `sessions/{id}/applications/{uid}` — 신청 시점 스냅샷(점수, 상태: `applied|selected|held|rejected`).
- `sessions/{id}/participants/{uid}` — 확정 인원 + **회차 닉네임**(캐릭터 기반, 회차 내 중복 없음) + 테이블 배정.
- `sessions/{id}/seating/{tableId}` — `{ tableId, theme, seats: [{uid, nickname, seatPos}] }` (Gemini 자리배치 산출물).
- `sessions/{id}/choices/{uid}` — `{ first: [uid…], mid: [uid…], final: {first: uid, second: uid}, letter: "…" }`.

### 3.5 `matches` / `reports`

```jsonc
// matches/{matchId} — 쌍방 최종 일치 시 생성 (실명/연락처 공개 트리거)
{ "sessionId":"session-8", "pair":["uidA","uidB"], "createdAt":"ts" }

// reports/{reportId} — 회차 종료 후 Gemini 생성 개인 리포트
{
  "sessionId":"session-8", "uid":"uidA",
  "model":"gemini-2.5-flash-lite", "promptVersion":"v1",
  "content": { /* 케미 리포트 구조화 결과 */ },
  "createdAt":"ts"
}
```

---

## 4. Storage 구조

mileage_thief의 `<collection>/{partition}/.../{id}_{uuid}.{ext}` 규칙 차용. 업로드 후 **다운로드 URL을 Firestore에 저장**.

```
profile/{uid}/avatar_{uuid}.jpg            # 프로필 사진
verification/{uid}/job_{uuid}.jpg          # 직업 인증 자료 (비공개, 운영자만)
sessions/{sessionId}/cover_{uuid}.jpg      # 회차 키비주얼
sessions/{sessionId}/baking_{uuid}.jpg     # 당일 베이킹 품목 사진
```

- 업로드 전 `flutter_image_compress`로 ~1MB 압축, 파일명 `uuid.v4()` 중복 방지.
- 인증 자료(`verification/`)는 보안 규칙에서 **본인+운영자만** 접근.

---

## 5. 인증 / 소셜 로그인 설계

### 5.1 흐름

```
[로그인 화면]
   │  (필수 동의 2종 체크 전까지 버튼 비활성)
   ├─ 약관 동의 게이트 (_showAgreementDialog 패턴)
   │     ├ 이용약관 동의 (필수)
   │     └ 개인정보처리방침 동의 (필수, URL 링크)
   ▼
[제공자 선택]
   Android: 구글 / 카카오
   iOS:     구글 / 애플 / 카카오
   ▼
[Firebase Auth 인증]
   ├ 구글: GoogleSignIn → GoogleAuthProvider.credential → signInWithCredential
   ├ 애플: SignInWithApple(nonce+sha256) → OAuthProvider("apple.com") → signInWithCredential
   └ 카카오: OAuth code (flutter_web_auth_2) → Cloud Function(createKakaoCustomToken) → signInWithCustomToken
   ▼
[users/{uid} get-then-merge]
   ├ 신규 → 온보딩으로 (기본 문서 생성)
   └ 기존 → 홈으로 (lastLoginAt/fcmToken 갱신)
```

### 5.2 카카오 로그인 (SDK 미사용 방식 권장 / mileage_thief 동일)

- 패키지 추가 없이 **OAuth Authorization Code + Cloud Functions 커스텀 토큰** 방식.
- 필요 구성:
  - `--dart-define KAKAO_REST_API_KEY=...`
  - Cloud Function `kakaoOauthBridge`(redirect 수신) + `createKakaoCustomToken`(callable) — region `asia-northeast3`.
  - 커스텀 URL 스킴(예: `chemistryovenoauth`)을 `AndroidManifest.xml` / `ios/Runner/Info.plist`에 등록.
- 대안: `kakao_flutter_sdk_user` 패키지를 쓰면 Functions 없이 네이티브 로그인 가능하나, Firebase Auth 연동 위해 커스텀 토큰 발급 함수는 여전히 필요.

### 5.3 동의(Consent) 처리

- 로그인 직전 모달에서 **필수 2종 체크** 후에만 로그인 실행.
- 동의 시각/정책 버전을 `users/{uid}.consent`에 기록(추후 약관 개정 추적).

### 5.4 에셋 재사용

본 프로젝트 `asset/` 하위의 구글/애플/카카오 로그인 버튼 이미지를 사용. (네이버는 이번 범위 제외.) 라이트/다크 변형이 있으면 `Theme.brightness`로 스왑.

---

## 6. Gemini 2.5 Flash Lite 연동

### 6.1 원칙
- **API 키는 Cloud Functions 환경변수**로만 보관(클라이언트 노출 금지).
- 기본 프롬프트는 `docs/gemini_prompts.md` 3종을 사용하고, Firestore `prompts/{version}` 로도 관리(런타임 교체).
- 가능하면 **JSON 구조화 출력**을 요청해 파싱(점수/테이블/리포트).

### 6.2 3개의 AI 작업 → Functions 매핑

| 작업 | 입력 | 기본 프롬프트 | 출력 → 저장 |
|---|---|---|---|
| **케미 점수계산 & 인원선정** | 회차 신청자 온보딩/선호 데이터 | `gemini_prompts.md §1` | STRICT/PSYCHOLOGY 점수, 테이블 구성 → `sessions/{id}/applications`, `participants` |
| **자리 배치** | 첫인상/중간 선택 + 케미 점수 + 성향 | `gemini_prompts.md §2` | 테이블별 좌석도 → `sessions/{id}/seating` |
| **케미 리포트** | 개인 선택 흐름 + 온보딩 + 점수 | `gemini_prompts.md §3` | 개인 리포트 → `reports/{reportId}` |

```
[Admin 앱]  "인원 선정" 버튼
   → callable Function: computeChemistryScores(sessionId)
       1) Firestore에서 신청자 데이터 로드
       2) prompts/v1 + 직렬화 데이터로 Gemini 2.5 Flash Lite 호출
       3) 응답(JSON) 파싱 → applications/participants 업데이트
   → 클라이언트는 결과 스트림으로 수신
```

> 운영 팁: Flash Lite는 비용/속도 이점이 크지만 복잡한 점수 규칙은 환각 위험이 있으므로, **하드 필터링(흡연·음주·기피직군·나이 0점)은 코드로 1차 검증** 후 AI는 정성 평가/테이블 무드/리포트에 집중시키는 하이브리드 권장.

---

## 7. 보안 규칙 (요지)

```
users/{uid}            : read 본인 또는 admin; write 본인(일부 필드)·admin
  verification/*       : read/write 본인 + admin only
characters/*           : read 누구나; write admin only
sessions/*             : read 인증 사용자; write admin only
  applications/{uid}   : create 본인; read 본인+admin; update admin(점수/상태)
  participants/*       : read 해당 회차 참가자; write admin/Functions
  choices/{uid}        : create/update 본인(진행 단계 내); read 본인+admin
matches/*              : read 매칭 당사자만; write Functions only
reports/{id}           : read 본인만; write Functions only
prompts/*              : read admin; write admin
```
- 실명/연락처 공개는 `matches` 생성(=쌍방 최종 일치) 이후로 제한.
- 점수/리포트/매칭 등 민감 산출물은 **Functions(Admin SDK)만 쓰기** 가능하게 하여 클라이언트 위변조 차단.

---

## 8. Phase 로드맵

### Phase 0 — 준비 (현재)
- [x] 디자인(HTML) 기준 화면/인터랙션 구현 점검 및 보정 (완료)
- [x] AI 프롬프트 원본 문서화 (`docs/gemini_prompts.md`)
- [x] 본 아키텍처 설계 문서 작성
- [ ] Firestore 스키마/보안규칙 초안 팀 리뷰

### Phase 1 — Firebase 프로젝트 부트스트랩
- [ ] 케미스트리오븐 Firebase 프로젝트 생성 (dev/prod 분리 권장)
- [ ] FlutterFire CLI로 `firebase_options.dart` 생성, `google-services.json` / `GoogleService-Info.plist` 배치
- [ ] `firebase_core` 초기화(main.dart) + 비차단 초기화 패턴 적용
- [ ] Storage 버킷 생성, 기본 보안 규칙 배포(잠금 상태)

### Phase 2 — 인증
- [ ] `AuthService` 구현 (구글/애플/카카오) — 플랫폼별 버튼 노출
- [ ] 약관 동의 게이트 + `users/{uid}` get-then-merge 생성
- [ ] 카카오: OAuth 브리지 + `createKakaoCustomToken` Function, URL 스킴 등록
- [ ] 로그인 → 신규/기존 분기 → 온보딩/홈 라우팅
- [ ] 에셋(구글/애플/카카오 버튼) 연결

### Phase 3 — 사용자 데이터 & 온보딩
- [ ] `chemistry_repository.dart` 추상화 + `firestore_chemistry_repository.dart`
- [ ] `characters` 시드 업로드(20종)
- [ ] 온보딩 결과 → `users/{uid}.onboarding` 저장 (선호값/설문/기본 캐릭터)
- [ ] 프로필 사진/직업 인증 Storage 업로드 + 인증 상태 필드

### Phase 4 — 회차 & 신청 (사용자/운영자)
- [ ] 운영자: 회차 생성/모집(`sessions` CRUD, 키비주얼·베이킹 품목 업로드)
- [ ] 사용자: 회차 상세/신청(`applications` 생성)
- [ ] 3:3 모집현황/공개 로직, 결제 확인 → `confirmed`

### Phase 5 — AI 점수계산 & 인원선정
- [ ] `computeChemistryScores` Function (하드필터 코드 + Gemini 정성 평가)
- [ ] 운영자 신청자 상세(프로필/선호/답변 탭)에서 점수 확인 → 선정/보류/탈락
- [ ] 확정 인원 닉네임 배정 → `participants`

### Phase 6 — 오브닝(회차 당일) 진행
- [ ] 첫인상/로테이션/중간/최종 선택 → `choices` 저장(실시간)
- [ ] `assignSeating` Function (자리배치 프롬프트) → `seating`
- [ ] 쌍방 매칭 판정 → `matches` 생성(실명/연락처 공개)

### Phase 7 — 케미 리포트 & 사후
- [ ] `generateReport` Function (리포트 프롬프트) → `reports`
- [ ] 리포트 화면/소셜(라운지·커플보드·리뷰) 데이터 연결
- [ ] 푸시 알림(선정/매칭/리포트 발행)

### Phase 8 — 하드닝 & 출시
- [ ] 보안 규칙 정교화 + 인덱스 구성, 부하/비용 점검
- [ ] AI 출력 검증/폴백, 운영 대시보드 지표
- [ ] 스토어 심사(개인정보 처리방침, 데이터 삭제 경로), 회원탈퇴

---

## 9. 부록 — 환경설정 체크리스트

- [ ] `--dart-define`: `KAKAO_REST_API_KEY`
- [ ] 커스텀 URL 스킴: `chemistryovenoauth` (Android Manifest / iOS Info.plist)
- [ ] Cloud Functions(asia-northeast3): `kakaoOauthBridge`, `createKakaoCustomToken`, `computeChemistryScores`, `assignSeating`, `generateReport`
- [ ] Functions 환경변수: `GEMINI_API_KEY`
- [ ] Firestore 복합 인덱스: 회차별 신청자 점수 정렬, 선택 집계 등
- [ ] iOS: Apple 로그인 Capability, 카카오 URL 스킴 / Android: SHA 인증서(구글)
- [ ] 약관/개인정보처리방침 URL (`config/app`)

---

_최종 갱신: 2026-06-18 · 작성 기준: mileage_thief 아키텍처 분석 + 케미스트리오븐 디자인(HTML) 도메인 분석_
