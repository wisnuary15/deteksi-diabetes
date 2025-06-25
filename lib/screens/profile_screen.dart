import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_loading.dart';
import '../widgets/modern_dialogs.dart';
import '../widgets/profile_avatar.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/profile_image_service.dart';
import '../services/profile_analytics_service.dart';
import 'edit_profile_screen.dart';
import 'user_profile_setup_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'hospital_map_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  User? _currentUser;
  bool _isLoading = true;
  bool _isUpdatingImage = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  ProfileImageService? _profileImageService;
  ProfileAnalyticsService? _analyticsService;
  Timer? _refreshTimer;
  static const Duration _cacheRefreshInterval = Duration(minutes: 5);

  // Cached data for better performance
  static User? _cachedUser;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidityDuration = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeServices();
    _loadUserData();
    _setupPeriodicRefresh();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _profileImageService = ProfileImageService(prefs);
      _analyticsService = ProfileAnalyticsService(prefs);

      // Track profile view
      await _analyticsService?.trackProfileView();
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData({bool forceRefresh = false}) async {
    // Use cached data if available and valid
    if (!forceRefresh &&
        _cachedUser != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheValidityDuration) {
      setState(() {
        _currentUser = _cachedUser;
        _isLoading = false;
      });
      return;
    }

    try {
      final user = await AuthService.getCurrentUser();

      // Update cache
      _cachedUser = user;
      _cacheTimestamp = DateTime.now();

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ModernSnackBar.show(
        context,
        message: 'Gagal memuat data pengguna: $e',
        type: ModernSnackBarType.error,
      );
    }
  }

  void _setupPeriodicRefresh() {
    _refreshTimer = Timer.periodic(_cacheRefreshInterval, (timer) {
      if (mounted) {
        _refreshUserData();
      }
    });
  }

  Future<void> _refreshUserData() async {
    // Silently refresh user data without loading state
    try {
      final user = await AuthService.getCurrentUser();
      if (mounted && user != null) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      // Silent refresh, don't show error to user
      print('Error refreshing user data: $e');
    }
  }

  Future<void> _logout() async {
    final confirmed = await ModernDialog.showConfirmation(
      context,
      title: 'Keluar Aplikasi',
      content: 'Apakah Anda yakin ingin keluar dari aplikasi?',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      confirmVariant: ModernButtonVariant.danger,
      icon: Icons.logout_rounded,
      iconColor: AppColors.error,
    );

    if (confirmed == true) {
      try {
        await AuthService.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ModernSnackBar.show(
            context,
            message: 'Gagal keluar: $e',
            type: ModernSnackBarType.error,
          );
        }
      }
    }
  }

  Future<void> _updateProfileImage(String imagePath) async {
    if (_profileImageService == null) return;

    setState(() {
      _isUpdatingImage = true;
    });

    try {
      final savedImagePath = await _profileImageService!.saveProfileImage(
        imagePath,
      );

      if (savedImagePath != null) {
        // Update user object using AuthService
        final updateResult = await AuthService.updateUserProfileImage(
          savedImagePath,
        );
        if (updateResult['success']) {
          // Track image update
          await _analyticsService?.trackImageUpdate();

          // Update local user object and clear cache
          _currentUser = updateResult['user'] as User;
          _cachedUser = _currentUser;
          _cacheTimestamp = DateTime.now();

          if (mounted) {
            ModernSnackBar.show(
              context,
              message: 'Foto profil berhasil diperbarui',
              type: ModernSnackBarType.success,
            );
          }
        } else {
          if (mounted) {
            ModernSnackBar.show(
              context,
              message: updateResult['message'],
              type: ModernSnackBarType.error,
            );
          }
        }
      } else {
        if (mounted) {
          ModernSnackBar.show(
            context,
            message: 'Gagal menyimpan foto profil',
            type: ModernSnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ModernSnackBar.show(
          context,
          message: 'Error: ${e.toString()}',
          type: ModernSnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingImage = false;
        });
      }
    }
  }

  Future<void> _removeProfileImage() async {
    if (_profileImageService == null || _currentUser?.profileImagePath == null)
      return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto Profil'),
        content: const Text('Apakah Anda yakin ingin menghapus foto profil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isUpdatingImage = true;
      });

      try {
        // Remove image file
        await _profileImageService!
            .removeProfileImage(); // Update user object using AuthService with null to remove image
        final updateResult = await AuthService.updateUserProfileImage(null);

        if (updateResult['success']) {
          // Update local user object
          _currentUser = updateResult['user'] as User;

          if (mounted) {
            ModernSnackBar.show(
              context,
              message: 'Foto profil berhasil dihapus',
              type: ModernSnackBarType.success,
            );
          }
        } else {
          if (mounted) {
            ModernSnackBar.show(
              context,
              message: updateResult['message'],
              type: ModernSnackBarType.error,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ModernSnackBar.show(
            context,
            message: 'Error: ${e.toString()}',
            type: ModernSnackBarType.error,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUpdatingImage = false;
          });
        }
      }
    }
  }

  void _showImagePickerDialog() {
    if (_profileImageService == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
              'Foto Profil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () async {
                    Navigator.pop(context);
                    final imagePath = await ImagePickerService.pickImage(
                      source: ImageSource.camera,
                    );
                    if (imagePath != null) {
                      _updateProfileImage(imagePath);
                    }
                  },
                ),
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: () async {
                    Navigator.pop(context);
                    final imagePath = await ImagePickerService.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (imagePath != null) {
                      _updateProfileImage(imagePath);
                    }
                  },
                ),
                if (_currentUser?.profileImagePath != null)
                  _buildImageOption(
                    icon: Icons.delete_outline,
                    label: 'Hapus',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfileImage();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 32, color: color ?? AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModernAppBar(
        title: 'Profil Saya',
        useGradient: true,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, size: 20),
            ),
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingScreen() : _buildProfileContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: ModernLoadingIndicator(
        size: 48,
        message: 'Memuat profil...',
        showMessage: true,
      ),
    );
  }

  Widget _buildProfileContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildProfileStats(),
              const SizedBox(height: 24),
              _buildProfileActions(),
              const SizedBox(height: 24),
              _buildAppSettings(),
              // Add some bottom padding for better pull-to-refresh experience
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    try {
      // Show a subtle feedback to user
      HapticFeedback.lightImpact();

      await _loadUserData(forceRefresh: true);

      // Refresh profile image service
      await _initializeServices();

      if (mounted) {
        ModernSnackBar.show(
          context,
          message: 'Profil berhasil diperbarui',
          type: ModernSnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        ModernSnackBar.show(
          context,
          message: 'Gagal memperbarui profil: $e',
          type: ModernSnackBarType.error,
        );
      }
    }
  }

  Widget _buildProfileHeader() {
    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Professional Profile Avatar with tap to change
          ProfileAvatar(
            imagePath: _profileImageService?.profileImagePath,
            userName: _currentUser?.name ?? 'Pengguna',
            size: 120,
            showEditIcon: true,
            isLoading: _isUpdatingImage,
            onTap: _showImagePickerDialog,
          ),
          const SizedBox(height: 20),

          // User Name with enhanced styling
          Text(
            _currentUser?.name ?? 'Pengguna',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          if (_currentUser?.email != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentUser!.email,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Status Badge with improved design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Akun Aktif',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Quick edit button
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _currentUser != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditProfileScreen(user: _currentUser!),
                      ),
                    );
                  }
                : null,
            icon: Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
            label: Text(
              'Edit Profil',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.camera_alt_rounded,
              value: '12',
              label: 'Deteksi',
              color: AppColors.primary,
              delay: 100,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.chat_rounded,
              value: '47',
              label: 'Chat AI',
              color: AppColors.success,
              delay: 200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    int delay = 0,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, double animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: ModernCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder(
                  duration: Duration(milliseconds: 1000 + delay),
                  tween: IntTween(begin: 0, end: int.parse(value)),
                  builder: (context, int animatedValue, child) {
                    return Text(
                      animatedValue.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    );
                  },
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengaturan Profil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ModernInfoCard(
          title: 'Setup Profil Kesehatan',
          subtitle: 'Lengkapi data kesehatan untuk AI yang lebih personal',
          icon: Icons.health_and_safety_rounded,
          iconColor: AppColors.success,
          showArrow: true,
          onTap: () async {
            // Import UserProfileService dan UserProfileSetupScreen
            try {
              final prefs = await SharedPreferences.getInstance();
              final userProfileService = UserProfileService(prefs);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileSetupScreen(
                    userProfileService: userProfileService,
                  ),
                ),
              );
            } catch (e) {
              ModernSnackBar.show(
                context,
                message: 'Error: $e',
                type: ModernSnackBarType.error,
              );
            }
          },
        ),
        const SizedBox(height: 12),
        ModernInfoCard(
          title: 'Edit Profil',
          subtitle: 'Ubah informasi profil Anda',
          icon: Icons.edit_rounded,
          iconColor: AppColors.primary,
          showArrow: true,
          onTap: _currentUser != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditProfileScreen(user: _currentUser!),
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: 12),
        ModernInfoCard(
          title: 'Ubah Password',
          subtitle: 'Ganti kata sandi akun Anda',
          icon: Icons.lock_rounded,
          iconColor: AppColors.warning,
          showArrow: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangePasswordScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengaturan Aplikasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ModernInfoCard(
          title: 'Notifikasi',
          subtitle: 'Atur preferensi notifikasi',
          icon: Icons.notifications_rounded,
          iconColor: AppColors.secondary,
          showArrow: true,
          onTap: () {
            ModernSnackBar.show(
              context,
              message: 'Fitur notifikasi akan segera hadir',
              type: ModernSnackBarType.info,
            );
          },
        ),
        const SizedBox(height: 12),
        ModernInfoCard(
          title: 'Rumah Sakit Terdekat',
          subtitle: 'Temukan lokasi rumah sakit di sekitar Anda',
          icon: Icons.local_hospital_rounded,
          iconColor: Colors.red,
          showArrow: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HospitalMapScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ModernInfoCard(
          title: 'Tentang Aplikasi',
          subtitle: 'Versi 1.0.0',
          icon: Icons.info_rounded,
          iconColor: AppColors.textSecondary,
          showArrow: true,
          onTap: () {
            _showAboutDialog();
          },
        ),
        const SizedBox(height: 12),
        ModernInfoCard(
          title: 'Bantuan',
          subtitle: 'Panduan penggunaan aplikasi',
          icon: Icons.help_rounded,
          iconColor: AppColors.primary,
          showArrow: true,
          onTap: () {
            ModernSnackBar.show(
              context,
              message: 'Panduan bantuan akan segera hadir',
              type: ModernSnackBarType.info,
            );
          },
        ),
        const SizedBox(height: 24),
        ModernButton(
          text: 'Keluar Aplikasi',
          onPressed: _logout,
          variant: ModernButtonVariant.danger,
          size: ModernButtonSize.large,
          icon: Icons.logout_rounded,
          fullWidth: true,
        ),
      ],
    );
  }

  void _showAboutDialog() {
    ModernDialog.show(
      context,
      title: 'Tentang Aplikasi',
      icon: Icons.medical_services_rounded,
      iconColor: AppColors.primary,
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Aplikasi Deteksi Diabetes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Versi 1.0.0',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            'Aplikasi ini menggunakan teknologi AI untuk mendeteksi diabetes melalui analisis gambar lidah. Konsultasikan dengan dokter untuk diagnosis yang akurat.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        ModernDialogAction(
          text: 'Tutup',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
