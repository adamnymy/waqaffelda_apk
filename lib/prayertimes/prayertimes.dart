import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/prayer_times_service.dart';
import 'package:intl/intl.dart';
import '../widgets/google_maps_location_picker.dart';
import '../navbar.dart';
import '../homepage/homepage.dart';
import '../quran/quranpage.dart';
import '../setting/settingpage.dart';
import 'package:hijri/hijri_calendar.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({Key? key}) : super(key: key);

  @override
  _PrayerTimesPageState createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  String hijriDate = '';
  List<Map<String, dynamic>> prayerTimes = [];
  bool isLoading = true;
  String errorMessage = '';
  String locationName = 'Loading...';
  String currentDate = '';
  Map<String, String>? nextPrayer;

  String? selectedLocationName;
  double? selectedLatitude;
  double? selectedLongitude;
  String? selectedCity;
  Map<String, dynamic>? selectedCoordinates;

  final List<Map<String, dynamic>> malaysianCities = [
    {'name': 'Kuala Lumpur', 'lat': 3.139, 'lng': 101.6869},
    {'name': 'Johor Bahru', 'lat': 1.4927, 'lng': 103.7414},
    {'name': 'Penang', 'lat': 5.4164, 'lng': 100.3327},
    {'name': 'Kota Kinabalu', 'lat': 5.9804, 'lng': 116.0735},
    {'name': 'Kuching', 'lat': 1.5533, 'lng': 110.3592},
    {'name': 'Shah Alam', 'lat': 3.0733, 'lng': 101.5185},
    {'name': 'Melaka', 'lat': 2.2055, 'lng': 102.2502},
    {'name': 'Ipoh', 'lat': 4.5975, 'lng': 101.0901},
    {'name': 'Seremban', 'lat': 2.7297, 'lng': 101.9381},
    {'name': 'Petaling Jaya', 'lat': 3.1073, 'lng': 101.6067},
    {'name': 'Klang', 'lat': 3.0319, 'lng': 101.4443},
    {'name': 'Kajang', 'lat': 2.9929, 'lng': 101.7904},
    {'name': 'Ampang', 'lat': 3.1478, 'lng': 101.7596},
    {'name': 'Subang Jaya', 'lat': 3.1478, 'lng': 101.5867},
    {'name': 'Use Current Location', 'lat': null, 'lng': null},
  ];

  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _setCurrentDate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setCurrentDate() {
    currentDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
    hijriDate = "24 Rabiulawal 1447";
  }

  String _getHijriMonthName(int month) {
    switch (month) {
      case 1:
        return "Rabiulawal";
      case 2:
        return "Rabiulakhir";
      case 3:
        return "Jamadilawal";
      case 4:
        return "Jamadilakhir";
      case 5:
        return "Rejab";
      case 6:
        return "Syaaban";
      case 7:
        return "Ramadan";
      case 8:
        return "Syawal";
      case 9:
        return "Zulkaedah";
      case 10:
        return "Zulhijjah";
      case 11:
        return "Muharam";
      case 12:
        return "Safar";
      default:
        return "";
    }
  }

  Future<void> _loadPrayerTimes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      Map<String, dynamic>? apiData;

      if (selectedLatitude != null && selectedLongitude != null) {
        apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
          selectedLatitude!,
          selectedLongitude!,
        );
        locationName = selectedLocationName ?? 'Selected Location';
      } else {
        Position? position = await PrayerTimesService.getCurrentLocation();

        if (position != null) {
          apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
            position.latitude,
            position.longitude,
          );
          locationName = await PrayerTimesService.getLocationName(
            position.latitude,
            position.longitude,
          );
        } else {
          apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
            3.139,
            101.6869,
          );
          locationName = 'Kuala Lumpur, Malaysia';
        }
      }

      if (apiData != null) {
        final parsedTimes = PrayerTimesService.parsePrayerTimes(apiData);
        nextPrayer = PrayerTimesService.getNextPrayer(parsedTimes);
        if (mounted) {
          setState(() {
            prayerTimes = parsedTimes
                .map(
                  (prayer) => {
                    ...prayer,
                    'icon': _getIconFromString(prayer['icon']),
                    'color': Color(prayer['color']),
                  },
                )
                .toList();
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage =
                'Failed to load prayer times. Please check your internet connection.';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading prayer times: $e';
          isLoading = false;
        });
      }
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.map,
                      color: Color(0xFF2E7D32),
                    ),
                    title: const Text(
                      'Pick from Map',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Choose any location using Google Maps',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _openGoogleMapsPicker();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.my_location,
                      color: Color(0xFF2E7D32),
                    ),
                    title: const Text(
                      'Use Current Location',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Get prayer times for your current location',
                    ),
                    onTap: () {
                      setState(() {
                        selectedCity = null;
                        selectedCoordinates = null;
                      });
                      Navigator.pop(context);
                      _loadPrayerTimes();
                    },
                  ),
                  const Divider(),
                  ...malaysianCities
                      .map(
                        (city) => ListTile(
                          leading: const Icon(
                            Icons.location_city,
                            color: Color(0xFF2E7D32),
                          ),
                          title: Text(
                            city['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text('${city['lat']}, ${city['lng']}'),
                          onTap: () {
                            setState(() {
                              selectedCity = city['name'];
                              selectedCoordinates = {
                                'lat': city['lat'],
                                'lng': city['lng'],
                              };
                            });
                            Navigator.pop(context);
                            _loadPrayerTimes();
                          },
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGoogleMapsPicker() {
    double? initialLat = selectedCoordinates?['lat'];
    double? initialLng = selectedCoordinates?['lng'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OpenStreetMapLocationPicker(
          initialLatitude: initialLat,
          initialLongitude: initialLng,
          onLocationSelected: (lat, lng, address) {
            setState(() {
              selectedCity = address;
              selectedCoordinates = {'lat': lat, 'lng': lng};
            });
            _loadPrayerTimes();
          },
        ),
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'wb_twilight':
        return Icons.wb_twilight;
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'wb_cloudy':
        return Icons.wb_cloudy;
      case 'brightness_3':
        return Icons.brightness_3;
      case 'brightness_2':
        return Icons.brightness_2;
      default:
        return Icons.access_time;
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const Homepage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const QuranPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const SettingsPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Prayer Times',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            )
          : errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Prayer Times',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFF2E7D32),
                                      size: 24,
                                    ),
                                    onPressed: _showLocationPicker,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      color: Color(0xFF2E7D32),
                                      size: 24,
                                    ),
                                    onPressed: _loadPrayerTimes,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index >= prayerTimes.length) return null;
                          return _buildPrayerTimeCard(prayerTimes[index]);
                        }, childCount: prayerTimes.length),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildQiblaCard(),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ],
                ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locationName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentDate,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hijriDate,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          if (nextPrayer != null && nextPrayer!['time'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next Prayer: ${nextPrayer!['name'] ?? 'Unknown'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    nextPrayer!['time'] ?? '--:--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeCard(Map<String, dynamic> prayer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: prayer['isPassed'] ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              prayer['isPassed']
                  ? Colors.grey.withOpacity(0.2)
                  : prayer['color'].withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  prayer['isPassed']
                      ? Colors.grey.withOpacity(0.1)
                      : prayer['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              prayer['icon'],
              color: prayer['isPassed'] ? Colors.grey : prayer['color'],
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayer['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        prayer['isPassed']
                            ? Colors.grey
                            : const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  prayer['arabic'],
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            prayer['time'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: prayer['isPassed'] ? Colors.grey : prayer['color'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF36F21).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.explore,
              color: Color(0xFFF36F21),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qibla Direction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Find the direction to Mecca',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFF36F21),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPrayerTimes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}