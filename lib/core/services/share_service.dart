import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:literature/core/services/deep_link_service.dart';
import 'package:literature/models/post_model.dart';
import 'package:literature/repositories/post_repository.dart';

/// Service for sharing posts to other apps
class ShareService {
  final PostRepository _postRepository;

  ShareService({PostRepository? postRepository})
      : _postRepository = postRepository ?? PostRepository();

  /// Share a post to other apps
  /// Creates a deep link that opens the app if installed or redirects to store
  ///
  /// [sharePositionOrigin] is required for iOS/iPad to position the share sheet correctly
  Future<void> sharePost({
    required String postId,
    required String userId,
    required PostModel post,
    required String authorUsername,
    Rect? sharePositionOrigin,
  }) async {
    try {
      // Generate share text with deep link
      final shareText = DeepLinkService.generateShareText(
        postId: postId,
        postTitle: post.title.isNotEmpty ? post.title : 'Check out this post',
        authorUsername: authorUsername,
      );

      // Share using share_plus with position origin for iOS
      final result = await Share.share(
        shareText,
        subject: 'Literature - ${post.title}',
        sharePositionOrigin: sharePositionOrigin,
      );

      // Track share in Firestore if successfully shared
      if (result.status == ShareResultStatus.success) {
        await _postRepository.sharePost(
          userId: userId,
          postId: postId,
        );
      }
    } catch (e) {
      throw Exception('Failed to share post: $e');
    }
  }

  /// Share a post with custom text
  ///
  /// [sharePositionOrigin] is required for iOS/iPad to position the share sheet correctly
  Future<void> sharePostWithText({
    required String postId,
    required String userId,
    required String text,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final result = await Share.share(
        text,
        sharePositionOrigin: sharePositionOrigin,
      );

      if (result.status == ShareResultStatus.success) {
        await _postRepository.sharePost(
          userId: userId,
          postId: postId,
        );
      }
    } catch (e) {
      throw Exception('Failed to share post: $e');
    }
  }

  /// Helper method to get share position origin from a BuildContext and GlobalKey
  /// Call this before sharing to get the button's position on screen
  static Rect? getSharePositionOrigin(BuildContext context, [GlobalKey? key]) {
    final RenderBox? box = key?.currentContext?.findRenderObject() as RenderBox?
        ?? context.findRenderObject() as RenderBox?;

    if (box == null) return null;

    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    return Rect.fromLTWH(
      position.dx,
      position.dy,
      size.width,
      size.height,
    );
  }
}
