import 'package:flutter/material.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/models/post_model.dart';

/// Post content section for feed posts (centered, paginated for long content)
class FeedPostContent extends StatefulWidget {
  final PostModel post;

  const FeedPostContent({
    super.key,
    required this.post,
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

    // Optimized chunk size to maximize content while avoiding overflow
    // Accounts for title space on first page and limited vertical space
    const int charsPerPage = 280; // Balanced at ~280 chars for good readability

    if (content.length <= charsPerPage) {
      _contentChunks = [content];
      return;
    }

    // Split into chunks, trying to break at sentence boundaries
    List<String> chunks = [];
    String remainingText = content;

    while (remainingText.length > charsPerPage) {
      int breakPoint = charsPerPage;

      // Try to find a sentence ending (. ! ?) near the break point
      int lastPeriod = remainingText.lastIndexOf('.', breakPoint);
      int lastExclaim = remainingText.lastIndexOf('!', breakPoint);
      int lastQuestion = remainingText.lastIndexOf('?', breakPoint);

      int sentenceEnd = [lastPeriod, lastExclaim, lastQuestion]
          .reduce((a, b) => a > b ? a : b);

      // If we found a sentence ending within reasonable distance, use it
      if (sentenceEnd > breakPoint * 0.6) {
        breakPoint = sentenceEnd + 1;
      } else {
        // Otherwise, try to break at a space
        int lastSpace = remainingText.lastIndexOf(' ', breakPoint);
        if (lastSpace > breakPoint * 0.7) {
          breakPoint = lastSpace + 1;
        }
      }

      chunks.add(remainingText.substring(0, breakPoint).trim());
      remainingText = remainingText.substring(breakPoint).trim();
    }

    // Add the remaining text
    if (remainingText.isNotEmpty) {
      chunks.add(remainingText);
    }

    setState(() {
      _contentChunks = chunks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Paginated content
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: _contentChunks.length,
          itemBuilder: (context, index) {
            return Padding(
              // Add padding to avoid overlap with UI elements
              // Top: Search bar + Stories + Tabs + Filter chips
              // Bottom: Author info + Interactions + Page counter
              padding: const EdgeInsets.only(
                bottom: 200,
                top: 280,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show title only on first page
                      if (index == 0 && widget.post.title.isNotEmpty) ...[
                        Text(
                          widget.post.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.sm),
                      ],
                      Text(
                        _contentChunks[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Page counter at bottom - only show if multiple pages
        if (_contentChunks.length > 1)
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  border: Border.all(
                    color: Colors.white24,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_currentPage + 1}/${_contentChunks.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

        // Swipe hint - show on first page if there are multiple pages
        if (_contentChunks.length > 1 && _currentPage == 0)
          Positioned(
            right: AppSizes.md,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.xs),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
