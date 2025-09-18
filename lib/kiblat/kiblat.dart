 import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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
  bool _locked = false; // lock/hold current direction
  bool _wasAligned = false; // for one-shot haptic/sound
  double? _heldQAngle; // stored qibla angle when locked

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

    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      // If locked, ignore live heading updates
      if (_locked) return;
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

  void _showCalibrateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calibrate Compass'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('If the arrow seems inaccurate:'),
            SizedBox(height: 8),
            Text('• Move your phone in a figure-8 motion for 10–15 seconds.'),
            Text('• Keep away from magnets/metal (laptops, speakers, cables).'),
            Text('• Ensure Location and sensors are enabled.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
            // Lock/Calibrate controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _locked ? const Color(0xFF2E7D32) : Colors.white,
                    foregroundColor: _locked ? Colors.white : const Color(0xFF2E7D32),
                  ),
                  onPressed: () {
                    setState(() {
                      _locked = !_locked;
                      if (_locked) {
                        // store current qibla angle to hold
                        _heldQAngle = qiblaAngleDeg;
                      } else {
                        _heldQAngle = null;
                      }
                    });
                  },
                  icon: Icon(_locked ? Icons.lock : Icons.lock_open),
                  label: Text(_locked ? 'Locked' : 'Lock'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showCalibrateDialog,
                  icon: const Icon(Icons.tune, color: Color(0xFF2E7D32)),
                  label: const Text('Calibrate Compass', style: TextStyle(color: Color(0xFF2E7D32))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: _buildCompass(_locked ? _heldQAngle : qiblaAngleDeg),
              ),
            ),
            const SizedBox(height: 16),
            // Status chips for quick clarity
            if (bearingToKaaba != null) ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    backgroundColor: const Color(0xFF2E7D32).withOpacity(0.08),
                    label: Text('Qibla ${bearingToKaaba.toStringAsFixed(0)}°',
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                  ),
                  if (qiblaAngleDeg != null)
                    Builder(builder: (context) {
                      final off = qiblaAngleDeg.abs();
                      final aligned = off <= 5 || (360 - off) <= 5;
                      return Chip(
                        backgroundColor: aligned
                            ? const Color(0xFF4CAF50).withOpacity(0.15)
                            : const Color(0xFFF36F21).withOpacity(0.12),
                        label: Text(
                          aligned
                              ? 'Aligned for Salah'
                              : 'Off by ${off <= 180 ? off.toStringAsFixed(0) : (360 - off).toStringAsFixed(0)}°',
                          style: TextStyle(
                            color: aligned ? const Color(0xFF2E7D32) : const Color(0xFFF36F21),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              qiblaAngleDeg == null
                  ? 'Align the top of your phone with the arrow to face the Qibla.'
                  : 'Turn your device until the arrow points straight up (12 o’clock).',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
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
    final size = 300.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(
        painter: CompassPainter(qiblaAngleDeg: qiblaAngleDeg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.navigation,
                size: 56,
                color: qiblaAngleDeg == null ? Colors.grey : const Color(0xFFF36F21),
              ),
              const SizedBox(height: 8),
              Text(
                qiblaAngleDeg == null ? '--°' : '${qiblaAngleDeg.toStringAsFixed(0)}°',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class CompassPainter extends CustomPainter {
  final double? qiblaAngleDeg; // rotation relative to top (12 o’clock)
  CompassPainter({required this.qiblaAngleDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final bool isAligned = () {
      if (qiblaAngleDeg == null) return false;
      final off = qiblaAngleDeg!.abs();
      final delta = off <= 180 ? off : (360 - off);
      return delta <= 5; // within 5 degrees
    }();

    // Outer soft gradient ring
    final outerPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFEFF5F1), Colors.white],
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, outerPaint);

    // Outer border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = isAligned
          ? const Color(0xFF4CAF50).withOpacity(0.6)
          : const Color(0xFF2E7D32).withOpacity(0.25);
    canvas.drawCircle(center, radius, borderPaint);

    // Tick marks every 10°, thicker every 30°
    final tickPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2E7D32).withOpacity(0.45);
    final innerTickR = radius - 12;
    final outerTickR = radius - 2;
    final innerThickR = radius - 18;
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int d = 0; d < 360; d += 10) {
      final rad = (d - 90) * math.pi / 180; // rotate so 0° is at top
      final isThick = d % 30 == 0;
      final p1 = Offset(
        center.dx + (isThick ? innerThickR : innerTickR) * math.cos(rad),
        center.dy + (isThick ? innerThickR : innerTickR) * math.sin(rad),
      );
      final p2 = Offset(
        center.dx + outerTickR * math.cos(rad),
        center.dy + outerTickR * math.sin(rad),
      );
      tickPaint.strokeWidth = isThick ? 2.6 : 1.2;
      canvas.drawLine(p1, p2, tickPaint);

      // Cardinal labels at 0/90/180/270
      if (d % 90 == 0) {
        final label = d == 0
            ? 'N'
            : d == 90
                ? 'E'
                : d == 180
                    ? 'S'
                    : 'W';
        final labelOffset = Offset(
          center.dx + (innerThickR - 16) * math.cos(rad),
          center.dy + (innerThickR - 16) * math.sin(rad),
        );
        textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey,
          ),
        );
        textPainter.layout();
        canvas.save();
        canvas.translate(labelOffset.dx - textPainter.width / 2,
            labelOffset.dy - textPainter.height / 2);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }

    // Top target marker (12 o'clock) to indicate where to align the arrow
    final topAngle = (-90) * math.pi / 180;
    final targetOuter = Offset(
      center.dx + (radius - 2) * math.cos(topAngle),
      center.dy + (radius - 2) * math.sin(topAngle),
    );
    final targetInner = Offset(
      center.dx + (radius - 24) * math.cos(topAngle),
      center.dy + (radius - 24) * math.sin(topAngle),
    );
    final targetPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(targetInner, targetOuter, targetPaint);

    // Qibla arrow (drawn on the face for context)
    if (qiblaAngleDeg != null) {
      final angle = (qiblaAngleDeg! - 90) * math.pi / 180; // align with painter
      final arrowLength = radius - 34;
      final arrowHead = Offset(
        center.dx + arrowLength * math.cos(angle),
        center.dy + arrowLength * math.sin(angle),
      );

      final arrowPaint = Paint()
        ..color = const Color(0xFFF36F21)
        ..style = PaintingStyle.fill;

      final shaftPaint = Paint()
        ..color = const Color(0xFFF36F21).withOpacity(0.7)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      // Shaft
      final shaftTail = Offset(
        center.dx + (arrowLength - 40) * math.cos(angle),
        center.dy + (arrowLength - 40) * math.sin(angle),
      );
      canvas.drawLine(shaftTail, arrowHead, shaftPaint);

      // Arrow head triangle
      final left = Offset(
        arrowHead.dx + 10 * math.cos(angle + math.pi * 0.75),
        arrowHead.dy + 10 * math.sin(angle + math.pi * 0.75),
      );
      final right = Offset(
        arrowHead.dx + 10 * math.cos(angle - math.pi * 0.75),
        arrowHead.dy + 10 * math.sin(angle - math.pi * 0.75),
      );
      final path = Path()
        ..moveTo(arrowHead.dx, arrowHead.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
      canvas.drawPath(path, arrowPaint);

      // 'QIBLA' label near arrow head for clarity
      final labelOffset = Offset(
        arrowHead.dx + 12 * math.cos(angle),
        arrowHead.dy + 12 * math.sin(angle),
      );
      final tp = TextPainter(
        text: const TextSpan(
          text: 'QIBLA',
          style: TextStyle(
            color: Color(0xFFF36F21),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: labelOffset,
          width: tp.width + 12,
          height: tp.height + 6,
        ),
        const Radius.circular(8),
      );
      final bgPaint = Paint()..color = Colors.white.withOpacity(0.9);
      canvas.drawRRect(bgRect, bgPaint);
      tp.paint(canvas, Offset(labelOffset.dx - tp.width / 2, labelOffset.dy - tp.height / 2));
    }

    // Center hub
    final hub = Paint()..color = const Color(0xFF2E7D32).withOpacity(0.2);
    canvas.drawCircle(center, 6, hub);
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) {
    return oldDelegate.qiblaAngleDeg != qiblaAngleDeg;
  }
}

