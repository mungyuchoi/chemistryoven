import 'package:flutter/material.dart';

enum DemoMode { guest, user, participantToday, admin }

enum MainTab { home, schedule, lab, ovening, my }

extension MainTabX on MainTab {
  String get label {
    switch (this) {
      case MainTab.home:
        return '홈';
      case MainTab.schedule:
        return '일정';
      case MainTab.lab:
        return '케미Lab';
      case MainTab.ovening:
        return '오브닝';
      case MainTab.my:
        return '마이';
    }
  }

  IconData get icon {
    switch (this) {
      case MainTab.home:
        return Icons.home_outlined;
      case MainTab.schedule:
        return Icons.calendar_month_outlined;
      case MainTab.lab:
        return Icons.science_outlined;
      case MainTab.ovening:
        return Icons.local_fire_department_outlined;
      case MainTab.my:
        return Icons.person_outline;
    }
  }

  IconData get selectedIcon {
    switch (this) {
      case MainTab.home:
        return Icons.home;
      case MainTab.schedule:
        return Icons.calendar_month;
      case MainTab.lab:
        return Icons.science;
      case MainTab.ovening:
        return Icons.local_fire_department;
      case MainTab.my:
        return Icons.person;
    }
  }

  bool get requiresSession => this == MainTab.ovening;
}

extension DemoModeX on DemoMode {
  String get label {
    switch (this) {
      case DemoMode.guest:
        return '게스트';
      case DemoMode.user:
        return '사용자';
      case DemoMode.participantToday:
        return '행사참가자';
      case DemoMode.admin:
        return '관리자';
    }
  }

  String get description {
    switch (this) {
      case DemoMode.guest:
        return '가입 전 방문자가 앱 분위기와 회차를 둘러보는 상태';
      case DemoMode.user:
        return '신청과 인증 흐름을 확인하는 일반 사용자 상태';
      case DemoMode.participantToday:
        return '행사 당일 선택, 매칭, 리포트 흐름을 확인하는 상태';
      case DemoMode.admin:
        return '운영자가 신청자와 행사 진행을 관리하는 상태';
    }
  }

  IconData get icon {
    switch (this) {
      case DemoMode.guest:
        return Icons.person_outline;
      case DemoMode.user:
        return Icons.favorite_border;
      case DemoMode.participantToday:
        return Icons.celebration_outlined;
      case DemoMode.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }
}

enum DemoFlowStep {
  beforeApplication,
  verificationWaiting,
  verificationApproved,
  aiSelectionWaiting,
  selected,
  paymentWaiting,
  confirmed,
  nicknameCheck,
  firstImpressionChoice,
  rotationTalk,
  middleChoice,
  seatingGuide,
  pairBaking,
  finalChoice,
  matchResult,
  chemistryReport,
  review,
}

extension DemoFlowStepX on DemoFlowStep {
  String get label {
    switch (this) {
      case DemoFlowStep.beforeApplication:
        return '신청 전';
      case DemoFlowStep.verificationWaiting:
        return '인증 대기';
      case DemoFlowStep.verificationApproved:
        return '인증 승인';
      case DemoFlowStep.aiSelectionWaiting:
        return 'AI 선정 대기';
      case DemoFlowStep.selected:
        return '선정됨';
      case DemoFlowStep.paymentWaiting:
        return '입금 대기';
      case DemoFlowStep.confirmed:
        return '최종 확정';
      case DemoFlowStep.nicknameCheck:
        return '닉네임 확인';
      case DemoFlowStep.firstImpressionChoice:
        return '첫인상 선택';
      case DemoFlowStep.rotationTalk:
        return '로테이션 대화';
      case DemoFlowStep.middleChoice:
        return '중간 선택';
      case DemoFlowStep.seatingGuide:
        return '자리배치';
      case DemoFlowStep.pairBaking:
        return '페어 베이킹';
      case DemoFlowStep.finalChoice:
        return '최종 선택';
      case DemoFlowStep.matchResult:
        return '매칭 결과';
      case DemoFlowStep.chemistryReport:
        return '케미 리포트';
      case DemoFlowStep.review:
        return '후기 작성';
    }
  }

