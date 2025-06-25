class UserProfile {
  final String id;
  final String name;
  final int age;
  final String gender;
  final double? weight;
  final double? height;
  final String? bloodType;
  final List<String> medicalHistory;
  final List<String> currentMedications;
  final List<String> allergies;
  final String? familyDiabetesHistory;
  final String? lastDetectionResult;
  final String? riskLevel;
  final String? riskFactors; // ADD: New field for risk factors
  final DateTime? lastDetectionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.weight,
    this.height,
    this.bloodType,
    this.medicalHistory = const [],
    this.currentMedications = const [],
    this.allergies = const [],
    this.familyDiabetesHistory,
    this.lastDetectionResult,
    this.riskLevel,
    this.riskFactors, // ADD: New field
    this.lastDetectionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  double? get bmi {
    if (weight != null && height != null && height! > 0) {
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Tidak diketahui';

    if (bmiValue < 18.5) return 'Kurus';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Gemuk';
    return 'Obesitas';
  }

  bool get hasHighRisk {
    return riskLevel?.toLowerCase() == 'tinggi' ||
        riskLevel?.toLowerCase() == 'high';
  }

  bool get hasDiabetesHistory {
    return medicalHistory.any(
      (history) =>
          history.toLowerCase().contains('diabetes') ||
          history.toLowerCase().contains('gula darah'),
    );
  }

  bool get hasFamilyHistory {
    return familyDiabetesHistory != null &&
        familyDiabetesHistory!.isNotEmpty &&
        familyDiabetesHistory!.toLowerCase() != 'tidak ada';
  }

  String get calculatedRiskFactors {
    final factors = <String>[];

    if (age > 45) factors.add('Usia > 45 tahun');
    if (bmi != null && bmi! >= 25) factors.add('BMI tinggi');
    if (hasFamilyHistory) factors.add('Riwayat keluarga diabetes');
    if (hasDiabetesHistory) factors.add('Riwayat medis diabetes');

    return factors.isEmpty
        ? 'Tidak ada faktor risiko utama'
        : factors.join(', ');
  }

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    double? weight,
    double? height,
    String? bloodType,
    List<String>? medicalHistory,
    List<String>? currentMedications,
    List<String>? allergies,
    String? familyDiabetesHistory,
    String? lastDetectionResult,
    String? riskLevel,
    String? riskFactors, // ADD: New parameter
    DateTime? lastDetectionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bloodType: bloodType ?? this.bloodType,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      currentMedications: currentMedications ?? this.currentMedications,
      allergies: allergies ?? this.allergies,
      familyDiabetesHistory:
          familyDiabetesHistory ?? this.familyDiabetesHistory,
      lastDetectionResult: lastDetectionResult ?? this.lastDetectionResult,
      riskLevel: riskLevel ?? this.riskLevel,
      riskFactors: riskFactors ?? this.riskFactors, // ADD: New field
      lastDetectionDate: lastDetectionDate ?? this.lastDetectionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'bloodType': bloodType,
      'medicalHistory': medicalHistory,
      'currentMedications': currentMedications,
      'allergies': allergies,
      'familyDiabetesHistory': familyDiabetesHistory,
      'lastDetectionResult': lastDetectionResult,
      'riskLevel': riskLevel,
      'riskFactors': riskFactors, // ADD: New field
      'lastDetectionDate': lastDetectionDate?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // FIXED: Safe type casting in fromJson
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      // SAFE: Handle both String and int for age
      age: _safeParseInt(json['age']) ?? 25,
      gender: json['gender']?.toString() ?? '',
      // SAFE: Handle both String and double for weight/height
      weight: _safeParseDouble(json['weight']),
      height: _safeParseDouble(json['height']),
      bloodType: json['bloodType']?.toString(),
      medicalHistory: _safeParseStringList(json['medicalHistory']),
      currentMedications: _safeParseStringList(json['currentMedications']),
      allergies: _safeParseStringList(json['allergies']),
      familyDiabetesHistory: json['familyDiabetesHistory']?.toString(),
      lastDetectionResult: json['lastDetectionResult']?.toString(),
      riskLevel: json['riskLevel']?.toString(),
      riskFactors: json['riskFactors']?.toString(), // If this field exists
      // SAFE: Handle timestamp parsing
      lastDetectionDate: _safeParseDateTime(json['lastDetectionDate']),
      createdAt: _safeParseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _safeParseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  // ADD: Safe parsing helper methods
  static int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.round();
    return null;
  }

  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static List<String> _safeParseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((item) => item?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) {
      // Handle comma-separated string
      return value
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  static DateTime? _safeParseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return null;
      }
    }
    if (value is String) {
      // Try parsing as milliseconds first
      final intValue = int.tryParse(value);
      if (intValue != null) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(intValue);
        } catch (e) {
          // Fall through to ISO string parsing
        }
      }
      // Try parsing as ISO string
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // FIX: Add validation in fromMap method
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    // Validate gender
    final gender = map['gender'] as String? ?? 'Laki-laki';
    final genderOptions = ['Laki-laki', 'Perempuan'];
    final validGender = genderOptions.contains(gender)
        ? gender
        : genderOptions.first;

    // Validate blood type
    final bloodType = map['bloodType'] as String?;
    final bloodTypeOptions = ['A', 'B', 'AB', 'O'];
    final validBloodType =
        (bloodType != null && bloodTypeOptions.contains(bloodType))
        ? bloodType
        : null;

    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      age: map['age'] as int,
      gender: validGender,
      weight: map['weight'] as double?,
      height: map['height'] as double?,
      bloodType: validBloodType,
      medicalHistory: List<String>.from(map['medicalHistory'] ?? []),
      currentMedications: List<String>.from(map['currentMedications'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      familyDiabetesHistory: map['familyDiabetesHistory'] as String?,
      lastDetectionResult: map['lastDetectionResult'] as String?,
      riskLevel: map['riskLevel'] as String?,
      riskFactors: map['riskFactors'] as String?, // ADD: New field
      lastDetectionDate: map['lastDetectionDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastDetectionDate'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, age: $age, gender: $gender)';
  }
}

