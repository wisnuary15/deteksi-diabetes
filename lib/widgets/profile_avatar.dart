import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

class ProfileAvatar extends StatefulWidget {
  final String? imagePath;
  final String userName;
  final double size;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final bool isLoading;
  final bool showBorder;
  final bool showStatusIndicator;
  final Color? borderColor;
  final double borderWidth;

  const ProfileAvatar({
    super.key,
    this.imagePath,
    required this.userName,
    this.size = 100,
    this.onTap,
    this.showEditIcon = false,
    this.isLoading = false,
    this.showBorder = true,
    this.showStatusIndicator = false,
    this.borderColor,
    this.borderWidth = 3.0,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onTap,
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size / 2),
              child: _buildAvatarContent(),
            ),
          ),
          if (widget.showEditIcon && !widget.isLoading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: widget.size * 0.3,
                height: widget.size * 0.3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: widget.size * 0.15,
                ),
              ),
            ),
          if (widget.isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      return Image.file(
        File(widget.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _getInitials(widget.userName),
          style: TextStyle(
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '?';

    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    } else {
      return (nameParts[0].substring(0, 1) + nameParts[1].substring(0, 1))
          .toUpperCase();
    }
  }
}

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: 512,
        maxHeight: 512,
      );

      return pickedFile?.path;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  static void showImageSourceDialog(
    BuildContext context, {
    required Function(String) onImageSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pilih Foto Profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    onTap: () async {
                      Navigator.pop(context);
                      final imagePath = await pickImage(
                        source: ImageSource.camera,
                      );
                      if (imagePath != null) {
                        onImageSelected(imagePath);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    context,
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    onTap: () async {
                      Navigator.pop(context);
                      final imagePath = await pickImage(
                        source: ImageSource.gallery,
                      );
                      if (imagePath != null) {
                        onImageSelected(imagePath);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
