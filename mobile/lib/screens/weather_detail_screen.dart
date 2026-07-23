import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/weather_note.dart';
import '../utils/weather_utils.dart';
import '../models/location.dart';

class WeatherDetailScreen extends StatelessWidget {
  final Location location;
  final DailyForecast daily;
  final List<HourlyForecast> hourlyData;

  const WeatherDetailScreen({
    super.key,
    required this.location,
    required this.daily,
    required this.hourlyData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgImage = isDark ? 'assets/bg_dark.png' : 'assets/bg.png';
    final textColor = Colors.white;

    String dayName = '';
    String fullDate = '';
    try {
      final dt = DateTime.parse(daily.date);
      dayName = DateFormat('EEEE', 'id_ID').format(dt);
      fullDate = DateFormat('dd MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFF324154),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bgImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Image.asset('assets/ic_back.png', width: 24, height: 24, color: textColor),
                        ),
                      ),
                      Center(
                        child: Column(
                          children: [
                            Text(dayName, style: GoogleFonts.manrope(
                              fontSize: 20, fontWeight: FontWeight.w700, color: textColor,
                            )),
                            Text(fullDate, style: GoogleFonts.inter(
                              fontSize: 12, color: const Color(0xFFBAC2CB),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Header Summary
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C3542) : const Color(0xFF4D5B6E).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(Icons.thermostat, '${daily.tempMin?.toStringAsFixed(0) ?? '-'}° / ${daily.tempMax?.toStringAsFixed(0) ?? '-'}°', 'Suhu'),
                      _buildSummaryItem(Icons.water_drop, '${daily.precipitation?.toStringAsFixed(1) ?? '0'} mm', 'Hujan'),
                      _buildSummaryItem(Icons.wb_twilight, _formatTime(daily.sunrise), 'Terbit'),
                      _buildSummaryItem(Icons.nights_stay, _formatTime(daily.sunset), 'Terbenam'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Hourly List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 40, top: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: hourlyData.length,
                    itemBuilder: (context, index) {
                      final item = hourlyData[index];
                      return _buildHourlyCard(item, context, isDark);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '--:--';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(dateStr).toLocal());
    } catch (_) {
      return '--:--';
    }
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFBAC2CB), size: 24),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFBAC2CB))),
      ],
    );
  }

  Widget _buildHourlyCard(HourlyForecast item, BuildContext context, bool isDark) {
    String time = '--:--';
    bool isNightIcon = false;
    try {
      final dt = DateTime.parse(item.time).toLocal();
      time = DateFormat('HH:mm').format(dt);
      isNightIcon = dt.hour < 5 || dt.hour > 18;
    } catch (_) {}

    final asset = WeatherUtils.getWeatherIconAsset(item.weatherCode, isNight: isNightIcon);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222934).withOpacity(0.8) : const Color(0xFF3F4C5E).withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 50,
            child: Text(time, style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          // Icon
          Builder(
            builder: (context) {
              if (asset == 'draw_sun') {
                return Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFE082), Color(0xFFFF8F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              }
              return Image.asset(asset, width: 36, height: 36);
            }
          ),
          const SizedBox(width: 16),
          // Temp
          SizedBox(
            width: 50,
            child: Text('${item.temperature?.toStringAsFixed(0) ?? '-'}°C', style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
          // Divider
          Container(
            height: 30, width: 1,
            color: Colors.white.withOpacity(0.1),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          // Extra Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSmallInfo(Icons.water_drop, 'Kelembaban', '${item.humidity?.toStringAsFixed(0) ?? '-'}%'),
                const SizedBox(height: 4),
                _buildSmallInfo(Icons.umbrella, 'Hujan', '${item.precipitationProbability ?? '0'}%'),
                const SizedBox(height: 4),
                _buildSmallInfo(Icons.wb_sunny, 'UV Index', '${item.uvIndex?.toStringAsFixed(1) ?? '0'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFFBAC2CB)),
        const SizedBox(width: 4),
        Text('$label:', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFBAC2CB))),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}
