import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/repositories/firestore_chemistry_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 캐릭터(도감)를 Firestore에서 미리 로드. 시드 전/오프라인이면 더미로 폴백.
  final repository = FirestoreChemistryRepository();
  await repository.warmUp();

  runApp(ChemistryOvenApp(repository: repository));
}
