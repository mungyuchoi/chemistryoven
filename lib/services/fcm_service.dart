import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// 푸시 알림용 FCM 토큰을 users/{uid}.fcmToken 에 기록한다.
/// 로그인(앱 접속) 직후 [registerForCurrentUser] 를 호출한다.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _refreshHooked = false;

  /// 권한 요청 → 토큰 획득 → Firestore 기록. 비로그인이면 아무 것도 안 함.
  Future<void> registerForCurrentUser() async {
    final uid = FirebaseService.instance.uid;
    if (uid == null) {
      return;
    }
    try {
      await _messaging.requestPermission();
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _writeToken(uid, token);
      }

      // 토큰 갱신 시 자동 반영 (한 번만 구독)
      if (!_refreshHooked) {
        _refreshHooked = true;
        _messaging.onTokenRefresh.listen((newToken) {
          final currentUid = FirebaseService.instance.uid;
          if (currentUid != null && newToken.isNotEmpty) {
            _writeToken(currentUid, newToken);
          }
        });
      }
    } catch (error) {
      // iOS 시뮬레이터/APNs 미설정 등에서 실패할 수 있음 — 무시
      debugPrint('[fcm] 토큰 등록 실패: $error');
    }
  }

  Future<void> _writeToken(String uid, String token) {
    return FirebaseService.instance.userDoc(uid).set({
      'fcmToken': token,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
