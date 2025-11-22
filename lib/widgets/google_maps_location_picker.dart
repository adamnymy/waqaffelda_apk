import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class OpenStreetMapLocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double lat, double lng, String address) onLocationSelected;

  const OpenStreetMapLocationPicker({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _OpenStreetMapLocationPickerState createState() =>
      _OpenStreetMapLocationPickerState();
}

class _OpenStreetMapLocationPickerState
    extends State<OpenStreetMapLocationPicker> {
  MapController mapController = MapController();
  LatLng? selectedLocation;
  String selectedAddress = 'Loading...';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  void _initializeLocation() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      selectedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _getAddressFromCoordinates(selectedLocation!);
    } else {
      // Try to get current location
      try {
        Position position = await Geolocator.getCurrentPosition();
        selectedLocation = LatLng(position.latitude, position.longitude);
        _getAddressFromCoordinates(selectedLocation!);
      } catch (e) {
        // Default to Kuala Lumpur if location access fails
        selectedLocation = const LatLng(3.139, 101.6869);
        selectedAddress = 'Kuala Lumpur, Malaysia';
      }
    }
    setState(() {});
  }

  void _getAddressFromCoordinates(LatLng location) async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          selectedAddress =
              '${place.locality}, ${place.administrativeArea}, ${place.country}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        selectedAddress =
            'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
        isLoading = false;
      });
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng location) {
    setState(() {
      selectedLocation = location;
    });
    _getAddressFromCoordinates(location);
  }

  void _onConfirmLocation() {
    if (selectedLocation != null) {
      widget.onLocationSelected(
        selectedLocation!.latitude,
        selectedLocation!.longitude,
        selectedAddress,
      );
      Navigator.pop(context);
    }
  }

  void _goToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      LatLng currentLocation = LatLng(position.latitude, position.longitude);

      mapController.move(currentLocation, 15.0);

      setState(() {
        selectedLocation = currentLocation;
      });
      _getAddressFromCoordinates(currentLocation);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get current location')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map
          selectedLocation != null
              ? FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  center: selectedLocation!,
                  zoom: 15.0,
                  onTap: _onMapTapped,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'app.waqaffelda.waqafer',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selectedLocation!,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF36F21),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF36F21,
                                    ).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 20,
                              color: const Color(0xFFF36F21),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF36F21)),
                ),
              ),

          // Top gradient overlay for better readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
          ),

          // Custom AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF2E7D32),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Title
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Pilih Lokasi',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Current location button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF36F21),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF36F21).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                        ),
                        onPressed: _goToCurrentLocation,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Address card at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Location icon and label
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF36F21).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFFF36F21),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Lokasi Dipilih',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Address
                      isLoading
                          ? Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF36F21),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Mendapatkan alamat...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ],
                          )
                          : Text(
                            selectedAddress,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),

                      const SizedBox(height: 8),

                      // Coordinates
                      if (selectedLocation != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${selectedLocation!.latitude.toStringAsFixed(6)}, ${selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Confirm button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              selectedLocation != null
                                  ? _onConfirmLocation
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF36F21),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            shadowColor: const Color(
                              0xFFF36F21,
                            ).withOpacity(0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Sahkan Lokasi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
