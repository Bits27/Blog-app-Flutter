// Supabase implementation for profile data and avatar storage operations.
import 'dart:typed_data';

import '../../../core/supabase/supabase_client_provider.dart';
import '../domain/profile.dart';
import 'profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  static const _table = 'profiles';
  static const _bucket = 'profile_images';

  @override
  Future<Profile?> fetchMyProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to read profile.');
    }

    final data = await supabase
        .from(_table)
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromMap(data);
  }

  @override
  Future<Profile?> fetchProfileById(String userId) async {
    final data = await supabase
        .from(_table)
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromMap(data);
  }

  @override
  Future<String> fetchDisplayNameByUserId(String userId) async {
    final profile = await fetchProfileById(userId);
    final username = profile?.username.trim();
    if (username == null || username.isEmpty) {
      return 'Guest';
    }
    return username;
  }

  @override
  Future<void> upsertProfile({
    required String username,
    String? avatarUrl,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to update profile.');
    }

    await supabase.from(_table).upsert({
      'id': user.id,
      'username': username,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to upload avatar.');
    }

    final extension = fileName.toLowerCase().split('.').last;
    final path =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await supabase.storage.from(_bucket).uploadBinary(path, bytes);

    return supabase.storage.from(_bucket).getPublicUrl(path);
  }

  @override
  Future<void> deleteMyProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to delete profile.');
    }

    await supabase.from(_table).delete().eq('id', user.id);
  }
}
