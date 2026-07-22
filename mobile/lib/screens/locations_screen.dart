import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/location.dart';
import '../models/weather_note.dart';
import '../services/api_service.dart';
import '../utils/weather_utils.dart';
import '../main.dart';
import 'search_screen.dart';
class LocationsScreen extends StatefulWidget {
  final VoidCallback? onChanged;
  const LocationsScreen({super.key, this.onChanged});
  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;
  List<Location> _locations = [];
  Map<int, WeatherData?> _weathers = {};
  int? _expandedLocId;

  static const _bg      = Color(0xFF0D0F1A);
  static const _surface = Color(0xFF13162A);
  static const _card    = Color(0xFF181C30);
  static const _amber   = Color(0xFFE8914A);
  static const _blue    = Color(0xFF4A90E2);
  static const _white   = Color(0xFFFFFFFF);
  static const _sub     = Color(0xFF8A8FA8);
  static const _border  = Color(0xFF252A45);

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() { _loading = true; _error = null; });
    try {
      final locs = await _api.getAllLocations();
      setState(() { _locations = locs; _loading = false; });
      // Fetch cuaca untuk setiap lokasi (background)
      for (final loc in locs) {
        if (loc.id != null) _fetchWeatherForLocation(loc);
      }
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Tidak dapat terhubung ke server.';
        _loading = false;
      });
    }
  }

  Future<void> _fetchWeatherForLocation(Location loc) async {
    try {
      final w = await _api.fetchWeather(lat: loc.latitude, lon: loc.longitude);
      if (mounted) setState(() => _weathers[loc.id!] = w);
    } catch (_) {}
  }

  Future<void> _setPrimary(Location loc) async {
    if (loc.id == null) return;
    try {
      await _api.setPrimaryLocation(loc.id!);
      widget.onChanged?.call();
      _loadLocations();
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Gagal mengubah lokasi utama.');
    }
  }

  Future<void> _delete(Location loc) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF4A5568).withOpacity(0.95) : const Color(0xFF5A6B7C).withOpacity(0.95);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Locate?', style: GoogleFonts.manrope(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18,
        )),
        content: Text(
          'Lokasi "${loc.name}" akan di hapus dari\n"Saved Located"',
          style: GoogleFonts.manrope(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.manrope(
              color: const Color(0xFFE53E3E), fontWeight: FontWeight.w700,
            )),
          ),
        ],
      ),
    );
    if (ok != true || loc.id == null) return;
    try {
      await _api.deleteLocation(loc.id!);
      widget.onChanged?.call();
      _loadLocations();
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Gagal menghapus.');
    }
  }

  Future<void> _editName(Location loc) async {
    if (loc.id == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF4A5568).withOpacity(0.95) : const Color(0xFF5A6B7C).withOpacity(0.95);
    
    final parts = loc.name.split('|');
    final actualCity = parts[0];
    final currentAlias = parts.length > 1 ? parts[1] : '';
    
    final ctrl = TextEditingController(text: currentAlias);
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Center(
          child: Text('Tambah Catatan / Alias', style: GoogleFonts.manrope(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18,
          )),
        ),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Contoh: Rumah, Kantor',
            hintStyle: GoogleFonts.manrope(color: Colors.white30),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: Colors.white, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: Colors.white, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Save', style: GoogleFonts.manrope(
              color: Colors.white, fontWeight: FontWeight.w600,
            )),
          ),
        ],
      ),
    );
    if (ok != true) return; // user can clear alias by saving empty
    try {
      final newName = '${actualCity}|${ctrl.text.trim()}';
      await _api.updateLocation(loc.id!, name: newName, country: loc.country);
      widget.onChanged?.call();
      _loadLocations();
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Gagal mengubah nama.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: _white)),
      backgroundColor: const Color(0xFFF87171).withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  void _goToSearch() async {
    final added = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
    if (added == true) {
      widget.onChanged?.call();
      _loadLocations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Colors.white; // User requested white text for head navbar
    final subColor = isDark ? Colors.white70 : const Color(0xFFE0E0E0);

    return Scaffold(
      extendBody: true, // This allows the body background to show under the rounded corners of the bottom nav
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(isDark ? 'assets/bg_dark.png' : 'assets/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            // ── Top bar ────────────────────────────────────────
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
                    child: Text('skywheathr', style: GoogleFonts.manrope(
                      fontSize: 20, fontWeight: FontWeight.w700, color: textColor,
                    )),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (context, snapshot) {
                            return Text(
                              DateFormat('HH.mm').format(DateTime.now()),
                              style: GoogleFonts.inter(fontSize: 15, color: textColor, fontWeight: FontWeight.w500),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        // Toggle Switch
                        GestureDetector(
                          onTap: () {
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
                ],
              ),
            ),
            // Title Header
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Text('Saved Located', style: GoogleFonts.manrope(
                    fontSize: 22, fontWeight: FontWeight.w800, color: textColor,
                  )),
                  Text('${_locations.length} locate', style: GoogleFonts.manrope(
                    fontSize: 14, color: subColor,
                  )),
                ],
              ),
            ),

          // ── Content ────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFFFACC15), strokeWidth: 1.5,
                  ))
                : _error != null
                    ? _buildError()
                    : _locations.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
          ),
        ]),
        ), // closes SafeArea
      ), // closes Container
      bottomNavigationBar: _buildBottomNav(isDark, textColor, subColor),
    );
  }

  Widget _buildBottomNav(bool isDark, Color textColor, Color subColor) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2631).withOpacity(0.95) : const Color(0xFF405060).withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(100),
          topRight: Radius.circular(100),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Search
          IconButton(
            icon: Image.asset('assets/ic_search.png', width: 28, height: 28, color: Colors.white70),
            onPressed: _goToSearch,
          ),
          // Home
          IconButton(
            icon: Image.asset('assets/ic_home.png', width: 28, height: 28, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          // Map (Active)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.map_outlined, size: 28, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadLocations,
      color: _blue,
      backgroundColor: _card,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
        itemCount: _locations.length,
        itemBuilder: (_, i) => _buildLocationCard(_locations[i]),
      ),
    );
  }

  Widget _buildLocationCard(Location loc) {
    final weather = _weathers[loc.id];
    final temp = weather != null ? '${weather.temperature.toStringAsFixed(0)}°C' : '--';
    final label = weather != null ? WeatherUtils.getWeatherLabel(weather.weatherCode) : 'Memuat...';

    // Map weather code to our custom assets
    String weatherIconAsset = 'assets/weather_partly_cloudy_day.png'; // default
    if (weather != null) {
      if (weather.weatherCode == 0) weatherIconAsset = 'assets/weather_partly_cloudy_day.png'; // clear day fallback
      else if (weather.weatherCode >= 1 && weather.weatherCode <= 3) weatherIconAsset = 'assets/weather_partly_cloudy_day.png';
      else if (weather.weatherCode >= 51 && weather.weatherCode <= 67) weatherIconAsset = 'assets/weather_light_rain.png';
      else if (weather.weatherCode >= 71 && weather.weatherCode <= 77) weatherIconAsset = 'assets/weather_light_rain.png'; // snow placeholder
      else if (weather.weatherCode >= 95) weatherIconAsset = 'assets/weather_thunder.png';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C3542) : const Color(0xFF4D5B6E).withOpacity(0.9);
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.15);
    final bottomBarBg = isDark ? const Color(0xFF222934) : const Color(0xFF3F4C5E).withOpacity(0.9);

    final parts = loc.name.split('|');
    final actualCity = parts[0];
    final customAlias = parts.length > 1 ? parts[1] : '';
    final displayName = customAlias.isNotEmpty ? '$actualCity - $customAlias' : actualCity;

    Widget innerCard = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!loc.isPrimary) {
          setState(() {
            _expandedLocId = _expandedLocId == loc.id ? null : loc.id;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!loc.isPrimary) {
                setState(() {
                  _expandedLocId = _expandedLocId == loc.id ? null : loc.id;
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon & Temp
                  Column(
                    children: [
                    Image.asset(weatherIconAsset, width: 56, height: 56),
                    const SizedBox(height: 6),
                    Text(temp, style: GoogleFonts.manrope(
                      fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white,
                    )),
                  ],
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: GoogleFonts.manrope(
                        fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(loc.country.isNotEmpty ? loc.country : 'Indonesia', style: GoogleFonts.manrope(
                        fontSize: 12, color: Colors.white.withOpacity(0.85),
                      )),
                      const SizedBox(height: 6),
                      Text(label, style: GoogleFonts.manrope(
                        fontSize: 14, color: Colors.white,
                      )),
                    ],
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _editName(loc),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white, width: 1.2),
                        ),
                        child: const Center(
                          child: Icon(Icons.draw, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _delete(loc),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white, width: 1.2),
                        ),
                        child: const Center(
                          child: Icon(Icons.delete_outline, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          ),
          if (!loc.isPrimary && _expandedLocId == loc.id)
            GestureDetector(
              onTap: () => _setPrimary(loc),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: bottomBarBg,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_outline, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text('set untuk di tampilkan di dashboard', style: GoogleFonts.manrope(
                      fontSize: 12, color: Colors.white70,
                    )),
                  ],
                ),
              ),
            )
        ],
      ),
    ));

    if (loc.isPrimary) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22), // slightly larger than 20
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2), // tiny gap
                child: innerCard,
              ),
            ),
            Positioned(
              top: 2,
              child: const Icon(Icons.star, color: Colors.white, size: 18),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: innerCard,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🗺️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text('Belum Ada Lokasi Tersimpan', style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w700, color: _white,
          )),
          const SizedBox(height: 10),
          Text('Tambahkan lokasi melalui fitur pencarian.', style: GoogleFonts.inter(color: _sub)),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _goToSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF2C6AB5)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: _blue.withOpacity(0.35), blurRadius: 18,
                )],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Cari Lokasi', style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600,
                  )),
                ],
              ),
            ),
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
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 48),
          const SizedBox(height: 16),
          Text(_error!, style: GoogleFonts.inter(color: _sub), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _loadLocations,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _surface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _blue.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.refresh, color: _blue, size: 16),
                const SizedBox(width: 8),
                Text('Coba Lagi', style: GoogleFonts.inter(color: _blue, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
