Dokumentasi Kode: Klasifikasi Gambar dengan VGG16 & Fine-Tuning
1. Ringkasan Umum
Dokumen ini memberikan penjelasan mendetail untuk skrip Python yang melakukan klasifikasi gambar menggunakan transfer learning dengan model VGG16. Skrip ini dirancang untuk bekerja secara otomatis dengan data yang sudah terstruktur, membaginya menjadi set data latih, validasi, dan uji, lalu melatih model dalam dua tahap: feature extraction dan fine-tuning.

Tujuan Utama Kode:

Memuat dataset gambar dari sebuah direktori.

Membagi dataset secara otomatis menjadi 80% data latih, 10% data validasi, dan 10% data uji.

Membangun model klasifikasi gambar menggunakan arsitektur VGG16 yang sudah terlatih pada dataset ImageNet.

Melatih model menggunakan teknik transfer learning dan fine-tuning untuk mendapatkan akurasi yang tinggi.

Memvisualisasikan hasil training (akurasi dan loss).

Mengevaluasi performa model pada data uji yang belum pernah dilihat sebelumnya.

Menyimpan model final dalam format .keras dan .tflite untuk penggunaan di masa depan.

2. Prasyarat
Sebelum menjalankan kode, pastikan Anda telah memenuhi persyaratan berikut:

Library Python: Pastikan library berikut sudah terinstal.

pip install tensorflow matplotlib numpy

Struktur Direktori Data: Kode ini mengharapkan data gambar Anda diatur dalam struktur direktori tertentu. Harus ada satu direktori utama, dan di dalamnya terdapat sub-direktori untuk setiap kelas.

Contoh Struktur:

/path/to/your/data/
├── kelas_A/
│   ├── gambar1.jpg
│   ├── gambar2.jpg
│   └── ...
├── kelas_B/
│   ├── gambar101.jpg
│   ├── gambar102.jpg
│   └── ...
└── kelas_C/
    ├── gambar201.jpg
    └── ...

Anda harus mengganti data_dir = '/content/output_train/output_train' dengan path ke direktori utama data Anda (misalnya, /path/to/your/data/).

3. Penjelasan Alur Kerja Kode
Kode ini dibagi menjadi beberapa bagian logis yang akan dijelaskan di bawah ini.

Bagian 1: Impor Library
import tensorflow as tf
from tensorflow import keras
# ... (library lainnya)

Bagian ini mengimpor semua modul yang diperlukan:

TensorFlow & Keras: Framework utama untuk membangun dan melatih model deep learning.

Matplotlib: Untuk membuat plot dan visualisasi hasil training.

NumPy: Untuk operasi numerik (meskipun tidak banyak digunakan secara eksplisit, TensorFlow sangat bergantung padanya).

os: Untuk berinteraksi dengan sistem operasi (tidak digunakan secara aktif di kode ini, tetapi seringkali berguna).

Bagian 2: Persiapan Data Otomatis
data_dir = '/content/output_train/output_train'
# ...
train_ds = tf.keras.utils.image_dataset_from_directory(...)
val_test_ds = tf.keras.utils.image_dataset_from_directory(...)
# ...
val_ds = val_test_ds.take(...)
test_ds = val_test_ds.skip(...)

Ini adalah langkah krusial di mana data disiapkan.

image_dataset_from_directory: Fungsi ini secara otomatis memuat gambar dari direktori yang ditentukan. Fungsi ini juga akan menyimpulkan nama kelas dari nama sub-direktori.

Pembagian Data (Splitting):

Dataset pertama kali dibagi menjadi 80% untuk training (train_ds) dan 20% sisa (val_test_ds).

Dataset sisa yang 20% tersebut kemudian dibagi dua sama rata: 10% untuk validasi (val_ds) dan 10% untuk pengujian (test_ds). Ini adalah cara cerdas untuk mendapatkan tiga set data dari satu fungsi.

Optimasi Performa (.cache(), .shuffle(), .prefetch()):

.cache(): Menyimpan data di memori setelah dimuat pertama kali untuk mempercepat proses di epoch berikutnya.

.shuffle(): Mengacak data training untuk memastikan model tidak mempelajari urutan data.

.prefetch(): Memuat batch data berikutnya saat model sedang training dengan batch saat ini. Ini akan mengurangi waktu tunggu (bottleneck) I/O dan mempercepat training secara keseluruhan. AUTOTUNE secara dinamis menyesuaikan ukuran buffer.

Bagian 3: Pembangunan Arsitektur Model (VGG16)
base_model = VGG16(weights='imagenet', include_top=False, ...)
base_model.trainable = False
# ...
x = layers.Flatten()(x)
x = layers.Dense(256, activation='relu')(x)
# ...
outputs = layers.Dense(num_classes, activation='softmax')(x)

Di sini, arsitektur model Convolutional Neural Network (CNN) dibangun.

Data Augmentation: Lapisan ini (RandomFlip, RandomRotation, dll.) secara acak memodifikasi gambar training setiap epoch. Tujuannya adalah untuk "memperbanyak" data training secara artifisial sehingga model menjadi lebih tangguh (robust) dan tidak mudah overfitting.

Model Dasar (Base Model): VGG16 yang sudah terlatih pada dataset raksasa ImageNet digunakan sebagai model dasar.

weights='imagenet': Menggunakan bobot (pengetahuan) yang sudah dipelajari dari ImageNet.

include_top=False: Hanya menggunakan bagian konvolusi (ekstraktor fitur) dari VGG16, tanpa lapisan klasifikasi akhirnya.

