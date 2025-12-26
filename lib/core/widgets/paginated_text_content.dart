import 'package:flutter/material.dart';
import 'package:literature/core/constants/colors.dart';
import 'package:literature/core/constants/sizes.dart';

/// Paginated text content widget for long posts
/// Automatically splits content into pages when it exceeds a threshold
class PaginatedTextContent extends StatefulWidget {
  final String content;
  final String? title;
  final TextStyle? contentStyle;
  final TextStyle? titleStyle;
  final TextAlign textAlign;
  final int maxCharsPerPage;
  final EdgeInsets padding;

  const PaginatedTextContent({
    super.key,
    required this.content,
    this.title,
    this.contentStyle,
    this.titleStyle,
    this.textAlign = TextAlign.start,
    this.maxCharsPerPage = 800,
    this.padding = const EdgeInsets.all(AppSizes.lg),
  });

  @override
  State<PaginatedTextContent> createState() => _PaginatedTextContentState();
}

class _PaginatedTextContentState extends State<PaginatedTextContent> {
  late PageController _pageController;
  int _currentPage = 0;
  late List<String> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = _splitContentIntoPages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Split content into pages based on character count
  /// Tries to split at paragraph breaks or sentence ends
  List<String> _splitContentIntoPages() {
    final totalLength = widget.content.length;

    // If content is short enough, return as single page
    if (totalLength <= widget.maxCharsPerPage) {
      return [widget.content];
    }

    final pages = <String>[];
    var remainingContent = widget.content;

    while (remainingContent.length > widget.maxCharsPerPage) {
      var splitIndex = widget.maxCharsPerPage;

      // Try to split at paragraph break (double newline)
      final paragraphBreak = remainingContent.lastIndexOf('\n\n', splitIndex);
      if (paragraphBreak > splitIndex ~/ 2) {
        splitIndex = paragraphBreak + 2;
      } else {
        // Try to split at single newline
        final lineBreak = remainingContent.lastIndexOf('\n', splitIndex);
        if (lineBreak > splitIndex ~/ 2) {
          splitIndex = lineBreak + 1;
        } else {
          // Try to split at sentence end
          final sentenceEnd = remainingContent.lastIndexOf('. ', splitIndex);
          if (sentenceEnd > splitIndex ~/ 2) {
            splitIndex = sentenceEnd + 2;
          } else {
            // Last resort: split at space
            final spaceIndex = remainingContent.lastIndexOf(' ', splitIndex);
            if (spaceIndex > splitIndex ~/ 2) {
              splitIndex = spaceIndex + 1;
            }
          }
        }
      }

      pages.add(remainingContent.substring(0, splitIndex).trim());
      remainingContent = remainingContent.substring(splitIndex).trim();
    }

    // Add remaining content as last page
    if (remainingContent.isNotEmpty) {
      pages.add(remainingContent);
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final shouldPaginate = _pages.length > 1;

    return Stack(
      children: [
        // Content PageView
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: _pages.length,
          itemBuilder: (context, index) {
            return SingleChildScrollView(
              padding: widget.padding,
              child: Column(
                crossAxisAlignment: widget.textAlign == TextAlign.center
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                mainAxisAlignment: widget.textAlign == TextAlign.center
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  // Title only on first page
                  if (index == 0 && widget.title != null && widget.title!.isNotEmpty) ...[
                    Text(
                      widget.title!,
                      style: widget.titleStyle,
                      textAlign: widget.textAlign,
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],
                  Text(
                    _pages[index],
                    style: widget.contentStyle,
                    textAlign: widget.textAlign,
                  ),
                ],
              ),
            );
          },
        ),

        // Page indicator (only if paginated)
        if (shouldPaginate)
          Positioned(
            bottom: AppSizes.md,
            right: AppSizes.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.gray900.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                border: Border.all(color: AppColors.gray700),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_currentPage + 1}/${_pages.length}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_currentPage < _pages.length - 1) ...[
                    const SizedBox(width: AppSizes.xs),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.gray500,
                      size: 12,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