  String get description {
    switch (this) {
      case DemoFlowStep.beforeApplication:
        return '관심 회차를 둘러보고 신청 버튼을 누르기 전입니다.';
      case DemoFlowStep.verificationWaiting:
        return '신청서 제출 후 신원 인증 승인 여부를 기다립니다.';
      case DemoFlowStep.verificationApproved:
        return '운영자가 인증을 승인했고 AI 선정 단계로 넘어갈 수 있습니다.';
      case DemoFlowStep.aiSelectionWaiting:
        return '취향, 나이대, MBTI, 회차 성비를 기준으로 선정 결과를 기다립니다.';
      case DemoFlowStep.selected:
        return '참가 후보로 선정되었습니다. 입금 안내를 확인합니다.';
      case DemoFlowStep.paymentWaiting:
        return '입금 확인 전 상태입니다. 운영자가 더미 입금을 승인할 수 있습니다.';
      case DemoFlowStep.confirmed:
        return '최종 참가가 확정되었습니다. 행사 당일까지 안내를 확인합니다.';
      case DemoFlowStep.nicknameCheck:
        return 'AI가 정리한 디저트 닉네임과 오늘의 시작 좌석을 확인합니다.';
      case DemoFlowStep.firstImpressionChoice:
        return '입장 직후의 첫인상 선택을 제출합니다.';
      case DemoFlowStep.rotationTalk:
        return '전원과 짧게 1:1 대화를 나누며 대화 흐름을 확인합니다.';
      case DemoFlowStep.middleChoice:
        return '대화와 베이킹 후 함께하고 싶은 파트너를 선택합니다.';
      case DemoFlowStep.seatingGuide:
        return '첫인상과 중간 선택, 케미 점수를 바탕으로 새 테이블을 안내합니다.';
      case DemoFlowStep.pairBaking:
        return '배정된 파트너와 함께 디저트를 만들며 협업 케미를 확인합니다.';
      case DemoFlowStep.finalChoice:
        return '마지막으로 마음을 전할 상대와 짧은 메시지를 남깁니다.';
      case DemoFlowStep.matchResult:
        return '상호 선택 결과와 연락처 공개 전 안내를 확인합니다.';
      case DemoFlowStep.chemistryReport:
        return '행사 후 발송되는 케미 리포트를 확인합니다.';
      case DemoFlowStep.review:
        return '참가 후기를 작성하고 다음 회차 재참여를 유도합니다.';
    }
  }

  String get primaryActionLabel {
    switch (this) {
      case DemoFlowStep.beforeApplication:
        return '8기 신청하기';
      case DemoFlowStep.verificationWaiting:
        return '인증 승인으로 이동';
      case DemoFlowStep.verificationApproved:
        return 'AI 선정 대기 보기';
      case DemoFlowStep.aiSelectionWaiting:
        return '선정 결과 보기';
      case DemoFlowStep.selected:
        return '입금 안내 보기';
      case DemoFlowStep.paymentWaiting:
        return '입금 확인 처리';
      case DemoFlowStep.confirmed:
        return '닉네임 확인하기';
      case DemoFlowStep.nicknameCheck:
        return '첫인상 선택 열기';
      case DemoFlowStep.firstImpressionChoice:
        return '첫인상 선택 제출';
      case DemoFlowStep.rotationTalk:
        return '중간 선택 열기';
      case DemoFlowStep.middleChoice:
        return '중간 선택 제출';
      case DemoFlowStep.seatingGuide:
        return '페어 베이킹 시작';
      case DemoFlowStep.pairBaking:
        return '최종 선택 열기';
      case DemoFlowStep.finalChoice:
        return '최종 선택 제출';
      case DemoFlowStep.matchResult:
        return '케미 리포트 보기';
      case DemoFlowStep.chemistryReport:
        return '후기 작성하기';
      case DemoFlowStep.review:
        return '프로토타입 다시 시작';
    }
  }

  bool get isApplicationStage => index < DemoFlowStep.nicknameCheck.index;
  bool get isChoiceStage =>
      this == DemoFlowStep.firstImpressionChoice ||
      this == DemoFlowStep.middleChoice ||
      this == DemoFlowStep.finalChoice;
  bool get isEventStage => index >= DemoFlowStep.nicknameCheck.index;
}

class ChemistryClass {
  const ChemistryClass({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.eventYear,
    required this.eventMonth,
    required this.eventDay,
    required this.dateText,
    required this.timeText,
    required this.place,
    required this.theme,
    required this.statusLabel,
    required this.capacityLabel,
    required this.applicationCount,
    required this.priceText,
    required this.tags,
    required this.isOpen,
  });

  final String id;
  final String title;
  final String subtitle;
  final int eventYear;
  final int eventMonth;
  final int eventDay;
  final String dateText;
  final String timeText;
  final String place;
  final String theme;
  final String statusLabel;
  final String capacityLabel;
  final int applicationCount;
  final String priceText;
  final List<String> tags;
  final bool isOpen;

  DateTime get eventDate => DateTime(eventYear, eventMonth, eventDay);
}

class DemoApplicant {
  const DemoApplicant({
    required this.id,
    required this.nickname,
    required this.gender,
    required this.age,
    required this.job,
    required this.mbti,
    required this.status,
    required this.verified,
    required this.selected,
    required this.paid,
    required this.seat,
    required this.memo,
    required this.tags,
    required this.score,
  });

