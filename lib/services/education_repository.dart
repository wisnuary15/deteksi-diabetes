import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/education_article.dart';

class EducationRepository {
  static const String _apiKey =
      'b97c8a5e774e4b5296a37afd8041b24f'; // NewsAPI key
  static const String _baseUrl = 'https://newsapi.org/v2/everything';

  // Cache untuk artikel
  static List<EducationArticle> _cachedArticles = [];
  static DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  static Future<List<EducationArticle>> getArticles() async {
    try {
      // Cek cache terlebih dahulu
      if (_isCacheValid()) {
        return _cachedArticles;
      }

      // Fetch dari network
      final networkArticles = await _fetchFromNetwork();
      final offlineArticles = _getOfflineArticles();

      // Gabungkan dan update cache
      _cachedArticles = [...networkArticles, ...offlineArticles];
      _lastFetchTime = DateTime.now();

      return _cachedArticles;
    } catch (e) {
      print('Error fetching articles: $e');
      // Jika gagal, return cache lama atau artikel offline
      if (_cachedArticles.isNotEmpty) {
        return _cachedArticles;
      } else {
        return _getOfflineArticles();
      }
    }
  }

  static Future<List<EducationArticle>> _fetchFromNetwork() async {
    const query =
        'diabetes OR "diet sehat" OR "olahraga untuk diabetes" OR "kontrol gula darah"';
    final url = Uri.parse(
      '$_baseUrl?q=$query&language=id&sortBy=publishedAt&pageSize=10&apiKey=$_apiKey',
    );

    final response = await http
        .get(url, headers: {'User-Agent': 'DiabetesApp/1.0'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articles = (data['articles'] as List)
          .where((article) => _isRelevantArticle(article))
          .map((article) => EducationArticle.fromJson(article))
          .take(5) // Limit hasil network
          .toList();

      return articles;
    } else {
      throw Exception('Failed to load articles: ${response.statusCode}');
    }
  }

  static bool _isRelevantArticle(Map<String, dynamic> article) {
    const keywords = [
      'diabetes',
      'diabet',
      'diet',
      'sehat',
      'olahraga',
      'gula darah',
      'gula',
    ];
    final title = (article['title'] ?? '').toString().toLowerCase();
    final description = (article['description'] ?? '').toString().toLowerCase();

    return keywords.any(
      (keyword) => title.contains(keyword) || description.contains(keyword),
    );
  }

  static bool _isCacheValid() {
    return _cachedArticles.isNotEmpty &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiry;
  }

  static List<EducationArticle> _getOfflineArticles() {
    return [
      EducationArticle(
        id: 'offline_1',
        title: '10 Tips Mengontrol Gula Darah untuk Penderita Diabetes',
        content: '''
Mengontrol gula darah adalah kunci utama dalam mengelola diabetes. Berikut adalah 10 tips praktis yang dapat membantu Anda:

1. **Monitor Gula Darah Secara Rutin**
Periksa kadar gula darah sesuai anjuran dokter. Ini membantu Anda memahami pola dan efek makanan terhadap gula darah.

2. **Konsumsi Makanan Berserat Tinggi**
Serat membantu memperlambat penyerapan gula dan meningkatkan kontrol gula darah.

3. **Batasi Karbohidrat Sederhana**
Hindari gula, permen, dan makanan olahan yang dapat meningkatkan gula darah dengan cepat.

4. **Olahraga Teratur**
Aktivitas fisik membantu otot menggunakan glukosa, sehingga menurunkan kadar gula darah.

5. **Jaga Berat Badan Ideal**
Berat badan berlebih dapat memperburuk resistensi insulin.

6. **Kelola Stres**
Stres dapat meningkatkan kadar gula darah. Cobalah teknik relaksasi atau meditasi.

7. **Cukup Tidur**
Kurang tidur dapat mempengaruhi hormon yang mengatur gula darah.

8. **Minum Air Putih Cukup**
Dehidrasi dapat meningkatkan kadar gula darah.

9. **Konsumsi Obat Sesuai Anjuran**
Jangan melewatkan atau mengubah dosis obat tanpa konsultasi dokter.

10. **Kontrol Rutin ke Dokter**
Pemeriksaan berkala membantu memantau kondisi dan menyesuaikan terapi.
        ''',
        category: 'Tips Kesehatan',
        isOffline: true,
      ),

      EducationArticle(
        id: 'offline_2',
        title: 'Makanan yang Baik dan Buruk untuk Penderita Diabetes',
        content: '''
Memilih makanan yang tepat sangat penting untuk mengelola diabetes. Berikut panduan makanan untuk penderita diabetes:

**MAKANAN YANG DIREKOMENDASIKAN:**

🥬 **Sayuran Hijau**
- Bayam, kangkung, brokoli
- Rendah kalori dan karbohidrat
- Kaya vitamin dan mineral

🐟 **Ikan Berlemak**
- Salmon, makarel, sarden
- Kaya omega-3 yang baik untuk jantung

🥜 **Kacang-kacangan**
- Almond, kenari, kacang tanah
- Protein tinggi dan lemak sehat

🍓 **Buah-buahan Rendah Gula**
- Berry, apel, pir
- Kaya antioksidan dan serat

🌾 **Biji-bijian Utuh**
- Oat, quinoa, beras merah
- Serat tinggi dan indeks glikemik rendah

**MAKANAN YANG HARUS DIHINDARI:**

❌ **Makanan Manis**
- Permen, kue, es krim
- Minuman bersoda dan jus kemasan

❌ **Karbohidrat Olahan**
- Roti putih, pasta putih, nasi putih
- Meningkatkan gula darah dengan cepat

❌ **Makanan Gorengan**
- Tinggi lemak trans dan kalori
- Dapat memperburuk resistensi insulin

❌ **Daging Olahan**
- Sosis, bacon, ham
- Tinggi sodium dan pengawet

**TIPS MAKAN SEHAT:**
- Makan dalam porsi kecil tapi sering
- Kombinasikan protein, lemak sehat, dan karbohidrat kompleks
- Baca label nutrisi dengan teliti
- Konsultasi dengan ahli gizi untuk menu personal
        ''',
        category: 'Nutrisi',
        isOffline: true,
      ),

      EducationArticle(
        id: 'offline_3',
        title: 'Olahraga yang Aman dan Efektif untuk Penderita Diabetes',
        content: '''
Olahraga adalah bagian penting dalam pengelolaan diabetes. Berikut panduan olahraga yang aman dan efektif:

**MANFAAT OLAHRAGA UNTUK DIABETES:**
✅ Meningkatkan sensitivitas insulin
✅ Menurunkan kadar gula darah
✅ Membantu mengontrol berat badan
✅ Meningkatkan kesehatan jantung
✅ Mengurangi stres dan depresi

**JENIS OLAHRAGA YANG DIREKOMENDASIKAN:**

🚶 **Aerobik Intensitas Sedang (150 menit/minggu)**
- Jalan cepat
- Bersepeda
- Berenang
- Senam aerobik

💪 **Latihan Kekuatan (2-3x/minggu)**
- Angkat beban ringan
- Push-up
- Squat
- Resistance band

🧘 **Latihan Fleksibilitas**
- Yoga
- Stretching
- Tai chi

**TIPS AMAN BEROLAHRAGA:**

⏰ **Waktu yang Tepat**
- 1-3 jam setelah makan
- Hindari olahraga saat gula darah terlalu tinggi (>300 mg/dL)

🩺 **Monitoring**
- Cek gula darah sebelum dan sesudah olahraga
- Bawa snack untuk mencegah hipoglikemia

👟 **Peralatan**
- Gunakan sepatu yang nyaman
- Bawa air minum yang cukup
- Pakai pakaian yang menyerap keringat

⚠️ **Tanda Harus Berhenti**
- Pusing atau lemas berlebihan
- Nyeri dada
- Sesak napas yang tidak normal
- Gejala hipoglikemia

Selalu konsultasi dengan dokter sebelum memulai program olahraga baru!
        ''',
        category: 'Olahraga',
        isOffline: true,
      ),

      EducationArticle(
        id: 'offline_4',
        title: 'Mengenali Gejala dan Komplikasi Diabetes',
        content: '''
Mengenali gejala diabetes dan komplikasinya sangat penting untuk penanganan dini. Berikut informasi lengkapnya:

**GEJALA AWAL DIABETES:**

🚰 **Poliuria (Sering Buang Air Kecil)**
- Terutama di malam hari
- Volume urin berlebihan

🥤 **Polidipsia (Haus Berlebihan)**
- Merasa haus terus menerus
- Tidak hilang meski banyak minum

🍽️ **Polifagia (Lapar Berlebihan)**
- Nafsu makan meningkat
- Tetap lapar meski sudah makan

⚖️ **Penurunan Berat Badan**
- Tanpa diet atau olahraga
- Terjadi meski makan banyak

😴 **Kelelahan**
- Mudah lelah dan lemah
- Energi berkurang drastis

👁️ **Gangguan Penglihatan**
- Penglihatan kabur
- Sulit fokus

**KOMPLIKASI JANGKA PENDEK:**

⚡ **Hipoglikemia (Gula Darah Rendah)**
Gejala: Gemetar, berkeringat, pusing, bingung
Penanganan: Konsumsi 15g karbohidrat cepat

🔥 **Hiperglikemia (Gula Darah Tinggi)**
Gejala: Haus berlebihan, mual muntah, napas bau buah

**KOMPLIKASI JANGKA PANJANG:**

❤️ **Komplikasi Kardiovaskular**
- Penyakit jantung koroner
- Stroke, Hipertensi

🧠 **Neuropati (Kerusakan Saraf)**
- Kesemutan di tangan dan kaki
- Kehilangan sensasi

👁️ **Retinopati (Kerusakan Mata)**
- Gangguan penglihatan
- Buta mendadak

🦶 **Kaki Diabetik**
- Luka yang sulit sembuh
- Risiko amputasi

**PENCEGAHAN KOMPLIKASI:**
- Kontrol gula darah ketat
- Tekanan darah normal
- Tidak merokok
- Pemeriksaan mata berkala

Ingat: Deteksi dini dan pengelolaan yang baik dapat mencegah komplikasi serius!
        ''',
        category: 'Informasi Medis',
        isOffline: true,
      ),
    ];
  }
}
