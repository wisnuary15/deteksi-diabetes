import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/shimmer_loading.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/profile_image_service.dart';
import '../screens/profile_screen.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final bool showWelcomeMessage;
  final double avatarSize;
  final bool showEditIcon;
  final VoidCallback? onTap;

  const ProfileHeaderWidget({
    super.key,
    this.showWelcomeMessage = true,
    this.avatarSize = 60,
    this.showEditIcon = false,
    this.onTap,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  User? _currentUser;
  ProfileImageService? _profileImageService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadUserData();
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _profileImageService = ProfileImageService(prefs);
    } catch (e) {
      print('Error initializing profile image service: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToProfile() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  String _getFirstName(String fullName) {
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onTap: _navigateToProfile,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Profile Avatar
            Hero(
              tag: 'profile_avatar',
              child: ProfileAvatar(
                imagePath: _profileImageService?.profileImagePath,
                userName: _currentUser?.name ?? 'Pengguna',
                size: widget.avatarSize,
                showEditIcon: widget.showEditIcon,
                onTap: widget.showEditIcon ? null : _navigateToProfile,
              ),
            ),

            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showWelcomeMessage) ...[
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],

                  // User Name
                  Text(
                    _getFirstName(_currentUser?.name ?? 'Pengguna'),
                    style: TextStyle(
                      fontSize: widget.showWelcomeMessage ? 22 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (widget.showWelcomeMessage) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Bagaimana kesehatan Anda hari ini?',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],

                  if (!widget.showWelcomeMessage &&
                      _currentUser?.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _currentUser!.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Arrow or Profile Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          // Shimmer Avatar
          ShimmerLoading(
            isLoading: true,
            child: Container(
              width: widget.avatarSize,
              height: widget.avatarSize,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Shimmer Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showWelcomeMessage) ...[
                  ShimmerLoading(
                    isLoading: true,
                    child: Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                ShimmerLoading(
                  isLoading: true,
                  child: Container(
                    height: widget.showWelcomeMessage ? 22 : 18,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                if (widget.showWelcomeMessage) ...[
                  const SizedBox(height: 6),
                  ShimmerLoading(
                    isLoading: true,
                    child: Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Shimmer Icon
          ShimmerLoading(
            isLoading: true,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompactProfileWidget extends StatefulWidget {
  final VoidCallback? onTap;

  const CompactProfileWidget({super.key, this.onTap});

  @override
  State<CompactProfileWidget> createState() => _CompactProfileWidgetState();
}

class _CompactProfileWidgetState extends State<CompactProfileWidget> {
  User? _currentUser;
  ProfileImageService? _profileImageService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadUserData();
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _profileImageService = ProfileImageService(prefs);
    } catch (e) {
      print('Error initializing profile image service: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _navigateToProfile() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToProfile,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ProfileAvatar(
          imagePath: _profileImageService?.profileImagePath,
          userName: _currentUser?.name ?? 'U',
          size: 32,
          showEditIcon: false,
        ),
      ),
    );
  }
}
