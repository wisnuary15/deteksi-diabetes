import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

class ProfileImageService {
  static const String _profileImagePathKey = 'profile_image_path';

  final SharedPreferences _prefs;

  ProfileImageService(this._prefs);

  /// Get current profile image path
  String? get profileImagePath => _prefs.getString(_profileImagePathKey);

  /// Save profile image and return the saved path
  Future<String?> saveProfileImage(String imagePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/profile_images');

      // Create directory if it doesn't exist
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedImagePath = '${profileDir.path}/profile_$timestamp.jpg';

      // Read and resize image
      final originalImage = img.decodeImage(
        await File(imagePath).readAsBytes(),
      );
      if (originalImage == null) {
        throw Exception('Unable to decode image');
      }

      // Resize image to 512x512 for optimal storage
      final resizedImage = img.copyResize(
        originalImage,
        width: 512,
        height: 512,
        interpolation: img.Interpolation.cubic,
      );

      // Save compressed image
      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);
      await File(savedImagePath).writeAsBytes(compressedBytes);

      // Remove old profile image if exists
      await _removeOldProfileImage();

      // Save new path to preferences
      await _prefs.setString(_profileImagePathKey, savedImagePath);

      return savedImagePath;
    } catch (e) {
      print('Error saving profile image: $e');
      return null;
    }
  }

  /// Remove current profile image
  Future<bool> removeProfileImage() async {
    try {
      await _removeOldProfileImage();
      await _prefs.remove(_profileImagePathKey);
      return true;
    } catch (e) {
      print('Error removing profile image: $e');
      return false;
    }
  }

  /// Remove old profile image file
  Future<void> _removeOldProfileImage() async {
    final oldImagePath = profileImagePath;
    if (oldImagePath != null && oldImagePath.isNotEmpty) {
      final oldFile = File(oldImagePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }
  }

  /// Check if profile image exists and is valid
  Future<bool> isProfileImageValid() async {
    final imagePath = profileImagePath;
    if (imagePath == null || imagePath.isEmpty) return false;

    final file = File(imagePath);
    return await file.exists();
  }

  /// Get profile image file
  File? getProfileImageFile() {
    final imagePath = profileImagePath;
    if (imagePath == null || imagePath.isEmpty) return null;

    return File(imagePath);
  }

  /// Update profile image path (for migration purposes)
  Future<bool> updateProfileImagePath(String newPath) async {
    try {
      await _prefs.setString(_profileImagePathKey, newPath);
      return true;
    } catch (e) {
      print('Error updating profile image path: $e');
      return false;
    }
  }
}
