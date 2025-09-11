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
  _OpenStreetMapLocationPickerState createState() => _OpenStreetMapLocationPickerState();
}

class _OpenStreetMapLocationPickerState extends State<OpenStreetMapLocationPicker> {
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
      selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
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
          selectedAddress = '${place.locality}, ${place.administrativeArea}, ${place.country}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        selectedAddress = 'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          'Select Location',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _goToCurrentLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Address display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF5F7F6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Location:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 4),
                isLoading
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Getting address...'),
                        ],
                      )
                    : Text(
                        selectedAddress,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                if (selectedLocation != null)
                  Text(
                    'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          
          // Map
          Expanded(
            child: selectedLocation != null
                ? FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      center: selectedLocation!,
                      zoom: 15.0,
                      onTap: _onMapTapped,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.waqaffelda_apk',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedLocation!,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          
          // Confirm button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: selectedLocation != null ? _onConfirmLocation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
