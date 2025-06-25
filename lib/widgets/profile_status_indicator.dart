import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_profile_service.dart';

class ProfileStatusIndicator extends StatefulWidget {
  const ProfileStatusIndicator({super.key});

  @override
  State<ProfileStatusIndicator> createState() => _ProfileStatusIndicatorState();
}

class _ProfileStatusIndicatorState extends State<ProfileStatusIndicator> {
  bool _hasProfile = false;
  String _userName = 'User';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileService = UserProfileService(prefs);

      final hasProfile = userProfileService.hasProfile;
      String userName = 'User';

      if (hasProfile) {
        final profile = await userProfileService.getUserProfile();
        userName = profile?.name ?? 'User';
      }

      if (mounted) {
        setState(() {
          _hasProfile = hasProfile;
          _userName = userName;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking profile status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _hasProfile ? Colors.green.shade100 : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasProfile ? Colors.green.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _hasProfile ? Icons.check_circle : Icons.warning,
            size: 14,
            color: _hasProfile ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            _hasProfile ? _userName : 'Setup Profil',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _hasProfile
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
