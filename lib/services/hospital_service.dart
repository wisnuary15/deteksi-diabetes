import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Hospital {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? rating;
  final String? phoneNumber;
  final bool isOpenNow;
  final List<String> types;
  final double distance; // dalam kilometer

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.phoneNumber,
    required this.isOpenNow,
    required this.types,
    required this.distance,
  });
  factory Hospital.fromJson(Map<String, dynamic> json, Position userLocation) {
    // Support both Google Places API and Overpass API format
    double lat, lng;
    String name, address;

    // Check if it's Overpass API format
    if (json.containsKey('lat') && json.containsKey('lon')) {
      // Overpass API format
      lat = json['lat'].toDouble();
      lng = json['lon'].toDouble();

      final tags = json['tags'] ?? {};
      name = tags['name'] ?? tags['brand'] ?? tags['amenity'] ?? 'Rumah Sakit';

      // Build address from available tags
      final addressParts = <String>[];
      if (tags['addr:street'] != null) addressParts.add(tags['addr:street']);
      if (tags['addr:housenumber'] != null)
        addressParts.add(tags['addr:housenumber']);
      if (tags['addr:city'] != null) addressParts.add(tags['addr:city']);
      if (tags['addr:state'] != null) addressParts.add(tags['addr:state']);

      address = addressParts.isNotEmpty
          ? addressParts.join(', ')
          : 'Alamat tidak tersedia';
    } else {
      // Google Places API format (fallback)
      final location = json['geometry']['location'];
      lat = location['lat'].toDouble();
      lng = location['lng'].toDouble();
      name = json['name'] ?? 'Rumah Sakit';
      address =
          json['vicinity'] ??
          json['formatted_address'] ??
          'Alamat tidak tersedia';
    }

    // Calculate distance
    final distance =
        Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          lat,
          lng,
        ) /
        1000; // Convert to kilometers

    return Hospital(
      id: json['id']?.toString() ?? json['place_id'] ?? '${lat}_${lng}',
      name: name,
      address: address,
      latitude: lat,
      longitude: lng,
      rating: json['rating']?.toDouble(),
      phoneNumber:
          json['formatted_phone_number'] ??
          json['tags']?['phone'] ??
          json['tags']?['contact:phone'],
      isOpenNow: _parseOpeningHours(json),
      types: _parseTypes(json),
      distance: distance,
    );
  }

  static bool _parseOpeningHours(Map<String, dynamic> json) {
    // Try Google format first
    if (json['opening_hours']?['open_now'] != null) {
      return json['opening_hours']['open_now'];
    }

    // Try Overpass format
    final tags = json['tags'];
    if (tags != null && tags['opening_hours'] != null) {
      // For now, assume most hospitals are open 24/7 or during day hours
      final openingHours = tags['opening_hours'].toString().toLowerCase();
      if (openingHours.contains('24/7') || openingHours.contains('24 hours')) {
        return true;
      }
      // Simple heuristic: if it's during typical day hours (6 AM - 10 PM)
      final now = DateTime.now();
      return now.hour >= 6 && now.hour <= 22;
    }

    // Default: assume open during day hours
    final now = DateTime.now();
    return now.hour >= 6 && now.hour <= 22;
  }

  static List<String> _parseTypes(Map<String, dynamic> json) {
    // Google format
    if (json['types'] != null) {
      return List<String>.from(json['types']);
    }

    // Overpass format
    final tags = json['tags'];
    if (tags != null) {
      final types = <String>[];
      if (tags['amenity'] != null) types.add(tags['amenity']);
      if (tags['healthcare'] != null) types.add(tags['healthcare']);
      if (tags['building'] != null) types.add(tags['building']);
      return types;
    }

    return ['hospital', 'health'];
  }
}

