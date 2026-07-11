import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_service.dart';

/// 이미지 선택 → 압축 → Firebase Storage 업로드.
/// 경로 규칙은 docs/ARCHITECTURE_PLAN.md §4 참고.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final ImagePicker _picker = ImagePicker();

  /// 갤러리에서 사진 1장 선택. 취소 시 null.
  Future<XFile?> pickImage() => pickImageFrom(ImageSource.gallery);

  /// 갤러리/카메라 지정 선택. 취소 시 null.
  Future<XFile?> pickImageFrom(ImageSource source) {
    return _picker.pickImage(
      source: source,
      maxWidth: 2048,
      imageQuality: 90,
    );
  }

  /// 프로필 사진 업로드 → 다운로드 URL.
  Future<String> uploadProfilePhoto(String uid, XFile file) {
    return _uploadCompressed(file, 'profile/$uid/avatar_${_randomName()}.jpg');
  }

  /// 직업 인증 자료 업로드 → 다운로드 URL.
  Future<String> uploadJobVerification(String uid, XFile file) {
    return _uploadCompressed(file, 'verification/$uid/job_${_randomName()}.jpg');
  }

  /// 회차 커버(키비주얼) 이미지 업로드 → 다운로드 URL. (운영자용)
  Future<String> uploadSessionCover(String sessionId, XFile file) {
    return _uploadCompressed(
      file,
      'sessions/$sessionId/cover_${_randomName()}.jpg',
    );
  }

  Future<String> _uploadCompressed(XFile file, String path) async {
    final original = await file.readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      original,
      minWidth: 1080,
      minHeight: 1080,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    final ref = FirebaseService.instance.storage.ref(path);
    await ref.putData(
      compressed,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      ),
    );
    return ref.getDownloadURL();
  }

  String _randomName() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32);
    return '${now}_$rand';
  }
}
