import 'dart:convert';
import 'package:hamzain_traders/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central place for reading/writing the logged-in user's session.
/// Reuses whatever key your existing login flow already writes to
/// SharedPreferences under. If your login screen currently saves the
/// user under a different key, update `_userKey` below to match.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const String _userKey = 'logged_in_user';

  UserModel? _cachedUser;

  Future<void> saveUser(UserModel user) async {
    _cachedUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    if (_cachedUser != null) {
      // Defends against a stale in-memory session from before a
      // login-flow fix (see below) — never hand back a "logged in"
      // user with no real id.
      if (_cachedUser!.id.isEmpty) {
        await clearSession();
        return null;
      }
      return _cachedUser;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      final user = UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      // A previously-saved session with a missing/blank id is
      // useless (every address/cart/order API requires a real
      // user_id) and, left alone, silently causes "user_id is
      // required" errors on every screen while looking "logged in".
      // Self-heal by clearing it so callers see `null` and can
      // prompt a clean re-login instead.
      if (user.id.isEmpty) {
        await clearSession();
        return null;
      }
      _cachedUser = user;
      return _cachedUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    _cachedUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
