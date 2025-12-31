import 'dart:io';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_event.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';

/// Edit Profile Screen
/// Allows users to update their username and bio
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _usernameController.text = authState.user.username;
      _bioController.text = authState.user.bio;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_selectedImage == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _isUploading = false;
      });

      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;

      // Upload image if one was selected
      String? profileImageUrl;
      if (_selectedImage != null) {
        profileImageUrl = await _uploadProfileImage(authState.user.id);
        if (profileImageUrl == null) {
          // Upload failed, don't proceed with save
          return;
        }
      }

      if (!mounted) return;

      context.read<AuthBloc>().add(
        UpdateProfileRequested(
          username: _usernameController.text.trim(),
          bio: _bioController.text.trim(),
          profileImageUrl: profileImageUrl,
        ),
      );

      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) {
          return const Scaffold(body: Center(child: Text('Please log in')));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Profile'),
            actions: [
              TextButton(onPressed: _handleSave, child: const Text('Save')),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Picture
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (state.user.profileImageUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      state.user.profileImageUrl,
                                    )
                                  : null),
                          child: _selectedImage == null &&
                                  state.user.profileImageUrl.isEmpty
                              ? Text(
                                  state.user.username[0].toUpperCase(),
                                  style:
                                      Theme.of(context).textTheme.displayLarge,
                                )
                              : null,
                        ),
                        if (_isUploading)
                          Positioned.fill(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.5),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploading ? null : _pickImage,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: const HeroIcon(
                                HeroIcons.camera,
                                style: HeroIconStyle.solid,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),

                  // Username field (borderless)
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 0,
                      ),
                    ),
                    style: TextStyle(fontSize: 16),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username is required';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (value.contains(' ')) {
                        return 'Username cannot contain spaces';
                      }
                      return null;
                    },
                  ),
                  const Divider(),

                  // Bio field (borderless)
                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Tell us about yourself',
                      alignLabelWithHint: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 0,
                      ),
                    ),
                    style: TextStyle(fontSize: 16),
                  ),
                  const Divider(),
                  const SizedBox(height: AppSizes.lg),

                  // Account info (no card, just section with dividers)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const HeroIcon(
                              HeroIcons.informationCircle,
                              style: HeroIconStyle.outline,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Account Information',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Email',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              state.user.email,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Followers',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${state.user.followersCount}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Following',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${state.user.followingCount}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
