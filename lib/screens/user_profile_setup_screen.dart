import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../services/chat_preferences_service.dart';

class UserProfileSetupScreen extends StatefulWidget {
  final UserProfileService userProfileService;

  const UserProfileSetupScreen({super.key, required this.userProfileService});

  @override
  State<UserProfileSetupScreen> createState() => _UserProfileSetupScreenState();
}

class _UserProfileSetupScreenState extends State<UserProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _familyHistoryController = TextEditingController();

  String _selectedGender = 'Laki-laki';
  String? _selectedBloodType;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _bloodTypeOptions = ['A', 'B', 'AB', 'O'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _medicalHistoryController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _familyHistoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Setup Profil Anda',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _showExitDialog(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildHealthInfoSection(),
                    const SizedBox(height: 24),
                    _buildMedicalHistorySection(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            'Menyimpan profil Anda...',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.person_add, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          const Text(
            'Mari Berkenalan! 👋',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Informasi ini akan membantu DrAI memberikan saran yang lebih personal untuk Anda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Informasi Dasar',
      icon: Icons.person,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Nama Lengkap',
          hint: 'Masukkan nama lengkap Anda',
          prefixIcon: Icons.badge,
          isRequired: true,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Nama harus diisi';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _ageController,
          label: 'Usia',
          hint: 'Masukkan usia Anda',
          prefixIcon: Icons.cake,
          keyboardType: TextInputType.number,
          isRequired: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Usia harus diisi';
            }
            final age = int.tryParse(value!);
            if (age == null || age < 1 || age > 120) {
              return 'Usia harus antara 1-120 tahun';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Jenis Kelamin',
          value: _selectedGender,
          items: _genderOptions,
          prefixIcon: Icons.wc,
          onChanged: (value) => setState(() => _selectedGender = value!),
        ),
      ],
    );
  }

  Widget _buildHealthInfoSection() {
    return _buildSection(
      title: 'Informasi Kesehatan',
      icon: Icons.monitor_weight,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _weightController,
                label: 'Berat Badan (kg)',
                hint: 'Contoh: 65',
                prefixIcon: Icons.monitor_weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    final weight = double.tryParse(value!);
                    if (weight == null || weight < 20 || weight > 300) {
                      return 'Berat tidak valid';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _heightController,
                label: 'Tinggi Badan (cm)',
                hint: 'Contoh: 170',
                prefixIcon: Icons.height,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    final height = double.tryParse(value!);
                    if (height == null || height < 100 || height > 250) {
                      return 'Tinggi tidak valid';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Golongan Darah (Opsional)',
          value: _selectedBloodType,
          items: _bloodTypeOptions,
          prefixIcon: Icons.bloodtype,
          onChanged: (value) => setState(() => _selectedBloodType = value),
          isRequired: false,
        ),
      ],
    );
  }

  Widget _buildMedicalHistorySection() {
    return _buildSection(
      title: 'Riwayat Kesehatan',
      icon: Icons.medical_services,
      children: [
        _buildTextField(
          controller: _medicalHistoryController,
          label: 'Riwayat Penyakit (Opsional)',
          hint: 'Contoh: Hipertensi, Kolesterol tinggi',
          prefixIcon: Icons.history,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _medicationsController,
          label: 'Obat yang Sedang Dikonsumsi (Opsional)',
          hint: 'Contoh: Metformin, Amlodipine',
          prefixIcon: Icons.medication,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _allergiesController,
          label: 'Alergi (Opsional)',
          hint: 'Contoh: Seafood, Obat tertentu',
          prefixIcon: Icons.warning,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _familyHistoryController,
          label: 'Riwayat Diabetes Keluarga (Opsional)',
          hint: 'Contoh: Ayah diabetes tipe 2',
          prefixIcon: Icons.family_restroom,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label + (isRequired ? ' *' : ''),
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData prefixIcon,
    required void Function(String?) onChanged,
    bool isRequired = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label + (isRequired ? ' *' : ''),
        prefixIcon: Icon(prefixIcon, color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: const Text(
          'Simpan Profil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse input values
      final age = int.parse(_ageController.text);
      final weight = _weightController.text.isNotEmpty
          ? double.parse(_weightController.text)
          : null;
      final height = _heightController.text.isNotEmpty
          ? double.parse(_heightController.text)
          : null;

      // Create user profile
      final profile = UserProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        age: age,
        gender: _selectedGender,
        weight: weight,
        height: height,
        bloodType: _selectedBloodType,
        medicalHistory: _parseListInput(_medicalHistoryController.text),
        currentMedications: _parseListInput(_medicationsController.text),
        allergies: _parseListInput(_allergiesController.text),
        familyDiabetesHistory: _familyHistoryController.text.trim().isNotEmpty
            ? _familyHistoryController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ); // Save profile
      final success = await widget.userProfileService.saveUserProfile(profile);

      if (success) {
        // Update chat preferences based on profile
        try {
          await ChatPreferencesService.updateChatPreferencesFromProfile(
            profile,
          );
          print('Chat preferences updated successfully for new profile');
        } catch (e) {
          print('Warning: Failed to update chat preferences: $e');
          // Don't fail the profile creation if chat preferences fail
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profil berhasil disimpan! Selamat datang, ${profile.name}! 🎉',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Gagal menyimpan profil');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _parseListInput(String input) {
    if (input.trim().isEmpty) return [];
    return input
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Keluar Setup?'),
          ],
        ),
        content: const Text(
          'Profil Anda belum tersimpan. Apakah Anda yakin ingin keluar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close setup screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
