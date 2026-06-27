import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart';

class MyPageSummary {
  const MyPageSummary({
    required this.paymentCount,
    required this.verificationLabel,
    required this.reviewCount,
    required this.reportCount,
  });

  const MyPageSummary.empty()
    : paymentCount = 0,
      verificationLabel = '미완료',
      reviewCount = 0,
      reportCount = 0;

  final int paymentCount;
  final String verificationLabel;
  final int reviewCount;
  final int reportCount;

  String get paymentLabel => '$paymentCount건';
  String get reviewLabel => '$reviewCount';
  String get reportLabel => '$reportCount';
}

class MyPageSummaryService {
  MyPageSummaryService._();
  static final MyPageSummaryService instance = MyPageSummaryService._();

  final FirebaseService _fs = FirebaseService.instance;

  Future<MyPageSummary> fetch(String uid) async {
    final results = await Future.wait<Object>([
      _fs.userDoc(uid).get(),
      _countByOwner(_fs.payments, uid, fallbackField: 'userId'),
      _countByOwner(_fs.reviews, uid, fallbackField: 'authorUid'),
      _fs.reports.where('uid', isEqualTo: uid).get(),
    ]);

    final userSnapshot = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final paymentCount = results[1] as int;
    final reviewCount = results[2] as int;
    final reportSnapshot = results[3] as QuerySnapshot<Map<String, dynamic>>;

    return MyPageSummary(
      paymentCount: paymentCount,
      verificationLabel: _verificationLabel(userSnapshot.data()),
      reviewCount: reviewCount,
      reportCount: reportSnapshot.docs.length,
    );
  }

  Future<int> _countByOwner(
    CollectionReference<Map<String, dynamic>> collection,
    String uid, {
    required String fallbackField,
  }) async {
    final primary = await collection.where('uid', isEqualTo: uid).get();
    final ids = primary.docs.map((doc) => doc.id).toSet();

    final fallback = await collection
        .where(fallbackField, isEqualTo: uid)
        .get();
    ids.addAll(fallback.docs.map((doc) => doc.id));
    return ids.length;
  }

  String _verificationLabel(Map<String, dynamic>? user) {
    final raw = user?['verification'];
    if (raw is! Map) {
      return '미완료';
    }

    final values = raw.values.map((value) => value.toString()).toSet();
    if (values.isEmpty) {
      return '미완료';
    }
    if (values.contains('rejected')) {
      return '반려';
    }
    if (values.every((value) => value == 'approved')) {
      return '완료';
    }
    if (values.contains('pending')) {
      return '대기';
    }
    return '미완료';
  }
}
