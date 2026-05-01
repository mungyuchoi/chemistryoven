# 케미스트리오븐 앱 아키텍처 문서

> 파일명은 요청 원문을 따르기 위해 `ARICHITECTURE.MD`로 유지한다.
> 이 문서는 Firebase 선연동 설계서가 아니라, 사장님 검토용 Flutter UI 프로토타입을 먼저 만들기 위한 실행 설계서다.

## 1. 프로젝트 개요

### 앱의 목적

케미스트리오븐은 베이킹 클래스를 매개로 낯선 사람들이 자연스럽게 대화하고, 함께 베이킹하며, 단계별 선택을 통해 서로의 케미를 확인하는 소셜 베이킹 프로그램이다.

초기 개발 목표는 실제 DB, Firebase, Firestore, 외부 인증, 결제, Gemini API를 붙이는 것이 아니다. 먼저 Flutter 앱 화면 전체를 더미데이터로 구성하고, 사용자가 각 버튼을 눌렀을 때 신청 상태와 행사 진행 단계가 어떻게 바뀌는지 사장님이 직접 확인할 수 있는 UI 프로토타입을 만드는 것이 1차 목표다.

1차 MVP 기준:

- 실제 회원가입 없음: 더미 로그인, 게스트 모드, 관리자 모드, 행사 참가자 모드를 앱 내부에서 전환한다.
- 실제 Firebase 제외: `Firebase.initializeApp`, `cloud_firestore`, `firebase_auth`, `firebase_storage`, `cloud_functions`를 초기 구현에 붙이지 않는다.
- 실제 결제 없음: 입금 대기/입금 확인 상태만 더미로 표현한다.
- 실제 AI 호출 없음: AI 선정 결과, 닉네임, 케미 점수, 리포트는 더미데이터로 제공한다.
- 화면 검토 우선: 홈, 회차, 신청, 인증, 선정, 좌석, 선택, 매칭, 리포트, 후기, 관리자 화면을 모두 눈으로 확인 가능하게 만든다.
- DB/Firebase 작업은 사장님 검토, 수정, 최종 컨펌 이후 2차 작업으로 진행한다.

### 핵심 사용자

- 일반 사용자: 베이킹 클래스 또는 케미스트리오븐 회차를 둘러보고 신청하는 사용자.
- 케미 참가자: 선정/입금 확정 후 행사 당일 닉네임, 좌석, 상대 정보, 선택 제출, 매칭 결과, 케미 리포트를 확인하는 사용자.
- 관리자/호스트: 신청자 검토, 인증 승인/반려, AI 선정 결과 확인, 참가자 확정, 좌석 배치, 라운드 전환, 선택 집계, 매칭 승인, 리포트 발송 상태를 관리하는 운영자.
- 사장님/의사결정자: 실제 개발 전에 전체 화면, 문구, 플로우, 운영 난이도, 디자인 톤을 검토하는 사용자.

### 주요 사용 시나리오

1. 사용자는 앱을 열고 홈에서 모집 중인 4:4 소셜 베이킹 매칭 회차를 확인한다.
2. 회차 상세에서 일정, 장소, 프로그램 흐름, 참가 조건을 확인하고 신청한다.
3. 더미 프로필과 인증 자료 제출 화면을 거쳐 신청 상태가 `인증 대기`로 바뀐다.
4. 관리자 모드에서 인증을 승인하면 사용자의 상태가 `AI 선정 대기`로 바뀐다.
5. 관리자 모드에서 더미 AI 선정 결과를 확인하고 최종 참가자를 확정한다.
6. 사용자는 `선정됨`, `입금 대기`, `최종 확정` 상태 화면을 순서대로 확인한다.
7. 행사 당일 모드에서 닉네임, 현재 라운드, 좌석, 상대 닉네임, 선택 제출 화면을 확인한다.
8. 중간 선택 후 더미 베이킹 파트너/좌석 배치가 노출된다.
9. 최종 선택 후 매칭/비매칭 결과 화면과 연락처 공개 화면을 확인한다.
10. 행사 종료 후 케미 리포트와 후기 작성 화면을 확인한다.

### 기존 프로젝트 중 어떤 구조를 참고할지

우선 참고 순서:

1. `/Users/vory/StudioProjects/gatchacatch`
   - 최신 Flutter feature-first 구조, `provider`, 라우팅, `core/features/shared` 분리, 게시글/검색/프로필/관리자 구조 참고.
   - 단, Firebase 초기화와 Firestore 접근은 초기 프로토타입에 적용하지 않는다.
2. `/Users/vory/StudioProjects/dubai`
   - 기존 요청의 `dusegwon` 대체 참고 프로젝트다.
   - `lib/app/app.dart`, `lib/app/routes.dart`, `lib/app/main_tab_screen.dart`, `lib/app/theme.dart`의 앱 구조와 탭/관리자 패턴을 참고한다.
   - `features/profile/presentation/screens/*admin*`, `statistics_dashboard_screen.dart`, `notice_management_screen.dart`, `user_management_screen.dart` 등 운영자 화면 패턴을 참고한다.
   - 단, Firebase, Firestore, Analytics, FCM, Naver Map 초기화 코드는 초기 구현에서 제외한다.
3. `/Users/vory/StudioProjects/jobworld`
   - 간결한 `MaterialApp`, 테마, 커뮤니티, 광고/공지, repository/datasource 분리 방식을 보조 참고한다.
4. `/Users/vory/StudioProjects/mileage_thief`
   - 커스텀 BottomNavigationBar, 공지/강제 업데이트 UX, 커뮤니티 에디터, 알림 설정, 운영 기능 패턴을 보조 참고한다.

## 2. 참고 자료 분석

### `docs` 폴더에서 확인한 자료 목록

- `docs/무제.rtf`
- `docs/무제 2.rtfd/TXT.rtf`
- `docs/무제 2.rtfd/Attachment.png`
- `docs/어플 개발.pptx`
- `docs/어플 디자인.pptx`
- `docs/케미 8기.xlsx`

### `docs/무제.rtf` 핵심 내용

- 서비스명은 케미스트리 오븐 또는 Chemistry Oven.
- 서비스 정의는 베이킹 클래스를 매개로 자연스럽게 사람을 만나고 AI 기반 인원 선정과 상호 선택 시스템으로 케미를 확인하는 소셜 베이킹 앱.
- 일반 소개팅 앱이 아니라, 오프라인 베이킹 프로그램 운영 흐름을 디지털화하는 앱이다.
- 디지털화 대상:
  - 신청자 모집
  - 개인정보 및 성향 입력
  - 일정 신청
  - 신원 인증
  - AI 기반 인원 선정
  - 회차 확정 및 입금 관리
  - 당일 좌석 배치 및 이동 안내
  - 첫인상/중간/최종 선택
  - 상호 매칭 시 연락처 공개
  - 종료 후 케미 리포트 발송
  - 후기 수집
  - 관리자 운영 자동화
- 사용자 앱 메뉴는 홈, Baking Class, Chemistry Oven, 마이페이지 중심.
- 관리자 메뉴는 대시보드, 가입자 관리, 클래스 관리, 신청자 관리, AI 매칭 관리, 좌석 배치/진행 모드, 선택 집계/매칭, 리포트/후기/통계 중심.
- 운영 정책:
  - 케미 리포트는 프로그램 종료 후 1시간 뒤 발송.
  - 연락처는 상호 매칭된 사람에게만 공개.
  - 인증은 얼굴 사진 + 증빙 자료 업로드 후 운영자 수동 승인.
  - 회차 인원은 최소 4:4, 최대 5:5.
  - 최종 케미 점수는 `(STRICT + 객관) / 2`.
  - 좌석 배치는 앱에서 확인하고, 운영자는 전체 좌석표와 라운드 상태를 본다.

### `docs/무제 2.rtfd/TXT.rtf` 핵심 내용

- 케미스트리 오븐은 낯선 사람들과 대화하고 함께 베이킹하며 자연스럽게 케미를 확인하는 소셜 베이킹 프로그램이다.
- 전체 운영 흐름:
  - 신청
  - 정보 입력
  - 신원 인증
  - AI 인원 선정
  - 참가 확정
  - 당일 진행
  - 선택 제출
  - 상호 매칭
  - 연락처 공개
  - 케미 리포트 발송
- 운영 단계:
  - STEP 1 모집 및 신청
  - STEP 2 신원 인증
  - STEP 3 AI 기반 인원 선정
  - STEP 4 참가 확정 및 사전 안내
  - STEP 5 당일 프로그램 시작
  - STEP 6 아이스브레이킹
  - STEP 7 1:1 로테이션 대화
  - STEP 8 첫인상/중간 선택
  - STEP 9 커플 베이킹 클래스
  - STEP 10 최종 선택
  - STEP 11 상호 매칭 결과 공개
  - STEP 12 케미 리포트 발송
  - STEP 13 후기 작성 및 재참여 연결
- 운영자 입장 흐름은 모집 공지, 신청 접수, 인증 승인, AI 인원 선정, 최종 참가자 확정, 안내/입금 관리, 당일 좌석/진행 운영, 선택 집계, 매칭 공개, 리포트 발송, 후기 수집이다.
- 핵심 특징은 소규모 운영, AI 기반 인원 선정, 자연스러운 만남, 안전한 연결, 결과보다 분위기 중심이다.

### `docs/무제 2.rtfd/Attachment.png` 핵심 내용

- 물음표 아이콘 이미지로 확인되며, 앱 기능/화면 설계에 직접 반영할 내용은 없다.

### `docs/어플 개발.pptx` 핵심 내용

- 로그인/회원가입:
  - 간편 로그인, 이메일/비밀번호, 전화번호 확인, 개인정보 입력.
  - 참여하지 않아도 프로그램 확인이 가능하도록 간단 회원가입 우선.
  - 사진, 사원증, 명함, 회사명, 사업자등록증, 대학교/대학원/회사 이메일 등 인증 자료 업로드.
  - 관리자 승인 후 확인되는 시스템.
- Baking Class:
  - 달력으로 클래스 일정 확인.
  - 클래스명, 사진, 상세 시간, 신청하기.
  - 신청 내역과 최종 승인/입금 완료 내역 확인.
- 관리자 관리:
  - 신청자 일정 표.
  - ID/이름/나이/직업 등 표 형태 확인.
  - 엑셀 다운로드.
  - 신청자 상세 클릭.
  - 대상자 승인.
  - 승인 후 문자 또는 앱 안내 발송.
  - 클래스 오픈, 메뉴 수정, 일정 지정, 사진 업로드.
- Chemistry Oven:
  - 달력 기반 회차 신청.
  - 개인정보 입력 후 AI 성격 분석 및 키워드 정리.
  - 남자 5개, 여자 5개 디저트 닉네임.
  - Gemini 프롬프트 기반 하드필터링 + 소프트필터링.
  - STRICT 점수 100점, 객관 점수 100점, 두 점수 평균으로 인원 선정.
  - 중간 선택은 베이킹 자리 매칭에 반영.
  - 베이킹 자리 배치 우선순위는 중간 쌍방 선택, 첫인상 선택, 케미점수 순서로 제안됨.
  - 최종 선택 후 매칭 승인 시 이름과 연락처 전달, 비매칭 시 안내 멘트 전달.
  - 케미 리포트는 내가 한 선택, 나를 선택한 사람들, MBTI 해석, 드라마틱 해석, 베이킹 파트너, 관계 스냅샷, 총평 기준.

### `docs/어플 디자인.pptx` 핵심 내용

- 디자인 톤:
  - 크림/아이보리 배경.
  - 브라운/버건디 텍스트와 버튼.
  - 베이킹 일러스트와 하트/케미 모티프.
  - 따뜻하고 감성적인 프리미엄 베이킹 스튜디오 느낌.
