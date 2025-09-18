 import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class KiblatPage extends StatefulWidget {
  const KiblatPage({Key? key}) : super(key: key);

  @override
  State<KiblatPage> createState() => _KiblatPageState();
}

class _KiblatPageState extends State<KiblatPage> {
  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading; // in degrees 0-360
  Position? _position;
  String? _error;
  bool _loadingLocation = true;

  static const double _kaabaLat = 21.4225; // Masjid al-Haram
  static const double _kaabaLon = 39.8262;

  @override
  void initState() {
    super.initState();
    _init();
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      setState(() {
        _heading = event.heading; // may be null on some devices
      });
    }, onError: (e) {
      if (!mounted) return;
      setState(() => _error = 'Compass error: $e');
    });
  }

  Future<void> _init() async {
    try {
      await _ensureLocationPermission();
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      _error = 'Location unavailable: $e';
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw 'Location permission denied.';
    }
  }

  double? _bearingToKaabaDegrees() {
    final pos = _position;
    if (pos == null) return null;
    final lat1 = _degToRad(pos.latitude);
    final lon1 = _degToRad(pos.longitude);
    final lat2 = _degToRad(_kaabaLat);
    final lon2 = _degToRad(_kaabaLon);

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final theta = math.atan2(y, x);
    final bearing = (_radToDeg(theta) + 360) % 360; // degrees from north
    return bearing;
  }

  double _degToRad(double d) => d * math.pi / 180.0;
  double _radToDeg(double r) => r * 180.0 / math.pi;

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bearingToKaaba = _bearingToKaabaDegrees();
    final heading = _heading;
    final qiblaAngleDeg = (bearingToKaaba != null && heading != null)
        ? (bearingToKaaba - heading + 360) % 360
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Direction'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7F6),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            _buildStatusRow(bearingToKaaba, heading),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: _buildCompass(qiblaAngleDeg),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Align the top of your phone with the arrow to face the Qibla.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(double? bearingToKaaba, double? heading) {
    if (_loadingLocation) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('Getting location...')
        ],
      );
    }
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Colors.red));
    }
    if (bearingToKaaba == null) {
      return const Text('Unable to compute Qibla (no location).');
    }
    if (heading == null) {
      return const Text('Compass not available on this device.');
    }
    return Column(
      children: [
        Text('Qibla bearing: ${bearingToKaaba.toStringAsFixed(0)}°'),
        Text('Heading: ${heading.toStringAsFixed(0)}°'),
      ],
    );
  }

  Widget _buildCompass(double? qiblaAngleDeg) {
    final size = 260.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size - 16,
            height: size - 16,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.25), width: 4),
              shape: BoxShape.circle,
            ),
          ),
          const Positioned(
            top: 14,
            child: Text('N', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Transform.rotate(
            angle: (qiblaAngleDeg ?? 0) * math.pi / 180.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.navigation, size: 64, color: qiblaAngleDeg == null ? Colors.grey : const Color(0xFFF36F21)),
                const SizedBox(height: 8),
                Text(qiblaAngleDeg == null ? '--°' : '${qiblaAngleDeg.toStringAsFixed(0)}°',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