// Context yang akan dikirim ke AI
class UserContext {
  final UserProfile profile;
  final String currentQuery;
  final List<String> recentTopics;
  final String sessionContext;

  UserContext({
    required this.profile,
    required this.currentQuery,
    this.recentTopics = const [],
    this.sessionContext = '',
  });

  String toAIPrompt() {
    final buffer = StringBuffer();

    buffer.writeln('=== INFORMASI PENGGUNA ===');
    buffer.writeln('Nama: ${profile.name}');
    buffer.writeln('Usia: ${profile.age} tahun');
    buffer.writeln('Jenis Kelamin: ${profile.gender}');

    if (profile.weight != null && profile.height != null) {
      buffer.writeln('Tinggi: ${profile.height} cm');
      buffer.writeln('Berat: ${profile.weight} kg');
      buffer.writeln(
        'BMI: ${profile.bmi?.toStringAsFixed(1)} (${profile.bmiCategory})',
      );
    }

    if (profile.bloodType != null) {
      buffer.writeln('Golongan Darah: ${profile.bloodType}');
    }

    if (profile.medicalHistory.isNotEmpty) {
      buffer.writeln('Riwayat Medis: ${profile.medicalHistory.join(', ')}');
    }

    if (profile.currentMedications.isNotEmpty) {
      buffer.writeln('Obat Saat Ini: ${profile.currentMedications.join(', ')}');
    }

    if (profile.allergies.isNotEmpty) {
      buffer.writeln('Alergi: ${profile.allergies.join(', ')}');
    }

    if (profile.hasFamilyHistory) {
      buffer.writeln('Riwayat Keluarga: ${profile.familyDiabetesHistory}');
    }

    if (profile.lastDetectionResult != null) {
      buffer.writeln('Hasil Deteksi Terakhir: ${profile.lastDetectionResult}');
      buffer.writeln('Tingkat Risiko: ${profile.riskLevel}');
      if (profile.lastDetectionDate != null) {
        buffer.writeln(
          'Tanggal Deteksi: ${_formatDate(profile.lastDetectionDate!)}',
        );
      }
    }

    buffer.writeln('Faktor Risiko: ${profile.riskFactors}');
    buffer.writeln(
      'Faktor Risiko: ${profile.riskFactors ?? profile.calculatedRiskFactors}',
    );
    if (recentTopics.isNotEmpty) {
      buffer.writeln('\n=== TOPIK TERBARU ===');
      buffer.writeln(recentTopics.join(', '));
    }

    if (sessionContext.isNotEmpty) {
      buffer.writeln('\n=== KONTEKS SESI ===');
      buffer.writeln(sessionContext);
    }

    buffer.writeln('\n=== PETUNJUK UNTUK AI ===');
    buffer.writeln('- Gunakan nama ${profile.name} saat menyapa');
    buffer.writeln('- Berikan saran yang personal berdasarkan profil');
    buffer.writeln(
      '- Pertimbangkan usia, BMI, dan riwayat medis dalam jawaban',
    );
    if (profile.hasHighRisk) {
      buffer.writeln(
        '- PENTING: User memiliki risiko tinggi diabetes, berikan perhatian khusus',
      );
    }
    buffer.writeln('- Jika ada kondisi medis, sarankan konsultasi dokter');
    buffer.writeln(
      '- Berikan jawaban dalam bahasa Indonesia yang ramah dan profesional',
    );

    buffer.writeln('\n=== PERTANYAAN USER ===');
    buffer.writeln(currentQuery);

    return buffer.toString();
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
