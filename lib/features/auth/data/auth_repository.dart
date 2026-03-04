// Contract for authentication and auth-profile helper operations.
abstract class AuthRepository {
  Future<bool> isUsernameTaken(String username);

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  });

  Future<void> signOut();

  Future<void> updatePassword(String newPassword);

  Future<void> updateUsernameMetadata(String username);
}
