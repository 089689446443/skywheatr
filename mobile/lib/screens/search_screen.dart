import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/location.dart';
import '../services/api_service.dart';
import '../main.dart'; // for themeNotifier
import 'locations_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiService();
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  List<GeoSearchResult> _results = [];
  List<String> _history = [];
  bool _searching = false;
  bool _saving = false;
  String? _error;
  Timer? _debounce;
  int _navIndex = 0; // Search is 0

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _addToHistory(String q) async {
    if (q.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final hist = prefs.getStringList('search_history') ?? [];
    hist.remove(q);
    hist.insert(0, q);
    if (hist.length > 10) hist.removeLast();
    await prefs.setStringList('search_history', hist);
    setState(() { _history = hist; });
  }

  Future<void> _removeFromHistory(String q) async {
    final prefs = await SharedPreferences.getInstance();
    final hist = prefs.getStringList('search_history') ?? [];
    hist.remove(q);
    await prefs.setStringList('search_history', hist);
    setState(() { _history = hist; });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() { _results = []; _error = null; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(value));
  }

  Future<void> _search(String q) async {
    setState(() { _searching = true; _error = null; });
    try {
      final results = await _api.searchLocation(q);
      _addToHistory(q);
      setState(() {
        _results = results;
        _searching = false;
        if (results.isEmpty) _error = 'Tidak ada kota yang ditemukan untuk "$q"';
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Gagal mencari lokasi.';
        _searching = false;
      });
    }
  }

  Future<void> _saveLocation(GeoSearchResult result) async {
    setState(() => _saving = true);
    try {
      final location = result.toLocation();
      await _api.createLocation(location);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${result.name} berhasil disimpan!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Gagal menyimpan lokasi.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Colors.white;
    final subColor = Colors.white70;
    final searchBgColor = Colors.transparent;
    final cardColor = isDark ? const Color(0xFF2C3746).withOpacity(0.85) : const Color(0xFF536474).withOpacity(0.65);
    final plusBgColor = isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.2);

    return Scaffold(
      extendBody: true,
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
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset('assets/ic_back.png', width: 24, height: 24, color: textColor),
                ),
                Expanded(
                  child: Center(
                    child: Text('skywheathr', style: GoogleFonts.manrope(
                      fontSize: 20, fontWeight: FontWeight.w700, color: textColor,
                    )),
                  ),
                ),
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
                          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                        Align(
                          alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
                          child: Icon(
                            isDark ? Icons.nightlight_round : Icons.wb_sunny,
                            color: const Color(0xFFFACC15),
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),

            // ── Search field ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: searchBgColor,
                  borderRadius: BorderRadius.circular(26), // pill shape
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 0.5),
                ),
                child: Row(children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      style: GoogleFonts.inter(fontSize: 15, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search Locate',
                        hintStyle: GoogleFonts.inter(color: textColor.withOpacity(0.8), fontSize: 15),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (v) { if (v.trim().length >= 2) _search(v); },
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        setState(() { _results = []; _error = null; });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.close, color: textColor, size: 16),
                      ),
                    )
                  else 
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.close, color: textColor, size: 16),
                    ), // Placeholder based on mockup even if empty
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Image.asset('assets/ic_search.png', width: 22, height: 22, color: textColor),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // ── Loading & Error ───────────────────────────────────────
            if (_searching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(color: Color(0xFF4A90E2), strokeWidth: 1.5),
              ),
            if (_error != null && !_searching)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(_error!, style: GoogleFonts.inter(color: subColor), textAlign: TextAlign.center),
              ),

            // ── Results or History ───────────────────────────────────────
            Expanded(
              child: AbsorbPointer(
                absorbing: _saving,
                child: _ctrl.text.isEmpty && _history.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final h = _history[index];
                        return ListTile(
                          leading: const Icon(Icons.history, color: Colors.white70),
                          title: Text(h, style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => _removeFromHistory(h),
                          ),
                          onTap: () {
                            _ctrl.text = h;
                            _search(h);
                          },
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      itemCount: _results.length,
                      itemBuilder: (_, i) => _buildResultCard(_results[i], textColor, subColor, cardColor, plusBgColor),
                    ),
              ),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(isDark, textColor, subColor),
    );
  }

  Widget _buildResultCard(GeoSearchResult result, Color textColor, Color subColor, Color cardColor, Color plusBgColor) {
    return GestureDetector(
      onTap: () => _saveLocation(result),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          Image.asset('assets/ic_pin.png', width: 20, height: 20, color: textColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(result.name, style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: textColor,
              )),
              const SizedBox(height: 2),
              Text(
                [if (result.admin1.isNotEmpty && result.admin1 != result.name) result.admin1,
                 if (result.country.isNotEmpty) result.country].join(', '),
                style: GoogleFonts.inter(fontSize: 13, color: subColor),
              ),
            ]),
          ),
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: plusBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Image.asset('assets/ic_plus.png', width: 16, height: 16, color: textColor),
            ),
          ),
        ]),
      ),
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
          // Search (Active)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/ic_search.png', width: 28, height: 28, color: Colors.white),
          ),
          // Home
          IconButton(
            icon: Image.asset('assets/ic_home.png', width: 28, height: 28, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          // Map
          IconButton(
            icon: Icon(Icons.map_outlined, size: 28, color: Colors.white70),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LocationsScreen()));
            },
          ),
        ],
      ),
    );
  }
}