- 홈 예시:
  - 상단 로고와 알림 아이콘.
  - 큰 브랜드 배너.
  - 모집 중인 `4:4 소셜 베이킹 매칭` 카드.
  - 시간, 장소, AI 케미 분석 + 베이킹 + 대화 요약.
  - `신청하기` CTA.
  - `케미 레시피` 아이콘 카드: AI 분석, 함께 베이킹, 대화 & 게임, 새로운 케미.
  - 내 신청 현황.
  - 이번 회차 안내.
  - BottomNavigationBar: 홈, 회차, 내역, 마이.
- 초기 UI 프로토타입은 이 시안을 우선 반영하되, 과한 장식보다 실제 화면 검토가 쉬운 정보 구조를 우선한다.

### `docs/케미 8기.xlsx` 핵심 내용

엑셀에는 실제 개인정보가 포함되어 있으므로 설계 문서와 앱 더미데이터에는 실명/연락처/구체 신상 정보를 직접 반영하지 않는다. 참고할 것은 운영 구조와 입력 필드, 시트의 역할뿐이다.

확인된 시트:

- `Raw data`: 신청 원자료.
- `자료정리`: 원자료 정리 및 컬럼 표준화.
- `인원선정 종합`: 전체 신청자 후보 정렬/필터링.
- `인기인 정렬`: 선호도 또는 운영 우선순위 기반 정렬 자료로 추정.
- `인원선정 최종`: 시간대별 최종 선정자 표.
- `18M`, `18L`, `18E`: 회차 또는 그룹별 참가자 리스트.
- `18M 키워드`, `18L 키워드`, `18E 키워드`: 참가자별 키워드, 닉네임, 궁합/좌석/토크 자료로 추정.

엑셀에서 반영할 구조:

- 신청자 필드:
  - 성별
  - 이름
  - 연락처
  - 직업
  - 나이
  - 선호 나이대
  - 키
  - 이상형 키
  - MBTI
  - 원하는 MBTI
  - 종교
  - 선호 종교
  - 나는 어떤 사람인지
  - 이상형
  - 비선호 직군
  - 운영진 요청사항
- 운영 방식:
  - 원자료와 정리표를 분리한다.
  - 전체 후보와 최종 선정자를 분리한다.
  - 회차별 5:5 후보/확정 리스트를 따로 둔다.
  - 키워드 시트에서 참가자 소개/이상형/닉네임/토크 소재를 추출한다.

### 실제 구현에 반영할 내용

- 앱은 전체 운영 단계가 보이는 프로토타입이어야 한다.
- 사용자 화면과 관리자 화면을 모두 만든다.
- 신청 상태와 행사 진행 상태가 버튼 클릭으로 변하는 더미 플로우를 만든다.
- 회차 신청, 인증, 선정, 입금, 좌석, 선택, 매칭, 리포트까지 하나의 데모 시나리오로 연결한다.
- 문구와 화면은 사장님이 바로 검토할 수 있게 실제 서비스 톤에 가깝게 작성한다.

### 참고만 하고 직접 반영하지 않을 내용

- 엑셀의 실제 개인정보.
- 엑셀의 기존 수식과 수동 정리 방식.
- Firebase/Firestore/DB 관련 상세 구현.
- 실제 Gemini API 프롬프트.
- 실제 SMS/알림톡 발송.
- 실제 결제/입금 확인 자동화.
- 실제 본인 인증 API.

## 3. 기존 프로젝트 분석

### `gatchacatch`에서 참고할 구조

실제 경로:

- `/Users/vory/StudioProjects/gatchacatch`

참고할 부분:

- `lib/main.dart`
  - `MultiProvider` 진입 구조.
  - `AuthProvider` 등록 방식.
  - 앱 루트 분리 방식.
- `lib/app/app.dart`
  - `MaterialApp`, `theme`, `darkTheme`, `supportedLocales`, `initialRoute`, `onGenerateRoute`.
- `lib/app/routes.dart`
  - 라우트 상수와 `onGenerateRoute` 중앙 관리.
- `lib/features/main_tab_screen.dart`
  - 하단 탭 구조.
  - 중앙 `+` 버튼 클릭 시 모달 표시.
  - 로그인 필요 액션을 막는 UX.
- `lib/app/theme.dart`
  - 앱 테마를 별도 파일로 분리.
- `lib/core/constants/firestore_paths.dart`
  - 경로 상수 관리 패턴. 초기에는 Firestore 없이 `AppRoutes`, `DemoStatus`, `DummyAssetPaths` 같은 상수 관리에 응용한다.
- `lib/shared/providers/auth_provider.dart`
  - `ChangeNotifier` 기반 전역 상태관리 패턴.
  - 초기 케미스트리오븐에서는 실제 Auth가 아니라 `DemoModeController` 또는 `AppModeProvider`로 대체한다.
- `lib/features/feed/data/models/post_model.dart`
  - 모델의 `fromFirestore`, `toFirestore`, `copyWith` 패턴.
  - 초기에는 `fromJson`, `toJson`, `copyWith` 중심으로 작성한다.
- `lib/features/profile/presentation/screens/admin/*`
  - 관리자 화면 목록, 신고/공지/통계/사용자 관리 패턴.

초기 구현에서 제외할 부분:

- `Firebase.initializeApp`
- `FirebaseAuth`
- `CloudFirestore`
- `FirebaseStorage`
- `FirebaseMessaging`
- `CloudFunctions`
- 실제 Google/Naver/Kakao/Apple 로그인
- 실제 지도 SDK 초기화

### `mileage_thief`에서 참고할 구조

실제 경로:

- `/Users/vory/StudioProjects/mileage_thief`

참고할 부분:

- `lib/screen/home_screen.dart`
  - 커스텀 BottomNavigationBar.
  - 공지 팝업, 강제 업데이트 안내 UX.
  - 프로필 탭 진입 시 로그인 유도 구조.
- `lib/services/remote_config_service.dart`
  - 후속 Firebase 단계에서 Remote Config 기반 앱 버전/공지 관리 참고.
- `lib/services/notification_service.dart`
  - 후속 Firebase 단계에서 FCM/local notification 참고.
- `lib/community_editor/`
  - 후기/게시글 작성 화면이 고도화될 때 참고.
- `lib/screen/admin_page_screen.dart`
  - 운영자 화면의 메뉴/기능 묶음 참고.
- `lib/widgets/segment_tab_bar.dart`, `lib/widgets/press_scale.dart`
  - UI 컴포넌트 참고.

초기 구현에서 제외할 부분:

- Firebase Realtime Database/Firestore 직접 접근.
- FCM 초기화.
- AdMob.
- Branch link.
- 실제 포인트/랭킹/이벤트 수익화.

### `gatcha_catch`에서 참고할 구조

`pubspec.yaml`의 프로젝트명은 `gatcha_catch`이며 실제 폴더명은 `gatchacatch`다. 문서에서는 기존 요청의 `gatcha_catch`를 `gatchacatch` 폴더로 해석한다.

핵심 참고 패턴:

- feature-first 구조:
  - `features/auth`
  - `features/feed`
  - `features/map`
  - `features/search`
  - `features/profile`
  - `features/settings`
  - `features/notifications`
- 공통 계층:
  - `app`
  - `core`
  - `shared`
- 데이터 계층:
  - `data/models`
  - `data/repositories`
- 프레젠테이션 계층:
  - `presentation/screens`
  - `presentation/widgets`

케미스트리오븐 적용 방식:

- `features/chemistry`는 케미 회차 목록/상세/신청 화면을 담당한다.
- `features/classes`는 일반 베이킹 클래스 목록/상세/신청 화면을 담당한다.
- `features/applications`는 내 신청 현황과 상태 타임라인을 담당한다.
- `features/event_flow`는 행사 당일 좌석/라운드/선택 흐름을 담당한다.
- `features/matching`은 중간 선택, 최종 선택, 매칭 결과를 담당한다.
- `features/reports`는 케미 리포트와 후기 작성을 담당한다.
- `features/admin`은 관리자 검토용 화면을 담당한다.

### `dubai`에서 참고할 구조

기존 요청의 `dusegwon`은 상위 폴더에서 발견되지 않았고, 사용자가 `dubai`를 참조하면 된다고 정정했다. 따라서 `dusegwon` 참고 항목은 `/Users/vory/StudioProjects/dubai`로 대체한다.

실제 경로:

- `/Users/vory/StudioProjects/dubai`

참고할 파일:

- `lib/app/app.dart`
  - 앱 루트 구성, `MaterialApp`, 라우트, Provider 등록.
  - 초기 케미스트리오븐은 이 구조를 참고하되 `Firebase`와 `NotificationService` 초기화는 제거한다.
- `lib/app/routes.dart`
  - 라우트 상수 파일.
  - 초기 케미스트리오븐도 `AppRoutes.home`, `AppRoutes.chemistryDetail`, `AppRoutes.applicationStatus`, `AppRoutes.adminDashboard` 등을 상수화한다.
- `lib/app/main_tab_screen.dart`
  - 하단 탭 4개 + 중앙 액션 버튼 패턴.
  - 케미스트리오븐은 홈, 회차, 내역, 마이 탭으로 시작한다.
  - 중앙 액션 버튼은 `빠른 신청`, `데모 상태 변경`, `관리자 전환` 중 하나로 검토 가능하게 설계한다.
- `lib/app/theme.dart`
  - 테마 분리 방식.
  - 케미스트리오븐은 크림/아이보리/버건디/브라운 중심의 `ChemistryTheme`를 둔다.
- `lib/features/profile/presentation/screens/admin_screen.dart`
- `lib/features/profile/presentation/screens/statistics_dashboard_screen.dart`
- `lib/features/profile/presentation/screens/notice_management_screen.dart`
- `lib/features/profile/presentation/screens/user_management_screen.dart`
- `lib/features/profile/presentation/screens/report_management_screen.dart`
  - 관리자 메뉴 구성과 화면 분리 패턴 참고.

초기 구현에서 제외할 부분:

- `firebase_core`, `cloud_firestore`, `firebase_auth`, `firebase_storage`, `firebase_messaging`.
- `AnalyticsObserver`.
- `NotificationService`.
- `FlutterNaverMap`.
- 실제 사장님/사업자 기능 DB 연동.

### `jobworld`에서 참고할 구조

실제 경로:

- `/Users/vory/StudioProjects/jobworld`

참고할 부분:

- `lib/app/jobworld_app.dart`
  - 단순한 `MaterialApp`과 테마 분리.
- `lib/screens/home_screen.dart`
  - 홈 화면에 여러 기능을 탭/섹션으로 엮는 방식.
- `lib/features/spot/data/repositories/spot_repository.dart`
  - Repository 인터페이스와 구현체 분리.
- `lib/features/spot/data/datasources/spot_firestore_data_source.dart`
  - 데이터 소스 분리와 fallback 구조.
  - 케미스트리오븐 초기 구현에서는 `DummyDataSource`와 `MockRepository`로 대체한다.
- `lib/features/community/data/repositories/community_post_repository.dart`
  - 게시글 생성 시 사용자 요약 정보와 카운터를 같이 관리하는 패턴.
  - 후속 Firestore 전환 시 참고한다.

### 케미스트리오븐에 적용할 공통 패턴

- `app`, `core`, `shared`, `features` 분리.
- `features/*/data/models`, `features/*/data/repositories`, `features/*/presentation/screens`, `features/*/presentation/widgets` 구조.
- 초기 상태관리는 `provider` + `ChangeNotifier`.
- 초기 데이터는 `lib/data/dummy/`에 고정 더미데이터로 둔다.
- 실제 저장소 대신 `MockRepository`를 둔다.
- 화면 검토를 위해 모든 주요 플로우는 앱 안에서 클릭으로 상태를 바꿀 수 있게 한다.
- Firestore 전환을 대비해 더미 모델 필드명은 후속 DB 설계와 최대한 일치시킨다.

