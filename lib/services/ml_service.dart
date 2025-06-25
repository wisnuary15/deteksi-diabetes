import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/detection_result.dart';

class MLService {
  static Interpreter? _interpreter;
  static bool _isModelLoaded = false;


  static List<String> _labels = [
    'diabetes',
    'non_diabetes',
  ]; // Urutan harus sama persis dengan training
  static final Map<String, DetectionResult> _cache = {};

  static const int INPUT_SIZE = 180; 
  static const int NUM_CHANNELS = 3;
  static const int NUM_CLASSES = 2;

  static Future<void> loadModel() async {
    try {
      print('🔄 Loading TensorFlow Lite model...');

      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
      _isModelLoaded = true;

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      print('✅ Model loaded successfully');
      print('📥 Input shape: $inputShape');
      print('📤 Output shape: $outputShape');

      // PERBAIKAN: Validasi shape
      if (inputShape[1] != INPUT_SIZE || inputShape[2] != INPUT_SIZE) {
        print(
          '⚠️ Warning: Expected input size $INPUT_SIZE but got ${inputShape[1]}x${inputShape[2]}',
        );
      }
    } catch (e) {
      print('❌ Error loading model: $e');
      _isModelLoaded = false;
      throw Exception('Gagal memuat model: $e');
    }
  }

  static Future<DetectionResult> predictImage(File imageFile) async {
    // Check cache first
    if (_cache.containsKey(imageFile.path)) {
      print('📁 Using cached result for: ${imageFile.path}');
      return _cache[imageFile.path]!;
    }

    if (!_isModelLoaded) {
      await loadModel();
    }

    try {
      print('🔬 Preprocessing image...');
      final input = await _preprocessImageVGG16Style(imageFile);

      // PERBAIKAN: Output sesuai dengan model yang sebenarnya
      var output = List.generate(1, (_) => List.filled(NUM_CLASSES, 0.0));

      print('🚀 Running model inference...');
      _interpreter!.run(input, output);

      final probabilities = output[0];
      print('📊 Raw probabilities: $probabilities');

      // PERBAIKAN: Validasi probabilitas
      if (probabilities.every((p) => p == 0.0)) {
        throw Exception('Model mengembalikan probabilitas 0 untuk semua kelas');
      }

      int predictedIndex = probabilities.indexWhere(
        (prob) => prob == probabilities.reduce((a, b) => a > b ? a : b),
      );
      double confidence = probabilities[predictedIndex];
      String className = _labels[predictedIndex];

      // TAMBAHAN: Simpan semua probabilitas untuk AI
      Map<String, double> allProbabilities = {};
      for (int i = 0; i < _labels.length; i++) {
        allProbabilities[_labels[i]] = probabilities[i];
      }

      // PERBAIKAN: Deteksi confidence rendah
      if (confidence < 0.5) {
        print(
          '⚠️ Warning: Low confidence prediction (${(confidence * 100).toStringAsFixed(2)}%)',
        );
      }

      final result = DetectionResult(
        className: className,
        confidence: confidence,
        imagePath: imageFile.path,
        timestamp: DateTime.now(),
        recommendations: _generateRecommendations(className, confidence),
        allProbabilities: allProbabilities, // TAMBAHAN: Untuk analisis AI
      );

      _cache[imageFile.path] = result;

      print(
        '🎯 Predicted: $className with ${(confidence * 100).toStringAsFixed(2)}%',
      );
      return result;
    } catch (e) {
      print('❌ Prediction error: $e');
      throw Exception('Gagal melakukan prediksi: $e');
    }
  }

  // PERBAIKAN: Preprocessing yang SAMA PERSIS dengan training
  static Future<List<List<List<List<double>>>>> _preprocessImageVGG16Style(
    File imageFile,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) throw Exception('Gagal mendekode gambar');

      // LANGKAH 1: Resize ke ukuran yang tepat (180x180)
      image = img.copyResize(image, width: INPUT_SIZE, height: INPUT_SIZE);

      // LANGKAH 2: Konversi ke format yang dibutuhkan model
      final input = List.generate(
        1,
        (_) => List.generate(
          INPUT_SIZE,
          (y) => List.generate(INPUT_SIZE, (x) {
            final pixel = image!.getPixel(x, y);

            // PERBAIKAN: VGG16 preprocessing seperti di training
            // Convert RGB 0-255 to double
            double r = pixel.r.toDouble();
            double g = pixel.g.toDouble();
            double b = pixel.b.toDouble();

            // LANGKAH 3: Terapkan VGG16 preprocessing (SAMA seperti training)
            // VGG16 preprocessing: subtract ImageNet mean
            r = r - 103.939; // Red channel mean
            g = g - 116.779; // Green channel mean
            b = b - 123.68; // Blue channel mean

            return [r, g, b];
          }),
        ),
      );

      return input;
    } catch (e) {
      print('❌ Image preprocessing error: $e');
      throw Exception('Gagal memproses gambar: $e');
    }
  }

  // PERBAIKAN: Rekomendasi berdasarkan confidence level
  static List<String> _generateRecommendations(
    String className,
    double confidence,
  ) {
    List<String> baseRecommendations = [];

    if (className == 'diabetes') {
      baseRecommendations = [
        'Konsultasikan dengan dokter spesialis endokrin segera',
        'Lakukan pemeriksaan gula darah puasa dan HbA1c',
        'Terapkan diet rendah karbohidrat dan gula',
        'Rutin berolahraga aerobik 150 menit/minggu',
        'Monitor tekanan darah dan kolesterol',
        'Hindari makanan olahan dan minuman manis',
      ];
    } else {
      baseRecommendations = [
        'Pertahankan gaya hidup sehat yang sudah baik',
        'Lakukan pemeriksaan kesehatan rutin 6 bulan sekali',
        'Konsumsi makanan bergizi seimbang',
        'Tetap aktif dengan olahraga teratur',
        'Konsumsi buah dan sayuran segar',
        'Jaga hidrasi dengan minum air putih cukup',
      ];
    }

    // PERBAIKAN: Tambahkan disclaimer berdasarkan confidence
    if (confidence < 0.7) {
      baseRecommendations.insert(
        0,
        '⚠️ Tingkat kepercayaan prediksi rendah (${(confidence * 100).toStringAsFixed(1)}%). Hasil ini hanya screening awal.',
      );
    }

    baseRecommendations.add(
      '📋 Catatan: Ini adalah screening awal. Konsultasi medis tetap disarankan untuk diagnosis yang akurat.',
    );

    return baseRecommendations;
  }

  // PERBAIKAN: Tambahkan method untuk debugging
  static Future<Map<String, dynamic>> debugPrediction(File imageFile) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    try {
      final input = await _preprocessImageVGG16Style(imageFile);
      var output = List.generate(1, (_) => List.filled(NUM_CLASSES, 0.0));

      _interpreter!.run(input, output);

      return {
        'raw_probabilities': output[0],
        'input_shape': input.length > 0
            ? [1, INPUT_SIZE, INPUT_SIZE, NUM_CHANNELS]
            : [],
        'preprocessed_sample':
            input.length > 0 && input[0].length > 0 && input[0][0].length > 0
            ? input[0][0][0] // First pixel values
            : [],
        'labels': _labels,
        'model_loaded': _isModelLoaded,
      };
    } catch (e) {
      return {'error': e.toString(), 'model_loaded': _isModelLoaded};
    }
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
    _cache.clear();
    print('🗑️ Model disposed & cache cleared');
  }
}
