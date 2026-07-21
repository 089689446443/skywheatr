/// Utility untuk mengonversi WMO Weather Code ke label dan emoji
class WeatherUtils {
  /// Konversi kode cuaca WMO ke deskripsi bahasa Indonesia
  static String getWeatherLabel(int? code) {
    if (code == null) return 'Tidak diketahui';
    if (code == 0) return 'Cerah';
    if (code == 1) return 'Sebagian Cerah';
    if (code == 2) return 'Berawan Sebagian';
    if (code == 3) return 'Mendung';
    if (code == 45 || code == 48) return 'Berkabut';
    if (code >= 51 && code <= 57) return 'Gerimis';
    if (code >= 61 && code <= 67) return 'Hujan';
    if (code >= 71 && code <= 77) return 'Bersalju';
    if (code >= 80 && code <= 82) return 'Hujan Lebat';
    if (code == 85 || code == 86) return 'Hujan Salju';
    if (code == 95) return 'Badai Petir';
    if (code == 96 || code == 99) return 'Badai Petir + Es';
    return 'Tidak diketahui';
  }

  /// Konversi kode cuaca WMO ke emoji
  static String getWeatherEmoji(int? code) {
    if (code == null) return '🌡️';
    if (code == 0) return '☀️';
    if (code == 1 || code == 2) return '🌤️';
    if (code == 3) return '☁️';
    if (code == 45 || code == 48) return '🌫️';
    if (code >= 51 && code <= 67) return '🌧️';
    if (code >= 71 && code <= 77) return '❄️';
    if (code >= 80 && code <= 82) return '🌦️';
    if (code >= 95 && code <= 99) return '⛈️';
    return '🌡️';
  }

  /// Konversi kode cuaca WMO ke asset gambar kustom
  static String getWeatherIconAsset(int? code, {bool isNight = false}) {
    if (code == null) return 'assets/weather_partly_cloudy_day.png'; // fallback

    // Badai petir
    if (code >= 95 && code <= 99) {
      return 'assets/weather_thunderstorm.png';
    }

    // Hujan Lebat (80-82)
    if (code >= 80 && code <= 82) {
      return 'assets/weather_heavy_rain.png';
    }

    // Hujan / Gerimis (51-67)
    if (code >= 51 && code <= 67) return 'assets/weather_light_rain.png';
    
    // Salju (71-77)
    if (code >= 71 && code <= 77) return 'assets/weather_light_rain.png'; // placeholder for snow

    // Berkabut (45-48)
    if (code == 45 || code == 48) return 'assets/weather_partly_cloudy_day.png'; // placeholder for fog

    // Mendung penuh
    if (code == 3) return 'assets/weather_partly_cloudy_day.png'; // placeholder for cloud

    // Cerah / Sebagian cerah (0, 1, 2)
    if (code == 0 || code == 1 || code == 2) {
      if (isNight) {
        return 'assets/moon.png';
      } else {
        return 'assets/weather_partly_cloudy_day.png';
      }
    }

    return 'assets/weather_partly_cloudy_day.png';
  }

  /// Daftar mood dengan emoji dan label
  static const List<Map<String, String>> moodOptions = [
    {'emoji': '😊', 'label': 'Senang'},
    {'emoji': '😐', 'label': 'Biasa'},
    {'emoji': '😢', 'label': 'Sedih'},
    {'emoji': '😡', 'label': 'Marah'},
    {'emoji': '😴', 'label': 'Lelah'},
    {'emoji': '😰', 'label': 'Cemas'},
    {'emoji': '🤒', 'label': 'Sakit'},
    {'emoji': '🥳', 'label': 'Gembira'},
  ];

  /// Format suhu menjadi string
  static String formatTemperature(double? temp) {
    if (temp == null) return '-';
    return '${temp.toStringAsFixed(1)}°C';
  }

  /// Format kecepatan angin menjadi string
  static String formatWindSpeed(double? speed) {
    if (speed == null) return '-';
    return '${speed.toStringAsFixed(1)} km/h';
  }

  /// Tentukan warna berdasarkan suhu
  static String getTemperatureCategory(double? temp) {
    if (temp == null) return 'normal';
    if (temp <= 15) return 'cold';
    if (temp <= 25) return 'cool';
    if (temp <= 32) return 'warm';
    return 'hot';
  }
}