## 4. 전체 앱 구조

### 추천 폴더 구조

초기 UI 프로토타입 기준:

```text
lib/
  main.dart
  app/
    app.dart
    routes.dart
    theme.dart
    main_tab_screen.dart
  core/
    constants/
      app_constants.dart
      demo_status.dart
      asset_paths.dart
    utils/
      date_format_utils.dart
      status_label_utils.dart
      validation_utils.dart
    widgets/
      chemistry_app_bar.dart
      chemistry_bottom_nav.dart
      chemistry_card.dart
      status_chip.dart
      primary_button.dart
      empty_state.dart
      loading_state.dart
      error_state.dart
      demo_mode_banner.dart
  shared/
    models/
      app_user.dart
      user_profile.dart
      verification.dart
      baking_class.dart
      event_session.dart
      application.dart
      seat_plan.dart
      choice.dart
      match_result.dart
      chemistry_report.dart
      review.dart
      notice.dart
    providers/
      app_mode_provider.dart
      demo_flow_provider.dart
  data/
    dummy/
      dummy_users.dart
      dummy_profiles.dart
      dummy_classes.dart
      dummy_events.dart
      dummy_applications.dart
      dummy_match_runs.dart
      dummy_seat_plans.dart
      dummy_choices.dart
      dummy_reports.dart
      dummy_notices.dart
    repositories/
      mock_auth_repository.dart
      mock_class_repository.dart
      mock_event_repository.dart
      mock_application_repository.dart
      mock_matching_repository.dart
      mock_report_repository.dart
      mock_admin_repository.dart
  features/
    home/
      presentation/
        screens/
          home_screen.dart
        widgets/
          hero_banner.dart
          recruiting_event_card.dart
          chemistry_recipe_grid.dart
          my_application_summary_card.dart
          notice_preview_card.dart
    classes/
      presentation/
        screens/
          baking_class_list_screen.dart
          baking_class_detail_screen.dart
          class_calendar_screen.dart
        widgets/
          baking_class_card.dart
          class_schedule_tile.dart
    chemistry/
      presentation/
        screens/
          chemistry_event_list_screen.dart
          chemistry_event_detail_screen.dart
          chemistry_apply_screen.dart
        widgets/
          chemistry_event_card.dart
          program_step_timeline.dart
          participant_condition_panel.dart
    applications/
      presentation/
        screens/
          my_applications_screen.dart
          application_status_screen.dart
          verification_upload_screen.dart
          payment_status_screen.dart
        widgets/
          application_status_timeline.dart
          verification_card.dart
          payment_guide_card.dart
    event_flow/
      presentation/
        screens/
          today_event_screen.dart
          nickname_screen.dart
          round_seat_screen.dart
          participant_info_screen.dart
          choice_submit_screen.dart
        widgets/
          round_timer_card.dart
          seat_assignment_card.dart
          dessert_nickname_avatar.dart
          participant_keyword_sheet.dart
    matching/
      presentation/
        screens/
          baking_partner_screen.dart
          final_choice_screen.dart
          match_result_screen.dart
        widgets/
          choice_candidate_card.dart
          match_result_card.dart
    reports/
      presentation/
        screens/
          chemistry_report_screen.dart
          review_write_screen.dart
        widgets/
          report_section_card.dart
          review_rating_selector.dart
    admin/
      presentation/
        screens/
          admin_dashboard_screen.dart
          admin_event_manage_screen.dart
          admin_applicant_list_screen.dart
          admin_verification_review_screen.dart
          admin_matching_run_screen.dart
          admin_participant_confirm_screen.dart
          admin_payment_check_screen.dart
          admin_seat_plan_screen.dart
          admin_event_control_screen.dart
          admin_choice_result_screen.dart
          admin_match_approval_screen.dart
          admin_report_status_screen.dart
        widgets/
          admin_stat_card.dart
          applicant_table.dart
          admin_action_bar.dart
          seat_plan_table.dart
          choice_result_matrix.dart
    profile/
      presentation/
        screens/
          my_page_screen.dart
          profile_form_screen.dart
          settings_screen.dart
        widgets/
          profile_status_card.dart
          demo_mode_switcher.dart
```

### 주요 Dart 파일 구성

- `main.dart`
  - `WidgetsFlutterBinding.ensureInitialized()` 후 `runApp(const ChemistryOvenApp())`.
  - 초기 버전에서는 `Firebase.initializeApp()`를 호출하지 않는다.
- `app/app.dart`
  - `MultiProvider` 등록.
  - `MaterialApp` 설정.
  - `title: '케미스트리오븐'`.
  - `theme: ChemistryTheme.lightTheme`.
  - `initialRoute: AppRoutes.mainTab`.
- `app/main_tab_screen.dart`
  - 홈, 회차, 내역, 마이 4개 탭.
  - 필요 시 중앙 데모 액션 버튼을 둔다.
- `app/routes.dart`
  - 모든 상세/관리자 화면 route name 관리.
- `shared/providers/app_mode_provider.dart`
  - `DemoAppMode.guest`, `DemoAppMode.user`, `DemoAppMode.participantToday`, `DemoAppMode.admin`.
  - 사장님 검토 중 한 화면에서 모드를 쉽게 바꾸기 위해 사용한다.
- `shared/providers/demo_flow_provider.dart`
  - 신청 상태와 행사 진행 상태를 더미로 변경한다.
  - `advanceApplicationStatus()`, `resetDemo()`, `setAdminApproved()`, `submitChoice()` 같은 메서드를 제공한다.

### 공통 위젯 구조

- `ChemistryCard`
  - 8~12px radius, 얇은 border, 부드러운 shadow.
  - 홈 카드, 신청 상태 카드, 관리자 통계 카드에 재사용.
- `StatusChip`
  - `신청 전`, `인증 대기`, `승인됨`, `입금 대기`, `확정`, `행사 중`, `리포트 준비` 등 상태 표시.
- `ProgramStepTimeline`
  - 신청부터 리포트까지 단계형 플로우 표시.
- `DemoModeBanner`
  - 화면 상단에 `더미데이터 UI 검토 모드`를 작게 표시.
  - 실제 앱 출시 전에는 제거.
- `PrimaryButton`
  - 버건디 CTA 버튼.
- `EmptyState`, `LoadingState`, `ErrorState`
  - 초기 프로토타입에서도 빈 상태와 오류 상태를 반드시 보여줄 수 있어야 한다.

### 서비스 레이어 구조

초기에는 실제 네트워크 서비스가 없으므로 서비스보다 `MockRepository`와 `Provider` 중심으로 간다.

- `MockAuthRepository`
  - 게스트/사용자/관리자 전환.
- `MockEventRepository`
  - 일반 클래스, 케미 회차, 공지 더미 제공.
- `MockApplicationRepository`
  - 신청 상태 변경.
- `MockMatchingRepository`
  - 더미 AI 점수, 닉네임, 좌석, 선택 결과 제공.
- `MockReportRepository`
  - 더미 케미 리포트 제공.
- `MockAdminRepository`
  - 관리자 대시보드 수치, 신청자 목록, 승인/반려/확정 시뮬레이션.

후속 Firebase 컨펌 이후에는 같은 인터페이스를 유지하고 `FirestoreEventRepository`, `FirestoreApplicationRepository` 등으로 교체한다.

### 모델 레이어 구조

모델은 더미와 Firestore 전환을 모두 고려해 plain Dart class로 시작한다.

초기 권장 메서드:

- `factory Model.fromJson(Map<String, dynamic> json)`
- `Map<String, dynamic> toJson()`
- `Model copyWith(...)`

후속 Firebase 단계에서 추가:

- `factory Model.fromFirestore(DocumentSnapshot doc)`
- `Map<String, dynamic> toFirestore()`

### 화면 레이어 구조

- `screens`: 한 화면 전체를 담당.
- `widgets`: 화면 내부 반복 UI 담당.
- 화면은 가능한 한 repository를 직접 호출하지 않고 provider를 통해 데이터를 받는다.
- 단, 프로토타입 속도를 위해 좁은 화면에서는 `DummyData`를 직접 읽는 것을 허용하되, 문서상 권장 구조는 provider/repository 분리다.

## 5. 주요 기능 설계

### 홈 화면

목표:

- 앱의 세계관과 현재 모집 중인 회차를 한눈에 보여준다.
- 사장님이 첫 화면 톤을 검토할 수 있어야 한다.

구성:

- 상단:
  - 로고 또는 텍스트 `Chemistry Oven`.
  - 알림 아이콘.
  - 데모 모드 전환 버튼은 검토용으로 마이페이지 또는 floating panel에 둔다.
- 메인 배너:
  - 문구: `디저트보다 더 달콤한 순간, 사람과 사람이 만날 때 피어나는 케미.`
  - 이미지: `docs/어플 디자인.pptx`의 베이킹 일러스트 톤을 참고하되, 초기에는 로컬 임시 에셋 또는 placeholder gradient/image를 사용할 수 있다.
- 모집 카드:
  - `모집 중`
  - `4:4 소셜 베이킹 매칭`
  - `토요일 16:00`
  - `석촌`
  - `AI 케미 분석 + 베이킹 + 대화`
  - `신청하기`
- 케미 레시피:
  - AI 분석
  - 함께 베이킹
  - 대화 & 게임
  - 새로운 케미
- 내 신청 현황:
  - 신청 없음: `아직 신청한 회차가 없어요`
  - 신청 있음: 현재 상태와 다음 해야 할 일 표시.
- 이번 회차 안내:
  - 공지/준비물/장소 안내.

### 검색 화면

초기 프로토타입에서는 별도 복잡 검색보다 `회차/클래스 찾기` 중심으로 구성한다.

기능:

- 키워드 검색:
  - `베이킹`
  - `소셜 매칭`
  - `주말`
  - `석촌`
- 필터:
  - 전체
  - 모집 중
  - 일반 클래스
  - 케미스트리오븐
  - 마감 임박
- 결과 카드:
  - 클래스명/회차명
  - 일정
  - 장소
  - 정원
  - 현재 상태

후속 단계에서 Firestore 검색으로 바꿀 수 있게 `MockEventRepository.searchEvents(query, filters)` 형태를 추천한다.

### 상세 화면

대상:

- 일반 베이킹 클래스 상세.
- 케미스트리오븐 회차 상세.

공통 구성:

- 대표 이미지.
- 제목.
- 모집 상태.
- 날짜/시간.
- 장소.
- 정원.
- 가격 또는 참가비 안내.
- 프로그램 설명.
- 준비물.
- 취소/환불 정책은 확인 필요.
- 신청 버튼.

케미 회차 상세 추가 구성:

- 운영 흐름:
  - 신청
  - 인증
  - AI 선정
  - 입금 확정
  - 당일 진행
  - 선택
  - 매칭
  - 리포트
- 개인정보 비공개 안내.
- 상호 선택 시에만 연락처 공개 안내.
- 디저트 닉네임 시스템 안내.
- 선택은 첫인상/중간/최종 총 3회라는 안내.

### 커뮤니티 또는 게시판 기능

초기 사장님 검토용 MVP에서는 커뮤니티를 필수 기능으로 두지 않는다. 우선순위는 운영 플로우 검토다.

대신 아래는 포함할 수 있다:

- 후기 목록.
- 후기 작성.
- 공지사항.
- 문의하기 placeholder.

후속 출시 버전에서 커뮤니티가 필요하면 `gatchacatch`와 `jobworld`의 `posts`, `comments`, `likes`, `reports` 구조를 참고한다.