  final String id;
  final String nickname;
  final String gender;
  final int age;
  final String job;
  final String mbti;
  final String status;
  final bool verified;
  final bool selected;
  final bool paid;
  final String seat;
  final String memo;
  final List<String> tags;
  final int score;

  DemoApplicant copyWith({
    String? status,
    bool? verified,
    bool? selected,
    bool? paid,
    String? seat,
  }) {
    return DemoApplicant(
      id: id,
      nickname: nickname,
      gender: gender,
      age: age,
      job: job,
      mbti: mbti,
      status: status ?? this.status,
      verified: verified ?? this.verified,
      selected: selected ?? this.selected,
      paid: paid ?? this.paid,
      seat: seat ?? this.seat,
      memo: memo,
      tags: tags,
      score: score,
    );
  }
}

class EventRound {
  const EventRound({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.order,
  });

  final String id;
  final String title;
  final String description;
  final String status;
  final int order;

  EventRound copyWith({String? status}) {
    return EventRound(
      id: id,
      title: title,
      description: description,
      status: status ?? this.status,
      order: order,
    );
  }
}

class MatchingPair {
  const MatchingPair({
    required this.id,
    required this.leftNickname,
    required this.rightNickname,
    required this.score,
    required this.status,
    required this.sharedTags,
  });

  final String id;
  final String leftNickname;
  final String rightNickname;
  final int score;
  final String status;
  final List<String> sharedTags;

  MatchingPair copyWith({String? status}) {
    return MatchingPair(
      id: id,
      leftNickname: leftNickname,
      rightNickname: rightNickname,
      score: score,
      status: status ?? this.status,
      sharedTags: sharedTags,
    );
  }
}

class ChemistryReport {
  const ChemistryReport({
    required this.id,
    required this.nickname,
    required this.summary,
    required this.score,
    required this.items,
    required this.sent,
  });

  final String id;
  final String nickname;
  final String summary;
  final int score;
  final List<String> items;
  final bool sent;

  ChemistryReport copyWith({bool? sent}) {
    return ChemistryReport(
      id: id,
      nickname: nickname,
      summary: summary,
      score: score,
      items: items,
      sent: sent ?? this.sent,
    );
  }
}

class SeatAssignment {
  const SeatAssignment({
    required this.tableName,
    required this.participants,
    required this.note,
  });

  final String tableName;
  final List<String> participants;
  final String note;
}

class ChoiceSummary {
  const ChoiceSummary({
    required this.roundName,
    required this.totalChoices,
    required this.mutualMatches,
    required this.topDessert,
  });

  final String roundName;
  final int totalChoices;
  final int mutualMatches;
  final String topDessert;
}

enum ChoicePhase { firstImpression, middle, finalChoice }

extension ChoicePhaseX on ChoicePhase {
  String get label {
    switch (this) {
      case ChoicePhase.firstImpression:
        return '첫인상 선택';
      case ChoicePhase.middle:
        return '중간 선택';
      case ChoicePhase.finalChoice:
        return '최종 선택';
    }
  }

  String get instruction {
    switch (this) {
      case ChoicePhase.firstImpression:
        return '첫 대화 후 가장 더 이야기해보고 싶은 닉네임을 선택합니다.';
      case ChoicePhase.middle:
        return '베이킹 파트너로 함께하고 싶은 닉네임을 선택합니다.';
      case ChoicePhase.finalChoice:
        return '마지막으로 마음을 전하고 싶은 닉네임을 선택합니다.';
    }
  }
}

class DemoParticipantProfile {
  const DemoParticipantProfile({
    required this.nickname,
    required this.gender,
    required this.seat,
    required this.keywords,
  });

  final String nickname;
  final String gender;
  final String seat;
  final List<String> keywords;
}

class ChoiceCandidate {
  const ChoiceCandidate({
    required this.nickname,
    required this.gender,
    required this.keywords,
    required this.chemistryScore,
  });

  final String nickname;
  final String gender;
  final List<String> keywords;
  final int chemistryScore;
}

enum OnboardingStep {
  intro,
  account,
  basicInfo,
  rhythm,
  conversation,
  tastes,
  lifestyle,
  keywords,
  preferences,
  profilePreview,
  verification,
  result,
}

extension OnboardingStepX on OnboardingStep {
  String get stepLabel {
    switch (this) {
      case OnboardingStep.intro:
        return 'STEP 0';
      case OnboardingStep.account:
        return 'STEP 1';
      case OnboardingStep.basicInfo:
        return 'STEP 2';
      case OnboardingStep.rhythm:
        return 'STEP 3';
      case OnboardingStep.conversation:
        return 'STEP 4';
      case OnboardingStep.tastes:
        return 'STEP 5';
      case OnboardingStep.lifestyle:
        return 'STEP 6';
      case OnboardingStep.keywords:
        return 'STEP 7';
      case OnboardingStep.preferences:
        return 'STEP 8';
      case OnboardingStep.profilePreview:
        return 'STEP 9';
      case OnboardingStep.verification:
        return 'STEP 10';
      case OnboardingStep.result:
        return 'CHEMISTRY ANALYSIS';
    }
  }

