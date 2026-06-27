import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app/app.dart';
import 'core/constants/kakao_config.dart';
import 'data/repositories/firestore_chemistry_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 카카오 SDK 초기화 (네이티브 앱 키)
  KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);

  // 저장된 로그인 세션(currentUser)이 복원될 때까지 대기 → 자동 로그인 판단에 사용.
  await FirebaseAuth.instance
      .authStateChanges()
      .first
      .timeout(const Duration(seconds: 3), onTimeout: () => null);

  // 캐릭터(도감)를 Firestore에서 미리 로드. 시드 전/오프라인이면 더미로 폴백.
  final repository = FirestoreChemistryRepository();
  await repository.warmUp();

  runApp(ChemistryOvenApp(repository: repository));
}