### 즐겨찾기 / 저장 기능

초기에는 실제 계정 저장 없이 로컬 상태로만 표현한다.

기능:

- 클래스/회차 카드의 하트 버튼.
- `내역` 또는 `마이`에서 저장한 회차 보기.
- 앱 재시작 유지까지 필요하면 `shared_preferences` 사용 가능하지만, 1차 UI 검토에서는 메모리 상태만으로 충분하다.

후속 Firebase 단계:

- `users/{uid}/saved_events/{eventId}`
- `users/{uid}/saved_classes/{classId}`

### 프로필 / 설정 화면

초기 프로토타입 구성:

- 데모 모드 전환:
  - 게스트
  - 일반 사용자
  - 행사 참가자
  - 관리자
- 내 프로필:
  - 이름/닉네임
  - 성별
  - 나이
  - 키
  - 직업
  - MBTI
  - 종교
  - 취향 태그
  - 이상형 키워드
  - 대화 스타일
- 인증 상태 카드:
  - 미제출
  - 제출 완료
  - 승인 대기
  - 승인 완료
  - 반려
  - 재업로드 요청
- 신청 내역.
- 케미 리포트.
- 후기 작성 내역.
- 알림 설정 placeholder.
- 문의 placeholder.

### 관리자 또는 운영자 기능

초기 프로토타입에서 반드시 포함한다. 이 앱은 운영 프로세스 검토가 핵심이기 때문이다.

관리자 화면:

- 관리자 대시보드:
  - 다가오는 회차 수.
  - 신청자 수.
  - 인증 대기 수.
  - 선정 대기 수.
  - 입금 대기 수.
  - 최종 확정 수.
  - 리포트 준비 수.
- 회차 생성/수정 화면:
  - 제목
  - 유형: 일반 클래스/케미 회차
  - 일시
  - 장소
  - 정원
  - 가격
  - 모집 상태
  - 대표 이미지 placeholder
- 신청자 목록:
  - 이름은 더미.
  - 성별, 나이, 직업, MBTI, 인증 상태, 신청 상태.
  - 상세 열기.
- 인증 승인/반려:
  - 얼굴 사진 placeholder.
  - 증빙자료 placeholder.
  - 승인/반려/재업로드 요청 버튼.
- AI 선정 결과 보기:
  - STRICT 점수.
  - 객관 점수.
  - 평균 점수.
  - 추천 조합.
  - 디저트 닉네임.
  - 운영자 메모.
- 최종 참가자 수동 조정:
  - 후보 추가/제외.
  - 남녀 비율.
  - 최종 확정 버튼.
- 입금 확인:
  - 입금 대기/입금 확인/취소.
- 좌석 배치:
  - 라운드별 테이블.
  - 현재 라운드.
  - 수동 수정 버튼 placeholder.
- 라운드 전환:
  - 아이스브레이킹.
  - 1:1 로테이션.
  - 첫인상 선택.
  - 중간 선택.
  - 베이킹.
  - 최종 선택.
  - 결과 공개.
- 선택 집계:
  - 첫인상 선택 집계.
  - 중간 선택 집계.
  - 최종 선택 집계.
  - 상호 선택 표시.
- 매칭 승인:
  - 상호 선택 매칭 후보.
  - 연락처 공개 승인.
  - 비매칭 안내.
- 리포트 발송 상태:
  - 준비 중.
  - 발송 예정.
  - 발송 완료.
  - 후기 작성 여부.

### 기타 docs에서 도출된 핵심 기능

- 디저트 닉네임:
  - 남성: 크루아상, 단팥빵, 소금빵, 스콘, 초콜릿.
  - 여성: 티라미수, 피낭시에, 마들렌, 에그타르트, 푸딩.
  - 실제 성별 기반 닉네임 정책은 사장님 확인 필요.
- 참가자 정보 공개:
  - 프로그램 당일에만 참가자 전용 화면에서 표시.
  - 오픈 정보 예시: 나이, 직종, MBTI, 자기소개 키워드, 이상형 키워드, 좋아하는 여행지, 인생 영화, 맛집, `나는 OO 하는 사람이다`, `나는 OO 하는 사람이 좋다`.
- 선택 단계:
  - 첫인상 선택.
  - 중간 선택.
  - 최종 선택.
  - 각 단계 마감 후 수정 불가.
- 베이킹 파트너 배치:
  - 중간 쌍방 선택 우선.
  - 첫인상 선택 반영.
  - 케미 점수 반영.
  - 초기 프로토타입에서는 더미 알고리즘으로 결과만 보여준다.

## 6. 화면 흐름

### 앱 시작 흐름

초기 UI 프로토타입:

```text
앱 실행
→ Splash 또는 짧은 브랜드 화면
→ MainTabScreen
→ DemoModeBanner 표시
→ 홈 화면
```

초기에는 Firebase 초기화, 로그인 세션 확인, FCM 토큰 저장이 없다.

### 로그인 여부에 따른 흐름

초기에는 실제 로그인 없이 앱 모드를 전환한다.

```text
게스트 모드
→ 홈/회차/클래스 둘러보기 가능
→ 신청 버튼 클릭
→ 더미 로그인 유도 또는 사용자 모드로 전환

사용자 모드
→ 신청 가능
→ 프로필/인증 입력 가능
→ 내 신청 현황 확인 가능

행사 참가자 모드
→ 당일 화면 접근 가능
→ 좌석/상대 정보/선택 제출 가능

관리자 모드
→ 관리자 대시보드 접근 가능
→ 신청자/인증/선정/좌석/선택/매칭/리포트 조작 가능
```

추천 구현:

- `AppModeProvider.currentMode`
- `DemoAppMode.guest`
- `DemoAppMode.user`
- `DemoAppMode.participantToday`
- `DemoAppMode.admin`

### 주요 탭 이동 구조

기본 BottomNavigationBar:

- 홈
- 회차
- 내역
- 마이

선택 가능 추가 구조:

- 중앙 액션 버튼:
  - 검토용 데모 메뉴 열기.
  - `신청 상태 한 단계 진행`.
  - `관리자 모드 전환`.

사장님 검토에 방해되지 않도록 중앙 액션 버튼은 개발/검토 모드에서만 노출하는 것이 좋다.

### 상세 화면 진입 흐름

```text
홈 모집 카드
→ ChemistryEventDetailScreen
→ 신청하기
→ ChemistryApplyScreen
→ VerificationUploadScreen
→ ApplicationStatusScreen
```

일반 클래스:

```text
회차 탭
→ BakingClassListScreen
→ BakingClassDetailScreen
→ ClassApplicationStatus
```

케미 회차:

```text
회차 탭
→ ChemistryEventListScreen
→ ChemistryEventDetailScreen
→ ChemistryApplyScreen
```

### 작성/수정/삭제 흐름

초기 MVP에서 사용자 작성 기능은 후기 작성만 필수로 둔다.

후기 작성:

```text
케미 리포트
→ 후기 작성하기
→ ReviewWriteScreen
→ 더미 저장
→ 후기 작성 완료 상태 표시
```

관리자 회차 작성/수정:

```text
관리자 대시보드
→ 회차 관리
→ 회차 생성 또는 수정
→ 더미 리스트 반영
```

삭제:

- 초기에는 실제 삭제보다 `마감`, `숨김`, `취소` 상태 토글로 표현한다.
- 실제 삭제 정책은 후속 DB 설계 시 확정한다.

### 관리자 기능 흐름

```text
마이
→ 데모 모드: 관리자 선택
→ AdminDashboardScreen
→ 회차 선택
→ 신청자 목록
→ 인증 검토
→ AI 선정 결과
→ 최종 참가자 확정
→ 입금 확인
→ 좌석 배치
→ 행사 진행 모드
→ 선택 집계
→ 매칭 승인
→ 리포트 발송 상태
```

관리자 기능은 실제 DB 없이도 `DemoFlowProvider`의 상태를 변경해 사용자 화면에 반영되어야 한다.

## 7. 데이터 모델 설계

초기 모델은 `fromJson`, `toJson`, `copyWith` 중심으로 구현한다. Firestore 변환은 후속 컨펌 후 추가한다.

### `AppUser`

용도:

- 더미 로그인 사용자, 참가자, 관리자 정보를 표현.

필드:

- `id`: `String`, non-null.
- `displayName`: `String`, non-null.
- `phone`: `String?`, nullable.
- `email`: `String?`, nullable.
- `profileImageUrl`: `String?`, nullable.
- `roles`: `List<String>`, non-null, 기본 `['user']`.
- `isAdmin`: `bool`, non-null.
- `createdAt`: `DateTime?`, nullable.

### `UserProfile`

용도:

- 신청서와 AI 선정에 쓰이는 사용자 성향/선호 정보.

필드:

- `userId`: `String`, non-null.
- `name`: `String`, non-null, 더미에서는 가명 사용.
- `birthDate`: `DateTime?`, nullable.
- `gender`: `String`, non-null, 예: `male`, `female`, `other`.
- `age`: `int?`, nullable.
- `heightCm`: `int?`, nullable.
- `job`: `String?`, nullable.
- `workType`: `String?`, nullable.
- `religion`: `String?`, nullable.
- `mbti`: `String?`, nullable.
- `region`: `String?`, nullable.
- `introTags`: `List<String>`, non-null.
- `tasteTags`: `List<String>`, non-null.
- `idealTypeTags`: `List<String>`, non-null.
- `myConversationStyles`: `List<String>`, non-null.
- `preferredConversationStyles`: `List<String>`, non-null.
- `preferredAgeRange`: `String?`, nullable.
- `preferredHeightRange`: `String?`, nullable.
- `preferredMbti`: `List<String>`, non-null.
- `unpreferredJobs`: `List<String>`, non-null.
- `preferredReligionPolicy`: `String?`, nullable.

### `Verification`

용도:

- 인증 제출/승인/반려 상태 표현.

필드:

- `id`: `String`, non-null.
- `userId`: `String`, non-null.
- `status`: `VerificationStatus`, non-null.
- `faceImagePath`: `String?`, nullable, 초기에는 local placeholder.
- `documentImagePaths`: `List<String>`, non-null.
- `documentType`: `String?`, nullable, 예: 사원증, 명함, 회사 이메일.
- `rejectReason`: `String?`, nullable.
- `submittedAt`: `DateTime?`, nullable.
- `reviewedAt`: `DateTime?`, nullable.
- `reviewedBy`: `String?`, nullable.

상태:

- `notSubmitted`
- `pending`
- `approved`
- `rejected`
- `reuploadRequired`

### `BakingClass`

용도:

- 일반 베이킹 클래스.

필드:

- `id`: `String`, non-null.
- `title`: `String`, non-null.
- `description`: `String`, non-null.
- `imageUrl`: `String?`, nullable.
- `menuName`: `String?`, nullable.
- `locationName`: `String`, non-null.
- `address`: `String?`, nullable.
- `startAt`: `DateTime`, non-null.
- `durationMinutes`: `int`, non-null.
- `capacity`: `int`, non-null.
- `appliedCount`: `int`, non-null.
- `price`: `int?`, nullable.
- `status`: `ClassStatus`, non-null.

상태:

- `draft`
- `recruiting`
- `closed`
- `cancelled`

### `EventSession`

용도:

- 케미스트리오븐 회차.

필드:

- `id`: `String`, non-null.
- `title`: `String`, non-null.
- `subtitle`: `String?`, nullable.
- `description`: `String`, non-null.
- `locationName`: `String`, non-null.
- `address`: `String?`, nullable.
- `startAt`: `DateTime`, non-null.
- `endAt`: `DateTime?`, nullable.
- `minMaleCount`: `int`, non-null.
- `maxMaleCount`: `int`, non-null.
- `minFemaleCount`: `int`, non-null.
- `maxFemaleCount`: `int`, non-null.
- `price`: `int?`, nullable.
- `status`: `EventStatus`, non-null.
- `programSteps`: `List<String>`, non-null.
- `notice`: `String?`, nullable.

상태:

- `draft`
- `recruiting`
- `selectionInProgress`
- `paymentPending`
- `confirmed`
- `inProgress`
- `finished`
- `cancelled`

### `Application`

용도:

- 회차 신청 상태.

필드:

- `id`: `String`, non-null.
- `eventId`: `String`, non-null.
- `userId`: `String`, non-null.
- `type`: `ApplicationType`, non-null, `bakingClass` 또는 `chemistry`.
- `status`: `ApplicationStatus`, non-null.
- `verificationStatus`: `VerificationStatus`, non-null.
- `paymentStatus`: `PaymentStatus`, non-null.
- `selectedNickname`: `String?`, nullable.
- `adminMemo`: `String?`, nullable.
- `appliedAt`: `DateTime?`, nullable.
- `updatedAt`: `DateTime?`, nullable.

신청 상태:

- `notApplied`
- `applied`
- `verificationPending`
- `verificationApproved`
- `waitingMatch`
- `selected`
- `paymentPending`
- `paymentConfirmed`
- `confirmed`
- `notSelected`
- `cancelledByUser`
- `cancelledByAdmin`
- `noShow`

결제 상태:

- `none`
- `bankTransferPending`
- `confirmed`
- `refunded`
- `cancelled`

### `MatchRun`

용도:

- AI 선정 실행 결과의 묶음.

필드:

- `id`: `String`, non-null.
- `eventId`: `String`, non-null.
- `status`: `MatchRunStatus`, non-null.
- `recommendedParticipantIds`: `List<String>`, non-null.
- `excludedParticipantIds`: `List<String>`, non-null.
- `averageScore`: `double?`, nullable.
- `summary`: `String?`, nullable.
- `createdAt`: `DateTime?`, nullable.
- `confirmedAt`: `DateTime?`, nullable.

초기에는 더미 AI 선정 결과만 표시한다.

### `PairScore`

용도:

- 남녀 또는 참가자 간 궁합 점수.

필드:

- `id`: `String`, non-null.
- `eventId`: `String`, non-null.
- `sourceUserId`: `String`, non-null.
- `targetUserId`: `String`, non-null.
- `strictScore`: `double`, non-null.
- `objectiveScore`: `double`, non-null.
- `finalScore`: `double`, non-null.
- `matchedKeywords`: `List<String>`, non-null.
- `memo`: `String?`, nullable.

초기 finalScore:

```text
(strictScore + objectiveScore) / 2
```

### `SeatPlan`

용도:

- 라운드별 좌석 배치.

필드:

- `id`: `String`, non-null.
- `eventId`: `String`, non-null.
- `round`: `int`, non-null.
- `roundType`: `RoundType`, non-null.
- `tableAssignments`: `List<TableAssignment>`, non-null.
- `startsAt`: `DateTime?`, nullable.
- `endsAt`: `DateTime?`, nullable.
- `status`: `SeatPlanStatus`, non-null.

`TableAssignment` 필드:

- `tableNo`: `String`, non-null.
- `participantAId`: `String`, non-null.
- `participantBId`: `String?`, nullable.
- `participantANickname`: `String`, non-null.
- `participantBNickname`: `String?`, nullable.

### `Choice`

용도:

- 첫인상/중간/최종 선택 제출.

필드:

- `id`: `String`, non-null.
- `eventId`: `String`, non-null.
- `fromUserId`: `String`, non-null.
- `toUserIds`: `List<String>`, non-null.
- `choiceType`: `ChoiceType`, non-null.
- `submittedAt`: `DateTime?`, nullable.
- `isLocked`: `bool`, non-null.

선택 타입:

- `firstImpression`
- `middle`
- `finalChoice`

### `MatchResult`

용도:

- 상호 매칭 결과.

필드:

- `id`: `String`, non-null.
- `eventId`: `String`, non-null.
- `userAId`: `String`, non-null.
- `userBId`: `String`, non-null.
- `userANickname`: `String`, non-null.
- `userBNickname`: `String`, non-null.
- `status`: `MatchResultStatus`, non-null.
- `contactRevealStatus`: `ContactRevealStatus`, non-null.
- `adminApproved`: `bool`, non-null.
- `message`: `String?`, nullable.
- `createdAt`: `DateTime?`, nullable.

### `ChemistryReport`

용도:

- 프로그램 종료 후 보여주는 케미 리포트.

필드:

- `id`: `String`, non-null.
- `eventId`: `String`, non-null.
- `userId`: `String`, non-null.
- `nickname`: `String`, non-null.
- `characterTitle`: `String`, non-null.
- `personalitySummary`: `String`, non-null.
- `myChoicesSummary`: `String`, non-null.
- `chosenBySummary`: `String`, non-null.
- `bakingPartnerSnapshot`: `String`, non-null.
- `mbtiInterpretation`: `String?`, nullable.
- `dramaticInterpretation`: `String?`, nullable.
- `totalComment`: `String`, non-null.
- `status`: `ReportStatus`, non-null.
- `readyAt`: `DateTime?`, nullable.
- `sentAt`: `DateTime?`, nullable.

리포트 상태:

- `pending`
- `ready`
- `sent`

### `Review`

용도:

- 후기 작성.

필드:

- `id`: `String`, non-null.
- `eventId`: `String`, non-null.
- `userId`: `String`, non-null.
- `rating`: `int`, non-null.
- `goodPoint`: `String?`, nullable.
- `badPoint`: `String?`, nullable.
- `suggestion`: `String?`, nullable.
- `wantsNextNotification`: `bool`, non-null.
- `createdAt`: `DateTime?`, nullable.

### Firestore 변환 방식

초기 구현에서는 Firestore 변환을 작성하지 않는다. 단, 후속 전환을 위해 아래 원칙을 문서에 남긴다.

- `DateTime`은 Firestore 전환 시 `Timestamp`로 변환.
- enum은 문자열로 저장.
- 카운터는 서버 전환 후 `FieldValue.increment` 사용.
- 생성/수정 시각은 서버 전환 후 `FieldValue.serverTimestamp` 사용.
- 민감 정보는 일반 `users` 문서가 아니라 별도 컬렉션과 Storage path로 분리.

## 8. Firestore / Firebase 설계

이 섹션은 지금 바로 구현할 기준이 아니다. 사장님 컨펌 후 Firebase/Firestore를 붙일 때 적용할 후보 설계다.

### 초기 MVP에서 Firebase 제외

PHASE 1~5에서는 아래를 하지 않는다.

- Firebase 프로젝트 생성/연결.
- `firebase_options.dart` 생성.
- Android `google-services.json` 추가.
- iOS `GoogleService-Info.plist` 추가.
- `Firebase.initializeApp()` 호출.
- Firestore 읽기/쓰기.
- Firebase Auth 로그인.
- Firebase Storage 업로드.
- Cloud Functions 배포.
- Gemini API 호출.
- SMS/알림톡 API 호출.
- PG 결제 연동.

초기에는 아래만 사용한다.

- 더미데이터.
- `MockRepository`.
- `ChangeNotifier`.
- 필요 시 `shared_preferences` 정도의 로컬 설정 저장.

### 컨펌 후 적용할 컬렉션 구조 후보

```text
users/{uid}
user_profiles/{uid}
user_verifications/{uid}
baking_classes/{classId}
events/{eventId}
events/{eventId}/applications/{applicationId}
events/{eventId}/seat_plans/{roundId}
events/{eventId}/choices/{choiceId}
match_runs/{runId}
match_runs/{runId}/pair_scores/{scoreId}
matches/{matchId}
reports/{reportId}
reviews/{reviewId}
notices/{noticeId}
notifications/{notificationId}
admin_logs/{logId}
app_config/{docId}
```

### 문서 ID 정책 후보

- `users/{uid}`: Firebase Auth UID.
- `user_profiles/{uid}`: Firebase Auth UID와 동일.
- `user_verifications/{uid}`: Firebase Auth UID와 동일.
- `baking_classes/{classId}`: 자동 ID 또는 `class_yyyyMMdd_HHmm_slug`.
- `events/{eventId}`: 자동 ID 또는 `chem_yyyyMMdd_HHmm`.
- `applications/{applicationId}`: `uid`를 문서 ID로 사용 가능. 중복 신청 정책에 따라 `eventId_uid`도 가능.
- `match_runs/{runId}`: 자동 ID.
- `pair_scores/{scoreId}`: `sourceUserId_targetUserId`.
- `seat_plans/{roundId}`: `round_01`, `round_02`, `baking`.
- `choices/{choiceId}`: `choiceType_fromUserId`.
- `matches/{matchId}`: `eventId_userA_userB`.
- `reports/{reportId}`: `eventId_uid`.
- `reviews/{reviewId}`: `eventId_uid`.

### 하위 컬렉션 구조 후보

- `events/{eventId}/applications/{uid}`
  - 회차별 신청자 조회에 유리.
- `events/{eventId}/seat_plans/{roundId}`
  - 회차별 라운드 진행 관리에 유리.
- `events/{eventId}/choices/{choiceId}`
  - 회차별 선택 집계에 유리.
- `users/{uid}/applications/{eventId}`
  - 사용자별 신청 내역 조회가 필요하면 중복 요약 저장.
- `users/{uid}/notifications/{notificationId}`
  - 개인 알림함.

중복 요약 저장은 후속 단계에서 비용/일관성 정책을 보고 결정한다.

### 인덱스가 필요할 수 있는 쿼리 후보

후속 Firestore 전환 시 예상:

- `events`
  - `type + status + startAt`
  - `status + startAt`
  - `locationName + startAt`
- `events/{eventId}/applications`
  - `status + appliedAt`
  - `verificationStatus + appliedAt`
  - `paymentStatus + updatedAt`
  - `gender + age + status`
- `match_runs`
  - `eventId + createdAt`
- `reports`
  - `eventId + status`
  - `userId + createdAt`
- `reviews`
  - `eventId + createdAt`
- `notifications`
  - `uid + createdAt`

### Firebase Authentication 사용 여부 후보

후속 컨펌 후 사용한다.

후보 방식:

- Google 로그인.
- Apple 로그인.
- 카카오/네이버는 기존 프로젝트의 `flutter_web_auth_2 + Cloud Functions custom token` 패턴 참고.
- 휴대폰 본인 인증은 Firebase Auth 전화번호 인증과 별개로 PASS 같은 국내 본인 인증 API가 필요할 수 있음. 확인 필요.

초기 UI 프로토타입:

- 실제 인증 없음.
- `MockAuthRepository`로 더미 사용자 전환.

### Firebase Storage 사용 여부 후보

후속 컨펌 후 사용한다.

후보 저장 경로:

```text
users/{uid}/profile/profile.jpg
verifications/{uid}/face.jpg
verifications/{uid}/documents/doc_001.jpg
classes/{classId}/images/img_001.jpg
events/{eventId}/images/cover.jpg
reviews/{reviewId}/images/img_001.jpg
```

주의:

- 얼굴 사진과 증빙 자료는 민감 정보이므로 public cache를 걸지 않는다.
- 인증 자료는 관리자 외 접근 차단.
- 일정 기간 후 파기 정책 필요. 확인 필요.

### Cloud Functions 사용 가능성 후보

후속 컨펌 후 검토한다.

가능 기능:

- AI/Gemini 기반 프로필 키워드 분석.
- AI/Gemini 기반 인원 선정 보조.
- 케미 리포트 생성.
- 알림톡/SMS 발송.
- FCM 발송.
- 매칭 확정 시 연락처 공개 처리.
- 인증 자료 자동 만료/삭제.
- 관리자 로그 기록.

초기 UI 프로토타입:

- Cloud Functions 없음.
- 더미 결과만 제공.

### 보안 규칙 설계 방향 후보

후속 컨펌 후 작성한다.

원칙:

- 사용자는 본인 `users/{uid}`와 `user_profiles/{uid}`만 읽고 수정.
- 인증 자료는 본인 업로드, 관리자 읽기만 허용.
- 관리자는 `roles`에 `admin`이 있는 경우에만 신청자/인증/매칭/좌석/리포트 관리.
- 매칭 연락처는 상호 매칭 + 관리자 승인 + 본인 관련 매칭일 때만 읽기.
- 비매칭자의 개인정보는 절대 노출하지 않는다.
- 후기/공지 공개 범위는 별도 정책 필요.

## 9. 상태관리 설계

### 기존 프로젝트에서 사용 중인 상태관리 방식 확인

- `gatchacatch`: `provider`와 `ChangeNotifier` 사용.
- `dubai`: `provider`와 `AuthProvider` 사용.
- `jobworld`: 일부 화면 자체 state와 repository/service 직접 사용.
- `mileage_thief`: 화면 state, static service, Firebase stream 혼합.

케미스트리오븐 초기 프로토타입은 검토와 구현 속도가 중요하므로 `provider` + `ChangeNotifier`를 추천한다.

### 케미스트리오븐에 추천할 상태관리 방식

초기 등록 Provider:

- `AppModeProvider`
  - 현재 데모 모드 관리.
  - `guest`, `user`, `participantToday`, `admin`.
- `DemoFlowProvider`
  - 신청 상태, 인증 상태, 결제 상태, 행사 진행 단계, 선택 제출 여부, 매칭 결과, 리포트 상태 관리.
- `EventProvider`
  - 더미 일반 클래스/케미 회차 목록과 선택된 회차 관리.
- `AdminDemoProvider`
  - 관리자 화면에서 신청자 승인/반려/선정/입금/좌석/매칭 상태 변경.

### Provider / Service / Repository 역할 분리

- Provider:
  - UI에서 필요한 상태를 보관.
  - 버튼 클릭 이벤트를 받아 repository 호출.
  - 화면 갱신을 위해 `notifyListeners()`.
- MockRepository:
  - 더미데이터 조회와 더미 상태 변경.
  - 나중에 FirestoreRepository로 바꿀 수 있게 인터페이스 형태 유지.
- Service:
  - 초기에는 최소화.
  - 후속 Firebase 단계에서 AI, 알림, 인증, 결제 같은 외부 연동 담당.

### 앱 전역 상태

`AppModeProvider`:

- `DemoAppMode currentMode`
- `bool get isAdmin`
- `bool get isParticipantToday`
- `AppUser? currentUser`
- `void switchMode(DemoAppMode mode)`

### 사용자 상태

`DemoFlowProvider`:

- `ApplicationStatus applicationStatus`
- `VerificationStatus verificationStatus`
- `PaymentStatus paymentStatus`
- `EventProgressStage progressStage`
- `Choice? firstChoice`
- `Choice? middleChoice`
- `Choice? finalChoice`
- `MatchResult? matchResult`
- `ChemistryReport? report`

### 데이터 로딩 상태

더미데이터라도 로딩/빈상태/오류 화면 검토를 위해 상태를 만든다.

권장 공통 타입:

```dart
enum LoadState {
  initial,
  loading,
  success,
  empty,
  error,
}
```

각 Provider는 `LoadState loadState`, `String? errorMessage`를 가진다.

### 에러 처리 방식

초기 프로토타입:

- 더미 오류 버튼을 관리자/검토 모드에 둔다.
- 빈 상태, 네트워크 오류처럼 보이는 상태, 권한 부족 상태를 강제로 볼 수 있게 한다.

후속 Firebase 단계:

- `FirebaseException`을 사용자 친화 메시지로 변환.
- 인증 만료, 권한 부족, 네트워크 오류, Storage 업로드 실패를 구분.

## 10. UI/UX 설계 방향

### 전체 디자인 톤

키워드:

- 따뜻함.
- 프리미엄.
- 감성적.
- 부담 없는 설렘.
- 베이킹과 사람 사이의 케미.

참고:

- `docs/어플 디자인.pptx`의 크림/아이보리 배경, 버건디 포인트, 베이킹 일러스트, 부드러운 카드 UI.

주의:

- 너무 소개팅 앱처럼 보이지 않게 한다.
- 너무 예약 앱처럼 건조하지 않게 한다.
- 화면 검토가 목적이므로 텍스트와 상태가 명확해야 한다.

### 색상 / 폰트 방향

색상 예시:

- Background: `#FFF8EF`, `#FFFDF8`
- Surface: `#FFFFFF`, `#FFF4E6`
- Primary: `#8A1518` 또는 `#8C1D1D`
- Secondary: `#B9825A`
- Text Primary: `#3B2018`
- Text Secondary: `#7A6256`
- Border: `#E7D2C2`
- Success: `#2F8A5B`
- Warning: `#C3831F`
- Error: `#B3261E`

폰트:

- 기본은 시스템 폰트 또는 `Noto Sans KR` 계열.
- `mileage_thief`처럼 커스텀 감성 폰트를 쓰는 방식도 가능하지만, 초기 검토 단계에서는 가독성을 우선한다.

### 카드 UI

- radius는 8~12px.
- 홈의 모집 카드는 조금 더 강조하되 과한 shadow는 피한다.
- 상태 카드는 타임라인과 chip을 함께 사용한다.
- 관리자 카드는 밀도 높게, 반복 조작이 쉬운 구조로 만든다.

### 리스트 UI

- 회차 리스트:
  - 모집 상태 chip.
  - 날짜/시간.
  - 장소.
  - 정원.
  - CTA.
- 관리자 신청자 리스트:
  - 모바일에서는 카드형.
  - 태블릿/웹 폭에서는 표 형태.
  - 필터: 성별, 나이대, 인증 상태, 신청 상태, 결제 상태.

### 상세 페이지 UI

- 상단 이미지/브랜드 배너.
- 핵심 정보 summary.
- 프로그램 단계 timeline.
- 신청 조건.
- CTA sticky bottom 가능.
- 신청 후에는 CTA 대신 현재 상태와 다음 액션 표시.

### 검색 / 필터 UI

- 검색창.
- chip 필터.
- 날짜 필터.
- 모집 상태 필터.
- 초기에는 기능보다 화면 검토가 목적이므로 더미 검색 결과를 명확하게 보여준다.

### 빈 상태 / 로딩 / 에러 UI

반드시 확인 가능한 상태:

- 신청 내역 없음.
- 모집 중 회차 없음.
- 인증 반려.
- 선정되지 않음.
- 입금 대기.
- 비매칭.
- 리포트 준비 중.
- 권한 없음.
- 더미 오류.

### 기존 프로젝트에서 재사용 가능한 UI 패턴

- `gatchacatch/lib/features/main_tab_screen.dart`
  - 하단 탭 + 중앙 액션 버튼.
- `dubai/lib/app/main_tab_screen.dart`
  - 탭 유지와 bottom sheet action menu.
- `dubai/lib/app/theme.dart`
  - 테마 파일 분리 방식.
- `dubai/lib/core/widgets/section_card.dart`
  - 섹션 카드 구조 참고.
- `mileage_thief/lib/widgets/segment_tab_bar.dart`
  - 관리자 필터/탭에 참고.
- `jobworld/lib/widgets/common_widgets.dart`
  - 공통 위젯 묶음 방식 참고.

## 11. Android / iOS 설정

### 패키지명 / 번들 ID 설계 방향

초기 Flutter 프로젝트 생성 시 후보:

- Android package: `com.mungyu.chemistryoven`
- iOS bundle ID: `com.mungyu.chemistryOven`

확인 필요:

- 실제 배포 계정의 네이밍 규칙.
- 사장님 또는 회사 소유 도메인 기반 bundle ID 사용 여부.

### 앱 이름

권장:

- 한국어 표시명: `케미스트리오븐`
- 영문 표시명: `Chemistry Oven`

### 아이콘 / 스플래시

초기 UI 프로토타입:

- 앱 아이콘은 placeholder 가능.
- 스플래시는 간단한 로고/문구로 충분.
- `docs/어플 디자인.pptx`의 베이킹 일러스트 톤을 참고.

후속 컨펌 후:

- 정식 로고.
- 앱 아이콘.
- Android adaptive icon.
- iOS alpha 제거 icon.
- `flutter_launcher_icons`.
- 필요 시 `flutter_native_splash`.

### Firebase 설정 파일 위치

초기에는 Firebase를 붙이지 않으므로 파일을 만들지 않는다.

후속 컨펌 후 위치:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- Dart: `lib/firebase_options.dart`

### 권한 설정

초기 UI 프로토타입:

- 실제 카메라/앨범 권한 없이 이미지 placeholder와 더미 업로드 화면으로 진행한다.
- 이미지 선택 기능을 꼭 보여줘야 하면 `image_picker`를 붙일 수 있지만, 실제 인증 저장은 하지 않는다.

후속 컨펌 후 필요한 권한:

- 카메라 권한.
- 사진 라이브러리 권한.
- 알림 권한.
- 위치 권한은 장소 지도 기능을 넣을 때만.

### 배포 전 체크리스트

초기 검토 빌드:

- Android debug build 실행.
- iOS simulator 실행 가능 여부 확인.
- Firebase 미연동 상태에서 앱이 정상 실행되는지 확인.
- 모든 더미 버튼이 상태 변화를 일으키는지 확인.
- 관리자 모드와 사용자 모드 전환이 쉬운지 확인.

정식 배포 전:

- Firebase 보안 규칙.
- 개인정보처리방침.
- 이용약관.
- 민감정보 파기 정책.
- 본인 인증 정책.
- 결제/환불 정책.
- iOS 심사용 계정.
- 앱 아이콘/스플래시.
- 푸시 알림 문구.
- 알림톡/SMS 수신 동의.

## 12. 개발 PHASE 계획

### PHASE 0. 자료 조사 및 UI 범위 확정

목표:

- 앱의 구현 범위를 `사장님 검토용 더미데이터 UI 프로토타입`으로 확정한다.

해야 할 작업:

- `docs` 폴더 자료를 다시 요약한다.
- `gatchacatch`, `dubai`, `jobworld`, `mileage_thief`의 참고 구조를 정리한다.
- Firebase 제외 범위를 명확히 한다.
- 검토용 필수 화면 목록을 확정한다.
- 더미 플로우의 시작/종료 상태를 확정한다.

산출물:

- `ARICHITECTURE.MD`.
- 화면 목록.
- 더미 상태 목록.
- 개발 우선순위.

참고할 기존 프로젝트:

- `gatchacatch`: feature-first 구조.
- `dubai`: 앱/라우트/탭/관리자 화면 구조.

주의사항:

- 이 단계에서 앱 코드를 만들지 않는다.
- 문서와 실제 구현 범위를 섞지 않는다.
- Firebase를 붙이지 않는다는 결정을 문서 전체에 반영한다.

완료 기준:

- 사장님 검토용 UI 프로토타입이라는 목표가 문서에 명확히 적혀 있다.
- `dusegwon` 대신 `dubai` 참고가 반영되어 있다.

### PHASE 1. Flutter 프로젝트 초기 세팅, Firebase 제외

목표:

- Firebase 없이 실행되는 Flutter 앱의 최소 골격을 만든다.

해야 할 작업:

- Flutter 프로젝트 생성.
- `pubspec.yaml` 구성.
- `provider`, `intl`, `shared_preferences` 정도만 우선 추가.
- Firebase 관련 패키지는 넣지 않는다.
- `lib/main.dart` 생성.
- `lib/app/app.dart`, `routes.dart`, `theme.dart`, `main_tab_screen.dart` 생성.
- 기본 탭 구성:
  - 홈
  - 회차
  - 내역
  - 마이
- `ChemistryTheme` 구성.
- `DemoModeBanner`와 `AppModeProvider` 구성.

산출물:

- Firebase 없이 실행되는 Flutter 앱.
- 빈 탭 4개.
- 검토용 테마.

참고할 기존 프로젝트:

- `dubai/lib/app/app.dart`
- `dubai/lib/app/routes.dart`
- `dubai/lib/app/main_tab_screen.dart`
- `dubai/lib/app/theme.dart`
- `gatchacatch/lib/features/main_tab_screen.dart`

주의사항:

- `Firebase.initializeApp()`를 작성하지 않는다.
- `firebase_options.dart`를 만들지 않는다.
- `google-services.json`, `GoogleService-Info.plist`를 추가하지 않는다.
- 실제 로그인 SDK를 붙이지 않는다.

완료 기준:

- `flutter run`으로 앱이 뜬다.
- 홈/회차/내역/마이 탭 이동이 된다.
- 앱 전체가 케미스트리오븐 톤의 색상으로 보인다.

### PHASE 2. 더미 모델/더미 데이터/MockRepository 구성

목표:

- 모든 화면이 실제 DB 없이 동작하도록 더미데이터와 상태 변경 구조를 만든다.

해야 할 작업:

- `shared/models` 작성:
  - `AppUser`
  - `UserProfile`
  - `Verification`
  - `BakingClass`
  - `EventSession`
  - `Application`
  - `MatchRun`
  - `PairScore`
  - `SeatPlan`
  - `Choice`
  - `MatchResult`
  - `ChemistryReport`
  - `Review`
  - `Notice`
- `data/dummy` 작성:
  - 더미 사용자 10명.
  - 더미 관리자 1명.
  - 더미 일반 베이킹 클래스 3개.
  - 더미 케미 회차 3개.
  - 더미 신청 내역.
  - 더미 AI 선정 결과.
  - 더미 좌석 배치.
  - 더미 선택 결과.
  - 더미 매칭 결과.
  - 더미 케미 리포트.
- `data/repositories/mock_*_repository.dart` 작성.
- `DemoFlowProvider` 작성.

산출물:

- 실제 DB 없이 모든 화면에 공급할 데이터.
- 클릭 시 상태가 바뀌는 demo provider.

참고할 기존 프로젝트:

- `gatchacatch/lib/features/feed/data/models/post_model.dart`
- `gatchacatch/lib/shared/models/user_model.dart`
- `jobworld/lib/features/spot/data/repositories/spot_repository.dart`

주의사항:

- 더미데이터에 실제 엑셀 개인정보를 넣지 않는다.
- 이름/연락처는 가명/가짜 번호만 사용한다.
- Firestore 변환 코드는 아직 작성하지 않는다.

완료 기준:

- 더미 모델이 앱 내 모든 화면의 데이터를 표현할 수 있다.
- 신청 상태를 한 단계씩 진행시킬 수 있다.

### PHASE 3. 사용자용 전체 화면 구현

목표:

- 사장님이 사용자 입장에서 처음부터 끝까지 흐름을 확인할 수 있게 한다.

해야 할 작업:

- 홈 화면 구현.
- 회차 탭 구현:
  - 일반 베이킹 클래스 목록.
  - 케미스트리오븐 회차 목록.
  - 필터/검색.
- 클래스 상세 화면 구현.
- 케미 회차 상세 화면 구현.
- 신청 화면 구현.
- 프로필 입력 화면 구현.
- 인증 업로드 더미 화면 구현.
- 신청 상태 화면 구현.
- 내역 화면 구현.
- 마이페이지 구현.
- 설정 placeholder 구현.

산출물:

- 일반 사용자 흐름 전체.
- 신청 전부터 최종 확정 전까지 상태 확인 가능.

참고할 기존 프로젝트:

- `docs/어플 디자인.pptx`
- `gatchacatch/lib/features/search/presentation/screens/search_screen.dart`
- `dubai/lib/features/profile/presentation/screens/my_page_screen.dart`
- `mileage_thief/lib/screen/home_screen.dart`

주의사항:

- 화면 안에 기능 설명 텍스트를 과하게 넣지 않는다.
- 검토용 버튼은 `DemoModeBanner`나 마이페이지에 모은다.
- 실제 이미지 업로드나 인증 API를 붙이지 않는다.

완료 기준:

- 사용자가 신청하기를 누르고 신청 상태 화면까지 이동한다.
- 더미 인증 제출 후 상태가 `인증 대기`로 바뀐다.
- 상태 타임라인이 현재 단계를 명확히 보여준다.

### PHASE 4. 관리자용 검토/운영 화면 구현

목표:

- 운영자가 수작업으로 하는 흐름을 앱 화면에서 검토할 수 있게 한다.

해야 할 작업:

- 관리자 대시보드.
- 회차 생성/수정 화면.
- 신청자 목록 화면.
- 신청자 상세 화면.
- 인증 승인/반려 화면.
- AI 선정 결과 화면.
- 최종 참가자 수동 조정 화면.
- 입금 확인 화면.
- 좌석 배치 화면.
- 행사 진행 컨트롤 화면.
- 선택 집계 화면.
- 매칭 승인 화면.
- 리포트 발송 상태 화면.

산출물:

- 관리자 모드 전체 화면.
- 사용자 더미 상태와 연결되는 관리자 버튼.

참고할 기존 프로젝트:

- `dubai/lib/features/profile/presentation/screens/admin_screen.dart`
- `dubai/lib/features/profile/presentation/screens/statistics_dashboard_screen.dart`
- `dubai/lib/features/profile/presentation/screens/notice_management_screen.dart`
- `dubai/lib/features/profile/presentation/screens/user_management_screen.dart`
- `gatchacatch/lib/features/profile/presentation/screens/admin/*`

주의사항:

- 표가 너무 작아지면 모바일에서는 카드형으로 표시한다.
- 사장님 검토에서는 “운영자가 이 버튼을 누르면 사용자 화면이 어떻게 바뀌는지”가 보여야 한다.
- 관리자 기능도 Firebase 없이 더미 상태만 변경한다.

완료 기준:

- 관리자 모드에서 인증 승인 시 사용자 신청 상태가 바뀐다.
- AI 선정 확정 시 사용자가 `선정됨` 상태를 볼 수 있다.
- 입금 확인 시 사용자가 `최종 확정` 상태를 볼 수 있다.

### PHASE 5. 행사 당일 단계 시뮬레이션 구현

목표:

- 케미스트리오븐의 핵심인 당일 프로그램 진행 화면을 더미로 끝까지 확인한다.

해야 할 작업:

- 참가자 닉네임 화면.
- 오늘의 회차 화면.
- 현재 라운드/좌석 화면.
- 상대 기본 정보/키워드 bottom sheet.
- 첫인상 선택 화면.
- 중간 선택 화면.
- 베이킹 파트너 배치 화면.
- 최종 선택 화면.
- 매칭 결과 화면.
- 비매칭 결과 화면.
- 연락처 공개 화면.
- 케미 리포트 화면.
- 후기 작성 화면.

산출물:

- 행사 당일 전체 데모 플로우.
- 사용자와 관리자 양쪽에서 진행 단계 확인 가능.

참고할 기존 프로젝트:

- `docs/무제 2.rtfd/TXT.rtf`
- `docs/어플 개발.pptx`
- `docs/어플 디자인.pptx`
- `dubai/lib/app/main_tab_screen.dart`

주의사항:

- 최종 선택 전에는 연락처가 절대 보이지 않게 한다.
- 비매칭 화면도 반드시 검토 가능해야 한다.
- 중간 선택 후 좌석 배치 결과가 바뀌는 것처럼 보여야 한다.

완료 기준:

- `신청 전 → 후기 작성`까지 클릭으로 진행 가능하다.
- 첫인상/중간/최종 선택이 각각 다른 화면으로 구분된다.
- 매칭 성공/실패 케이스를 모두 볼 수 있다.

### PHASE 6. 사장님 검토/피드백 반영

목표:

- 실제 DB 작업 전에 화면, 문구, 운영 흐름, 디자인을 확정한다.

해야 할 작업:

- Android 또는 iOS 빌드로 사장님 검토.
- 홈 톤 검토.
- 신청서 문항 검토.
- 인증 자료 화면 검토.
- 관리자 승인 흐름 검토.
- AI 선정 결과 화면 검토.
- 좌석/라운드 진행 방식 검토.
- 선택/매칭/연락처 공개 정책 검토.
- 리포트 문구 검토.
- 수정 요청 반영.

산출물:

- 컨펌된 UI 플로우.
- 수정 완료된 화면.
- Firebase 전환 전 확정된 데이터 필드 목록.

참고할 기존 프로젝트:

- 없음. 이 단계는 케미스트리오븐 자체 검토가 중심이다.

주의사항:

- 이 단계에서도 Firebase를 붙이지 않는다.
- 화면 확정 전 DB를 만들면 필드 변경 비용이 커진다.
- 사장님이 직접 눌러보는 흐름을 우선한다.

완료 기준:

- 사장님이 화면 흐름을 컨펌한다.
- DB/Firebase 전환 범위가 확정된다.
- 개인정보/인증/결제/알림 정책의 확인 필요 항목이 정리된다.

### PHASE 7. 컨펌 후 Firebase/Firestore 연동 설계 및 전환

목표:

- 확정된 UI와 데이터 필드를 기반으로 실제 Firebase/Firestore 연동을 시작한다.

해야 할 작업:

- Firebase 프로젝트 생성.
- `flutterfire configure`.
- `firebase_options.dart` 생성.
- Android/iOS Firebase 설정 파일 추가.
- Firebase Auth 연결.
- Firestore 컬렉션 생성.
- Storage 업로드 연결.
- `MockRepository`를 `FirestoreRepository`로 교체.
- 보안 규칙 작성.
- 관리자 권한 정책 작성.
- Cloud Functions 검토:
  - AI 분석.
  - 리포트 생성.
  - 알림톡/SMS.
  - FCM.
- 비용 추정.

산출물:

- 실제 DB 연동 앱.
- Firebase 보안 규칙 초안.
- Storage 권한 정책.
- Cloud Functions 후보 목록.

참고할 기존 프로젝트:

- `gatchacatch/lib/core/services/firestore_service.dart`
- `gatchacatch/lib/core/constants/firestore_paths.dart`
- `gatchacatch/lib/core/services/storage_service.dart`
- `jobworld/server/notification/src/index.ts`
- `mileage_thief/functions/index.js`
- `dubai/lib/core/services/auth_service.dart`

주의사항:

- 이 단계 전까지는 Firebase를 붙이지 않는다.
- 실제 개인정보 저장 전에 보안 규칙을 먼저 검토한다.
- 인증 이미지와 연락처 공개 정책은 특별히 신중히 설계한다.

완료 기준:

- 더미데이터 없이 실제 Firestore 데이터로 주요 화면이 동작한다.
- 관리자 권한이 없는 사용자는 민감 화면에 접근할 수 없다.
- 상호 매칭 전 연락처가 노출되지 않는다.

### PHASE 8. 테스트 및 배포 준비

목표:

- 검토용 앱 또는 실제 출시 앱을 안정적으로 빌드하고 배포 준비한다.

해야 할 작업:

