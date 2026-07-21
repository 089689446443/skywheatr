/// Model lokasi tersimpan — sesuai tabel locations di SQLite
class Location {
  final int? id;
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final String timezone;
  final bool isPrimary;
  final String? createdAt;

  const Location({
    this.id,
    required this.name,
    this.country = '',
    required this.latitude,
    required this.longitude,
    this.timezone = '',
    this.isPrimary = false,
    this.createdAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      country: json['country'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: json['timezone'] as String? ?? '',
      isPrimary: (json['is_primary'] as int? ?? 0) == 1,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
  };

  /// Nama tampilan: "Jakarta, Indonesia"
  String get displayName => country.isNotEmpty ? '$name, $country' : name;

  Location copyWith({
    int? id,
    String? name,
    String? country,
    double? latitude,
    double? longitude,
    String? timezone,
    bool? isPrimary,
    String? createdAt,
  }) =>
      Location(
        id: id ?? this.id,
        name: name ?? this.name,
        country: country ?? this.country,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        timezone: timezone ?? this.timezone,
        isPrimary: isPrimary ?? this.isPrimary,
        createdAt: createdAt ?? this.createdAt,
      );
}

/// Hasil pencarian lokasi dari Open-Meteo Geocoding API
class GeoSearchResult {
  final String name;
  final String country;
  final String countryCode;
  final String admin1; // Provinsi
  final double latitude;
  final double longitude;
  final String timezone;

  const GeoSearchResult({
    required this.name,
    this.country = '',
    this.countryCode = '',
    this.admin1 = '',
    required this.latitude,
    required this.longitude,
    this.timezone = '',
  });

  factory GeoSearchResult.fromJson(Map<String, dynamic> json) {
    return GeoSearchResult(
      name: json['name'] as String? ?? '',
      country: json['country'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      admin1: json['admin1'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: json['timezone'] as String? ?? '',
    );
  }

  String get displayName {
    final parts = [name];
    if (admin1.isNotEmpty && admin1 != name) parts.add(admin1);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  /// Konversi ke Location untuk disimpan
  Location toLocation() => Location(
    name: name,
    country: country,
    latitude: latitude,
    longitude: longitude,
    timezone: timezone,
  );
}
