class DetectionResult {
  final String className; 
  final double confidence;
  final String imagePath;
  final DateTime timestamp;
  final List<String> recommendations;
  final Map<String, double>?
  allProbabilities; 

  DetectionResult({
    required this.className,
    required this.confidence,
    required this.imagePath,
    required this.timestamp,
    required this.recommendations,
    this.allProbabilities,
  });

  // Helper getter untuk backward compatibility
  bool get isPositive => className == 'diabetes';

  // TAMBAHAN: Getter untuk kategori risiko berdasarkan hasil ML
  String get riskLevel {
    if (className == 'diabetes') {
      if (confidence >= 0.8) return 'TINGGI';
      if (confidence >= 0.6) return 'SEDANG-TINGGI';
      return 'PERLU KONFIRMASI';
    } else {
      if (confidence >= 0.8) return 'RENDAH';
      if (confidence >= 0.6) return 'SEDANG-RENDAH';
      return 'PERLU KONFIRMASI';
    }
  }

  // TAMBAHAN: Deskripsi hasil untuk AI
  String get aiDescription {
    final confidencePercent = (confidence * 100).toStringAsFixed(1);
    final alternativeClass = className == 'diabetes'
        ? 'non_diabetes'
        : 'diabetes';
    final alternativeConfidence =
        allProbabilities != null &&
            allProbabilities!.containsKey(alternativeClass)
        ? (allProbabilities![alternativeClass]! * 100).toStringAsFixed(1)
        : 'N/A';

    return '''
HASIL DETEKSI AI DIABETES:
- Kelas Prediksi: ${className == 'diabetes' ? 'DIABETES' : 'NON-DIABETES'}
- Tingkat Kepercayaan: $confidencePercent%
- Tingkat Risiko: $riskLevel
- Probabilitas Alternatif: $alternativeConfidence%
- Waktu Deteksi: ${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}
- Status Confidence: ${confidence >= 0.7
        ? 'TINGGI'
        : confidence >= 0.5
        ? 'SEDANG'
        : 'RENDAH'}
''';
  }

  // TAMBAHAN: Konteks medis untuk AI
  String get medicalContext {
    if (className == 'diabetes') {
      return '''
KONTEKS MEDIS DETEKSI POSITIF:
- Model AI mendeteksi indikasi diabetes pada analisis lidah
- Kemungkinan tanda-tanda: perubahan warna lidah, coating abnormal, tekstur kering
- Perlu follow-up dengan pemeriksaan laboratorium (GDP, TTGO, HbA1c)
- Hasil ini adalah screening awal, bukan diagnosis pasti
''';
    } else {
      return '''
KONTEKS MEDIS DETEKSI NEGATIF:
- Model AI tidak mendeteksi indikasi diabetes pada analisis lidah
- Lidah menunjukkan karakteristik normal atau tidak menunjukkan tanda diabetes
- Tetap disarankan pemeriksaan kesehatan rutin untuk pencegahan
- Hasil ini adalah screening awal untuk deteksi dini
''';
    }
  }

  // TAMBAHAN: Rekomendasi berdasarkan tingkat risiko
  String get riskBasedRecommendation {
    switch (riskLevel) {
      case 'TINGGI':
        return '''
REKOMENDASI RISIKO TINGGI:
- SEGERA konsultasi dengan dokter spesialis endokrin
- Lakukan pemeriksaan gula darah lengkap (GDP, TTGO, HbA1c)
- Mulai modifikasi gaya hidup sekarang juga
- Monitor gejala diabetes: poliuria, polidipsia, polifagia
- Pantau berat badan dan tekanan darah
''';
      case 'SEDANG-TINGGI':
        return '''
REKOMENDASI RISIKO SEDANG-TINGGI:
- Konsultasi dengan dokter dalam 1-2 minggu
- Lakukan pemeriksaan gula darah puasa
- Mulai diet rendah gula dan karbohidrat olahan
- Tingkatkan aktivitas fisik secara bertahap
- Monitor kondisi kesehatan secara rutin
''';
      case 'SEDANG-RENDAH':
        return '''
REKOMENDASI RISIKO SEDANG-RENDAH:
- Konsultasi dengan dokter untuk konfirmasi
- Lakukan pemeriksaan kesehatan rutin
- Pertahankan pola makan sehat
- Tetap aktif dengan olahraga teratur
- Pantau faktor risiko diabetes lainnya
''';
      case 'RENDAH':
        return '''
REKOMENDASI RISIKO RENDAH:
- Pertahankan gaya hidup sehat yang sudah baik
- Lakukan screening diabetes rutin setiap 3 tahun
- Konsumsi makanan bergizi seimbang
- Tetap aktif dengan olahraga 150 menit/minggu
- Jaga berat badan ideal
''';
      default:
        return '''
REKOMENDASI PERLU KONFIRMASI:
- Ulangi pemeriksaan dengan foto yang lebih baik
- Konsultasi dengan dokter untuk evaluasi lebih lanjut
- Lakukan pemeriksaan gula darah untuk konfirmasi
- Tidak mengabaikan gejala yang mungkin muncul
''';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'className': className,
      'confidence': confidence,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'recommendations': recommendations,
      'allProbabilities': allProbabilities,
      'riskLevel': riskLevel,
      'aiDescription': aiDescription,
    };
  }

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      className: json['className'],
      confidence: json['confidence'],
      imagePath: json['imagePath'],
      timestamp: DateTime.parse(json['timestamp']),
      recommendations: List<String>.from(json['recommendations']),
      allProbabilities: json['allProbabilities'] != null
          ? Map<String, double>.from(json['allProbabilities'])
          : null,
    );
  }

  String get displayText {
    switch (className) {
      case 'diabetes':
        return 'Indikasi Diabetes Terdeteksi';
      case 'non_diabetes':
        return 'Tidak Ada Indikasi Diabetes';
      default:
        return 'Hasil Tidak Dikenal';
    }
  }

  String get confidenceText {
    return 'Tingkat Kepercayaan: ${(confidence * 100).toStringAsFixed(1)}%';
  }

  // TAMBAHAN: Formatted text untuk display
  String get riskLevelText {
    switch (riskLevel) {
      case 'TINGGI':
        return 'Risiko Tinggi';
      case 'SEDANG-TINGGI':
        return 'Risiko Sedang-Tinggi';
      case 'SEDANG-RENDAH':
        return 'Risiko Sedang-Rendah';
      case 'RENDAH':
        return 'Risiko Rendah';
      default:
        return 'Perlu Konfirmasi';
    }
  }
}
