import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_app_bar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      // Registrasi berhasil
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Kembali ke login screen
      Navigator.of(context).pop();
    } else {
      // Registrasi gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModernAppBar(title: 'Daftar Akun', showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(),

                  const SizedBox(height: 32),

                  // Register Form
                  _buildRegisterForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Buat Akun Baru',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Lengkapi data diri Anda untuk melanjutkan',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return ModernCard(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            ModernTextField(
              label: 'Nama Lengkap',
              hint: 'Masukkan nama lengkap Anda',
              controller: _nameController,
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama harus diisi';
                }
                if (value.length < 2) {
                  return 'Nama minimal 2 karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            ModernTextField(
              label: 'Email',
              hint: 'Masukkan email Anda',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email harus diisi';
                }
                if (!EmailValidator.validate(value)) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            ModernTextField(
              label: 'No. Telepon',
              hint: 'Masukkan nomor telepon Anda',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nomor telepon harus diisi';
                }
                if (value.length < 10) {
                  return 'Nomor telepon minimal 10 digit';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            ModernTextField(
              label: 'Password',
              hint: 'Masukkan password Anda',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password harus diisi';
                }
                if (value.length < 6) {
                  return 'Password minimal 6 karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            ModernTextField(
              label: 'Konfirmasi Password',
              hint: 'Ulangi password Anda',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Konfirmasi password harus diisi';
                }
                if (value != _passwordController.text) {
                  return 'Password tidak sama';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            ModernButton(
              text: 'Daftar',
              onPressed: _isLoading ? null : _register,
              isLoading: _isLoading,
              variant: ModernButtonVariant.primary,
              size: ModernButtonSize.large,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
