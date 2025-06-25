import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback onEnableLocation;
  final VoidCallback onOpenSettings;

  const LocationPermissionDialog({
    super.key,
    required this.onEnableLocation,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.location_off, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          const Text('Akses Lokasi Diperlukan'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Untuk menampilkan rumah sakit terdekat, aplikasi memerlukan akses ke lokasi Anda.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Kami akan menggunakan informasi lokasi untuk:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            '• Menampilkan posisi Anda di peta\n'
            '• Mencari rumah sakit terdekat\n'
            '• Memberikan petunjuk arah yang akurat',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onEnableLocation();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Izinkan Akses'),
        ),
      ],
    );
  }
}

class LocationServiceDisabledDialog extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const LocationServiceDisabledDialog({
    super.key,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.location_disabled, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          const Text('Layanan Lokasi Nonaktif'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Layanan lokasi di perangkat Anda sedang nonaktif. '
            'Silakan aktifkan GPS untuk menggunakan fitur rumah sakit terdekat.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onOpenSettings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Buka Pengaturan'),
        ),
      ],
    );
  }
}

class HospitalLoadingWidget extends StatelessWidget {
  final String message;

  const HospitalLoadingWidget({
    super.key,
    this.message = 'Mencari rumah sakit terdekat...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.red.shade400,
                ),
              ),
              Icon(Icons.local_hospital, size: 32, color: Colors.red.shade400),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Mohon tunggu sebentar...',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class NoLocationAccessWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  const NoLocationAccessWidget({
    super.key,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'Tidak Dapat Mengakses Lokasi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Untuk menampilkan rumah sakit terdekat, kami memerlukan akses ke lokasi Anda. '
              'Pastikan GPS aktif dan berikan izin akses lokasi.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Buka Pengaturan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
