/// Model prakiraan cuaca per jam
class HourlyForecast {
  final String time;
  final double? temperature;
  final int? weatherCode;
  final double? windSpeed;
  final int? precipitationProbability;
  final double? humidity;

  const HourlyForecast({
    required this.time,
    this.temperature,
    this.weatherCode,
    this.windSpeed,
    this.precipitationProbability,
    this.humidity,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: json['time'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble(),
      weatherCode: (json['weather_code'] as num?)?.toInt(),
      windSpeed: (json['wind_speed'] as num?)?.toDouble(),
      precipitationProbability: (json['precipitation_probability'] as num?)?.toInt(),
      humidity: (json['humidity'] as num?)?.toDouble(),
    );
  }
}

/// Model prakiraan cuaca harian
class DailyForecast {
  final String date;
  final double? tempMax;
  final double? tempMin;
  final int? weatherCode;
  final double? precipitation;
  final double? windSpeedMax;
  final double? uvIndexMax;
  final String? sunrise;
  final String? sunset;

  const DailyForecast({
    required this.date,
    this.tempMax,
    this.tempMin,
    this.weatherCode,
    this.precipitation,
    this.windSpeedMax,
    this.uvIndexMax,
    this.sunrise,
    this.sunset,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: json['date'] as String? ?? '',
      tempMax: (json['temp_max'] as num?)?.toDouble(),
      tempMin: (json['temp_min'] as num?)?.toDouble(),
      weatherCode: (json['weather_code'] as num?)?.toInt(),
      precipitation: (json['precipitation'] as num?)?.toDouble(),
      windSpeedMax: (json['wind_speed_max'] as num?)?.toDouble(),
      uvIndexMax: (json['uv_index_max'] as num?)?.toDouble(),
      sunrise: json['sunrise'] as String?,
      sunset: json['sunset'] as String?,
    );
  }
}

/// Data cuaca lengkap dari Open-Meteo (via backend)
class WeatherData {
  final double latitude;
  final double longitude;
  final String timezone;
  final double temperature;
  final double? apparentTemperature;
  final double? relativeHumidity;
  final double windSpeed;
  final double? windDirection;
  final int weatherCode;
  final double? precipitation;
  final double? uvIndex;
  final String weatherTime;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> forecast;

  const WeatherData({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.temperature,
    this.apparentTemperature,
    this.relativeHumidity,
    required this.windSpeed,
    this.windDirection,
    required this.weatherCode,
    this.precipitation,
    this.uvIndex,
    required this.weatherTime,
    this.hourly = const [],
    this.forecast = const [],
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final hourlyList = (json['hourly'] as List<dynamic>? ?? [])
        .map((e) => HourlyForecast.fromJson(e as Map<String, dynamic>))
        .toList();

    final forecastList = (json['forecast'] as List<dynamic>? ?? [])
        .map((e) => DailyForecast.fromJson(e as Map<String, dynamic>))
        .toList();

    return WeatherData(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: json['timezone'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      apparentTemperature: (json['apparent_temperature'] as num?)?.toDouble(),
      relativeHumidity: (json['relative_humidity'] as num?)?.toDouble(),
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 0.0,
      windDirection: (json['wind_direction'] as num?)?.toDouble(),
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      precipitation: (json['precipitation'] as num?)?.toDouble(),
      uvIndex: (json['uv_index'] as num?)?.toDouble(),
      weatherTime: json['weather_time'] as String? ?? '',
      hourly: hourlyList,
      forecast: forecastList,
    );
  }
}
