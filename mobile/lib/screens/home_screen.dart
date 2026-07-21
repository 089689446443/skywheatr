import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import '../models/location.dart';
import '../models/weather_note.dart';
import '../services/api_service.dart';
import '../utils/weather_utils.dart';
import '../main.dart'; // import themeNotifier
import 'locations_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Location> initialLocations;
  final Location? initialPrimaryLocation;
  final WeatherData? initialWeather;
  final String? initialError;

  const HomeScreen({
    super.key,
    this.initialLocations = const [],
    this.initialPrimaryLocation,
    this.initialWeather,
    this.initialError,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _api = ApiService();

  late Location? _primaryLocation;
  late WeatherData? _weather;
  late List<Location> _allLocations;

  bool _loading = false;
  String? _error;
  int _navIndex = 1; // 1 = Home (tengah)

  // Desain Token
  static const _bg = Color(0xFF324154); // Slate blue dari desain
  static const _textMain = Colors.white;
  static const _textSub = Color(0xFFBAC2CB);
  static const _panelBg = Color(0xFF455568);
  static const _bottomNavBg = Color(0xFF405060);

  @override
  void initState() {
    super.initState();
    _primaryLocation = widget.initialPrimaryLocation;
    _weather = widget.initialWeather;
    _allLocations = widget.initialLocations;
    _error = widget.initialError;
  }

  Future<void> _refreshData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final locs = await _api.getAllLocations();
      _allLocations = locs;
      if (locs.isNotEmpty) {
        _primaryLocation = locs.firstWhere((l) => l.isPrimary, orElse: () => locs.first);
        _weather = await _api.fetchWeather(lat: _primaryLocation!.latitude, lon: _primaryLocation!.longitude);
      } else {
        _primaryLocation = null;
        _weather = null;
      }
    } catch (e) {
      _error = e is ApiException ? e.message : 'Gagal memuat data.';
    } finally {
      setState(() => _loading = false);
    }
  }

  void _goToSearch() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    if (added == true) _refreshData();
  }

  void _goToLocations() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LocationsScreen(onChanged: _refreshData)),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgImage = isDark ? 'assets/bg_dark.png' : 'assets/bg.png';

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(bgImage),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: _loading && _weather == null
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _error != null && _weather == null
                    ? _buildError()
                    : _primaryLocation == null
                        ? _buildNoLocation()
                        : Stack(
                            children: [
                              _buildDashboard(),
                              _buildTopBar(),
                            ],
                          ),
          ),

          // Floating Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  // ── DASHBOARD ──────────────────────────────────────────────
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 70, bottom: 120),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeroSection(),
          const SizedBox(height: 40),
          _buildTodaySummary(),
          const SizedBox(height: 16),
          _buildHourlyChart(),
          const SizedBox(height: 24),
          _buildWeeklyForecast(),
          const SizedBox(height: 24),
          _buildExtraStats(),
        ],
      ),
    );
  }

  // ── TOP BAR ────────────────────────────────────────────────
  Widget _buildTopBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        color: isDark ? const Color(0xFF111721).withOpacity(0.95) : _bg.withOpacity(0.95),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _goToLocations,
            child: Image.asset('assets/ic_menu.png', width: 24, height: 24, color: _textMain),
          ),
          Text(
            'skywheathr',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textMain,
            ),
          ),
          // Toggle Switch 
          GestureDetector(
            onTap: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
            },
            child: Container(
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(4),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: Theme.of(context).brightness == Brightness.dark
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Theme.of(context).brightness == Brightness.dark
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Icon(
                      Theme.of(context).brightness == Brightness.dark 
                          ? Icons.nightlight_round 
                          : Icons.wb_sunny,
                      color: const Color(0xFFFACC15),
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ── HERO SECTION ───────────────────────────────────────────
  Widget _buildHeroSection() {
    final w = _weather!;
    final loc = _primaryLocation!;
    final emoji = WeatherUtils.getWeatherEmoji(w.weatherCode);
    final label = WeatherUtils.getWeatherLabel(w.weatherCode);
    final temp = w.temperature.toStringAsFixed(0);

    return Column(
      children: [
        Text(
          loc.name,
          style: GoogleFonts.miriamLibre(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _textMain,
          ),
        ),
        if (loc.country.isNotEmpty)
          Text(
            loc.country,
            style: GoogleFonts.miriamLibre(
              fontSize: 16,
              color: _textSub,
            ),
          ),
        const SizedBox(height: 16),
        // Big Icon
        Image.asset(
          WeatherUtils.getWeatherIconAsset(w.weatherCode), 
          width: 140, 
          height: 140, 
          fit: BoxFit.contain
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              temp,
              style: GoogleFonts.lexend(
                fontSize: 80,
                fontWeight: FontWeight.w300,
                color: _textMain,
                height: 1.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '°C',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: _textMain,
                ),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 18,
            color: _textMain,
          ),
        ),
      ],
    );
  }

  // ── TODAY SUMMARY ──────────────────────────────────────────
  Widget _buildTodaySummary() {
    final today = _weather!.forecast.isNotEmpty ? _weather!.forecast.first : null;
    final min = today?.tempMin?.toStringAsFixed(0) ?? '--';
    final max = today?.tempMax?.toStringAsFixed(0) ?? '--';
    
    // Parse sunrise sunset
    String sunrise = '--.--';
    String sunset = '--.--';
    if (today?.sunrise != null) {
      try {
        sunrise = DateFormat('HH.mm').format(DateTime.parse(today!.sunrise!));
      } catch (_) {}
    }
    if (today?.sunset != null) {
      try {
        sunset = DateFormat('HH.mm').format(DateTime.parse(today!.sunset!));
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Hari ini',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _textMain),
              ),
              const SizedBox(width: 8),
              Text(
                '$min°C / $max°C',
                style: GoogleFonts.inter(fontSize: 14, color: _textSub),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.wb_twilight, color: Color(0xFFFACC15), size: 16),
              const SizedBox(width: 4),
              Text(sunrise, style: GoogleFonts.inter(fontSize: 14, color: _textMain)),
              const SizedBox(width: 16),
              const Icon(Icons.wb_twilight, color: Color(0xFFFACC15), size: 16),
              const SizedBox(width: 4),
              Text(sunset, style: GoogleFonts.inter(fontSize: 14, color: _textMain)),
            ],
          ),
        ],
      ),
    );
  }

  // ── HOURLY LINE CHART ──────────────────────────────────────
  Widget _buildHourlyChart() {
    final hourly = _weather?.hourly ?? [];
    if (hourly.isEmpty) return const SizedBox();

    final items = hourly.take(24).toList();

    return SizedBox(
      height: 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: items.length * 60.0,
          height: 120,
          child: CustomPaint(
            painter: HourlyChartPainter(items: items),
          ),
        ),
      ),
    );
  }

  // ── WEEKLY FORECAST ────────────────────────────────────────
  Widget _buildWeeklyForecast() {
    final daily = _weather?.forecast ?? [];
    if (daily.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perkiraan Cuaca Seminggu',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: _textMain),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(7, (i) {
                if (i >= daily.length) return const SizedBox();
                final d = daily[i];
                String dayName = '--';
                try {
                  final dt = DateTime.parse(d.date);
                dayName = DateFormat('E', 'id_ID').format(dt).toUpperCase();
              } catch (_) {}

              final emoji = WeatherUtils.getWeatherEmoji(d.weatherCode);
              final temp = d.tempMax?.toStringAsFixed(0) ?? '--';

              return Container(
                width: 55,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(dayName, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: _textMain)),
                    const SizedBox(height: 12),
                    Image.asset(WeatherUtils.getWeatherIconAsset(d.weatherCode), width: 36, height: 36),
                    const SizedBox(height: 12),
                    Text('$temp°', style: GoogleFonts.lexend(fontSize: 18, color: _textMain)),
                  ],
                ),
              );
            }),
            ),
          ),
        ],
      ),
    );
  }

  // ── EXTRA STATS ────────────────────────────────────────────
  Widget _buildExtraStats() {
    final w = _weather!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.3) : _panelBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(40), // Pill shape horizontal
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.thermostat, '${w.apparentTemperature?.toStringAsFixed(0) ?? '--'}°C', 'Terasa seperti'),
          _statItem(Icons.water_drop, '${w.relativeHumidity?.toStringAsFixed(0) ?? '--'}%', 'Kelembapan'),
          _statItem(Icons.air, 'Tenaga ${w.windSpeed.toStringAsFixed(0)}', 'S'), // S = wind direction approx
          _statItem(Icons.speed, '1013 hPa', 'Tekanan udara'), // Mock data, OpenMeteo also provides pressure if requested
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _textSub, size: 20),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _textMain)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 9, color: _textSub)),
      ],
    );
  }

  // ── BOTTOM NAV ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2631).withOpacity(0.95) : _bottomNavBg.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(100),
          topRight: Radius.circular(100),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Image.asset('assets/ic_search.png', width: 28, height: 28, color: _navIndex == 0 ? _textMain : _textSub),
            onPressed: () {
              setState(() => _navIndex = 0);
              _goToSearch();
            },
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/ic_home.png', width: 28, height: 28, color: _textMain),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined, size: 28),
            color: _navIndex == 2 ? _textMain : _textSub,
            onPressed: () {
              setState(() => _navIndex = 2);
              _goToLocations();
            },
          ),
        ],
      ),
    );
  }

  // ── ERROR & NO LOCATION ────────────────────────────────────
  Widget _buildNoLocation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 60, color: _textSub),
          const SizedBox(height: 16),
          Text('Belum ada lokasi', style: GoogleFonts.inter(color: _textMain, fontSize: 18)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _goToSearch,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2)),
            child: const Text('Cari Lokasi'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_error ?? 'Terjadi kesalahan', style: GoogleFonts.inter(color: _textMain, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2)),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM PAINTER UNTUK CHART ─────────────────────────────
