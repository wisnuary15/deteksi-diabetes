import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_profile_service.dart';
import '../screens/user_profile_setup_screen.dart';
import '../screens/user_profile_edit_screen.dart';
import '../models/user_profile.dart';

class FloatingProfileButton extends StatefulWidget {
  const FloatingProfileButton({super.key});

  @override
  State<FloatingProfileButton> createState() => _FloatingProfileButtonState();
}

class _FloatingProfileButtonState extends State<FloatingProfileButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _hasProfile = false;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkProfileStatus();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
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
        });
      }
    } catch (e) {
      print('Error checking profile status: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: _onPressed,
        backgroundColor: _hasProfile
            ? Colors.green.shade600
            : Colors.orange.shade600,
        heroTag: "profile_fab",
        child: Icon(
          _hasProfile ? Icons.person : Icons.person_add,
          color: Colors.white,
        ),
      ),
    );
  }

  void _onPressed() {
    if (_hasProfile) {
      _showProfileMenu();
    } else {
      _showSetupDialog();
    }
  }

  void _showProfileMenu() {
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
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(Icons.person, color: Colors.green.shade600),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Profil aktif',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildMenuTile(
              icon: Icons.edit,
              title: 'Edit Profil',
              subtitle: 'Ubah informasi profil Anda',
              color: Colors.blue,
              onTap: _handleEditProfile,
            ),
            _buildMenuTile(
              icon: Icons.person_add,
              title: 'Buat Profil Baru',
              subtitle: 'Setup profil baru (menimpa yang lama)',
              color: Colors.orange,
              onTap: _handleNewProfile,
            ),
            _buildMenuTile(
              icon: Icons.info,
              title: 'Lihat Profil',
              subtitle: 'Tampilkan informasi lengkap',
              color: Colors.purple,
              onTap: _handleViewProfile,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Setup Profil'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda belum memiliki profil. Setup profil untuk mendapatkan saran yang lebih personal dari DrAI.',
            ),
            SizedBox(height: 16),
            Text(
              '✅ Saran diet sesuai usia & kondisi\n'
              '✅ Interpretasi hasil yang personal\n'
              '✅ Rekomendasi berdasarkan riwayat\n',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Nanti', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleNewProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text(
              'Setup Sekarang',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileService = UserProfileService(prefs);
      final userProfile = await userProfileService.getUserProfile();

      if (userProfile == null) {
        _showErrorSnackBar('Profil tidak dapat dimuat');
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileEditScreen(
            userProfileService: userProfileService,
            currentProfile: userProfile,
          ),
        ),
      );

      if (result != null) {
        await _checkProfileStatus(); // Refresh status

        if (result == 'deleted') {
          _showSuccessSnackBar('Profil berhasil dihapus');
        } else if (result is UserProfile) {
          _showSuccessSnackBar('Profil ${result.name} berhasil diperbarui!');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _handleNewProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileService = UserProfileService(prefs);

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              UserProfileSetupScreen(userProfileService: userProfileService),
        ),
      );

      if (result == true) {
        await _checkProfileStatus(); // Refresh status
        _showSuccessSnackBar('Profil baru berhasil dibuat!');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  void _handleViewProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userProfileService = UserProfileService(prefs);
      final userProfile = await userProfileService.getUserProfile();

      if (userProfile != null) {
        _showProfileInfoDialog(userProfile);
      } else {
        _showErrorSnackBar('Profil tidak dapat dimuat');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  void _showProfileInfoDialog(UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.person, color: Colors.blue.shade600),
            ),
            const SizedBox(width: 8),
            Text(profile.name),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Usia', '${profile.age} tahun'),
              _buildInfoRow('Jenis Kelamin', profile.gender),
              if (profile.weight != null)
                _buildInfoRow('Berat Badan', '${profile.weight} kg'),
              if (profile.height != null)
                _buildInfoRow('Tinggi Badan', '${profile.height} cm'),
              if (profile.bloodType != null)
                _buildInfoRow('Golongan Darah', profile.bloodType!),
              if (profile.bmi != null)
                _buildInfoRow(
                  'BMI',
                  '${profile.bmi!.toStringAsFixed(1)} (${profile.bmiCategory})',
                ),
              if (profile.medicalHistory.isNotEmpty)
                _buildInfoRow(
                  'Riwayat Penyakit',
                  profile.medicalHistory.join(', '),
                ),
              if (profile.currentMedications.isNotEmpty)
                _buildInfoRow(
                  'Obat Saat Ini',
                  profile.currentMedications.join(', '),
                ),
              if (profile.allergies.isNotEmpty)
                _buildInfoRow('Alergi', profile.allergies.join(', ')),
              if (profile.familyDiabetesHistory != null)
                _buildInfoRow(
                  'Riwayat Diabetes Keluarga',
                  profile.familyDiabetesHistory!,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleEditProfile();
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
