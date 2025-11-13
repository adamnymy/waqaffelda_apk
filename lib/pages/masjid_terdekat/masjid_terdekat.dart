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

  // Color scheme matching main.dart theme
  static const Color primaryColor = Color(0xFF00897B); // Deep Teal - PRIMARY
  static const Color secondaryColor = Color(0xFFFBC02D); // Golden Yellow - SECONDARY
  static const Color accentColor = Color(0xFF10B981); // Emerald (for success/positive actions)
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color surfaceColor = Color(0xFFFFFFFF); // White
  static const Color backgroundColor = Color(0xFFF5F7FA); // Light gray background
  static const Color textPrimary = Color(0xFF000000); // Black (onBackground)
  static const Color textSecondary = Color(0xFF6B7280); // Gray for secondary text
  static const Color borderColor = Color(0xFFE5E7EB); // Light gray border

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

  void _showMosqueDetails(Mosque mosque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMosqueDetailsSheet(mosque),
    );
  }

  Widget _buildMosqueDetailsSheet(Mosque mosque) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: SvgPicture.asset(
                            'assets/icons/menu/masjid.svg',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Mosque name
                    Text(
                      mosque.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Info section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.navigation_rounded,
                            'Jarak',
                            '${(mosque.distance / 1000).toStringAsFixed(1)} km',
                            accentColor,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.circle,
                            'Status',
                            mosque.isOpen ? 'Dibuka' : 'Ditutup',
                            mosque.isOpen ? accentColor : warningColor,
                          ),
                          if (mosque.address.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.location_on_rounded,
                              'Alamat',
                              mosque.address,
                              primaryColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openGoogleMaps(mosque),
                        icon: const Icon(Icons.navigation_rounded, size: 20),
                        label: const Text('Buka Navigasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _shareLocation(mosque),
                        icon: const Icon(Icons.share_rounded, size: 20),
                        label: const Text('Kongsi Lokasi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
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
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
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
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Masjid Terdekat',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showList ? Icons.map_outlined : Icons.list_rounded,
              color: primaryColor,
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
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _mosques.isEmpty
                  ? _buildEmptyState()
                  : _showList
                      ? Column(
                          children: [
                            _buildHeader(),
                            Expanded(child: _buildListView()),
                          ],
                        )
                      : _buildMapView(),
      floatingActionButton: !_isLoading &&
              _errorMessage.isEmpty &&
              !_showList
          ? FloatingActionButton(
              onPressed: () {
                if (_currentPosition != null && _mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      15,
                    ),
                  );
                }
              },
              backgroundColor: primaryColor,
              child: const Icon(Icons.my_location_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_mosques.length} Masjid Dijumpai',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dalam radius $_searchRadius km',
                      style: const TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Radius selector
          const Text(
            'Jarak Carian',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRadiusChip('2'),
                const SizedBox(width: 8),
                _buildRadiusChip('5'),
                const SizedBox(width: 8),
                _buildRadiusChip('10'),
                const SizedBox(width: 8),
                _buildRadiusChip('20'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusChip(String value) {
    final isSelected = _searchRadius == value;
    return FilterChip(
      selected: isSelected,
      label: Text('$value km'),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _searchRadius = value;
          });
          _searchNearbyMosques();
        }
      },
      selectedColor: primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isSelected ? Colors.white : textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? primaryColor : borderColor,
          width: 1,
        ),
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
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Mencari Masjid Terdekat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mengesan lokasi anda...',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
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
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: textSecondary,
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
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                color: primaryColor.withOpacity(0.1),
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
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tiada masjid atau surau dalam\nradius $_searchRadius km dari lokasi anda',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchRadius = '20';
                  });
                  _searchNearbyMosques();
                },
                icon: const Icon(Icons.search_rounded, size: 20),
                label: const Text('Cari Radius Lebih Luas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.all(16),
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
    final isFirst = index == 0;
    final distanceKm = (mosque.distance / 1000).toStringAsFixed(1);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isFirst ? primaryColor.withOpacity(0.2) : borderColor,
          width: isFirst ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showMosqueDetails(mosque),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isFirst
                      ? primaryColor.withOpacity(0.1)
                      : primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SvgPicture.asset(
                    'assets/icons/menu/masjid.svg',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Name and distance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirst)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: secondaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TERDEKAT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Text(
                      mosque.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          size: 14,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$distanceKm km',
                          style: const TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Action button
              IconButton(
                onPressed: () => _openGoogleMaps(mosque),
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: textSecondary,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: backgroundColor,
                  padding: const EdgeInsets.all(12),
                ),
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
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        zoom: 13,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
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
