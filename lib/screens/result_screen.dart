import 'package:flutter/material.dart';
import 'dart:io';
import '../models/detection_result.dart';
import '../services/history_service.dart';
import '../constants/app_colors.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_card.dart';

class ResultScreen extends StatefulWidget {
  final DetectionResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;

  Future<void> _saveToHistory() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await HistoryService.saveResult(widget.result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hasil berhasil disimpan ke riwayat'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ModernAppBar(title: 'Hasil Analisis AI', centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview
              _buildImagePreview(),

              const SizedBox(height: 32),

              // AI Result Card
              _buildResultCard(),

              const SizedBox(height: 24),

              // Recommendations Card
              _buildRecommendationsCard(),

              const SizedBox(height: 24),

              // Disclaimer
              _buildDisclaimer(),

              const SizedBox(height: 32),

              // Save Button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.neutral100,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: File(widget.result.imagePath).existsSync()
              ? Image.file(File(widget.result.imagePath), fit: BoxFit.cover)
              : Container(
                  color: AppColors.neutral100,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gambar tidak ditemukan',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final isPositive = widget.result.isPositive;
    final statusColor = isPositive ? AppColors.warning : AppColors.success;
    final statusBgColor = isPositive
        ? AppColors.warningBackground
        : AppColors.successBackground;

    return ModernCard(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: statusBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_rounded,
              size: 40,
              color: statusColor,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            widget.result.displayText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            widget.result.confidenceText,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.psychology, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Dianalisis dengan AI VGG16',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 24),
              SizedBox(width: 12),
              Text(
                'Rekomendasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          ...widget.result.recommendations.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hasil ini adalah prediksi AI dan bukan diagnosis medis. Konsultasikan dengan dokter untuk pemeriksaan lebih lanjut.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ModernButton(
      text: _isSaving ? 'Menyimpan...' : 'Simpan ke Riwayat',
      onPressed: _isSaving ? null : _saveToHistory,
      icon: _isSaving ? null : Icons.bookmark_add_outlined,
      isLoading: _isSaving,
      variant: ModernButtonVariant.primary,
      fullWidth: true,
    );
  }
}
