import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/dummy/dummy_chemistry_data.dart';
import '../data/repositories/firestore_chemistry_repository.dart';
import 'firebase_service.dart';

/// 케미 캐릭터 마스터(20종)를 Firestore `characters/{id}` 에 업로드한다.
///
/// 보안 규칙상 쓰기는 운영자(roles 에 'admin')만 가능하므로,
/// 개발 중에는 본인 users/{uid}.roles 를 ["user","admin"] 로 설정한 뒤 실행한다.
/// (docs/ARCHITECTURE_PLAN.md §7 참고)
class CharacterSeeder {
  CharacterSeeder._();
  static final CharacterSeeder instance = CharacterSeeder._();

  /// 컬렉션이 비어 있을 때만 시드한다. 업로드한 개수를 반환(이미 있으면 0).
  Future<int> seedIfEmpty() async {
    final col = FirebaseService.instance.characters;
    final existing = await col.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return 0;
    }
    return _writeAll();
  }

  /// 무조건 덮어쓴다(개발용). 업로드한 개수 반환.
  Future<int> seedForce() => _writeAll();

  Future<int> _writeAll() async {
    final db = FirebaseService.instance.db;
    final col = FirebaseService.instance.characters;
    final batch = db.batch();
    for (var i = 0; i < demoCharacters.length; i++) {
      final character = demoCharacters[i];
      batch.set(
        col.doc(character.id),
        characterToMap(character, i),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    return demoCharacters.length;
  }
}
