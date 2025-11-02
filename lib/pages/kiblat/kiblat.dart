import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  // Alignment threshold (degrees). Consider aligned when within ± this value.
  static const double _alignmentThreshold = 3.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // Start compass subscription only after location is obtained
  void _startCompassSubscription() {
    // Guard: Only subscribe to compass on mobile platforms
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      if (mounted) {
        setState(() {
          _error = 'Compass not supported on this platform.';
        });
      }
      return;
    }

    // Cancel existing subscription if any
    _compassSub?.cancel();

    // Check if compass is available
    if (FlutterCompass.events == null) {
      if (mounted) {
        setState(() {
          _error = 'Compass sensor not found on this device.';
        });
      }
      return;
    }

    _compassSub = FlutterCompass.events!.listen(
      (event) {
        if (!mounted) return;
        final newHeading = event.heading; // may be null on some devices

        // Handle null heading (compass not available or needs calibration)
        if (newHeading == null) {
          // Don't set error, just skip this reading
          print('Compass reading null - may need calibration');
          return;
        }

        // Only process if we have a valid position
        if (_position == null) return;

        // Compute qibla angle to check alignment for feedback
        final bearing = _bearingToKaabaDegrees();
        if (bearing != null) {
          final qAngle = (bearing - newHeading + 360) % 360;
          final off = qAngle.abs();
          final delta = off <= 180 ? off : (360 - off);
          // Consider aligned if within ±_alignmentThreshold degrees
          final isAligned = delta <= _alignmentThreshold;
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
        print('Compass error: $e');
        // Don't show error to user, compass might recover
        // Only log for debugging
      },
      cancelOnError: false, // Don't cancel on error, try to recover
    );
  }

  Future<void> _init() async {
    if (!mounted) return;

    try {
      await _ensureLocationPermission();

      Position? currentPosition;
      bool hasLastKnown = false;

      // 1. Try to get last known position for a quick start.
      try {
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && mounted) {
          hasLastKnown = true;
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
      } catch (e) {
        print('Last known position error: $e');
      }

      // 2. Get current position to refine accuracy with retry logic
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries && mounted) {
        try {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: Duration(
              seconds: 10 + (retryCount * 5),
            ), // Progressive timeout
          );
          break; // Success, exit retry loop
        } on TimeoutException catch (_) {
          retryCount++;
          print('Location timeout, attempt $retryCount of $maxRetries');
          if (retryCount >= maxRetries) {
            // If we have last known position, continue with that
            if (hasLastKnown && mounted) {
              print('Using last known position after timeout');
              return; // Already have last known position active
            }
            throw TimeoutException(
              'Location request timed out after $maxRetries attempts',
            );
          }
          // Wait a bit before retry
          await Future.delayed(Duration(seconds: 1));
        } catch (e) {
          retryCount++;
          print('Location error (attempt $retryCount): $e');
          if (retryCount >= maxRetries) {
            if (hasLastKnown && mounted) {
              return; // Use last known position
            }
            rethrow;
          }
          await Future.delayed(Duration(seconds: 1));
        }
      }

      // Successfully got current position
      if (currentPosition != null && mounted) {
        setState(() {
          _position = currentPosition;
          _loadingLocation = false;
        });
        // Restart compass subscription with accurate position
        _startCompassSubscription();
        // Update location name and distance with the new, more accurate position.
        _updateLocationDetails(currentPosition);
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Could not get location in time. Please refresh or check GPS settings.';
          _loadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'Location unavailable: ${e.toString().replaceAll('Exception:', '').trim()}';
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
      throw Exception(
        'GPS is turned off. Please enable location services in your device settings.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Please enable it in app settings.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission denied. Please allow location access to find Qibla direction.',
      );
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

    // Convert to degrees and normalize to 0-360 (this is the TRUE bearing)
    final double trueBearing = (_radToDeg(theta) + 360) % 360;

    // flutter_compass returns heading relative to magnetic north on Android,
    // and relative to true north on iOS. We must return the Qibla bearing
    // in the same reference frame as the device heading so comparisons are
    // correct.
    // - On Android: convert true bearing -> magnetic bearing by subtracting
    //   the magnetic declination (positive = east). Magnetic = True - Decl.
    // - On iOS: the heading is already relative to true north, so return
    //   the true bearing unchanged.
    final magneticDeclination = _getMagneticDeclination(
      pos.latitude,
      pos.longitude,
    );

    if (kIsWeb) {
      // Web compass handling varies widely; return true bearing as a safe
      // default (user will calibrate/verify on actual devices).
      return trueBearing;
    }

    if (Platform.isAndroid) {
      final double magneticBearing =
          (trueBearing - magneticDeclination + 360) % 360;
      return magneticBearing;
    } else {
      // iOS and other platforms: assume heading is relative to true north
      return trueBearing;
    }
  }

  // Get more accurate magnetic declination for Malaysia
  // Based on World Magnetic Model data for 2024
  double _getMagneticDeclination(double latitude, double longitude) {
    // Malaysia magnetic declination (positive = east, negative = west)
    // Values based on NOAA World Magnetic Model for 2024

    // West Malaysia (Peninsular Malaysia)
    if (longitude < 105.0) {
      // Northern region (Perlis, Kedah, Penang, Perak)
      if (latitude > 4.5) {
        return 0.3; // ~0.3° East
      }
      // Central region (Selangor, KL, Negeri Sembilan, Melaka)
      else if (latitude > 2.5) {
        return 0.2; // ~0.2° East
      }
      // Southern region (Johor)
      else {
        return 0.1; // ~0.1° East
      }
    }
    // East Malaysia (Sabah, Sarawak, Labuan)
    else {
      // Northern Sabah/Sarawak
      if (latitude > 3.0) {
        return 0.8; // ~0.8° East
      }
      // Southern Sabah/Sarawak
      else {
        return 0.6; // ~0.6° East
      }
    }
  }

  double _degToRad(double d) => d * math.pi / 180.0;
  double _radToDeg(double r) => r * 180.0 / math.pi;

  // Get cardinal direction from bearing
  String _getCardinalDirection(double bearing) {
    const directions = [
      'U', // Utara (North)
      'TL', // Timur Laut (Northeast)
      'T', // Timur (East)
      'TG', // Tenggara (Southeast)
      'S', // Selatan (South)
      'BD', // Barat Daya (Southwest)
      'B', // Barat (West)
      'BL', // Barat Laut (Northwest)
    ];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

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

    // Check if aligned (within ±_alignmentThreshold degrees)
    final isAligned =
        (() {
          if (qiblaAngleDeg == null) return false;
          final off = qiblaAngleDeg;
          final delta = off <= 180 ? off : (360 - off);
          return delta <= _alignmentThreshold;
        })();

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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: _loadingLocation ? Colors.grey : colorScheme.onSurface,
            ),
            tooltip: 'Refresh Location',
            onPressed:
                _loadingLocation
                    ? null
                    : () async {
                      setState(() {
                        _loadingLocation = true;
                        _error = null;
                        _position = null;
                        _heading = null;
                        _wasAligned = false;
                      });
                      _compassSub?.cancel();
                      await _init();
                    },
          ),
        ],
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

                          // Compass with Glow Effect (only when aligned)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow:
                                  isAligned
                                      ? [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 30,
                                          spreadRadius: 10,
                                        ),
                                      ]
                                      : [], // No shadow when not aligned
                            ),
                            child: _buildCompass(
                              bearingToKaaba,
                              heading,
                              colorScheme,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Qibla Direction Display with Card
                          Container(
                            padding: const EdgeInsets.all(24),
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
                            child: Column(
                              children: [
                                Text(
                                  'Arah Kiblat',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      bearingToKaaba == null
                                          ? '--'
                                          : '${bearingToKaaba.toStringAsFixed(1)}°',
                                      style: TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.primary,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        bearingToKaaba == null
                                            ? ''
                                            : _getCardinalDirection(
                                              bearingToKaaba,
                                            ),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
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

  Widget _buildCompass(
    double? qiblaBearing,
    double? heading,
    ColorScheme colorScheme,
  ) {
    final size = 280.0;
    return Column(
      children: [
        // Kaaba icon at top (static, always visible)
        SvgPicture.asset(
          'assets/icons/arah_kiblat/kaaba-icon.svg',
          width: 48,
          height: 48,
        ),
        const SizedBox(height: 16),
        // Compass circle
        Container(
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
              qiblaBearing: qiblaBearing,
              heading: heading,
              primaryColor: colorScheme.primary,
              secondaryColor: colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

class CompassPainter extends CustomPainter {
  final double? qiblaBearing; // absolute bearing to Kaaba in degrees
  final double? heading; // current compass heading in degrees
  final Color primaryColor;
  final Color secondaryColor;

  CompassPainter({
    required this.qiblaBearing,
    required this.heading,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw static compass (no rotation)

    // Simple outer circle
    final outerCirclePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.grey[300]!;
    canvas.drawCircle(center, radius, outerCirclePaint);

    // Draw only major tick marks (every 30 degrees) - minimal
    final tickPaint =
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 2
          ..color = Colors.grey[400]!;

    for (int d = 0; d < 360; d += 30) {
      final rad = (d - 90) * math.pi / 180;
      final innerR = radius - 12;
      final outerR = radius - 2;

      final p1 = Offset(
        center.dx + innerR * math.cos(rad),
        center.dy + innerR * math.sin(rad),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(rad),
        center.dy + outerR * math.sin(rad),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Simple cardinal direction labels - only N
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // North indicator (always at top)
    final northRad = (0 - 90) * math.pi / 180;
    final northOffset = Offset(
      center.dx + (radius - 35) * math.cos(northRad),
      center.dy + (radius - 35) * math.sin(northRad),
    );

    textPainter.text = TextSpan(
      text: 'N',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    );
    textPainter.layout();
    canvas.save();
    canvas.translate(
      northOffset.dx - textPainter.width / 2,
      northOffset.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    // Draw rotating arrow that points to Qibla
    if (qiblaBearing != null && heading != null) {
      // Calculate the relative angle: where Qibla is relative to current heading
      final relativeAngle = (qiblaBearing! - heading!);
      final arrowAngle = relativeAngle * math.pi / 180;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(arrowAngle);

      // Modern sleek arrow design
      final arrowLength = radius - 40;

      // Main arrow body - rounded capsule shape
      final bodyPath = Path();
      final bodyWidth = 10.0;
      final bodyLength = arrowLength - 25;

      // Create rounded rectangle for arrow body
      bodyPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -bodyLength / 2 + 5),
            width: bodyWidth,
            height: bodyLength,
          ),
          Radius.circular(bodyWidth / 2),
        ),
      );

      final bodyPaint =
          Paint()
            ..color = secondaryColor
            ..style = PaintingStyle.fill;

      canvas.drawPath(bodyPath, bodyPaint);

      // Arrow head - sharp pointed triangle
      final headPaint =
          Paint()
            ..color = secondaryColor
            ..style = PaintingStyle.fill;

      final headPath =
          Path()
            ..moveTo(0, -arrowLength) // Sharp tip
            ..lineTo(-18, -arrowLength + 32) // Left wing
            ..lineTo(-8, -arrowLength + 26) // Left inner
            ..lineTo(0, -arrowLength + 22) // Center notch
            ..lineTo(8, -arrowLength + 26) // Right inner
            ..lineTo(18, -arrowLength + 32) // Right wing
            ..close();

      canvas.drawPath(headPath, headPaint);

      // Add subtle shadow/depth to arrow head
      final shadowPaint =
          Paint()
            ..color = Colors.black.withOpacity(0.15)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawPath(headPath, shadowPaint);

      // Optional: Add a small circle at the base for better visual balance
      final basePaint =
          Paint()
            ..color = secondaryColor.withOpacity(0.8)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(0, 10), 6, basePaint);

      canvas.restore();
    }

    // Simple center dot
    final centerDotPaint =
        Paint()
          ..color = Colors.grey[400]!
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) {
    return oldDelegate.qiblaBearing != qiblaBearing ||
        oldDelegate.heading != heading;
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
