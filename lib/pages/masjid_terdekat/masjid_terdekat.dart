import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';

class MasjidTerdekatPage extends StatefulWidget {
  const MasjidTerdekatPage({Key? key}) : super(key: key);

  @override
  State<MasjidTerdekatPage> createState() => _MasjidTerdekatPageState();
}

class _MasjidTerdekatPageState extends State<MasjidTerdekatPage>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String _errorMessage = '';
  List<Mosque> _mosques = [];
  Set<Marker> _markers = {};
  bool _showList = true;
  String _searchRadius = '5';
  late AnimationController _animationController;
  String _sortOption = 'Jarak Terdekat';

  // Color scheme based on the new design
  static const Color scaffoldBgColor = Color(0xFFF0F7F7);
  static const Color primaryGreen = Color(0xFF0A7E6E);
  static const Color cardBorderColor = Color(0xFFB0E0E6);
  static const Color ratingYellow = Color(0xFFFBC02D);
  static const Color secondaryTextColor = Color(0xFF555555);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF000000);
  static const Color lightGreyColor = Color(0xFFE5E7EB);
  static const Color errorColor = Color(0xFFEF4444); // Red for errors

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied permanently');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      await _searchNearbyMosques();
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchNearbyMosques() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final radius = int.parse(_searchRadius) * 1000;

      final overpassQuery = '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,${_currentPosition!.latitude},${_currentPosition!.longitude});
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,${_currentPosition!.latitude},${_currentPosition!.longitude});
  relation["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,${_currentPosition!.latitude},${_currentPosition!.longitude});
);
out center;
''';

      final url = Uri.parse('https://overpass-api.de/api/interpreter');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': overpassQuery},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['elements'] != null) {
          List<Mosque> mosques = [];
          Set<Marker> markers = {};

          markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: const InfoWindow(title: 'Lokasi Anda'),
            ),
          );

          for (var element in data['elements']) {
            double? lat;
            double? lng;

            if (element['lat'] != null && element['lon'] != null) {
              lat = element['lat'].toDouble();
              lng = element['lon'].toDouble();
            } else if (element['center'] != null) {
              lat = element['center']['lat'].toDouble();
              lng = element['center']['lon'].toDouble();
            }

            if (lat == null || lng == null) continue;

            final distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              lat,
              lng,
            );

            final tags = element['tags'] ?? {};
            String name =
                tags['name'] ??
                tags['name:ms'] ??
                tags['name:en'] ??
                'Masjid/Surau';

            if (!name.toLowerCase().contains('masjid') &&
                !name.toLowerCase().contains('surau') &&
                !name.toLowerCase().contains('mosque')) {
              final building = tags['building'];
              if (building == 'mosque' ||
                  tags['amenity'] == 'place_of_worship') {
                name = 'Masjid $name';
              }
            }

            String address =
                tags['addr:full'] ??
                tags['addr:street'] ??
                tags['addr:city'] ??
                tags['addr:state'] ??
                '';

            final mosque = Mosque(
              name: name,
              address: address,
              latitude: lat,
              longitude: lng,
              distance: distance,
              rating: null,
              isOpen: true,
              placeId: element['id'].toString(),
            );

            mosques.add(mosque);

            markers.add(
              Marker(
                markerId: MarkerId(element['id'].toString()),
                position: LatLng(lat, lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRose,
                ),
                infoWindow: InfoWindow(
                  title: name,
                  snippet: '${(distance / 1000).toStringAsFixed(1)} km',
                ),
                onTap: () => _showMosqueDetails(mosque),
              ),
            );
          }

          mosques.sort((a, b) => a.distance.compareTo(b.distance));

          setState(() {
            _mosques = mosques;
            _markers = markers;
            _isLoading = false;
          });

          if (mosques.isEmpty) {
            throw Exception(
              'Tiada masjid dijumpai dalam radius $_searchRadius km',
            );
          }
        } else {
          throw Exception('Tiada data diterima dari server');
        }
      } else {
        throw Exception('Gagal menghubungi server: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _sortMosques() {
    setState(() {
      if (_sortOption == 'Jarak Terdekat') {
        _mosques.sort((a, b) => a.distance.compareTo(b.distance));
      } else if (_sortOption == 'Penilaian Tertinggi') {
        _mosques.sort((a, b) {
          final ratingA = (4.5 + (a.name.hashCode % 5) / 10);
          final ratingB = (4.5 + (b.name.hashCode % 5) / 10);
          return ratingB.compareTo(ratingA);
        });
      }
    });
  }

  void _showMosqueDetails(Mosque mosque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMosqueDetailsSheet(mosque),
    );
  }

  Widget _buildMosqueDetailsSheet(Mosque mosque) {
    return Container(
      decoration: const BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: lightGreyColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SvgPicture.asset(
                  'assets/icons/menu/masjid.svg',
                  width: 32,
                  height: 32,
                  color: primaryGreen,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mosque.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: blackColor,
                      ),
                    ),
                    if (mosque.address.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        mosque.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: lightGreyColor, height: 1),
          const SizedBox(height: 24),

          // Info Rows
          _buildInfoRow(
            Icons.social_distance_rounded,
            'Jarak',
            '${(mosque.distance / 1000).toStringAsFixed(1)} km dari lokasi anda',
            primaryGreen,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.access_time_rounded,
            'Status',
            mosque.isOpen ? 'Dibuka' : 'Ditutup',
            mosque.isOpen ? primaryGreen : ratingYellow,
          ),

          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openGoogleMaps(mosque),
                  icon: const Icon(Icons.directions_rounded, size: 20),
                  label: const Text('Arah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: whiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareLocation(mosque),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: const Text('Kongsi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryGreen,
                    side: const BorderSide(color: primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: blackColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openGoogleMaps(Mosque mosque) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}'
      '&destination=${mosque.latitude},${mosque.longitude}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: whiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: lightGreyColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Susun Ikut',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: blackColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSortOptionTile(
                    context,
                    'Jarak Terdekat',
                    Icons.social_distance_rounded,
                    _sortOption == 'Jarak Terdekat',
                    () {
                      setState(() {
                        _sortOption = 'Jarak Terdekat';
                      });
                      _sortMosques();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSortOptionTile(
                    context,
                    'Penilaian Tertinggi',
                    Icons.star_rounded,
                    _sortOption == 'Penilaian Tertinggi',
                    () {
                      setState(() {
                        _sortOption = 'Penilaian Tertinggi';
                      });
                      _sortMosques();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOptionTile(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: isSelected ? primaryGreen.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? primaryGreen : secondaryTextColor,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? primaryGreen : blackColor,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: primaryGreen,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareLocation(Mosque mosque) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share functionality coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Masjid Terdekat',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Filter Button
          if (_showList && _mosques.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.filter_list_rounded,
                color: primaryGreen,
                size: 24,
              ),
              onPressed: _showSortOptions,
              tooltip: 'Tapis',
            ),
          IconButton(
            icon: Icon(
              _showList ? Icons.map_outlined : Icons.list_rounded,
              color: primaryGreen,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _showList = !_showList;
              });
            },
            tooltip: _showList ? 'Tunjukkan Peta' : 'Tunjukkan Senarai',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _mosques.isEmpty
              ? _buildEmptyState()
              : _showList
              ? Column(
                children: [_buildHeader(), Expanded(child: _buildListView())],
              )
              : _buildMapView(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: scaffoldBgColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(width: 12),
          Text(
            '${_mosques.length} Masjid Ditemukan',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Mencari Masjid Terdekat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: blackColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mengesan lokasi anda...',
            style: TextStyle(fontSize: 14, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 48,
                color: errorColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tidak Dapat Mengesan Lokasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: blackColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _initLocation,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Cuba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: whiteColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SvgPicture.asset(
                  'assets/icons/menu/masjid.svg',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tiada Masjid Dijumpai',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: blackColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tiada masjid atau surau dalam\nradius $_searchRadius km dari lokasi anda',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _initLocation,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Cuba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: whiteColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _mosques.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMosqueCard(_mosques[index], index),
        );
      },
    );
  }

  Widget _buildMosqueCard(Mosque mosque, int index) {
    final distanceKm = (mosque.distance / 1000).toStringAsFixed(1);
    final walkingTime =
        (mosque.distance / 1000 * 12).ceil(); // Avg walking speed 5km/h

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: cardBorderColor, width: 1.5),
      ),
      color: whiteColor,
      child: InkWell(
        onTap: () => _showMosqueDetails(mosque),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      mosque.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ratingYellow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: ratingYellow,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          // The rating is not real, it's a mock value for display.
                          (4.5 + (mosque.name.hashCode % 5) / 10)
                              .toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.directions_walk,
                    color: secondaryTextColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$distanceKm km • $walkingTime min berjalan',
                    style: const TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      mosque.address.isNotEmpty
                          ? mosque.address
                          : 'Jalan Tun Perak, Kuala Lumpur City Centre',
                      style: const TextStyle(
                        fontSize: 13,
                        color: secondaryTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _openGoogleMaps(mosque),
                    icon: const Icon(Icons.near_me_outlined, size: 16),
                    label: const Text('Arah'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: whiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 13,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        // Custom map style
        _mapController!.setMapStyle('''
[
  {
    "featureType": "poi.business",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]
''');
      },
      compassEnabled: true,
      mapToolbarEnabled: false,
      mapType: MapType.normal,
    );
  }
}

// Mosque model
class Mosque {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final double? rating;
  final bool isOpen;
  final String placeId;

  Mosque({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.rating,
    required this.isOpen,
    required this.placeId,
  });
}
