import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
  bool _wasAligned = false; // for one-shot haptic/sound
  String _locationName = 'Getting location...';
  double? _distanceToKaaba; // in km

  static const double _kaabaLat = 21.4225; // Masjid al-Haram
  static const double _kaabaLon = 39.8262;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // Start compass subscription only after location is obtained
  void _startCompassSubscription() {
    // Guard: Only subscribe to compass on mobile platforms
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      setState(() {
        _error = 'Compass not supported on this platform.';
      });
      return;
    }

    // Cancel existing subscription if any
    _compassSub?.cancel();

    _compassSub = FlutterCompass.events?.listen(
      (event) {
        if (!mounted) return;
        final newHeading = event.heading; // may be null on some devices
        if (newHeading == null) return;

        // Only process if we have a valid position
        if (_position == null) return;

        // Compute qibla angle to check alignment for feedback
        final bearing = _bearingToKaabaDegrees();
        if (bearing != null) {
          final qAngle = (bearing - newHeading + 360) % 360;
          final off = qAngle.abs();
          final delta = off <= 180 ? off : (360 - off);
          final isAligned = delta.round() == 0;
          if (isAligned && !_wasAligned) {
            // Strong haptic + vibration + sound once when aligned to Qibla
            try {
              HapticFeedback.heavyImpact();
            } catch (_) {}
            try {
              HapticFeedback.vibrate();
            } catch (_) {}
            try {
              HapticFeedback.heavyImpact();
            } catch (_) {}
            try {
              HapticFeedback.vibrate();
            } catch (_) {}
            try {
              HapticFeedback.heavyImpact();
            } catch (_) {}
            SystemSound.play(SystemSoundType.click);
          }
          _wasAligned = isAligned;
        }

        setState(() {
          _heading = newHeading;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _error = 'Compass error: $e');
      },
    );
  }

  Future<void> _init() async {
    if (!mounted) return;

    try {
      await _ensureLocationPermission();

      // 1. Try to get last known position for a quick start.
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        if (mounted) {
          setState(() {
            _position = lastKnown;
            _loadingLocation = false; // Show compass immediately
            _locationName = 'Updating location...';
          });
          // Start compass subscription after we have initial position
          _startCompassSubscription();
          // Update location name and distance in the background
          _updateLocationDetails(lastKnown);
        }
      }

      // 2. Get current position to refine accuracy.
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high, // Changed to high for better accuracy
        timeLimit: const Duration(seconds: 15), // Add a timeout
      );

      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
        // Start compass subscription with accurate position
        _startCompassSubscription();
        // Update location name and distance with the new, more accurate position.
        _updateLocationDetails(_position!);
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not get location in time. Please try again.';
          _loadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Location unavailable: $e';
          _loadingLocation = false;
        });
      }
    }
  }

  // Helper to fetch location name and distance without blocking the UI
  Future<void> _updateLocationDetails(Position position) async {
    final distance = _calculateDistance(
      position.latitude,
      position.longitude,
      _kaabaLat,
      _kaabaLon,
    );

    String locationName = 'Location Found';
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        locationName =
            place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            'Unknown Location';
      }
    } catch (e) {
      // Ignore reverse geocoding errors, as we have a fallback.
    }

    if (mounted) {
      setState(() {
        _distanceToKaaba = distance;
        _locationName = locationName;
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
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
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final theta = math.atan2(y, x);

    // Convert to degrees and normalize to 0-360
    double bearing = (_radToDeg(theta) + 360) % 360;

    // Apply magnetic declination for Malaysia (approximately +0.5° to +1.5°)
    // For better accuracy across Malaysia, we use an average of +1.0°
    // This compensates for the difference between true north and magnetic north
    final magneticDeclination = _getMagneticDeclination(
      pos.latitude,
      pos.longitude,
    );
    bearing = (bearing + magneticDeclination + 360) % 360;

    return bearing;
  }

  // Get approximate magnetic declination for Malaysia region
  double _getMagneticDeclination(double latitude, double longitude) {
    // Malaysia is roughly between latitude 1°N to 7°N, longitude 99°E to 119°E
    // Magnetic declination in Malaysia varies from +0.3° to +1.8°
    // We use a simplified model based on location

    // Northern Malaysia (Perlis, Kedah, Penang, Perak) - higher declination
    if (latitude > 5.0) {
      return 1.2;
    }
    // Central Malaysia (Selangor, KL, Pahang, etc) - medium declination
    else if (latitude > 3.0) {
      return 1.0;
    }
    // Southern Malaysia (Johor) and East Malaysia - lower declination
    else {
      return 0.8;
    }
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
    final colorScheme = Theme.of(context).colorScheme;
    final bearingToKaaba = _bearingToKaabaDegrees();
    final heading = _heading;
    final qiblaAngleDeg =
        (bearingToKaaba != null && heading != null)
            ? (bearingToKaaba - heading + 360) % 360
            : null;

    // Check if aligned (exactly 0 degrees)
    final isAligned =
        qiblaAngleDeg != null &&
        (qiblaAngleDeg.round() == 0 || qiblaAngleDeg.round() == 360);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Arah Kiblat',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _loadingLocation
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Mendapatkan lokasi...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              )
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.red[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Lokasi Tidak Tersedia',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _loadingLocation = true;
                            _error = null;
                            _position = null;
                            _heading = null;
                          });
                          _compassSub?.cancel();
                          _init();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Cuba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Location Card with Gradient
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.secondary.withOpacity(0.1),
                                  colorScheme.secondary.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.secondary.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: colorScheme.secondary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lokasi Semasa',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _locationName,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Status Badge
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isAligned
                                      ? Colors.green[50]
                                      : colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color:
                                    isAligned
                                        ? Colors.green[300]!
                                        : colorScheme.primary.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAligned
                                      ? Icons.check_circle
                                      : Icons.explore,
                                  color:
                                      isAligned
                                          ? Colors.green[700]
                                          : colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isAligned
                                      ? 'Tepat ke Kiblat ✓'
                                      : 'Pusingkan peranti anda',
                                  style: TextStyle(
                                    color:
                                        isAligned
                                            ? Colors.green[700]
                                            : colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Compass with Glow Effect
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      isAligned
                                          ? Colors.green.withOpacity(0.3)
                                          : colorScheme.primary.withOpacity(
                                            0.2,
                                          ),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: _buildCompass(qiblaAngleDeg, colorScheme),
                          ),

                          const SizedBox(height: 32),

                          // Angle Display with Card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.compass_calibration,
                                  color: colorScheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  qiblaAngleDeg == null
                                      ? '--°'
                                      : '${qiblaAngleDeg.toStringAsFixed(0)}°',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Distance Card
                          if (_distanceToKaaba != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.route,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Jarak ke Kaabah: ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${_distanceToKaaba!.toStringAsFixed(0)} km',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 32),

                          // Calibration Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.secondary.withOpacity(0.15),
                                  colorScheme.secondary.withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.secondary.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary.withOpacity(
                                      0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.tips_and_updates,
                                    color: colorScheme.secondary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tips Ketepatan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '• Jauhkan dari objek magnetik\n• Gerakkan telefon bentuk 8/∞ untuk kalibrasi\n• Pastikan GPS aktif untuk ketepatan lokasi',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildCompass(double? qiblaAngleDeg, ColorScheme colorScheme) {
    final size = 280.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: CompassPainter(
          qiblaAngleDeg: qiblaAngleDeg,
          primaryColor: colorScheme.primary,
          secondaryColor: colorScheme.secondary,
        ),
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  final double? qiblaAngleDeg; // rotation relative to top (12 o'clock)
  final Color primaryColor;
  final Color secondaryColor;

  CompassPainter({
    required this.qiblaAngleDeg,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;

    // Outer border - using primary color
    final borderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = primaryColor;
    canvas.drawCircle(center, radius, borderPaint);

    // Tick marks
    final tickPaint =
        Paint()
          ..strokeCap = StrokeCap.round
          ..color = Colors.grey[400]!;

    for (int d = 0; d < 360; d += 30) {
      final rad = (d - 90) * math.pi / 180;
      final innerR = radius - 15;
      final outerR = radius - 5;

      final p1 = Offset(
        center.dx + innerR * math.cos(rad),
        center.dy + innerR * math.sin(rad),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(rad),
        center.dy + outerR * math.sin(rad),
      );
      tickPaint.strokeWidth = 2;
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Cardinal labels
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int d = 0; d < 360; d += 90) {
      final rad = (d - 90) * math.pi / 180;
      final label =
          d == 0
              ? 'N'
              : d == 90
              ? 'E'
              : d == 180
              ? 'S'
              : 'W';
      final labelOffset = Offset(
        center.dx + (radius - 30) * math.cos(rad),
        center.dy + (radius - 30) * math.sin(rad),
      );
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      );
      textPainter.layout();
      canvas.save();
      canvas.translate(
        labelOffset.dx - textPainter.width / 2,
        labelOffset.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // QIBLA label at top
    final qiblaLabel = TextPainter(
      text: TextSpan(
        text: 'QIBLA',
        style: TextStyle(
          color: secondaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    qiblaLabel.layout();
    qiblaLabel.paint(
      canvas,
      Offset(center.dx - qiblaLabel.width / 2, center.dy - radius + 20),
    );

    // Qibla arrow
    if (qiblaAngleDeg != null) {
      final angle = (qiblaAngleDeg! - 90) * math.pi / 180;
      final arrowLength = radius - 50;

      // Arrow body
      final arrowPaint =
          Paint()
            ..color = secondaryColor
            ..style = PaintingStyle.fill;

      final arrowHead = Offset(
        center.dx + arrowLength * math.cos(angle),
        center.dy + arrowLength * math.sin(angle),
      );

      // Draw arrow shaft
      final shaftWidth = 8.0;
      final shaftLength = arrowLength - 20;

      final shaftStart = Offset(
        center.dx - shaftLength * 0.3 * math.cos(angle),
        center.dy - shaftLength * 0.3 * math.sin(angle),
      );

      final shaftEnd = Offset(
        center.dx + (arrowLength - 25) * math.cos(angle),
        center.dy + (arrowLength - 25) * math.sin(angle),
      );

      // Draw shaft as thick line
      final shaftPaint =
          Paint()
            ..color = secondaryColor
            ..strokeWidth = shaftWidth
            ..strokeCap = StrokeCap.round;

      canvas.drawLine(shaftStart, shaftEnd, shaftPaint);

      // Arrow head (triangle)
      final headSize = 20.0;
      final left = Offset(
        arrowHead.dx + headSize * math.cos(angle + math.pi * 0.75),
        arrowHead.dy + headSize * math.sin(angle + math.pi * 0.75),
      );
      final right = Offset(
        arrowHead.dx + headSize * math.cos(angle - math.pi * 0.75),
        arrowHead.dy + headSize * math.sin(angle - math.pi * 0.75),
      );
      final path =
          Path()
            ..moveTo(arrowHead.dx, arrowHead.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(right.dx, right.dy)
            ..close();
      canvas.drawPath(path, arrowPaint);
    }

    // Center dot
    final centerPaint = Paint()..color = Colors.grey[300]!;
    canvas.drawCircle(center, 5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) {
    return oldDelegate.qiblaAngleDeg != qiblaAngleDeg;
  }
}

class KaabaIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Scale factor to fit the icon
    final scale = size.width / 40;

    // Main Kaaba body (dark gray rectangle)
    paint.color = const Color(0xFF3F3F3F);
    canvas.drawRect(Rect.fromLTWH(2 * scale, 0, 36 * scale, 36 * scale), paint);

    // Golden band
    paint.color = const Color(0xFFF1B31C);
    canvas.drawRect(
      Rect.fromLTWH(2 * scale, 7 * scale, 36 * scale, 4 * scale),
      paint,
    );

    // Door (light gray)
    paint.color = const Color(0xFF9B9B9A);
    canvas.drawRect(
      Rect.fromLTWH(8 * scale, 28 * scale, 5 * scale, 8 * scale),
      paint,
    );

    // Golden decorative elements
    paint.color = const Color(0xFFF1B31C);

    // Left circle
    canvas.drawCircle(Offset(11 * scale, 18 * scale), 2 * scale, paint);

    // Right circle
    canvas.drawCircle(Offset(30 * scale, 18 * scale), 2 * scale, paint);

    // Center diamond/star
    final path = Path();
    path.moveTo(20 * scale, 15 * scale);
    path.lineTo(18 * scale, 18 * scale);
    path.lineTo(20 * scale, 21 * scale);
    path.lineTo(22 * scale, 18 * scale);
    path.close();
    canvas.drawPath(path, paint);

    // Outline stroke
    final strokePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white;

    canvas.drawRect(
      Rect.fromLTWH(2 * scale, 0, 36 * scale, 36 * scale),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