  String get title {
    switch (this) {
      case OnboardingStep.intro:
        return '나의 케미를 알아볼까요?';
      case OnboardingStep.account:
        return '안전하게 시작할 계정을 만들어요.';
      case OnboardingStep.basicInfo:
        return '기본 정보를 알려주세요.';
      case OnboardingStep.rhythm:
        return '나의 일상 리듬을 알려주세요.';
      case OnboardingStep.conversation:
        return '처음 만난 사람과\n가까워지기 좋은 순간은?';
      case OnboardingStep.tastes:
        return '대화가 자연스럽게 시작될 취향을 알려주세요.';
      case OnboardingStep.lifestyle:
        return '디저트와 라이프스타일 취향을 알려주세요.';
      case OnboardingStep.keywords:
        return '호감 포인트와 관계 온도를 골라주세요.';
      case OnboardingStep.preferences:
        return '편안한 만남을 위해 선호 조건을 알려주세요.';
      case OnboardingStep.profilePreview:
        return 'AI가 볼 프로필을 미리 확인해요.';
      case OnboardingStep.verification:
        return '안전한 오브닝을 위해 기본 인증을 진행합니다.';
      case OnboardingStep.result:
        return '케미 분석이 완료되었어요.';
    }
  }

  String get subtitle {
    switch (this) {
      case OnboardingStep.intro:
        return '몇 가지 질문으로 나의 성향과 잘 맞는 오브닝을 추천해드려요.';
      case OnboardingStep.account:
        return '휴대폰 인증과 로그인 정보를 먼저 준비해요.';
      case OnboardingStep.basicInfo:
        return '정확한 회차 추천과 인원 구성에 사용돼요.';
      case OnboardingStep.rhythm:
        return '비슷한 시간대에 편하게 참여할 수 있는 회차를 추천해드려요.';
      case OnboardingStep.conversation:
        return '대화 스타일을 분석하기보다, 자연스럽게 가까워지는 순간을 찾아볼게요.';
      case OnboardingStep.tastes:
        return '현장 대화와 케미 분석에 활용돼요.';
      case OnboardingStep.lifestyle:
        return '베이킹 현장에서 편안한 메뉴와 대화 소재를 추천해요.';
      case OnboardingStep.keywords:
        return '길게 쓰지 않아도 좋아요. 선택한 키워드로 케미 포인트를 잡아요.';
      case OnboardingStep.preferences:
        return '상관없음도 좋은 선택이에요. 선정·매칭 참고용으로만 사용돼요.';
      case OnboardingStep.profilePreview:
        return '공개 정보와 운영진 확인 정보를 분리해서 보여줘요.';
      case OnboardingStep.verification:
        return '제출된 인증 자료는 운영진 확인용으로만 사용돼요.';
      case OnboardingStep.result:
        return '내 성향을 가장 잘 닮은 케미 캐릭터를 찾았어요.';
    }
  }
}

class OnboardingAnswer {
  const OnboardingAnswer({
    required this.step,
    required this.title,
    required this.values,
  });

  final OnboardingStep step;
  final String title;
  final List<String> values;
}

class ChemistryCharacter {
  const ChemistryCharacter({
    required this.id,
    required this.initial,
    required this.name,
    required this.englishName,
    required this.summary,
    required this.description,
    required this.tags,
    required this.matchHint,
    required this.forMen,
  });

  final String id;
  final String initial;
  final String name;
  final String englishName;
  final String summary;
  final String description;
  final List<String> tags;
  final String matchHint;
  final bool forMen;
}

enum OveningState {
  beforeApplication,
  waiting,
  openReady,
  voting,
  result,
  report,
}

extension OveningStateX on OveningState {
  String get label {
    switch (this) {
      case OveningState.beforeApplication:
        return '신청 전';
      case OveningState.waiting:
        return '오픈 대기';
      case OveningState.openReady:
        return '당일 오픈';
      case OveningState.voting:
        return '투표 진행';
      case OveningState.result:
        return '매칭 결과';
      case OveningState.report:
        return '케미 리포트';
    }
  }
}

class AdminScoreRow {
  const AdminScoreRow({
    required this.name,
    required this.gender,
    required this.strictScore,
    required this.objectiveScore,
    required this.chemistryScore,
    required this.summary,
  });

  final String name;
  final String gender;
  final int strictScore;
  final int objectiveScore;
  final int chemistryScore;
  final String summary;
}
