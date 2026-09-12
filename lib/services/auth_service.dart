import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Session? get currentSession => _supabase.auth.currentSession;

  Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: 'smarthomex://auth-callback/',
      data: {
        'full_name': fullName.trim(),
      },
    );

    if (response.user != null && response.session != null) {
      await ensureUserData(
        user: response.user!,
        fullName: fullName,
        email: email,
      );
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.user != null) {
      await ensureUserData(
        user: response.user!,
        email: email,
      );
    }

    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'smarthomex://auth-callback/',
    );
  }

  Future<void> ensureCurrentUserData() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return;

    await ensureUserData(
      user: user,
      fullName: user.userMetadata?['full_name'] as String?,
      email: user.email,
    );
  }

  Future<void> ensureUserData({
    required User user,
    String? fullName,
    String? email,
  }) async {
    final existingProfile = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existingProfile == null) {
      await _supabase.from('profiles').insert({
        'id': user.id,
        'full_name':
            fullName?.trim().isNotEmpty == true
                ? fullName!.trim()
                : user.userMetadata?['full_name'],
        'email': email?.trim() ?? user.email,
      });
    }

    final existingHome = await _supabase
        .from('homes')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    if (existingHome.isEmpty) {
      await _supabase.from('homes').insert({
        'user_id': user.id,
        'name': 'My Home',
      });
    }
  }
}