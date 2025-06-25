import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Hash password dengan salt
  static String _hashPassword(String password) {
    final salt = 'diabetes_app_salt_2024';
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate unique user ID
  static String _generateUserId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999);
    return 'user_${timestamp}_$randomNum';
  }

  // Register user baru
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Ambil users yang sudah ada
      final usersJson = prefs.getString(_usersKey) ?? '[]';
      final List<dynamic> usersList = json.decode(usersJson);

      // Cek apakah email sudah terdaftar
      final existingUser = usersList.firstWhere(
        (user) => user['email'] == email,
        orElse: () => null,
      );

      if (existingUser != null) {
        return {
          'success': false,
          'message': 'Email sudah terdaftar. Silakan gunakan email lain.',
        };
      }

      // Buat user baru
      final newUser = User(
        id: _generateUserId(),
        email: email,
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
      );

      // Simpan password terenkripsi
      await _secureStorage.write(
        key: 'password_${newUser.id}',
        value: _hashPassword(password),
      );

      // Tambah user ke list
      usersList.add(newUser.toJson());

      // Simpan ke SharedPreferences
      await prefs.setString(_usersKey, json.encode(usersList));

      return {
        'success': true,
        'message': 'Registrasi berhasil! Silakan login.',
        'user': newUser,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat registrasi: $e',
      };
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Ambil users
      final usersJson = prefs.getString(_usersKey) ?? '[]';
      final List<dynamic> usersList = json.decode(usersJson);

      // Cari user berdasarkan email
      final userData = usersList.firstWhere(
        (user) => user['email'] == email,
        orElse: () => null,
      );

      if (userData == null) {
        return {'success': false, 'message': 'Email tidak terdaftar.'};
      }

      final user = User.fromJson(userData);

      // Ambil password terenkripsi
      final storedPassword = await _secureStorage.read(
        key: 'password_${user.id}',
      );

      if (storedPassword == null || storedPassword != _hashPassword(password)) {
        return {'success': false, 'message': 'Password salah.'};
      }

      // Update last login
      final updatedUser = user.copyWith(lastLogin: DateTime.now());

      // Update user di list
      final userIndex = usersList.indexWhere((u) => u['id'] == user.id);
      usersList[userIndex] = updatedUser.toJson();

      // Simpan perubahan
      await prefs.setString(_usersKey, json.encode(usersList));
      await prefs.setString(_currentUserKey, json.encode(updatedUser.toJson()));
      await prefs.setBool(_isLoggedInKey, true);

      return {
        'success': true,
        'message': 'Login berhasil!',
        'user': updatedUser,
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan saat login: $e'};
    }
  }

  // Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Ambil current user
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_currentUserKey);

    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }

    return null;
  }

  // Update profile user
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return {'success': false, 'message': 'User tidak ditemukan.'};
      }

      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '[]';
      final List<dynamic> usersList = json.decode(usersJson);

      // Update user
      final updatedUser = currentUser.copyWith(name: name, phone: phone);

      // Update di list
      final userIndex = usersList.indexWhere((u) => u['id'] == currentUser.id);
      usersList[userIndex] = updatedUser.toJson();

      // Simpan perubahan
      await prefs.setString(_usersKey, json.encode(usersList));
      await prefs.setString(_currentUserKey, json.encode(updatedUser.toJson()));

      return {
        'success': true,
        'message': 'Profile berhasil diupdate!',
        'user': updatedUser,
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal update profile: $e'};
    }
  }

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return {'success': false, 'message': 'User tidak ditemukan.'};
      }

      // Cek old password
      final storedPassword = await _secureStorage.read(
        key: 'password_${currentUser.id}',
      );

      if (storedPassword != _hashPassword(oldPassword)) {
        return {'success': false, 'message': 'Password lama salah.'};
      }

      // Simpan password baru
      await _secureStorage.write(
        key: 'password_${currentUser.id}',
        value: _hashPassword(newPassword),
      );

      return {'success': true, 'message': 'Password berhasil diubah!'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengubah password: $e'};
    }
  }

  // Update profile image
  static Future<Map<String, dynamic>> updateUserProfileImage(
    String? imagePath,
  ) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        return {'success': false, 'message': 'User tidak ditemukan.'};
      }

      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '[]';
      final List<dynamic> usersList = json.decode(usersJson);

      // Update user with new profile image (null or empty string means remove)
      final updatedUsersList = usersList.map((userData) {
        if (userData['id'] == currentUser.id) {
          userData['profileImagePath'] = imagePath ?? '';
        }
        return userData;
      }).toList();

      // Save updated users list
      await prefs.setString(_usersKey, json.encode(updatedUsersList));

      // Update current user
      final updatedUser = currentUser.copyWith(
        profileImagePath: imagePath ?? '',
      );
      await prefs.setString(_currentUserKey, json.encode(updatedUser.toJson()));

      return {
        'success': true,
        'message': imagePath == null || imagePath.isEmpty
            ? 'Foto profil berhasil dihapus!'
            : 'Foto profil berhasil diperbarui!',
        'user': updatedUser,
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal memperbarui foto profil: $e'};
    }
  }
}
