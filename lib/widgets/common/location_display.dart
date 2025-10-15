import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// Reusable location display widget with tap-to-show modal
/// Shows coordinates in a compact format with ability to view all formats
class LocationDisplay extends StatelessWidget {
  final LatLng location;
  final bool compact;

  const LocationDisplay({
    super.key,
    required this.location,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return GestureDetector(
        onTap: () => _showLocationFormats(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 18),
              const SizedBox(width: 6),
              Text(
                '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.open_in_new,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      );
    }

    // Non-compact version (just text)
    return Text(
      '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
          ),
    );
  }

  void _showLocationFormats(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Location Formats',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              // Decimal Degrees (DD)
              _buildFormatRow(
                context,
                'DD (Decimal Degrees)',
                '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
              ),
              // Degrees Minutes Seconds (DMS)
              _buildFormatRow(
                context,
                'DMS (Degrees Minutes Seconds)',
                _convertToDMS(location.latitude, location.longitude),
              ),
              // Degrees Decimal Minutes (DDM)
              _buildFormatRow(
                context,
                'DDM (Degrees Decimal Minutes)',
                _convertToDDM(location.latitude, location.longitude),
              ),
              // MGRS (Military Grid Reference System)
              _buildFormatRow(
                context,
                'MGRS (Military Grid)',
                _convertToMGRS(location.latitude, location.longitude),
              ),
              // Google Plus Code
              _buildFormatRow(
                context,
                'Plus Code',
                _convertToPlusCode(location.latitude, location.longitude),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.copy,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Convert to Degrees Minutes Seconds (DMS) format
  String _convertToDMS(double lat, double lon) {
    String latDir = lat >= 0 ? 'N' : 'S';
    String lonDir = lon >= 0 ? 'E' : 'W';

    lat = lat.abs();
    lon = lon.abs();

    int latDeg = lat.floor();
    double latMinDec = (lat - latDeg) * 60;
    int latMin = latMinDec.floor();
    double latSec = (latMinDec - latMin) * 60;

    int lonDeg = lon.floor();
    double lonMinDec = (lon - lonDeg) * 60;
    int lonMin = lonMinDec.floor();
    double lonSec = (lonMinDec - lonMin) * 60;

    return '$latDeg°$latMin\'${latSec.toStringAsFixed(2)}"$latDir, $lonDeg°$lonMin\'${lonSec.toStringAsFixed(2)}"$lonDir';
  }

  /// Convert to Degrees Decimal Minutes (DDM) format
  String _convertToDDM(double lat, double lon) {
    String latDir = lat >= 0 ? 'N' : 'S';
    String lonDir = lon >= 0 ? 'E' : 'W';

    lat = lat.abs();
    lon = lon.abs();

    int latDeg = lat.floor();
    double latMin = (lat - latDeg) * 60;

    int lonDeg = lon.floor();
    double lonMin = (lon - lonDeg) * 60;

    return '$latDeg° ${latMin.toStringAsFixed(4)}\'$latDir, $lonDeg° ${lonMin.toStringAsFixed(4)}\'$lonDir';
  }

  /// Convert to MGRS (Military Grid Reference System) format
  /// Simplified implementation - returns approximate grid zone
  String _convertToMGRS(double lat, double lon) {
    // Zone number (1-60)
    int zone = ((lon + 180) / 6).floor() + 1;

    // Zone letter (C-X, excluding I and O)
    const letters = 'CDEFGHJKLMNPQRSTUVWX';
    int letterIndex = ((lat + 80) / 8).floor();
    if (letterIndex < 0) letterIndex = 0;
    if (letterIndex >= letters.length) letterIndex = letters.length - 1;
    String letter = letters[letterIndex];

    // Simplified - just show zone designation
    // Full MGRS would require UTM conversion library
    return '$zone$letter (approximate)';
  }

  /// Convert to Google Plus Code format
  /// Simplified implementation - returns approximate code
  String _convertToPlusCode(double lat, double lon) {
    // This is a simplified version - full Plus Code requires the open_location_code package
    const base = '23456789CFGHJMPQRVWX';

    // Normalize coordinates
    lat = (lat + 90) / 180; // 0 to 1
    lon = (lon + 180) / 360; // 0 to 1

    String code = '';
    for (int i = 0; i < 8; i++) {
      if (i == 4) code += '+';

      int latDigit = (lat * 20).floor() % 20;
      int lonDigit = (lon * 20).floor() % 20;

      code += base[latDigit];
      code += base[lonDigit];

      lat = (lat * 20) % 1;
      lon = (lon * 20) % 1;
    }

    return code;
  }
}
