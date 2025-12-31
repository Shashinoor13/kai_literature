import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/constants/colors.dart';
import 'package:literature/features/notifications/bloc/notification_bloc.dart';
import 'package:literature/features/notifications/bloc/notification_event.dart';
import 'package:literature/features/notifications/bloc/notification_state.dart';
import 'package:literature/features/auth/bloc/auth_bloc.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/repositories/notification_repository.dart';
import 'package:literature/models/notification_model.dart';

/// Notifications Screen - In-app notification center
/// See CLAUDE.md: Navigation Structure > Bottom Navigation Bar > Notifications
/// NOTE: NO push notifications (no FCM) - in-app only
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final authState = context.read<AuthBloc>().state;
        final userId = authState is Authenticated ? authState.user.id : '';
        return NotificationBloc(
          notificationRepository: NotificationRepository(),
        )..add(LoadNotifications(userId));
      },
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  List<_NotificationGroup> _groupNotifications(List<NotificationModel> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));
    final oneYearAgo = today.subtract(const Duration(days: 365));

    final todayNotifications = <NotificationModel>[];
    final last7DaysNotifications = <NotificationModel>[];
    final last30DaysNotifications = <NotificationModel>[];
    final lastYearNotifications = <NotificationModel>[];

    for (final notification in notifications) {
      final createdDate = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      if (createdDate.isAtSameMomentAs(today) || createdDate.isAfter(today)) {
        todayNotifications.add(notification);
      } else if (createdDate.isAfter(sevenDaysAgo)) {
        last7DaysNotifications.add(notification);
      } else if (createdDate.isAfter(thirtyDaysAgo)) {
        last30DaysNotifications.add(notification);
      } else if (createdDate.isAfter(oneYearAgo)) {
        lastYearNotifications.add(notification);
      }
    }

    final groups = <_NotificationGroup>[];
    if (todayNotifications.isNotEmpty) {
      groups.add(_NotificationGroup('Today', todayNotifications));
    }
    if (last7DaysNotifications.isNotEmpty) {
      groups.add(_NotificationGroup('Last 7 days', last7DaysNotifications));
    }
    if (last30DaysNotifications.isNotEmpty) {
      groups.add(_NotificationGroup('Last 30 days', last30DaysNotifications));
    }
    if (lastYearNotifications.isNotEmpty) {
      groups.add(_NotificationGroup('Last year', lastYearNotifications));
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userId = authState is Authenticated ? authState.user.id : '';

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      MarkAllNotificationsAsRead(userId),
                    );
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: AppColors.black),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.black),
            );
          }

          if (state is NotificationError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.screenPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_outlined,
                        size: 64,
                        color: AppColors.gray300,
                      ),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        'No notifications yet',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final groupedNotifications = _groupNotifications(state.notifications);

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              itemCount: groupedNotifications.length,
              itemBuilder: (context, index) {
                final group = groupedNotifications[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
                      child: Text(
                        group.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gray500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Notifications in this group
                    ...group.notifications.map((notification) => Column(
                      children: [
                        _NotificationItem(
                          notification: notification,
                          userId: userId,
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.gray300,
                        ),
                      ],
                    )),
                  ],
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final String userId;

  const _NotificationItem({required this.notification, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.gray900,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.md),
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      ),
      onDismissed: (_) {
        context.read<NotificationBloc>().add(
          DeleteNotification(userId, notification.id),
        );
      },
      child: InkWell(
        onTap: () {
          // Mark as read
          if (!notification.isRead) {
            context.read<NotificationBloc>().add(
              MarkNotificationAsRead(userId, notification.id),
            );
          }

          // TODO: Navigate based on notification type
          // You can implement navigation to posts or user profiles here
        },
        child: Container(
          color: notification.isRead ? Colors.transparent : AppColors.gray100,
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.gray300,
                backgroundImage:
                    notification.fromUserProfileImage != null &&
                        notification.fromUserProfileImage!.isNotEmpty
                    ? CachedNetworkImageProvider(
                        notification.fromUserProfileImage!,
                      )
                    : null,
                child:
                    notification.fromUserProfileImage == null ||
                        notification.fromUserProfileImage!.isEmpty
                    ? const Icon(
                        Icons.person_outline,
                        size: AppSizes.iconMd,
                        color: AppColors.gray500,
                      )
                    : null,
              ),
              const SizedBox(width: AppSizes.md),
              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.getMessage(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      timeago.format(notification.createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class to group notifications by time period
class _NotificationGroup {
  final String title;
  final List<NotificationModel> notifications;

  _NotificationGroup(this.title, this.notifications);
}
