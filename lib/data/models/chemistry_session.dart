import 'package:cloud_firestore/cloud_firestore.dart';

import 'demo_models.dart';

/// sessions/{id} 회차 문서 모델.
/// 스키마는 docs/ARCHITECTURE_PLAN.md §3.4 참고.
class ChemistrySession {
  const ChemistrySession({
    required this.id,
    required this.title,
    this.dateText = '',
    this.timeText = '',
    this.location = '',
    this.priceText = '',
    this.recruitMale = 4,
    this.recruitFemale = 4,
    this.menuName = '',
    this.allergens = const [],
    this.bakingItems = const [],
    this.keyVisualUrl,
    this.status = 'recruiting',
    this.eventStage,
    this.notice = '',
    this.applicationCount = 0,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String title;
  final String dateText;
  final String timeText;
  final String location;
  final String priceText;
  final int recruitMale;
  final int recruitFemale;
  final String menuName;
  final List<String> allergens;
  final List<String> bakingItems;
  final String? keyVisualUrl;
  final String status; // draft | recruiting | selecting | confirmed | ongoing | closed
  /// 당일 진행 단계 (DemoFlowStep enum 이름). 운영자가 변경하면 참가자 화면 동기화.
  final String? eventStage;
  final String notice;
  final int applicationCount;
  final String? createdBy;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'dateText': dateText,
      'timeText': timeText,
      'location': location,
      'priceText': priceText,
      'recruit': {'male': recruitMale, 'female': recruitFemale},
      'menuName': menuName,
      'allergens': allergens,
      'bakingItems': bakingItems,
      if (keyVisualUrl != null) 'keyVisualUrl': keyVisualUrl,
      'status': status,
      'notice': notice,
      'applicationCount': applicationCount,
      if (createdBy != null) 'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ChemistrySession.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    final recruit = (data['recruit'] as Map<String, dynamic>?) ?? const {};
    return ChemistrySession(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      dateText: (data['dateText'] as String?) ?? '',
      timeText: (data['timeText'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      priceText: (data['priceText'] as String?) ?? '',
      recruitMale: (recruit['male'] as num?)?.toInt() ?? 4,
      recruitFemale: (recruit['female'] as num?)?.toInt() ?? 4,
      menuName: (data['menuName'] as String?) ?? '',
      allergens: _stringList(data['allergens']),
      bakingItems: _stringList(data['bakingItems']),
      keyVisualUrl: data['keyVisualUrl'] as String?,
      status: (data['status'] as String?) ?? 'recruiting',
      eventStage: data['eventStage'] as String?,
      notice: (data['notice'] as String?) ?? '',
      applicationCount: (data['applicationCount'] as num?)?.toInt() ?? 0,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const [];
  }

  String get statusLabel => switch (status) {
    'draft' => '준비중',
    'recruiting' => '모집중',
    'selecting' => '선정중',
    'confirmed' => '확정',
    'ongoing' => '진행중',
    'closed' => '종료',
    _ => status,
  };

  /// 기존 데모 UI(ChemistryClass 기반 카드)에서 그대로 쓰기 위한 표시용 변환.
  ChemistryClass toDisplayClass() {
    final date = _parseDate(dateText);
    return ChemistryClass(
      id: id,
      title: title,
      subtitle: menuName,
      eventYear: date.year,
      eventMonth: date.month,
      eventDay: date.day,
      dateText: dateText,
      timeText: timeText,
      place: location,
      theme: menuName,
      statusLabel: statusLabel,
      capacityLabel: '남 $recruitMale · 여 $recruitFemale',
      applicationCount: applicationCount,
      priceText: priceText,
      tags: allergens,
      isOpen: status == 'recruiting',
    );
  }

  static DateTime _parseDate(String text) {
    // 'YYYY-MM-DD' 형태면 파싱, 아니면 오늘 날짜.
    final match = RegExp(r'(\d{4})[-.\/](\d{1,2})[-.\/](\d{1,2})').firstMatch(text);
    if (match != null) {
      return DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }
    return DateTime.now();
  }
}
