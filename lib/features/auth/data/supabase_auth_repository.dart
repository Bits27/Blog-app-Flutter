// Supabase-backed implementation of authentication repository behaviors.
import '../../../core/supabase/supabase_client_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  @override
  Future<bool> isUsernameTaken(String username) async {
    final existing = await supabase
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    return existing != null;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    if (response.session == null) {
      await supabase.auth.signInWithPassword(email: email, password: password);
    }

    final userId = supabase.auth.currentUser?.id ?? response.user?.id;
    if (userId == null) {
      throw Exception('Unable to create profile. Missing user id.');
    }

    await supabase.from('profiles').upsert({
      'id': userId,
      'username': username,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> updateUsernameMetadata(String username) async {
    await supabase.auth.updateUser(
      UserAttributes(data: {'username': username}),
    );
  }
}
