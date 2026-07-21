import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/location.dart';
import '../models/weather_note.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Minimum visual delay so the splash screen isn't just a flash
    final minDelay = Future.delayed(const Duration(milliseconds: 1500));

    Location? primaryLoc;
    WeatherData? weather;
    List<Location> allLocs = [];
    String? errorMsg;

    try {
      final locs = await _api.getAllLocations();
      allLocs = locs;
      
      if (locs.isNotEmpty) {
        primaryLoc = locs.firstWhere((l) => l.isPrimary, orElse: () => locs.first);
        weather = await _api.fetchWeather(lat: primaryLoc.latitude, lon: primaryLoc.longitude);
      }
    } catch (e) {
      errorMsg = e is ApiException ? e.message : 'Gagal memuat data.';
    }

    await minDelay;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
          initialLocations: allLocs,
          initialPrimaryLocation: primaryLoc,
          initialWeather: weather,
          initialError: errorMsg,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgImage = isDark ? 'assets/bg_dark.png' : 'assets/bg.png';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Splash
              Image.asset(
                'assets/logo_splash.png', 
                width: 200, 
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                'skywheathr',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE5D9C5),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF8A9BA8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
