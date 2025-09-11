import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/prayer_times_service.dart';
import 'package:intl/intl.dart';
import '../widgets/google_maps_location_picker.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({Key? key}) : super(key: key);

  @override
  _PrayerTimesPageState createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  List<Map<String, dynamic>> prayerTimes = [];
  bool isLoading = true;
  String errorMessage = '';
  String locationName = 'Loading...';
  String currentDate = '';
  Map<String, String>? nextPrayer;
  
  // Location selection variables
  String? selectedLocationName;
  double? selectedLatitude;
  double? selectedLongitude;
  String? selectedCity;
  Map<String, dynamic>? selectedCoordinates;
  
  // Popular Malaysian cities
  final List<Map<String, dynamic>> malaysianCities = [
    {'name': 'Kuala Lumpur', 'lat': 3.139, 'lng': 101.6869},
    {'name': 'Johor Bahru', 'lat': 1.4927, 'lng': 103.7414},
    {'name': 'Penang', 'lat': 5.4164, 'lng': 100.3327},
    {'name': 'Kota Kinabalu', 'lat': 5.9804, 'lng': 116.0735},
    {'name': 'Kuching', 'lat': 1.5533, 'lng': 110.3592},
    {'name': 'Shah Alam', 'lat': 3.0733, 'lng': 101.5185},
    {'name': 'Malacca', 'lat': 2.2055, 'lng': 102.2502},
    {'name': 'Ipoh', 'lat': 4.5975, 'lng': 101.0901},
    {'name': 'Seremban', 'lat': 2.7297, 'lng': 101.9381},
    {'name': 'Petaling Jaya', 'lat': 3.1073, 'lng': 101.6067},
    {'name': 'Klang', 'lat': 3.0319, 'lng': 101.4443},
    {'name': 'Kajang', 'lat': 2.9929, 'lng': 101.7904},
    {'name': 'Ampang', 'lat': 3.1478, 'lng': 101.7596},
    {'name': 'Subang Jaya', 'lat': 3.1478, 'lng': 101.5867},
    {'name': 'Use Current Location', 'lat': null, 'lng': null},
  ];

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _setCurrentDate();
  }

  void _setCurrentDate() {
    currentDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
  }

  Future<void> _loadPrayerTimes() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      Map<String, dynamic>? apiData;
      
      // Check if user has selected a specific location
      if (selectedLatitude != null && selectedLongitude != null) {
        // Use user-selected location
        apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
          selectedLatitude!, 
          selectedLongitude!
        );
        locationName = selectedLocationName ?? 'Selected Location';
      } else {
        // Try to get current location first
        Position? position = await PrayerTimesService.getCurrentLocation();
        
        if (position != null) {
          // Use current GPS location
          apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
            position.latitude, 
            position.longitude
          );
          locationName = await PrayerTimesService.getLocationName(
            position.latitude, 
            position.longitude
          );
        } else {
          // Fallback to Kuala Lumpur with Malaysia-specific method
          apiData = await PrayerTimesService.getPrayerTimesForMalaysia(
            3.139, // Kuala Lumpur latitude
            101.6869 // Kuala Lumpur longitude
          );
          locationName = 'Kuala Lumpur, Malaysia';
        }
      }

      if (apiData != null) {
        final parsedTimes = PrayerTimesService.parsePrayerTimes(apiData);
        nextPrayer = PrayerTimesService.getNextPrayer(parsedTimes);
        
        setState(() {
          prayerTimes = parsedTimes.map((prayer) => {
            ...prayer,
            'icon': _getIconFromString(prayer['icon']),
            'color': Color(prayer['color']),
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load prayer times. Please check your internet connection.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading prayer times: $e';
        isLoading = false;
      });
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
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 24),
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
            
            // Location list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Google Maps picker option
                  ListTile(
                    leading: const Icon(Icons.map, color: Color(0xFF2E7D32)),
                    title: const Text(
                      'Pick from Map',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Choose any location using Google Maps'),
                    onTap: () {
                      Navigator.pop(context);
                      _openGoogleMapsPicker();
                    },
                  ),
                  const Divider(),
                  
                  // Current location option
                  ListTile(
                    leading: const Icon(Icons.my_location, color: Color(0xFF2E7D32)),
                    title: const Text(
                      'Use Current Location',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Get prayer times for your current location'),
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
                  
                  // Malaysian cities
                  ...malaysianCities.map((city) => ListTile(
                    leading: const Icon(Icons.location_city, color: Color(0xFF2E7D32)),
                    title: Text(
                      city['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
                  )).toList(),
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
              selectedCoordinates = {
                'lat': lat,
                'lng': lng,
              };
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Prayer Times',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on, color: Colors.white),
            onPressed: _showLocationPicker,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPrayerTimes,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading prayer times...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            )
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPrayerTimes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location and Date Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    locationName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  currentDate,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            if (nextPrayer != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Next: ${nextPrayer!['name']} - ${nextPrayer!['time']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Prayer Times Title
                      const Text(
                        'Today\'s Prayer Times',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      // Prayer Times List
                      ...prayerTimes.map((prayer) => _buildPrayerTimeCard(prayer)).toList(),
            
            const SizedBox(height: 25),
            
            // Qibla Direction Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF36F21).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.explore,
                      color: Color(0xFFF36F21),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Qibla Direction',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Find the direction to Mecca',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrayerTimeCard(Map<String, dynamic> prayer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: prayer['isPassed'] 
          ? Border.all(color: Colors.grey.withOpacity(0.3), width: 1)
          : Border.all(color: prayer['color'].withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: prayer['isPassed'] 
                ? Colors.grey.withOpacity(0.1)
                : prayer['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              prayer['icon'],
              color: prayer['isPassed'] ? Colors.grey : prayer['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayer['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: prayer['isPassed'] ? Colors.grey : const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  prayer['arabic'],
                  style: TextStyle(
                    fontSize: 14,
                    color: prayer['isPassed'] ? Colors.grey : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                prayer['time'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: prayer['isPassed'] ? Colors.grey : prayer['color'],
                ),
              ),
              if (prayer['isPassed'])
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Passed',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}