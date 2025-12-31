import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/constants/colors.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_event.dart';
import 'package:literature/repositories/auth_repository.dart';

/// Settings Screen - Account settings and actions
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ChangePasswordSheet(authRepository: context.read<AuthRepository>()),
    );
  }

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
              'App Info',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: const HeroIcon(
              HeroIcons.informationCircle,
              style: HeroIconStyle.outline,
            ),
            title: const Text('About Literature'),
            trailing: const HeroIcon(
              HeroIcons.chevronRight,
              style: HeroIconStyle.outline,
              size: 20,
            ),
            onTap: () => context.push('/about'),
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
              HeroIcons.key,
              style: HeroIconStyle.outline,
            ),
            title: const Text('Change Password'),
            trailing: const HeroIcon(
              HeroIcons.chevronRight,
              style: HeroIconStyle.outline,
              size: 20,
            ),
            onTap: () => _showChangePasswordSheet(context),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
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

// Change Password bottom sheet widget
class _ChangePasswordSheet extends StatefulWidget {
  final AuthRepository authRepository;

  const _ChangePasswordSheet({required this.authRepository});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordChanged = false;
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authRepository.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      setState(() {
        _passwordChanged = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const HeroIcon(
                HeroIcons.exclamationCircle,
                size: 20,
                color: AppColors.white,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  e.toString().replaceAll('Exception: ', ''),
                  style: const TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.gray900,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            side: const BorderSide(color: AppColors.gray700),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  const HeroIcon(
                    HeroIcons.key,
                    style: HeroIconStyle.outline,
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  const Expanded(
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const HeroIcon(
                      HeroIcons.xMark,
                      style: HeroIconStyle.outline,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: _passwordChanged
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: AppSizes.xl),
                        // Success state
                        const HeroIcon(
                          HeroIcons.checkCircle,
                          size: 64,
                          color: Colors.white,
                        ),
                        const SizedBox(height: AppSizes.md),
                        const Text(
                          'Password Changed!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        const Text(
                          'Your password has been updated successfully.',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.xl),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Done'),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                      ],
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSizes.md),

                          // Description
                          const Text(
                            'Enter your current password and choose a new password.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),

                          // Current password field
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextFormField(
                              controller: _currentPasswordController,
                              obscureText: !_isCurrentPasswordVisible,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              decoration: InputDecoration(
                                fillColor: Colors.transparent,
                                hintText: 'Current password...',
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                isDense: true,
                                errorStyle: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                suffixIcon: IconButton(
                                  icon: HeroIcon(
                                    _isCurrentPasswordVisible
                                        ? HeroIcons.eye
                                        : HeroIcons.eyeSlash,
                                    size: 20,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isCurrentPasswordVisible =
                                          !_isCurrentPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Current password is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),

                          // New password field
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextFormField(
                              controller: _newPasswordController,
                              obscureText: !_isNewPasswordVisible,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              decoration: InputDecoration(
                                fillColor: Colors.transparent,
                                hintText: 'New password...',
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                isDense: true,
                                errorStyle: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                suffixIcon: IconButton(
                                  icon: HeroIcon(
                                    _isNewPasswordVisible
                                        ? HeroIcons.eye
                                        : HeroIcons.eyeSlash,
                                    size: 20,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isNewPasswordVisible =
                                          !_isNewPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'New password is required';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),

                          // Confirm password field
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              decoration: InputDecoration(
                                fillColor: Colors.transparent,
                                hintText: 'Confirm new password...',
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                isDense: true,
                                errorStyle: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                suffixIcon: IconButton(
                                  icon: HeroIcon(
                                    _isConfirmPasswordVisible
                                        ? HeroIcons.eye
                                        : HeroIcons.eyeSlash,
                                    size: 20,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _newPasswordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),

                          // Change password button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: Colors.white24,
                                disabledForegroundColor: Colors.white38,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                      ),
                                    )
                                  : const Text('Change Password'),
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),

                          // Cancel button
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(height: AppSizes.md),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
