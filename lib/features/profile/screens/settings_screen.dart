import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_event.dart';

/// Settings Screen - Account settings and actions
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(DeleteAccountRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        children: [
          const SizedBox(height: AppSizes.lg),
          ListTile(
            leading: const HeroIcon(
              HeroIcons.user,
              style: HeroIconStyle.outline,
            ),
            title: const Text('Edit Profile'),
            onTap: () => context.push('/edit-profile'),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(top: AppSizes.lg, bottom: AppSizes.sm),
            child: Text(
              'Privacy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: const HeroIcon(
              HeroIcons.noSymbol,
              style: HeroIconStyle.outline,
            ),
            title: const Text('Blocked Users'),
            trailing: const HeroIcon(
              HeroIcons.chevronRight,
              style: HeroIconStyle.outline,
              size: 20,
            ),
            onTap: () => context.push('/blocked-users'),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.only(top: AppSizes.lg, bottom: AppSizes.sm),
            child: Text(
              'Account Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: const HeroIcon(
              HeroIcons.arrowLeftOnRectangle,
              style: HeroIconStyle.outline,
            ),
            title: const Text('Logout'),
            onTap: () {
              context.read<AuthBloc>().add(SignOutRequested());
            },
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          ListTile(
            leading: const HeroIcon(
              HeroIcons.trash,
              style: HeroIconStyle.outline,
              color: Colors.red,
            ),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showDeleteConfirmation(context),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
