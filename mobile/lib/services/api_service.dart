import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';
import '../models/weather_note.dart';
import '../models/location.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Service HTTP — semua komunikasi ke Skywheatr Backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _client = http.Client();

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  Future<Map<String, String>> _getHeaders() async {
    final deviceId = await _getDeviceId();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Device-ID': deviceId,
    };
  }

  // ═══════════════════════════════════════════════════════
  // WEATHER
  // ═══════════════════════════════════════════════════════

  /// Ambil cuaca + hourly 24 jam + daily 7 hari
  Future<WeatherData> fetchWeather({required double lat, required double lon}) async {
    final cacheKey = 'weather_cache_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
    final prefs = await SharedPreferences.getInstance();
    
    // Check Local Cache
    final cacheData = prefs.getString(cacheKey);
    final cacheTimestamp = prefs.getInt('${cacheKey}_time');
    WeatherData? cachedWeather;

    if (cacheData != null && cacheTimestamp != null) {
      try {
        final body = jsonDecode(cacheData) as Map<String, dynamic>;
        cachedWeather = WeatherData.fromJson(body['data'] as Map<String, dynamic>);
        
        final now = DateTime.now().millisecondsSinceEpoch;
        // 1 hour = 3600000 milliseconds
        if (now - cacheTimestamp < 3600000) {
          return cachedWeather; // Return instant cache (0 detik)
        }
      } catch (e) {
        // Ignore parse error and proceed to fetch
      }
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/weather?lat=$lat&lon=$lon',
    );
    try {
      final headers = await _getHeaders();
      final res = await _client.get(uri, headers: headers).timeout(ApiConfig.receiveTimeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        // Save to cache
        await prefs.setString(cacheKey, res.body);
        await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
        
        return WeatherData.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ApiException(statusCode: res.statusCode, message: body['message'] as String? ?? 'Error');
    } on ApiException {
      rethrow;
    } catch (e) {
      // Offline Fallback: If no connection, return expired cache if exists
      if (cachedWeather != null) return cachedWeather;
      
      throw ApiException(
        statusCode: 0,
        message: 'Tidak dapat terhubung ke server. Pastikan Anda memiliki koneksi internet.',
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  // GEOCODING — cari lokasi berdasarkan nama kota
  // ═══════════════════════════════════════════════════════

  Future<List<GeoSearchResult>> searchLocation(String query) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/geocode?q=${Uri.encodeComponent(query)}',
    );
    try {
      final headers = await _getHeaders();
      final res = await _client.get(uri, headers: headers).timeout(ApiConfig.receiveTimeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        final list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => GeoSearchResult.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw ApiException(statusCode: res.statusCode, message: body['message'] as String? ?? 'Error');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Gagal mencari lokasi. Periksa koneksi.');
    }
  }

  Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1');
      final res = await _client.get(uri, headers: {
        'User-Agent': 'skywheatr/1.0',
      }).timeout(ApiConfig.receiveTimeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final address = body['address'];
        if (address != null) {
          return address['city'] ?? address['town'] ?? address['county'] ?? address['state'];
        }
      }
    } catch (_) {}
    return null;
  }

  // ═══════════════════════════════════════════════════════
  // LOCATIONS CRUD
  // ═══════════════════════════════════════════════════════

  /// GET /api/locations — ambil semua lokasi tersimpan
  Future<List<Location>> getAllLocations() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/locations');
    try {
      final headers = await _getHeaders();
      final res = await _client.get(uri, headers: headers).timeout(ApiConfig.receiveTimeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        final list = body['data'] as List<dynamic>? ?? [];
        return list.map((e) => Location.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw ApiException(statusCode: res.statusCode, message: body['message'] as String? ?? 'Error');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Tidak dapat terhubung ke server.');
    }
  }

  /// POST /api/locations — tambah lokasi baru
  Future<Location> createLocation(Location location) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/locations');
    try {
      final headers = await _getHeaders();
      final res = await _client
          .post(uri, headers: headers, body: jsonEncode(location.toJson()))
          .timeout(ApiConfig.receiveTimeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if ((res.statusCode == 200 || res.statusCode == 201) && body['success'] == true) {
        return Location.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ApiException(statusCode: res.statusCode, message: body['message'] as String? ?? 'Gagal menyimpan.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Tidak dapat terhubung ke server.');
    }
  }

  /// PUT /api/locations/:id — update nama lokasi
  Future<Location> updateLocation(int id, {required String name, String? country, String? timezone}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/locations/$id');
    try {
      final headers = await _getHeaders();
      final res = await _client
          .put(uri, headers: headers, body: jsonEncode({
            'name': name,
            if (country != null) 'country': country,
            if (timezone != null) 'timezone': timezone,
          }))
          .timeout(ApiConfig.receiveTimeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        return Location.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ApiException(statusCode: res.statusCode, message: body['message'] as String? ?? 'Gagal update.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Tidak dapat terhubung ke server.');
    }
  }

  /// DELETE /api/locations/:id — hapus lokasi
  Future<void> deleteLocation(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/locations/$id');
    try {
      final headers = await _getHeaders();
      final res = await _client.delete(uri, headers: headers).timeout(ApiConfig.receiveTimeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return;
      throw ApiException(statusCode: res.statusCode, message: body['message'] as String? ?? 'Gagal hapus.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Tidak dapat terhubung ke server.');
    }
  }

  /// PATCH /api/locations/:id/primary — set sebagai lokasi utama
  Future<void> setPrimaryLocation(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/locations/$id/primary');
    try {
      final headers = await _getHeaders();
      final res = await _client.patch(uri, headers: headers).timeout(ApiConfig.receiveTimeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return;
      throw ApiException(statusCode: res.statusCode, message: body['message'] as String? ?? 'Gagal set primary.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Tidak dapat terhubung ke server.');
    }
  }
}
