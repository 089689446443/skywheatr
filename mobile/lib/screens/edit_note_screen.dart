import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_note.dart';
import '../services/api_service.dart';
import '../utils/weather_utils.dart';
import '../widgets/weather_preview_card.dart';

/// Edit Note Screen — Perbarui catatan cuaca yang sudah ada (UPDATE)
class EditNoteScreen extends StatefulWidget {
  final WeatherNote note;

  const EditNoteScreen({super.key, required this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late TextEditingController _titleCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lonCtrl;
  late TextEditingController _activityCtrl;
  late TextEditingController _descCtrl;

  late DateTime _selectedDate;
  late String? _selectedMood;

  // Data cuaca saat ini (dari database)
  late double? _currentTemperature;
  late double? _currentWindSpeed;
  late int? _currentWeatherCode;
  late String? _currentWeatherTime;
  late String? _currentTimezone;

  // Data cuaca baru (dari fetch ulang)
  WeatherData? _newWeatherData;
  bool _isFetchingWeather = false;
  bool _isSaving = false;
  String? _weatherError;

  @override
  void initState() {
    super.initState();
    final note = widget.note;

    _titleCtrl = TextEditingController(text: note.title);
    _locationCtrl = TextEditingController(text: note.location);
    _latCtrl = TextEditingController(text: note.latitude.toString());
    _lonCtrl = TextEditingController(text: note.longitude.toString());
    _activityCtrl = TextEditingController(text: note.activity ?? '');
    _descCtrl = TextEditingController(text: note.description ?? '');

    _selectedDate = DateTime.tryParse(note.noteDate) ?? DateTime.now();
    _selectedMood = note.mood;

    _currentTemperature = note.temperature;
    _currentWindSpeed = note.windSpeed;
    _currentWeatherCode = note.weatherCode;
    _currentWeatherTime = note.weatherTime;
    _currentTimezone = note.timezone;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _activityCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchNewWeather() async {
    final latStr = _latCtrl.text.trim();
    final lonStr = _lonCtrl.text.trim();

    if (latStr.isEmpty || lonStr.isEmpty) {
      setState(() => _weatherError = 'Masukkan latitude dan longitude terlebih dahulu.');
      return;
    }

    final lat = double.tryParse(latStr);
    final lon = double.tryParse(lonStr);

    if (lat == null || lon == null) {
      setState(() => _weatherError = 'Format koordinat tidak valid.');
      return;
    }

    setState(() {
      _isFetchingWeather = true;
      _weatherError = null;
      _newWeatherData = null;
    });

    try {
      final weather = await _apiService.fetchWeather(lat: lat, lon: lon);
      setState(() {
        _newWeatherData = weather;
        // Update data cuaca lokal
        _currentTemperature = weather.temperature;
        _currentWindSpeed = weather.windSpeed;
        _currentWeatherCode = weather.weatherCode;
        _currentWeatherTime = weather.weatherTime;
        _currentTimezone = weather.timezone;
        _isFetchingWeather = false;
      });
    } catch (e) {
      setState(() {
        _weatherError = e is ApiException ? e.message : 'Gagal mengambil data cuaca.';
        _isFetchingWeather = false;
      });
    }
  }

  Future<void> _saveUpdatedNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedNote = WeatherNote(
        id: widget.note.id,
        title: _titleCtrl.text.trim(),
        noteDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        location: _locationCtrl.text.trim(),
        latitude: double.parse(_latCtrl.text.trim()),
        longitude: double.parse(_lonCtrl.text.trim()),
        temperature: _currentTemperature,
        windSpeed: _currentWindSpeed,
        weatherCode: _currentWeatherCode,
        weatherTime: _currentWeatherTime,
        timezone: _currentTimezone,
        mood: _selectedMood,
        activity: _activityCtrl.text.trim().isEmpty ? null : _activityCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );

      final result = await _apiService.updateNote(widget.note.id!, updatedNote);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Catatan berhasil diperbarui di database! ✅'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 700));
        Navigator.pop(context, result);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is ApiException ? e.message : 'Gagal memperbarui catatan.'),
          backgroundColor: const Color(0xFFF87171),
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF38BDF8),
              surface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Edit Catatan Cuaca'),
        backgroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveUpdatedNote,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Simpan'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF38BDF8),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Badge note ID
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Color(0xFFFBBF24), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Mengedit Catatan ID #${widget.note.id}',
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Info Dasar ────────────────────────────────────
            _buildSectionHeader('📝 Informasi Catatan'),

            _buildTextField(
              controller: _titleCtrl,
              label: 'Judul Catatan',
              icon: Icons.title,
              validator: (v) => v!.trim().isEmpty ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF94A3B8), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tanggal Catatan',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14, color: Color(0xFFF8FAFC), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─── Lokasi & Cuaca ────────────────────────────────
            _buildSectionHeader('📍 Lokasi & Data Cuaca'),

            _buildTextField(
              controller: _locationCtrl,
              label: 'Nama Lokasi',
              icon: Icons.location_on_outlined,
              validator: (v) => v!.trim().isEmpty ? 'Nama lokasi wajib diisi' : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _latCtrl,
                    label: 'Latitude',
                    icon: Icons.explore_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    validator: (v) {
                      if (v!.isEmpty) return 'Wajib';
                      if (double.tryParse(v) == null) return 'Angka desimal';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    controller: _lonCtrl,
                    label: 'Longitude',
                    icon: Icons.explore,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    validator: (v) {
                      if (v!.isEmpty) return 'Wajib';
                      if (double.tryParse(v) == null) return 'Angka desimal';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Data cuaca saat ini
            if (_currentTemperature != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Row(
                  children: [
                    Text(
                      WeatherUtils.getWeatherEmoji(_currentWeatherCode),
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Cuaca Tersimpan',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          ),
                          Text(
                            '${WeatherUtils.formatTemperature(_currentTemperature)}  •  ${WeatherUtils.formatWindSpeed(_currentWindSpeed)}',
                            style: const TextStyle(
                              color: Color(0xFFF8FAFC),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            WeatherUtils.getWeatherLabel(_currentWeatherCode),
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // Tombol update cuaca
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isFetchingWeather ? null : _fetchNewWeather,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: _isFetchingWeather
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)))
                    : const Icon(Icons.refresh, size: 18),
                label: Text(
                  _isFetchingWeather ? 'Mengambil Cuaca Baru...' : 'Perbarui Data Cuaca dari API',
                ),
              ),
            ),

            if (_weatherError != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF87171).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF87171).withOpacity(0.3)),
                ),
                child: Text(_weatherError!,
                    style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
              ),

            if (_newWeatherData != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: WeatherPreviewCard(weatherData: _newWeatherData!),
              ),

            const SizedBox(height: 24),

            // ─── Catatan Harian ────────────────────────────────
            _buildSectionHeader('✍️ Catatan Harian'),

            // Mood picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mood Hari Ini',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WeatherUtils.moodOptions.map((mood) {
                    final isSelected = _selectedMood == mood['emoji'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMood = isSelected ? null : mood['emoji']!;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF38BDF8).withOpacity(0.2)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(mood['emoji']!, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 5),
                            Text(
                              mood['label']!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _activityCtrl,
              label: 'Aktivitas (opsional)',
              icon: Icons.directions_run_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _descCtrl,
              label: 'Catatan Tambahan (opsional)',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveUpdatedNote,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)))
                    : const Icon(Icons.save, size: 20),
                label: Text(_isSaving ? 'Menyimpan Perubahan...' : 'Simpan Perubahan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF8FAFC),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Color(0xFFF8FAFC)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      ),
    );
  }
}
