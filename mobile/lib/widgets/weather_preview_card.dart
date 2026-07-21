import 'package:flutter/material.dart';
import '../models/weather_note.dart';
import '../utils/weather_utils.dart';

/// Card preview cuaca sebelum data disimpan (di Add/Edit screen)
class WeatherPreviewCard extends StatelessWidget {
  final WeatherData weatherData;

  const WeatherPreviewCard({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    final emoji = WeatherUtils.getWeatherEmoji(weatherData.weatherCode);
    final label = WeatherUtils.getWeatherLabel(weatherData.weatherCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C4A6E), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF38BDF8).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF38BDF8),
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Data Cuaca dari Open-Meteo API',
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main weather display
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big emoji
              Text(emoji, style: const TextStyle(fontSize: 56)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weatherData.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF8FAFC),
                      height: 1,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (weatherData.apparentTemperature != null)
                    Text(
                      'Terasa ${weatherData.apparentTemperature!.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Detail row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DetailItem(
                icon: '💨',
                label: 'Angin',
                value: WeatherUtils.formatWindSpeed(weatherData.windSpeed),
              ),
              _DetailItem(
                icon: '💧',
                label: 'Kelembapan',
                value: weatherData.relativeHumidity != null
                    ? '${weatherData.relativeHumidity!.toStringAsFixed(0)}%'
                    : '-',
              ),
              _DetailItem(
                icon: '🌐',
                label: 'Zona Waktu',
                value: weatherData.timezone.split('/').last,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Timestamp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  'Diambil: ${weatherData.weatherTime}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF1F5F9),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
