import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  _NotificationSettingsPageState createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // Per-prayer sound modes
  final Map<String, String> _prayerSoundModes = {
    'Subuh': 'beep',
    'Zohor': 'beep',
    'Asar': 'beep',
    'Maghrib': 'beep',
    'Isyak': 'beep',
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        // Load individual prayer settings
        for (var prayer in _prayerSoundModes.keys) {
          _prayerSoundModes[prayer] =
              prefs.getString('sound_mode_${prayer.toLowerCase()}') ?? 'beep';
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrayerSettings(String prayerName, String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sound_mode_${prayerName.toLowerCase()}', mode);

      setState(() {
        _prayerSoundModes[prayerName] = mode;
      });

      // Recreate notification channels with new sound mode
      debugPrint('🔄 Recreating notification channels for $prayerName: $mode');
      await NotificationService().createNotificationChannels();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tetapan $prayerName disimpan'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }

      debugPrint('✅ Settings saved for $prayerName: $mode');
    } catch (e) {
      debugPrint('❌ Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ralat menyimpan tetapan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Tetapan Notifikasi'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.notifications_active,
                                color: colorScheme.primary,
                                size: 32,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tetapan Bunyi Notifikasi',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Pilih bunyi untuk setiap waktu solat',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Per-Prayer Settings
                    ..._prayerSoundModes.entries.map((entry) {
                      return _buildPrayerSettingCard(
                        prayerName: entry.key,
                        currentMode: entry.value,
                      );
                    }).toList(),

                    SizedBox(height: 16),

                    // Info Card
                    Card(
                      elevation: 1,
                      color: Colors.blue[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nota',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Telefon mesti tidak dalam mod senyap untuk mendengar bunyi. Azan akan main sepenuhnya.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
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

  Widget _buildPrayerSettingCard({
    required String prayerName,
    required String currentMode,
  }) {
    // Get prayer-specific color
    final prayerColors = {
      'Subuh': Colors.blue,
      'Zohor': Colors.amber,
      'Asar': Colors.orange,
      'Maghrib': Colors.deepOrange,
      'Isyak': Colors.indigo,
    };
    final color = prayerColors[prayerName] ?? Colors.grey;

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.access_time, color: color, size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  prayerName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSoundModeChip(
                  prayerName: prayerName,
                  icon: Icons.music_note,
                  label: 'Azan',
                  mode: 'azan',
                  isSelected: currentMode == 'azan',
                  color: Colors.orange,
                ),
                _buildSoundModeChip(
                  prayerName: prayerName,
                  icon: Icons.notifications,
                  label: 'Bunyi',
                  mode: 'beep',
                  isSelected: currentMode == 'beep',
                  color: Colors.blue,
                ),
                _buildSoundModeChip(
                  prayerName: prayerName,
                  icon: Icons.vibration,
                  label: 'Getar',
                  mode: 'vibrate',
                  isSelected: currentMode == 'vibrate',
                  color: Colors.purple,
                ),
                _buildSoundModeChip(
                  prayerName: prayerName,
                  icon: Icons.notifications_off,
                  label: 'Senyap',
                  mode: 'silent',
                  isSelected: currentMode == 'silent',
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundModeChip({
    required String prayerName,
    required IconData icon,
    required String label,
    required String mode,
    required bool isSelected,
    required Color color,
  }) {
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : color),
          SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          _savePrayerSettings(prayerName, mode);
        }
      },
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[800],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
