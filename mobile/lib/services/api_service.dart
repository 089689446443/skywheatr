import 'dart:convert';
import 'package:http/http.dart' as http;
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
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ═══════════════════════════════════════════════════════
  // WEATHER
  // ═══════════════════════════════════════════════════════

  /// Ambil cuaca + hourly 24 jam + daily 7 hari
  Future<WeatherData> fetchWeather({required double lat, required double lon}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/weather?lat=$lat&lon=$lon',
    );
    try {
      final res = await _client.get(uri, headers: _headers).timeout(ApiConfig.receiveTimeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        return WeatherData.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ApiException(statusCode: res.statusCode, message: body['message'] as String? ?? 'Error');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Tidak dapat terhubung ke server. Pastikan backend berjalan.',
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
      final res = await _client.get(uri, headers: _headers).timeout(ApiConfig.receiveTimeout);
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

  // ═══════════════════════════════════════════════════════
  // LOCATIONS CRUD
  // ═══════════════════════════════════════════════════════

  /// GET /api/locations — ambil semua lokasi tersimpan
  Future<List<Location>> getAllLocations() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/locations');
    try {
      final res = await _client.get(uri, headers: _headers).timeout(ApiConfig.receiveTimeout);
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
      final res = await _client
          .post(uri, headers: _headers, body: jsonEncode(location.toJson()))
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
      final res = await _client
          .put(uri, headers: _headers, body: jsonEncode({
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
      final res = await _client.delete(uri, headers: _headers).timeout(ApiConfig.receiveTimeout);
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
      final res = await _client.patch(uri, headers: _headers).timeout(ApiConfig.receiveTimeout);
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
