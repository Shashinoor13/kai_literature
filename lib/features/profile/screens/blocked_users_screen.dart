import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/repositories/auth_repository.dart';
import 'package:literature/models/user_model.dart';

/// Blocked Users Screen - View and manage blocked users
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<UserModel>? _blockedUsers;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    try {
      final authRepo = context.read<AuthRepository>();
      final blockedUsers = await authRepo.getBlockedUsers(authState.user.id);

      if (!mounted) return;

      setState(() {
        _blockedUsers = blockedUsers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _unblockUser(UserModel user) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock @${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.unblockUser(
        currentUserId: authState.user.id,
        blockedUserId: user.id,
      );

      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Remove user from list
      setState(() {
        _blockedUsers?.removeWhere((u) => u.id == user.id);
      });

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('User unblocked successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text('Error: $_error'),
                )
              : _blockedUsers == null || _blockedUsers!.isEmpty
                  ? const Center(
                      child: Text(
                        'No blocked users',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.screenPadding),
                      itemCount: _blockedUsers!.length,
                      itemBuilder: (context, index) {
                        final user = _blockedUsers![index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSizes.md),
                          child: Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  child: Text(user.username[0].toUpperCase()),
                                ),
                                title: Text('@${user.username}'),
                                subtitle:
                                    user.bio.isNotEmpty ? Text(user.bio) : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.person_outline),
                                  tooltip: 'View Profile',
                                  onPressed: () {
                                    context.push('/user/${user.id}');
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSizes.screenPadding,
                                  0,
                                  AppSizes.screenPadding,
                                  AppSizes.md,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _unblockUser(user),
                                    child: const Text('Unblock'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
