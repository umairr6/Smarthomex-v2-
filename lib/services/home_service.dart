import 'package:supabase_flutter/supabase_flutter.dart';

class HomeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _userId {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('You are not logged in.');
    }

    return user.id;
  }

  // ==========================================
  // HOMES
  // ==========================================

  Future<List<Map<String, dynamic>>> getHomes() async {
    final response = await _supabase
        .from('homes')
        .select()
        .eq('user_id', _userId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createHome(
    String name,
  ) async {
    final response = await _supabase
        .from('homes')
        .insert({
          'user_id': _userId,
          'name': name.trim(),
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<void> renameHome(
    String homeId,
    String name,
  ) async {
    await _supabase
        .from('homes')
        .update({
          'name': name.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', homeId)
        .eq('user_id', _userId);
  }

  Future<void> deleteHome(String homeId) async {
    await _supabase
        .from('homes')
        .delete()
        .eq('id', homeId)
        .eq('user_id', _userId);
  }

  // ==========================================
  // ROOMS
  // ==========================================

  Future<List<Map<String, dynamic>>> getRooms(
    String homeId,
  ) async {
    final response = await _supabase
        .from('rooms')
        .select()
        .eq('home_id', homeId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createRoom({
    required String homeId,
    required String name,
  }) async {
    final response = await _supabase
        .from('rooms')
        .insert({
          'home_id': homeId,
          'name': name.trim(),
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<void> renameRoom({
    required String roomId,
    required String name,
  }) async {
    await _supabase
        .from('rooms')
        .update({
          'name': name.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', roomId);
  }

  Future<void> deleteRoom(String roomId) async {
    await _supabase
        .from('rooms')
        .delete()
        .eq('id', roomId);
  }
}