import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/database_helper.dart';

class AuthProvider extends ChangeNotifier {
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _fullnameKey = 'fullname';
  static const String _roleKey = 'role';
  static const String _isLoggedInKey = 'is_logged_in';

  User? _currentUser;
  bool _isLoggedIn = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    if (_isLoggedIn) {
      final userId = prefs.getString(_userIdKey);
      final username = prefs.getString(_usernameKey);
      final fullname = prefs.getString(_fullnameKey);
      final role = prefs.getString(_roleKey);
      if (userId != null && username != null && fullname != null && role != null) {
        _currentUser = User(
          idUser: userId,
          username: username,
          fullname: fullname,
          role: role,
          password: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final user = await DatabaseHelper.instance.login(username, password);
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_userIdKey, user.idUser);
        await prefs.setString(_usernameKey, user.username);
        await prefs.setString(_fullnameKey, user.fullname);
        await prefs.setString(_roleKey, user.role);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) return false;
    try {
      final user = await DatabaseHelper.instance.login(_currentUser!.username, oldPassword);
      if (user == null) return false;
      final updatedUser = _currentUser!.copyWith(
        password: newPassword,
        updatedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      print('Update password error: $e');
      return false;
    }
  }

  bool hasPermission(String requiredRole) {
    if (_currentUser == null) return false;
    if (_currentUser!.role == 'Admin') return true;
    if (_currentUser!.role == 'Manager') return requiredRole == 'Manager' || requiredRole == 'KepalaGudang';
    if (_currentUser!.role == 'KepalaGudang') return requiredRole == 'KepalaGudang';
    return false;
  }

  bool canCreateUser() => _currentUser?.role == 'Admin';
  bool canDeleteData() => _currentUser?.role == 'Admin';
  bool canExportData() => _currentUser?.role == 'Admin' || _currentUser?.role == 'Manager';
  bool canManageInventory() => true; // All roles can manage inventory
}
