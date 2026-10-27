import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../theme/app_theme.dart';
import '../utils/external_links.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/state_views.dart';
import '../widgets/status_banner.dart';

/// Shows the device location after the user asks for it.
class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Location')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StatusBanner(
                  title: 'Why location permission is needed',
                  message:
                      'The app reads your device location only when you press "Get my location" (or when you switch on location in an SOS alert). It is never read in the background and never sent to other people by this app.',
                ),
                const SizedBox(height: AppSpacing.md),
                _body(context, location, theme),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  key: const Key('get_location_button'),
                  onPressed: location.status == LocationStatus.loading
                      ? null
                      : () => context.read<LocationProvider>().fetch(),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Get my location'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  key: const Key('demo_location_button'),
                  onPressed: () => context.read<LocationProvider>().useDemoLocation(),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Show demonstration location'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, LocationProvider location, ThemeData theme) {
    switch (location.status) {
      case LocationStatus.idle:
        return const EmptyState(
          icon: Icons.location_searching,
          title: 'No location yet',
          message: 'Press "Get my location" to read your position, or show demonstration data.',
        );
      case LocationStatus.loading:
        return const SizedBox(height: 180, child: LoadingView(label: 'Finding your location...'));
      case LocationStatus.ready:
        final position = location.position!;
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: AppStyles.cardShape(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Real data and demo data are clearly labelled.
                Chip(
                  avatar: Icon(location.isDemo ? Icons.science_outlined : Icons.gps_fixed),
                  label: Text(location.isDemo
                      ? 'DEMONSTRATION DATA - not your location'
                      : 'Actual device location'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text('Latitude: ${position.latitude.toStringAsFixed(5)}',
                    key: const Key('latitude_text'), style: theme.textTheme.titleMedium),
                Text('Longitude: ${position.longitude.toStringAsFixed(5)}',
                    key: const Key('longitude_text'), style: theme.textTheme.titleMedium),
                if (position.accuracyMeters != null && !location.isDemo)
                  Text('Accuracy: about ${position.accuracyMeters!.round()} m'),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('open_map_button'),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await openExternal(position.mapUri);
                          if (!ok) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Could not open a map application.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Open in maps'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(ClipboardData(text: position.coordinatesText));
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Coordinates copied.')),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      case LocationStatus.denied:
        return _problem(
          location.message ?? 'Location permission was denied.',
          actionLabel: 'Try again',
          onAction: () => context.read<LocationProvider>().fetch(),
        );
      case LocationStatus.deniedForever:
        return _problem(
          location.message ?? 'Location permission is permanently denied.',
          actionLabel: 'Open app settings',
          onAction: () => context.read<LocationProvider>().openAppSettings(),
        );
      case LocationStatus.serviceOff:
        return _problem(
          location.message ?? 'Location services are off.',
          actionLabel: 'Open location settings',
          onAction: () => context.read<LocationProvider>().openLocationSettings(),
        );
      case LocationStatus.error:
        return _problem(
          location.message ?? 'Your location is unavailable.',
          actionLabel: 'Try again',
          onAction: () => context.read<LocationProvider>().fetch(),
        );
    }
  }

  Widget _problem(String message, {required String actionLabel, required VoidCallback onAction}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatusBanner(kind: BannerKind.error, title: 'Location unavailable', message: message),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}