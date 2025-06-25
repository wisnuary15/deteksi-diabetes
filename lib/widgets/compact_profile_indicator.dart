import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_profile_service.dart';

class CompactProfileIndicator extends StatefulWidget {
  const CompactProfileIndicator({super.key});

  @override
  State<CompactProfileIndicator> createState() =>
      _CompactProfileIndicatorState();
}

class _CompactProfileIndicatorState extends State<CompactProfileIndicator> {
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
        userName = profile?.name.split(' ').first ?? 'User'; // Only first name
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
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _hasProfile
            ? Colors.white.withOpacity(0.2)
            : Colors.orange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _hasProfile
              ? Colors.white.withOpacity(0.3)
              : Colors.orange.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _hasProfile ? Icons.person : Icons.warning,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            _hasProfile ? _userName : 'Setup',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