- Android 빌드 테스트.
- iOS 빌드 테스트.
- 화면별 스냅샷 QA.
- 작은 화면/큰 화면 QA.
- 상태별 QA:
  - 신청 없음.
  - 인증 대기.
  - 인증 반려.
  - 선정됨.
  - 미선정.
  - 입금 대기.
  - 확정.
  - 행사 중.
  - 매칭 성공.
  - 비매칭.
  - 리포트 준비 중.
- Firebase 전환 후:
  - 보안 규칙 테스트.
  - Storage 권한 테스트.
  - 알림 테스트.
  - 비용 모니터링.
- 앱 아이콘/스플래시 확인.
- 개인정보처리방침/이용약관 준비.
- Play Store/App Store 등록 준비.

산출물:

- 검토용 빌드 또는 출시 후보 빌드.
- QA 체크리스트.
- 배포 전 이슈 목록.

참고할 기존 프로젝트:

- `jobworld`, `gatchacatch`, `dubai`, `mileage_thief`의 Android/iOS 설정.

주의사항:

- iOS 심사에서 소개팅/매칭/개인정보/연락처 공개가 민감하게 보일 수 있다.
- 개인정보처리방침과 이용약관은 반드시 준비한다.
- 본인 인증과 증빙자료 수집 목적/보관기간/삭제 정책을 명확히 한다.

완료 기준:

- 주요 플로우가 크래시 없이 동작한다.
- 검토 또는 출시 목적에 맞는 빌드가 생성된다.
- 개인정보/심사/보안 체크리스트가 완료된다.

## 13. 구현 우선순위

### 반드시 먼저 구현할 것

- Firebase 제외 Flutter 앱 골격.
- `AppModeProvider`.
- `DemoFlowProvider`.
- 더미 모델.
- 더미 회차/신청자/참가자/리포트 데이터.
- 홈 화면.
- 회차 목록/상세.
- 신청 화면.
- 신청 상태 타임라인.
- 마이페이지의 데모 모드 전환.
- 관리자 대시보드.
- 신청자 목록.
- 인증 승인/반려.
- AI 선정 결과 더미 화면.
- 행사 당일 좌석/선택/매칭/리포트 흐름.

### 나중에 구현해도 되는 것

- 실제 이미지 업로드.
- 실제 휴대폰 본인 인증.
- 실제 알림.
- 실제 결제.
- 커뮤니티 게시판.
- 고급 검색.
- 상세 통계.
- 다크모드 고도화.
- 지도.
- 캘린더 고도화.

### 앱 출시 후 개선할 것

- AI 선정 알고리즘 정교화.
- Gemini 기반 리포트 자동 생성.
- 알림톡/SMS 자동화.
- 결제 PG 연동.
- 재참여자 특별 회차.
- 포인트/랭킹/이벤트.
- 후기 기반 추천.
- 관리자 웹 분리.
- 개인정보 자동 파기.

## 14. 리스크 및 주의사항

### docs 자료와 실제 코드 구조가 충돌할 수 있는 부분

- docs는 운영 아이디어와 수동 엑셀 방식이 섞여 있다.
- 엑셀 구조를 그대로 DB로 옮기면 확장성이 떨어진다.
- 화면 검토 전 DB를 만들면 필드 변경이 잦아질 가능성이 높다.
- 따라서 초기에는 더미데이터 UI로 흐름을 검증하고, 컨펌 후 DB 구조를 확정한다.

### Firebase 비용 증가 가능성

후속 Firebase 단계에서 비용 리스크가 있다.

- 신청자 목록 실시간 구독 남발.
- 관리자 통계 count 쿼리 반복.
- 케미 리포트/AI 분석 Cloud Functions 호출.
- Storage 인증 이미지 업로드.
- FCM/알림톡/SMS 외부 비용.

대응:

- 초기에는 Firebase 제외.
- 컨펌 후 쿼리 설계와 비용 추정.
- 관리자 통계는 집계 문서 또는 scheduled aggregation 고려.
- AI 호출은 관리자 버튼 기반 수동 실행부터 시작.

### iOS 심사 이슈 가능성

주의 영역:

- 소개팅/매칭 성격.
- 개인정보 수집.
- 얼굴 사진/증빙 자료 수집.
- 연락처 공개.
- 결제/환불.
- 사용자 신고/차단 정책.

대응:

- 앱 설명은 `소셜 베이킹 프로그램 운영 앱` 중심으로 표현.
- 개인정보처리방침과 이용약관 준비.
- 상호 선택 시에만 연락처 공개되는 안전 장치 명확화.
- 신고/문의/탈퇴 기능 준비.

### 데이터 구조 변경 리스크

- 프로필 질문이 바뀔 수 있다.
- AI 점수 방식이 바뀔 수 있다.
- 선택 단계가 3회에서 변경될 수 있다.
- 닉네임 정책이 바뀔 수 있다.
- 관리자 확정/입금 정책이 바뀔 수 있다.

대응:

- 초기 UI 프로토타입으로 정책 먼저 확정.
- enum과 status를 중앙 상수로 관리.
- Firestore 전환 전 데이터 필드 최종 확인.

### 기존 프로젝트 코드를 그대로 복사할 때 발생할 수 있는 문제

- `gatchacatch`, `dubai`, `jobworld`, `mileage_thief`는 Firebase/지도/광고/알림 코드가 이미 섞여 있다.
- 그대로 복사하면 초기 프로토타입에서 불필요한 설정 파일과 빌드 오류가 생길 수 있다.
- 패키지 버전 차이로 충돌 가능.
- 앱 ID, OAuth scheme, Firebase project ID가 기존 프로젝트 값으로 남을 위험.

대응:

- 구조와 패턴만 참고한다.
- Firebase 코드는 초기 구현에서 복사하지 않는다.
- 필요한 UI 위젯도 도메인 이름과 색상, 문구를 케미스트리오븐 기준으로 바꾼다.

## 15. 최종 권장 개발 순서

### 실제 Codex가 다음 단계에서 구현할 때 따라야 할 순서

1. Flutter 프로젝트 생성.
2. Firebase 패키지 없이 최소 의존성만 설정.
3. `lib/app` 구조 생성.
4. `ChemistryTheme` 작성.
5. `MainTabScreen` 작성.
6. `AppModeProvider` 작성.
7. `DemoFlowProvider` 작성.
8. 더미 모델 작성.
9. 더미 데이터 작성.
10. MockRepository 작성.
11. 홈 화면 구현.
12. 회차 목록/상세 구현.
13. 신청/인증/상태 화면 구현.
14. 관리자 대시보드/신청자/인증/선정 화면 구현.
15. 행사 당일 좌석/선택/매칭/리포트 화면 구현.
16. 마이페이지에서 데모 모드 전환 가능하게 연결.
17. 사장님 검토용 빌드 생성.
18. 피드백 반영.
19. 컨펌 후 Firebase/Firestore 전환.

### 우선 생성해야 할 파일 목록

```text
lib/main.dart
lib/app/app.dart
lib/app/routes.dart
lib/app/theme.dart
lib/app/main_tab_screen.dart
lib/shared/providers/app_mode_provider.dart
lib/shared/providers/demo_flow_provider.dart
lib/core/constants/demo_status.dart
lib/core/widgets/demo_mode_banner.dart
lib/core/widgets/chemistry_card.dart
lib/core/widgets/status_chip.dart
lib/data/dummy/dummy_events.dart
lib/data/dummy/dummy_users.dart
lib/data/dummy/dummy_applications.dart
lib/data/dummy/dummy_reports.dart
lib/data/repositories/mock_event_repository.dart
lib/data/repositories/mock_application_repository.dart
lib/data/repositories/mock_admin_repository.dart
lib/features/home/presentation/screens/home_screen.dart
lib/features/chemistry/presentation/screens/chemistry_event_list_screen.dart
lib/features/chemistry/presentation/screens/chemistry_event_detail_screen.dart
lib/features/applications/presentation/screens/application_status_screen.dart
lib/features/admin/presentation/screens/admin_dashboard_screen.dart
lib/features/event_flow/presentation/screens/today_event_screen.dart
lib/features/matching/presentation/screens/match_result_screen.dart
lib/features/reports/presentation/screens/chemistry_report_screen.dart
lib/features/profile/presentation/screens/my_page_screen.dart
```

### 우선 확인해야 할 기존 코드 위치

- `dubai/lib/app/app.dart`
- `dubai/lib/app/routes.dart`
- `dubai/lib/app/main_tab_screen.dart`
- `dubai/lib/app/theme.dart`
- `dubai/lib/features/profile/presentation/screens/admin_screen.dart`
- `dubai/lib/features/profile/presentation/screens/statistics_dashboard_screen.dart`
- `gatchacatch/lib/features/main_tab_screen.dart`
- `gatchacatch/lib/shared/providers/auth_provider.dart`
- `gatchacatch/lib/shared/models/user_model.dart`
- `gatchacatch/lib/features/feed/data/models/post_model.dart`
- `jobworld/lib/app/jobworld_app.dart`
- `jobworld/lib/features/spot/data/repositories/spot_repository.dart`
- `mileage_thief/lib/screen/home_screen.dart`
- `mileage_thief/lib/widgets/segment_tab_bar.dart`

### 구현 전 추가로 확인해야 할 사항

- 앱 이름 표기:
  - `케미스트리오븐`
  - `케미스트리 오븐`
  - `Chemistry Oven`
- 사장님 검토용 빌드는 Android 우선인지 iOS 우선인지.
- 홈 배너 이미지를 PPT 시안 기반으로 임시 사용할지, 새 에셋을 만들지.
- 일반 베이킹 클래스가 MVP 검토에 반드시 필요한지.
- 회차 가격/입금 문구.
- 취소/환불 정책 문구.
- 인증 자료 종류.
- 참가자 공개 정보 범위.
- 최종 선택 가능 인원 수.
- 매칭 연락처 공개 전 관리자 승인 필수 여부.
- 케미 리포트 문구 톤.
- 관리자 화면을 앱 내부에 둘지, 추후 웹으로 분리할지.

## 다음 Codex 작업 프롬프트 예시

```text
현재 폴더에 신규 Flutter 앱을 생성하고, ARICHITECTURE.MD 기준으로 Firebase 없이 더미데이터 기반 UI 프로토타입을 구현해주세요.

중요:
- Firebase, Firestore, Auth, Storage, Cloud Functions를 붙이지 마세요.
- 실제 DB 없이 lib/data/dummy와 MockRepository로만 동작하게 해주세요.
- 우선 홈/회차/내역/마이 BottomNavigationBar를 만들고, 마이페이지에서 게스트/사용자/행사참가자/관리자 데모 모드를 전환할 수 있게 해주세요.
- 홈 화면은 docs/어플 디자인.pptx의 톤을 참고해서 크림/아이보리/버건디 계열로 구성해주세요.
- 신청 전 → 인증 대기 → 인증 승인 → AI 선정 대기 → 선정됨 → 입금 대기 → 최종 확정 → 행사 당일 → 선택 → 매칭 결과 → 케미 리포트 → 후기 작성 흐름을 DemoFlowProvider로 진행할 수 있게 해주세요.
- 관리자 모드에서는 인증 승인/반려, AI 선정 결과 보기, 최종 참가자 확정, 입금 확인, 좌석 배치, 라운드 전환, 선택 집계, 매칭 승인, 리포트 발송 상태 화면을 더미로 구현해주세요.
- 기존 프로젝트는 /Users/vory/StudioProjects/gatchacatch, /Users/vory/StudioProjects/dubai, /Users/vory/StudioProjects/jobworld, /Users/vory/StudioProjects/mileage_thief를 참고하되 파일은 수정하지 마세요.
```
