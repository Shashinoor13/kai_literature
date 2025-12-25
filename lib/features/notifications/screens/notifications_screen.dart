import 'package:flutter/material.dart';
import 'package:literature/core/constants/sizes.dart';

/// Notifications Screen - In-app notification center
/// See CLAUDE.md: Navigation Structure > Bottom Navigation Bar > Notifications
/// NOTE: NO push notifications (no FCM) - in-app only
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'In-app notifications only',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
