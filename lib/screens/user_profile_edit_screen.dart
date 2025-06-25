import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../services/chat_preferences_service.dart';

class UserProfileEditScreen extends StatefulWidget {
  final UserProfileService userProfileService;
  final UserProfile currentProfile;

  const UserProfileEditScreen({
    super.key,
    required this.userProfileService,
    required this.currentProfile,
  });

  @override
  State<UserProfileEditScreen> createState() => _UserProfileEditScreenState();
}

class _UserProfileEditScreenState extends State<UserProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _medicalHistoryController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _familyHistoryController;

  late String _selectedGender;
  String? _selectedBloodType;
  bool _isLoading = false;
  bool _hasChanges = false;

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _bloodTypeOptions = ['A', 'B', 'AB', 'O'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final profile = widget.currentProfile;

    _nameController = TextEditingController(text: profile.name);
    _ageController = TextEditingController(text: profile.age.toString());
    _weightController = TextEditingController(
      text: profile.weight?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: profile.height?.toString() ?? '',
    );
    _medicalHistoryController = TextEditingController(
      text: profile.medicalHistory.join(', '),
    );
    _medicationsController = TextEditingController(
      text: profile.currentMedications.join(', '),
    );
    _allergiesController = TextEditingController(
      text: profile.allergies.join(', '),
    );
    _familyHistoryController = TextEditingController(
      text: profile.familyDiabetesHistory ?? '',
    );

    // FIX: Validate gender value
    _selectedGender = _genderOptions.contains(profile.gender)
        ? profile.gender
        : _genderOptions.first;

    // FIX: Validate blood type value
    _selectedBloodType =
        (profile.bloodType != null &&
            _bloodTypeOptions.contains(profile.bloodType))
        ? profile.bloodType
        : null;

    // Add listeners to detect changes
    _addChangeListeners();
  }

  void _addChangeListeners() {
    final controllers = [
      _nameController,
      _ageController,
      _weightController,
      _heightController,
      _medicalHistoryController,
      _medicationsController,
      _allergiesController,
      _familyHistoryController,
    ];

    for (final controller in controllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'Edit Profil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue.shade600,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => _handleBackPressed(),
          ),
          actions: [
            if (_hasChanges)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: _resetChanges,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
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
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildHealthInfoSection(),
                      const SizedBox(height: 24),
                      _buildMedicalHistorySection(),
                      const SizedBox(height: 24),
                      _buildDetectionHistorySection(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
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
            'Menyimpan perubahan...',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profile = widget.currentProfile;

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
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 32, color: Colors.blue.shade600),
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Member sejak ${_formatDate(profile.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          if (_hasChanges) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '• Ada perubahan belum disimpan',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedGender = value;
                _hasChanges = true;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildHealthInfoSection() {
    final profile = widget.currentProfile;

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
          label: 'Golongan Darah',
          value: _selectedBloodType,
          items: _bloodTypeOptions,
          prefixIcon: Icons.bloodtype,
          onChanged: (value) {
            setState(() {
              _selectedBloodType = value;
              _hasChanges = true;
            });
          },
          isRequired: false,
        ),
        if (profile.bmi != null) ...[
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'BMI Saat Ini',
            value:
                '${profile.bmi!.toStringAsFixed(1)} (${profile.bmiCategory})',
            icon: Icons.calculate,
            color: _getBMIColor(profile.bmi!),
          ),
        ],
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

  Widget _buildDetectionHistorySection() {
    final profile = widget.currentProfile;

    if (profile.lastDetectionResult == null) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      title: 'Riwayat Deteksi',
      icon: Icons.analytics,
      children: [
        _buildInfoCard(
          title: 'Hasil Deteksi Terakhir',
          value: profile.lastDetectionResult!,
          icon: Icons.assessment,
          color: Colors.blue.shade600,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'Tingkat Risiko',
          value: profile.riskLevel ?? 'Tidak diketahui',
          icon: Icons.warning,
          color: _getRiskColor(profile.riskLevel),
        ),
        if (profile.lastDetectionDate != null) ...[
          const SizedBox(height: 12),
          _buildInfoCard(
            title: 'Tanggal Deteksi',
            value: _formatDate(profile.lastDetectionDate!),
            icon: Icons.calendar_today,
            color: Colors.grey.shade600,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Faktor Risiko: ${profile.riskFactors}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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
    // FIX: Ensure value is either null or exists in items
    final validValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: validValue,
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
      // FIX: Add hint when no value is selected
      hint: Text(
        isRequired
            ? 'Pilih ${label.replaceAll(' *', '')}'
            : 'Pilih ${label} (Opsional)',
        style: TextStyle(color: Colors.grey.shade600),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      // FIX: Add validator for required fields
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Field ini harus diisi';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _hasChanges ? _saveChanges : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasChanges
                  ? Colors.blue.shade600
                  : Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: _hasChanges ? 4 : 0,
            ),
            child: Text(
              _hasChanges ? 'Simpan Perubahan' : 'Tidak Ada Perubahan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _deleteProfile,
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              'Hapus Profil',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      return await _showUnsavedChangesDialog();
    }
    return true;
  }

  void _handleBackPressed() async {
    if (_hasChanges) {
      final shouldExit = await _showUnsavedChangesDialog();
      if (shouldExit) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Perubahan Belum Disimpan'),
          ],
        ),
        content: const Text(
          'Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin keluar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Keluar Tanpa Simpan',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, false);
              _saveChanges();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
            ),
            child: const Text(
              'Simpan & Keluar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _resetChanges() {
    setState(() {
      // Clear all controllers
      _nameController.dispose();
      _ageController.dispose();
      _weightController.dispose();
      _heightController.dispose();
      _medicalHistoryController.dispose();
      _medicationsController.dispose();
      _allergiesController.dispose();
      _familyHistoryController.dispose();

      // Reinitialize with original values
      _initializeControllers();
      _hasChanges = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Perubahan direset ke nilai semula'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _saveChanges() async {
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

      // FIX: Ensure selected values are valid
      final validGender = _genderOptions.contains(_selectedGender)
          ? _selectedGender
          : _genderOptions.first;

      final validBloodType =
          (_selectedBloodType != null &&
              _bloodTypeOptions.contains(_selectedBloodType!))
          ? _selectedBloodType
          : null;

      // Update user profile
      final updatedProfile = widget.currentProfile.copyWith(
        name: _nameController.text.trim(),
        age: age,
        gender: validGender,
        weight: weight,
        height: height,
        bloodType: validBloodType,
        medicalHistory: _parseListInput(_medicalHistoryController.text),
        currentMedications: _parseListInput(_medicationsController.text),
        allergies: _parseListInput(_allergiesController.text),
        familyDiabetesHistory: _familyHistoryController.text.trim().isNotEmpty
            ? _familyHistoryController.text.trim()
            : null,
        updatedAt: DateTime.now(),
      ); // Save profile
      final success = await widget.userProfileService.saveUserProfile(
        updatedProfile,
      );

      if (success) {
        // Update chat preferences based on updated profile
        try {
          await ChatPreferencesService.updateChatPreferencesFromProfile(
            updatedProfile,
          );
          print(
            'Chat preferences updated successfully for profile: ${updatedProfile.name}',
          );
        } catch (e) {
          print('Warning: Failed to update chat preferences: $e');
          // Don't fail the profile update if chat preferences fail
        }

        setState(() => _hasChanges = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profil ${updatedProfile.name} berhasil diperbarui! ✅',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context, updatedProfile);
        }
      } else {
        throw Exception('Gagal menyimpan perubahan profil');
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

  void _deleteProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Profil?'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus profil ini? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              try {
                await widget.userProfileService.clearProfile();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil berhasil dihapus'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pop(context, 'deleted');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error menghapus profil: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<String> _parseListInput(String input) {
    if (input.trim().isEmpty) return [];
    return input
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue.shade600;
    if (bmi < 25) return Colors.green.shade600;
    if (bmi < 30) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  Color _getRiskColor(String? risk) {
    if (risk == null) return Colors.grey.shade600;

    switch (risk.toLowerCase()) {
      case 'tinggi':
      case 'high':
        return Colors.red.shade600;
      case 'sedang':
      case 'medium':
        return Colors.orange.shade600;
      case 'rendah':
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