class HospitalService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  // Enable real data by default since Overpass API is free
  static const bool _useMockData = false;

  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return null;

      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Future<List<Hospital>> findNearbyHospitals({
    Position? userLocation,
    int radius = 5000, // radius dalam meter
    int maxResults = 20,
  }) async {
    if (_useMockData) {
      return _getMockHospitals(userLocation);
    }

    try {
      userLocation ??= await getCurrentLocation();
      if (userLocation == null) {
        print('Location access denied or not available, using mock data');
        return _getMockHospitals(null);
      }

      // Create Overpass QL query for hospitals
      final overpassQuery =
          '''
[out:json][timeout:25];
(
  node["amenity"="hospital"](around:$radius,${userLocation.latitude},${userLocation.longitude});
  node["amenity"="clinic"](around:$radius,${userLocation.latitude},${userLocation.longitude});
  node["healthcare"="hospital"](around:$radius,${userLocation.latitude},${userLocation.longitude});
  way["amenity"="hospital"](around:$radius,${userLocation.latitude},${userLocation.longitude});
  way["amenity"="clinic"](around:$radius,${userLocation.latitude},${userLocation.longitude});
  way["healthcare"="hospital"](around:$radius,${userLocation.latitude},${userLocation.longitude});
);
out center meta;
''';

      final response = await http
          .post(
            Uri.parse(_overpassUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'data=${Uri.encodeComponent(overpassQuery)}',
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List? ?? [];

        final hospitals = <Hospital>[];

        for (final element in elements) {
          try {
            // Convert way elements to point using center coordinates
            final hospitalData = <String, dynamic>{...element};

            if (element['type'] == 'way' && element['center'] != null) {
              hospitalData['lat'] = element['center']['lat'];
              hospitalData['lon'] = element['center']['lon'];
            }

            // Only process if we have coordinates
            if (hospitalData['lat'] != null && hospitalData['lon'] != null) {
              final hospital = Hospital.fromJson(hospitalData, userLocation);

              // Filter by name to avoid duplicates and unnamed entries
              if (hospital.name != 'Rumah Sakit' &&
                  hospital.name.isNotEmpty &&
                  !hospitals.any((h) => h.name == hospital.name)) {
                hospitals.add(hospital);
              }
            }
          } catch (e) {
            // Skip invalid entries
            print('Skipping invalid hospital entry: $e');
            continue;
          }
        }

        // Sort by distance and limit results
        hospitals.sort((a, b) => a.distance.compareTo(b.distance));

        final result = hospitals.take(maxResults).toList();

        // If we get very few results, add some mock data to ensure good UX
        if (result.length < 3) {
          print('Adding mock data due to limited Overpass results');
          final mockHospitals = _getMockHospitals(userLocation);
          result.addAll(
            mockHospitals
                .where((mock) => !result.any((real) => real.name == mock.name))
                .take(3),
          );
          result.sort((a, b) => a.distance.compareTo(b.distance));
        }

        return result;
      } else {
        throw Exception(
          'Gagal mengambil data rumah sakit dari Overpass API: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error finding hospitals with Overpass API: $e');

      // Fallback to mock data if Overpass API fails
      print('Falling back to mock data');
      return _getMockHospitals(userLocation);
    }
  }

  List<Hospital> _getMockHospitals(Position? userLocation) {
    // Data mock rumah sakit di Jakarta untuk demo
    final mockLocation =
        userLocation ??
        Position(
          latitude: -6.2088,
          longitude: 106.8456,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

    return [
      Hospital(
        id: '1',
        name: 'RS Cipto Mangunkusumo',
        address: 'Jl. Diponegoro No.71, Kenari, Senen, Jakarta Pusat',
        latitude: -6.1944,
        longitude: 106.8317,
        rating: 4.2,
        phoneNumber: '021-31900001',
        isOpenNow: true,
        types: ['hospital', 'health'],
        distance:
            Geolocator.distanceBetween(
              mockLocation.latitude,
              mockLocation.longitude,
              -6.1944,
              106.8317,
            ) /
            1000,
      ),
      Hospital(
        id: '2',
        name: 'RS Persahabatan',
        address: 'Jl. Persahabatan Raya No.1, Rawamangun, Jakarta Timur',
        latitude: -6.1889,
        longitude: 106.8781,
        rating: 4.1,
        phoneNumber: '021-4891708',
        isOpenNow: true,
        types: ['hospital', 'health'],
        distance:
            Geolocator.distanceBetween(
              mockLocation.latitude,
              mockLocation.longitude,
              -6.1889,
              106.8781,
            ) /
            1000,
      ),
      Hospital(
        id: '3',
        name: 'RS Fatmawati',
        address: 'Jl. RS Fatmawati Raya, Cipete Selatan, Jakarta Selatan',
        latitude: -6.2833,
        longitude: 106.7944,
        rating: 4.0,
        phoneNumber: '021-7501524',
        isOpenNow: true,
        types: ['hospital', 'health'],
        distance:
            Geolocator.distanceBetween(
              mockLocation.latitude,
              mockLocation.longitude,
              -6.2833,
              106.7944,
            ) /
            1000,
      ),
      Hospital(
        id: '4',
        name: 'RS Tarakan',
        address: 'Jl. Kyai Caringin No.7, Cideng, Gambir, Jakarta Pusat',
        latitude: -6.1667,
        longitude: 106.8167,
        rating: 3.9,
        phoneNumber: '021-3447614',
        isOpenNow: false,
        types: ['hospital', 'health'],
        distance:
            Geolocator.distanceBetween(
              mockLocation.latitude,
              mockLocation.longitude,
              -6.1667,
              106.8167,
            ) /
            1000,
      ),
      Hospital(
        id: '5',
        name: 'RS Hermina Kemayoran',
        address: 'Jl. Benyamin Sueb No.5, Kemayoran, Jakarta Pusat',
        latitude: -6.1689,
        longitude: 106.8456,
        rating: 4.3,
        phoneNumber: '021-4208888',
        isOpenNow: true,
        types: ['hospital', 'health'],
        distance:
            Geolocator.distanceBetween(
              mockLocation.latitude,
              mockLocation.longitude,
              -6.1689,
              106.8456,
            ) /
            1000,
      ),
    ]..sort((a, b) => a.distance.compareTo(b.distance));
  }

  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.subLocality}, ${place.locality}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Alamat tidak diketahui';
  }
}
