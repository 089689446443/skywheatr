import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_note.dart';
import '../utils/weather_utils.dart';
import '../screens/detail_screen.dart';

/// Card catatan cuaca untuk ditampilkan di Home Screen
class NoteCard extends StatelessWidget {
  final WeatherNote note;
  final VoidCallback onDeleted;

  const NoteCard({
    super.key,
    required this.note,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final weatherEmoji = WeatherUtils.getWeatherEmoji(note.weatherCode);
    final weatherLabel = WeatherUtils.getWeatherLabel(note.weatherCode);
    final formattedDate = _formatDate(note.noteDate);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B),
              const Color(0xFF0F172A).withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF334155),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color(0xFF38BDF8).withOpacity(0.1),
            onTap: () => _openDetail(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row atas: Weather emoji + judul + tanggal
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weather Icon Container
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF38BDF8).withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            weatherEmoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF8FAFC),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    note.location,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Tanggal di kanan
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (note.mood != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                note.mood!,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFF1E293B), height: 1),
                  const SizedBox(height: 12),

                  // Row bawah: suhu, angin, kondisi
                  Row(
                    children: [
                      _InfoChip(
                        icon: '🌡️',
                        label: WeatherUtils.formatTemperature(note.temperature),
                        color: const Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: '💨',
                        label: WeatherUtils.formatWindSpeed(note.windSpeed),
                        color: const Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: weatherEmoji,
                        label: weatherLabel,
                        color: const Color(0xFF818CF8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(note: note, onDeleted: onDeleted),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
