import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'result_screen.dart';
import '../services/ml_service.dart';
import '../constants/app_colors.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initializeML();
  }

  Future<void> _initializeML() async {
    try {
      await MLService.loadModel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat model ML: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _image = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _image = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Gunakan ML Service untuk prediksi real
      final result = await MLService.predictImage(_image!);

      setState(() {
        _isAnalyzing = false;
      });

      // Navigasi ke result screen dengan hasil ML
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResultScreen(result: result)),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menganalisis gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    MLService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModernAppBar(
        title: 'Deteksi Gambar Lidah',
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Image Preview Container
              ModernCard(
                padding: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  height: 400,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.surface,
                  ),
                  child: _image == null
                      ? _buildEmptyImageState()
                      : _buildImagePreview(),
                ),
              ),

              const SizedBox(height: 32),

              // Camera Controls
              _buildCameraControls(),

              const SizedBox(height: 24),

              // Analyze Button
              if (_image != null) _buildAnalyzeButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyImageState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.camera_alt_outlined,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Belum ada gambar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ambil foto lidah atau pilih dari galeri\nuntuk memulai analisis AI',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.file(
            _image!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () {
                  setState(() {
                    _image = null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return Row(
      children: [
        Expanded(
          child: ModernButton(
            text: 'Kamera',
            onPressed: _takePicture,
            icon: Icons.camera_alt,
            variant: ModernButtonVariant.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ModernButton(
            text: 'Galeri',
            onPressed: _pickFromGallery,
            icon: Icons.photo_library,
            variant: ModernButtonVariant.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return ModernButton(
      text: _isAnalyzing ? 'Menganalisis dengan AI...' : 'Analisis dengan AI',
      onPressed: _isAnalyzing ? null : _analyzeImage,
      icon: _isAnalyzing ? null : Icons.psychology,
      isLoading: _isAnalyzing,
      variant: ModernButtonVariant.primary,
      fullWidth: true,
    );
  }
}
