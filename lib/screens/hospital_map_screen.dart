import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/hospital_service.dart';
import '../widgets/modern_app_bar.dart';
import '../constants/app_colors.dart';

class HospitalMapScreen extends StatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<Hospital> _hospitals = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<Marker> _markers = [];
  bool _isUsingMockData = false;

  final HospitalService _hospitalService = HospitalService();

  // Default location (Jakarta) jika lokasi tidak dapat diakses
  static const LatLng _defaultLocation = LatLng(-6.2088, 106.8456);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isUsingMockData = false;
    });

    try {
      // Get current location
      _currentPosition = await _hospitalService.getCurrentLocation();

      // Find nearby hospitals
      _hospitals = await _hospitalService.findNearbyHospitals(
        userLocation: _currentPosition,
        radius: 10000, // 10km radius
        maxResults: 15,
      );

      // Create markers
      _createMarkers();

      // Determine if we're using mock data
      _isUsingMockData = _currentPosition == null;

      // Show message if using mock data due to location issues
      if (_isUsingMockData && _hospitals.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Menggunakan data contoh karena lokasi tidak dapat diakses. '
                'Aktifkan izin lokasi untuk hasil yang lebih akurat.',
              ),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createMarkers() {
    _markers.clear();

    // Add user location marker
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          point: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          width: 80,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
          ),
        ),
      );
    }

    // Add hospital markers
    for (final hospital in _hospitals) {
      _markers.add(
        Marker(
          point: LatLng(hospital.latitude, hospital.longitude),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showHospitalDetails(hospital),
            child: Container(
              decoration: BoxDecoration(
                color: hospital.isOpenNow
                    ? Colors.green.withOpacity(0.9)
                    : Colors.red.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_hospital,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      );
    }
  }

  void _showHospitalDetails(Hospital hospital) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildHospitalDetailsSheet(hospital),
      isScrollControlled: true,
    );
  }

  Widget _buildHospitalDetailsSheet(Hospital hospital) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.8,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Hospital name and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hospital.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: hospital.isOpenNow
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            hospital.isOpenNow ? 'Buka' : 'Tutup',
                            style: TextStyle(
                              color: hospital.isOpenNow
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Rating and distance
                    Row(
                      children: [
                        if (hospital.rating != null) ...[
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            hospital.rating!.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${hospital.distance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_pin, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hospital.address,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phone number
                    if (hospital.phoneNumber != null) ...[
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            hospital.phoneNumber!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openDirections(hospital),
                            icon: const Icon(Icons.directions),
                            label: const Text('Petunjuk Arah'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (hospital.phoneNumber != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _callHospital(hospital.phoneNumber!),
                              icon: const Icon(Icons.phone),
                              label: const Text('Telepon'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDirections(Hospital hospital) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka aplikasi maps')),
        );
      }
    }
  }

  Future<void> _callHospital(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat melakukan panggilan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Rumah Sakit Terdekat',
        actions: [
          IconButton(
            onPressed: _initializeMap,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mencari rumah sakit terdekat...'),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeMap,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Map
                Expanded(
                  flex: 2,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition != null
                          ? LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            )
                          : _defaultLocation,
                      initialZoom: 13,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.diabetes',
                        maxNativeZoom: 19,
                      ),
                      MarkerLayer(markers: _markers),
                    ],
                  ),
                ),

                // Mock data indicator
                if (_isUsingMockData)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.orange.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[700],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Menampilkan data contoh - Aktifkan lokasi untuk hasil akurat',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Hospital list
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, -2),
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Rumah Sakit Terdekat (${_hospitals.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _hospitals.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final hospital = _hospitals[index];
                              return _buildHospitalListItem(hospital);
                            },
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

  Widget _buildHospitalListItem(Hospital hospital) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hospital.isOpenNow
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          child: Icon(
            Icons.local_hospital,
            color: hospital.isOpenNow ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          hospital.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hospital.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${hospital.distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: hospital.isOpenNow
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hospital.isOpenNow ? 'Buka' : 'Tutup',
                    style: TextStyle(
                      fontSize: 10,
                      color: hospital.isOpenNow ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hospital.rating != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    hospital.rating!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _showHospitalDetails(hospital),
          icon: const Icon(Icons.info_outline),
        ),
        onTap: () {
          // Move camera to hospital location
          _mapController.move(
            LatLng(hospital.latitude, hospital.longitude),
            15,
          );
        },
      ),
    );
  }
}
