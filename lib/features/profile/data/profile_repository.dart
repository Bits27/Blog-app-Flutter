// Contract for profile read/write/delete and avatar upload operations.
import 'dart:typed_data';

import '../domain/profile.dart';

abstract class ProfileRepository {
  Future<Profile?> fetchMyProfile();
  Future<Profile?> fetchProfileById(String userId);
  Future<String> fetchDisplayNameByUserId(String userId);
  Future<void> upsertProfile({required String username, String? avatarUrl});
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  });

  Future<void> deleteMyProfile();
}
