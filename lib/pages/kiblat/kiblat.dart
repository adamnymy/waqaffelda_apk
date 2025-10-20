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
    // Guard: Only subscribe to compass on mobile platforms
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      setState(() {
        _error = 'Compass not supported on this platform.';
      });
      return;
    }

    _compassSub = FlutterCompass.events?.listen(
      (event) {
        if (!mounted) return;
        final newHeading = event.heading; // may be null on some devices
        if (newHeading == null) return;

        // Compute qibla angle to check alignment for feedback
        final bearing = _bearingToKaabaDegrees();
        if (bearing != null) {
          final qAngle = (bearing - newHeading + 360) % 360;
          final off = qAngle.abs();
          final delta = off <= 180 ? off : (360 - off);
          final isAligned = delta <= 5;
          if (isAligned && !_wasAligned) {
            // Haptic + sound once when entering aligned zone
            try {
              HapticFeedback.mediumImpact();
            } catch (_) {}
            try {
              HapticFeedback.lightImpact();
            } catch (_) {}
            try {
              HapticFeedback.vibrate();
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
    try {
      await _ensureLocationPermission();
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // Get location name
      if (_position != null) {
        _distanceToKaaba = _calculateDistance(
          _position!.latitude,
          _position!.longitude,
          _kaabaLat,
          _kaabaLon,
        );

        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            _position!.latitude,
            _position!.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            _locationName =
                place.locality ??
                place.subAdministrativeArea ??
                place.administrativeArea ??
                'Unknown Location';
          }
        } catch (e) {
          _locationName = 'Location Found';
        }
      }
    } catch (e) {
      _error = 'Location unavailable: $e';
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
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
    final qiblaAngleDeg =
        (bearingToKaaba != null && heading != null)
            ? (bearingToKaaba - heading + 360) % 360
            : null;

    // Check if aligned (within 5 degrees)
    final isAligned =
        qiblaAngleDeg != null &&
        ((qiblaAngleDeg.abs() <= 5) || ((360 - qiblaAngleDeg.abs()) <= 5));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body:
          _loadingLocation
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.teal),
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
                          });
                          _init();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Cuba Lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
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
                  // Simple App Bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(
                      top: 40,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Arah Kiblat',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                  ),

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
                                  Colors.orange[50]!,
                                  const Color(0xFFFFF4E6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.1),
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
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.orange[700],
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
                                          color: Colors.orange[800],
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
                                      : Colors.blue[50],
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color:
                                    isAligned
                                        ? Colors.green[300]!
                                        : Colors.blue[300]!,
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
                                          : Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isAligned
                                      ? 'Tepat ke Kiblat ✓'
                                      : 'Teruskan Memusingkan',
                                  style: TextStyle(
                                    color:
                                        isAligned
                                            ? Colors.green[700]
                                            : Colors.blue[700],
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
                                          : Colors.teal.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: _buildCompass(qiblaAngleDeg),
                          ),

                          const SizedBox(height: 32),

                          // Angle Display with Card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                                  color: Colors.teal[600],
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
                                    color: Colors.grey[800],
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
                                color: Colors.teal[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.teal[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.route,
                                    color: Colors.teal[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Jarak ke Kaabah: ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.teal[700],
                                    ),
                                  ),
                                  Text(
                                    '${_distanceToKaaba!.toStringAsFixed(0)} km',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal[900],
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
                                  Colors.amber[50]!,
                                  const Color(0xFFFFF4E6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.1),
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
                                    color: Colors.amber[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.tips_and_updates,
                                    color: Colors.amber[800],
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
                                        'Kalibrasi Kompas',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Gerakkan telefon dalam bentuk 8/∞',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
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

  Widget _buildCompass(double? qiblaAngleDeg) {
    final size = 280.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F7),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(painter: CompassPainter(qiblaAngleDeg: qiblaAngleDeg)),
    );
  }
}

class CompassPainter extends CustomPainter {
  final double? qiblaAngleDeg; // rotation relative to top (12 o’clock)
  CompassPainter({required this.qiblaAngleDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;

    // Outer border - green
    final borderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = Colors.green[600]!;
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
      text: const TextSpan(
        text: 'QIBLA',
        style: TextStyle(
          color: Colors.orange,
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
            ..color = Colors.orange[700]!
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
            ..color = Colors.orange[700]!
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
