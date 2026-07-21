/// Konfigurasi URL Backend Skywheatr API
///
/// Development (lokal) : baseUrl = 'http://localhost:3000'
/// Production (hosting): baseUrl = URL Render setelah deploy
///
/// Ganti [_productionUrl] dengan URL Render Anda setelah deploy,
/// lalu ubah [_isProduction] menjadi true sebelum build web.

class ApiConfig {
  // ── Toggle ini saat akan build untuk hosting ──────────────
  static const bool _isProduction = false;

  // ── Ganti URL ini setelah backend di-deploy ke Render ─────
  static const String _productionUrl = 'https://skywheatr-api.onrender.com';
  static const String _localUrl      = 'http://192.168.124.90:3000';

  // ── Digunakan oleh seluruh app ─────────────────────────────
  static const String baseUrl = _isProduction ? _productionUrl : _localUrl;

  static const Duration receiveTimeout = Duration(seconds: 20);
}
