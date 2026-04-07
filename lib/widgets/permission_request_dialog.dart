import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';

/// Dialog that requests location permissions on app startup
class PermissionRequestDialog extends StatefulWidget {
  final VoidCallback onPermissionsGranted;
  final VoidCallback? onPermissionsDenied;

  const PermissionRequestDialog({
    super.key,
    required this.onPermissionsGranted,
    this.onPermissionsDenied,
  });

  @override
  State<PermissionRequestDialog> createState() => _PermissionRequestDialogState();
}

class _PermissionRequestDialogState extends State<PermissionRequestDialog> {
  bool _isRequesting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Automatically check and request permissions when dialog opens
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });

    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable location services in your device settings.';
          _isRequesting = false;
        });
        return;
      }

      // Check current permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Location permission denied. This app requires location access to track your position and share it with your team.';
          _isRequesting = false;
        });
        widget.onPermissionsDenied?.call();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permission permanently denied. Please enable location access in your device settings.';
          _isRequesting = false;
        });
        widget.onPermissionsDenied?.call();
        return;
      }

      // Permission granted!
      setState(() {
        _isRequesting = false;
      });

      // Close dialog and notify parent
      Navigator.of(context).pop();
      widget.onPermissionsGranted();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error requesting permissions: $e';
        _isRequesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Allow dismissing dialog by back button or tapping outside
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.onPermissionsDenied?.call();
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.locationPermission),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MeshCore SAR needs access to your location to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPermissionReason(
              icon: Icons.track_changes,
              text: 'Track your position during search and rescue operations',
            ),
            const SizedBox(height: 8),
            _buildPermissionReason(
              icon: Icons.share_location,
              text: 'Share your location with team members via mesh network',
            ),
            const SizedBox(height: 8),
            _buildPermissionReason(
              icon: Icons.map,
              text: 'Display your location and trail on the map',
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_isRequesting) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
        actions: [
          // Always show a cancel/skip button
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onPermissionsDenied?.call();
            },
            child: Text(AppLocalizations.of(context)!.skip),
          ),
          if (_errorMessage != null && !_isRequesting)
            ElevatedButton(
              onPressed: () async {
                // Open app settings
                await Geolocator.openLocationSettings();
              },
              child: Text(AppLocalizations.of(context)!.openSettings),
            ),
          if (_errorMessage != null && !_isRequesting &&
              !_errorMessage!.contains('permanently denied'))
            ElevatedButton(
              onPressed: _checkAndRequestPermissions,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionReason({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