base_model.trainable = False: Membekukan semua bobot di model VGG16. Pada tahap pertama, kita tidak ingin mengubah pengetahuan yang sudah ada, kita hanya ingin melatih lapisan baru yang kita tambahkan.

Kepala Klasifikasi (Classifier Head): Lapisan-lapisan baru ditambahkan di atas model dasar yang beku.

Flatten: Mengubah output fitur 2D dari VGG16 menjadi vektor 1D.

Dense(256): Lapisan terhubung penuh (fully connected layer) sebagai perantara.

Dropout(0.5): Menonaktifkan 50% neuron secara acak selama training untuk mencegah overfitting.

Dense(num_classes, 'softmax'): Lapisan output final yang menghasilkan probabilitas untuk setiap kelas.

Bagian 4: Kompilasi dan Training
Proses training dibagi menjadi dua tahap utama.

Tahap 1: Feature Extraction

model.compile(optimizer=keras.optimizers.Adam(learning_rate=1e-3), ...)
history = model.fit(...)

Kompilasi: Model dikonfigurasi untuk proses training. Adam digunakan sebagai optimizer, sparse_categorical_crossentropy sebagai fungsi loss (cocok untuk klasifikasi integer), dan accuracy sebagai metrik. Learning rate diatur relatif tinggi (1e-3).

Training: Model dilatih hanya pada lapisan "kepala" yang baru ditambahkan, sementara VGG16 tetap beku. Tujuannya adalah agar lapisan baru ini belajar mengklasifikasikan fitur yang diekstrak oleh VGG16.

Callbacks:

EarlyStopping: Menghentikan training jika val_loss (loss pada data validasi) tidak membaik setelah 10 epoch. restore_best_weights=True memastikan model kembali ke bobot terbaik yang pernah dicapai.

ReduceLROnPlateau: Mengurangi learning rate jika val_loss stagnan, membantu model menemukan titik minimum yang lebih baik.

Tahap 2: Fine-Tuning

base_model.trainable = True
for layer in base_model.layers[:-4]:
    layer.trainable = False
# ...
model.compile(optimizer=keras.optimizers.Adam(learning_rate=1e-5), ...)
history_fine = model.fit(..., initial_epoch=history.epoch[-1])

Membuka Lapisan: base_model.trainable diatur ke True, tetapi kemudian beberapa lapisan teratas dari VGG16 (4 lapisan terakhir) dibiarkan dapat dilatih (trainable), sementara sisanya tetap beku. Tujuannya adalah untuk sedikit menyesuaikan fitur tingkat tinggi dari VGG16 agar lebih cocok dengan dataset spesifik kita.

Kompilasi Ulang: Model dikompilasi ulang dengan learning rate yang sangat rendah (1e-5). Ini sangat penting untuk mencegah perubahan drastis pada bobot VGG16 yang sudah bagus, yang dapat merusak pengetahuan yang sudah ada.

Melanjutkan Training: Training dilanjutkan dari epoch terakhir tahap pertama (initial_epoch).

Bagian 5: Visualisasi Hasil
plt.figure(figsize=(14, 6))
plt.subplot(1, 2, 1)
plt.plot(..., label='Training Accuracy')
# ...
plt.show()

Bagian ini menggabungkan riwayat dari kedua tahap training dan membuat dua plot:

Akurasi Training vs. Validasi: Menunjukkan seberapa baik model belajar pada data latih dan seberapa baik kinerjanya pada data validasi. Jika akurasi training terus naik sementara akurasi validasi stagnan/turun, itu pertanda overfitting.

Loss Training vs. Validasi: Menunjukkan kesalahan model. Idealnya, kedua kurva (training dan validasi) harus menurun dan saling berdekatan.

Bagian 6: Evaluasi dan Penyimpanan Model
test_loss, test_acc = model.evaluate(test_ds)
# ...
model.save(f'{model_filename}.keras')
converter = tf.lite.TFLiteConverter.from_keras_model(model)
# ...

Evaluasi: Performa model final diukur menggunakan data uji (test_ds), yang sama sekali belum pernah dilihat oleh model selama proses training dan validasi. Ini memberikan metrik yang paling objektif tentang kinerja model.

Penyimpanan:

.keras: Menyimpan seluruh model (arsitektur, bobot, konfigurasi optimizer) dalam format asli Keras. Dapat dimuat kembali di Python untuk inferensi atau training lanjutan.

.tflite: Mengonversi dan menyimpan model ke format TensorFlow Lite, yang dioptimalkan untuk penerapan di perangkat seluler (Android/iOS) dan perangkat embedded.

4. Cara Menggunakan Skrip
Siapkan Lingkungan: Instal semua library yang tercantum di bagian Prasyarat.

Siapkan Data: Atur dataset gambar Anda sesuai dengan struktur direktori yang dijelaskan di bagian Prasyarat.

Ubah Path Direktori: Buka file .py dan ubah baris berikut untuk menunjuk ke direktori utama data Anda:

data_dir = '/path/to/your/data' # Ganti dengan path Anda

Jalankan Skrip: Eksekusi skrip dari terminal Anda:

python nama_file_anda.py

Periksa Hasil: Skrip akan mencetak progres training di konsol. Setelah selesai, plot akurasi dan loss akan ditampilkan, dan akurasi final pada data uji akan dicetak. Dua file model, vgg16_finetuned_balanced_dataset.keras dan vgg16_finetuned_balanced_dataset.tflite, akan dibuat di direktori kerja Anda.