class HourlyChartPainter extends CustomPainter {
  final List<HourlyForecast> items;
  HourlyChartPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final double stepX = size.width / (items.length - 1);
    
    // Find min and max temp to scale the graph vertically
    double minTemp = items.first.temperature ?? 0;
    double maxTemp = items.first.temperature ?? 0;
    for (var i in items) {
      if (i.temperature! < minTemp) minTemp = i.temperature!;
      if (i.temperature! > maxTemp) maxTemp = i.temperature!;
    }
    
    // Padding vertical
    final double graphTop = 40;
    final double graphBottom = 80; 
    final double graphHeight = graphBottom - graphTop;
    
    double getY(double temp) {
      if (maxTemp == minTemp) return graphTop + graphHeight / 2;
      return graphBottom - ((temp - minTemp) / (maxTemp - minTemp)) * graphHeight;
    }

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final textStyleTime = GoogleFonts.inter(color: const Color(0xFFBAC2CB), fontSize: 11);
    final textStyleTemp = GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600);

    final path = Path();
    final List<Offset> points = [];

    // Hitung titik kordinat
    for (int i = 0; i < items.length; i++) {
      final x = i * stepX;
      final y = getY(items[i].temperature ?? 0);
      points.add(Offset(x, y));
    }

    // Gambar garis (smooth curve)
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        // Control points for smooth bezier curve
        final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Gambar dot dan teks
    for (int i = 0; i < items.length; i++) {
      final p = points[i];
      
      // Draw dotted vertical line down
      final dashPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      
      double dashY = p.dy + 5;
      while (dashY < size.height - 20) {
        canvas.drawLine(Offset(p.dx, dashY), Offset(p.dx, dashY + 3), dashPaint);
        dashY += 6;
      }

      // Draw dot
      canvas.drawCircle(p, 4, dotPaint);

      // Draw temperature text above
      final tempText = TextPainter(
        text: TextSpan(text: '${items[i].temperature?.toStringAsFixed(0)}°c', style: textStyleTemp),
        textDirection: ui.TextDirection.ltr,
      );
      tempText.layout();
      tempText.paint(canvas, Offset(p.dx - tempText.width / 2, p.dy - 20));

      // Draw time text below
      String timeStr = '00.00';
      try {
        timeStr = DateFormat('HH.mm').format(DateTime.parse(items[i].time));
      } catch (_) {}
      
      final timeText = TextPainter(
        text: TextSpan(text: timeStr, style: textStyleTime),
        textDirection: ui.TextDirection.ltr,
      );
      timeText.layout();
      timeText.paint(canvas, Offset(p.dx - timeText.width / 2, size.height - 15));

      // (Emoji drawing in CustomPainter removed to simplify drawing loop)
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
