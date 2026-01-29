import 'package:flutter/material.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/storages/gloabl/value.dart';
import 'package:literature/core/utils/content_theme.dart';
import 'package:literature/features/feed/bloc/feed_event.dart';
import 'package:literature/models/post_model.dart';

/// Post content section for feed posts (centered or top-aligned, paginated)
class FeedPostContent extends StatefulWidget {
  final PostModel post;
  final bool isUiHidden;

  const FeedPostContent({
    super.key,
    required this.post,
    this.isUiHidden = false,
  });

  @override
  State<FeedPostContent> createState() => _FeedPostContentState();
}

class _FeedPostContentState extends State<FeedPostContent> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<String> _contentChunks = [];

  @override
  void initState() {
    super.initState();
    _splitContentIntoChunks();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Split content into chunks that fit on screen
  void _splitContentIntoChunks() {
    final content = widget.post.content;
    const int charsPerPage = 280;

    if (content.length <= charsPerPage) {
      _contentChunks = [content];
      return;
    }

    List<String> chunks = [];
    String remainingText = content;

    while (remainingText.length > charsPerPage) {
      int breakPoint = charsPerPage;

      int lastPeriod = remainingText.lastIndexOf('.', breakPoint);
      int lastExclaim = remainingText.lastIndexOf('!', breakPoint);
      int lastQuestion = remainingText.lastIndexOf('?', breakPoint);

      int sentenceEnd = [
        lastPeriod,
        lastExclaim,
        lastQuestion,
      ].reduce((a, b) => a > b ? a : b);

      if (sentenceEnd > breakPoint * 0.6) {
        breakPoint = sentenceEnd + 1;
      } else {
        int lastSpace = remainingText.lastIndexOf(' ', breakPoint);
        if (lastSpace > breakPoint * 0.7) {
          breakPoint = lastSpace + 1;
        }
      }

      chunks.add(remainingText.substring(0, breakPoint).trim());
      remainingText = remainingText.substring(breakPoint).trim();
    }

    if (remainingText.isNotEmpty) {
      chunks.add(remainingText);
    }

    setState(() {
      _contentChunks = chunks;
    });
  }

  double _getTitleFontSize(double screenHeight) {
    if (screenHeight > 700) return 18;
    if (screenHeight > 600) return 16;
    if (screenHeight > 500) return 14;
    return 13;
  }

  double _getContentFontSize(double screenHeight) {
    if (screenHeight > 700) return 15;
    if (screenHeight > 600) return 14;
    if (screenHeight > 500) return 13;
    return 12;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final titleFontSize = _getTitleFontSize(screenHeight);
    final contentFontSize = _getContentFontSize(screenHeight);

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentPage = index);
          },
          itemCount: _contentChunks.length,
          itemBuilder: (context, index) {
            final contentWidget = _buildContentColumn(
              index,
              titleFontSize,
              contentFontSize,
            );

            if (widget.isUiHidden) {
              // Center vertically for full-screen mode
              return SingleChildScrollView(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Center(child: contentWidget),
                ),
              );
            } else {
              // Top-aligned for normal mode
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    top: AppSizes.xl,
                    bottom: AppSizes.xl,
                  ),
                  child: contentWidget,
                ),
              );
            }
          },
        ),

        // Page counter
        if (_contentChunks.length > 1)
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withAlpha(128),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_currentPage + 1}/${_contentChunks.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContentColumn(
    int index,
    double titleFontSize,
    double contentFontSize,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.xl,
      ),
      child: Container(
        color: ContentTheme.getDefaultBackgroundColor(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index == 0 && widget.post.title.isNotEmpty) ...[
              Text(
                widget.post.title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
                textAlign: widget.isUiHidden
                    ? TextAlign.center
                    : TextAlign.start,
              ),
              const SizedBox(height: AppSizes.sm),
            ],
            Text(
              _contentChunks[index],
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: contentFontSize,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: widget.isUiHidden ? TextAlign.center : TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to center scrollable content vertically
class ExpandedContentCentered extends StatelessWidget {
  final Widget child;
  const ExpandedContentCentered({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(child: SingleChildScrollView(child: child)),
        ),
      ],
    );
  }
}
