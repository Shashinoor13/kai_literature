import 'package:flutter/material.dart';
import 'package:literature/core/constants/sizes.dart';

import 'package:literature/models/post_model.dart';

/// Post content section for feed posts (centered or top-aligned, paginated)
// class FeedPostContent extends StatefulWidget {
//   final PostModel post;
//   final bool isUiHidden;

//   const FeedPostContent({
//     super.key,
//     required this.post,
//     this.isUiHidden = false,
//   });

//   @override
//   State<FeedPostContent> createState() => _FeedPostContentState();
// }

// class _FeedPostContentState extends State<FeedPostContent> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;

//   List<String> _contentChunks = [];
//   List<String> _fullScreenPages = [];
//   List<String> _fullScreenChunks = [];

//   @override
//   void initState() {
//     super.initState();
//     // _fullScreenPages = pages;
//     _currentPage = 0;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_pageController.hasClients) {
//         _pageController.jumpToPage(0);
//       }
//     });
//     // _splitContentIntoChunks();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();

//     if (widget.isUiHidden) {
//       _paginateForFullScreen();
//     } else {
//       _splitContentIntoChunks();
//     }
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   /// Split content into chunks that fit on screen
//   void _splitContentIntoChunks() {
//     final content = widget.post.content;
//     const int charsPerPage = 280;

//     if (content.length <= charsPerPage) {
//       _contentChunks = [content];
//       return;
//     }

//     List<String> chunks = [];
//     String remainingText = content;

//     while (remainingText.length > charsPerPage) {
//       int breakPoint = charsPerPage;

//       int lastPeriod = remainingText.lastIndexOf('.', breakPoint);
//       int lastExclaim = remainingText.lastIndexOf('!', breakPoint);
//       int lastQuestion = remainingText.lastIndexOf('?', breakPoint);

//       int sentenceEnd = [
//         lastPeriod,
//         lastExclaim,
//         lastQuestion,
//       ].reduce((a, b) => a > b ? a : b);

//       if (sentenceEnd > breakPoint * 0.6) {
//         breakPoint = sentenceEnd + 1;
//       } else {
//         int lastSpace = remainingText.lastIndexOf(' ', breakPoint);
//         if (lastSpace > breakPoint * 0.7) {
//           breakPoint = lastSpace + 1;
//         }
//       }

//       chunks.add(remainingText.substring(0, breakPoint).trim());
//       remainingText = remainingText.substring(breakPoint).trim();
//     }

//     if (remainingText.isNotEmpty) {
//       chunks.add(remainingText);
//     }

//     setState(() {
//       _contentChunks = chunks;
//     });
//   }

//   double _getTitleFontSize(double screenHeight) {
//     if (screenHeight > 700) return 18;
//     if (screenHeight > 600) return 16;
//     if (screenHeight > 500) return 14;
//     return 13;
//   }

//   double _getContentFontSize(double screenHeight) {
//     if (screenHeight > 700) return 15;
//     if (screenHeight > 600) return 14;
//     if (screenHeight > 500) return 13;
//     return 12;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final titleFontSize = _getTitleFontSize(screenHeight);
//     final contentFontSize = _getContentFontSize(screenHeight);

//     return Stack(
//       children: [
//         PageView.builder(
//           controller: _pageController,
//           physics: const PageScrollPhysics(),
//           onPageChanged: (index) {
//             setState(() => _currentPage = index);
//           },
//           itemCount: widget.isUiHidden
//               ? _fullScreenPages.length
//               : _contentChunks.length,
//           itemBuilder: (context, index) {
//             return widget.isUiHidden
//                 ? _buildFullScreenPage(index)
//                 : _buildContentColumn(index, titleFontSize, contentFontSize);
//           },
//         ),

//         // PageView.builder(
//         //   controller: _pageController,
//         //   onPageChanged: (index) {
//         //     setState(() => _currentPage = index);
//         //   },
//         //   itemCount: _contentChunks.length,
//         //   itemBuilder: (context, index) {
//         //     final contentWidget = _buildContentColumn(
//         //       index,
//         //       titleFontSize,
//         //       contentFontSize,
//         //     );

//         //     if (widget.isUiHidden) {
//         //       // Center vertically for full-screen mode
//         //       return SingleChildScrollView(
//         //         child: SizedBox(
//         //           height: MediaQuery.of(context).size.height,
//         //           child: Center(child: contentWidget),
//         //         ),
//         //       );
//         //     } else {
//         //       // Top-aligned for normal mode
//         //       return Center(
//         //         child: SingleChildScrollView(
//         //           padding: const EdgeInsets.only(
//         //             top: AppSizes.xl,
//         //             bottom: AppSizes.xl,
//         //           ),
//         //           child: contentWidget,
//         //         ),
//         //       );
//         //     }
//         //   },
//         // ),

//         // Page counter
//         if (widget.isUiHidden && _fullScreenPages.length > 1)
//           Positioned(
//             bottom: 80,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.chevron_left, size: 32),
//                   onPressed: _currentPage > 0
//                       ? () => _pageController.previousPage(
//                           duration: const Duration(milliseconds: 300),
//                           curve: Curves.easeOut,
//                         )
//                       : null,
//                 ),
//                 Text(
//                   '${_currentPage + 1} / ${_fullScreenPages.length}',
//                   style: const TextStyle(fontWeight: FontWeight.w500),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.chevron_right, size: 32),
//                   onPressed: _currentPage < _fullScreenPages.length - 1
//                       ? () => _pageController.nextPage(
//                           duration: const Duration(milliseconds: 300),
//                           curve: Curves.easeOut,
//                         )
//                       : null,
//                 ),
//               ],
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildFullScreenPage(int index) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSizes.xl,
//         vertical: AppSizes.xl,
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           if (index == 0 && widget.post.title.isNotEmpty) ...[
//             Text(
//               widget.post.title,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: _getTitleFontSize(MediaQuery.of(context).size.height),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: AppSizes.md),
//           ],
//           Text(
//             _fullScreenPages[index],
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: _getContentFontSize(MediaQuery.of(context).size.height),
//               height: 1.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _paginateForFullScreen() {
//     final content = widget.post.content;
//     if (content.isEmpty) return;

//     final media = MediaQuery.of(context);
//     final screenHeight = media.size.height;
//     final screenWidth = media.size.width;

//     final titleFontSize = _getTitleFontSize(screenHeight);
//     final contentFontSize = _getContentFontSize(screenHeight);

//     final titleHeight = widget.post.title.isNotEmpty
//         ? titleFontSize * 1.4 + AppSizes.md
//         : 0;

//     final availableHeight = screenHeight - titleHeight - (AppSizes.xl * 2);
//     final textStyle = TextStyle(fontSize: contentFontSize, height: 1.5);

//     List<String> pages = []; // ✅ local is OK
//     int start = 0;

//     while (start < content.length) {
//       int end = (start + 50).clamp(0, content.length);
//       String sub = content.substring(start, end);

//       while (true) {
//         final tp = TextPainter(
//           text: TextSpan(text: sub, style: textStyle),
//           textDirection: TextDirection.ltr,
//         );

//         tp.layout(maxWidth: screenWidth - AppSizes.xl * 2);

//         if (tp.height > availableHeight) {
//           final lastSpace = sub.lastIndexOf(' ');
//           if (lastSpace <= start) break;
//           sub = sub.substring(0, lastSpace);
//           break;
//         }

//         if (end == content.length) break;
//         end = (end + 20).clamp(0, content.length);
//         sub = content.substring(start, end);
//       }

//       pages.add(sub.trim());
//       start += sub.length;
//     }

//     // ✅ ASSIGN HERE
//     setState(() {
//       _fullScreenChunks = pages;
//       _currentPage = 0;
//     });

//     // ✅ Jump AFTER build
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_pageController.hasClients) {
//         _pageController.jumpToPage(0);
//       }
//     });
//   }

//   Widget _buildContentColumn(
//     int index,
//     double titleFontSize,
//     double contentFontSize,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSizes.xl,
//         vertical: AppSizes.xl,
//       ),
//       child: Container(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (index == 0 && widget.post.title.isNotEmpty) ...[
//               Text(
//                 widget.post.title,
//                 style: TextStyle(
//                   color: Theme.of(context).colorScheme.onSurface,
//                   fontSize: titleFontSize,
//                   fontWeight: FontWeight.bold,
//                   height: 1.4,
//                 ),
//                 textAlign: widget.isUiHidden
//                     ? TextAlign.center
//                     : TextAlign.start,
//               ),
//               const SizedBox(height: AppSizes.sm),
//             ],
//             Text(
//               _contentChunks[index],
//               style: TextStyle(
//                 color: Theme.of(context).colorScheme.onSurface,
//                 fontSize: contentFontSize,
//                 fontWeight: FontWeight.w400,
//                 height: 1.5,
//               ),
//               textAlign: widget.isUiHidden ? TextAlign.center : TextAlign.start,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Widget to center scrollable content vertically
// class ExpandedContentCentered extends StatelessWidget {
//   final Widget child;
//   const ExpandedContentCentered({super.key, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(
//           child: Center(child: SingleChildScrollView(child: child)),
//         ),
//       ],
//     );
//   }
// }

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
  List<String> _fullScreenPages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.isUiHidden) {
      _paginateForFullScreen();
    } else {
      _splitContentIntoChunks();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ================= NORMAL MODE =================
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
  // void _splitContentIntoChunks() {
  //   final content = widget.post.content;
  //   const int charsPerPage = 280;

  //   List<String> chunks = [];
  //   String remaining = content;

  //   while (remaining.length > charsPerPage) {
  //     int cut = remaining.lastIndexOf(' ', charsPerPage);
  //     if (cut <= 0) cut = charsPerPage;

  //     chunks.add(remaining.substring(0, cut).trim());
  //     remaining = remaining.substring(cut).trim();
  //   }

  //   if (remaining.isNotEmpty) chunks.add(remaining);

  //   setState(() {
  //     _contentChunks = chunks;
  //     _currentPage = 0;
  //   });
  // }

  // ================= FULL SCREEN MODE =================

  void _paginateForFullScreen() {
    final content = widget.post.content;
    if (content.isEmpty) return;

    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final screenWidth = media.size.width;

    final titleFont = _getTitleFontSize(screenHeight);
    final contentFont = _getContentFontSize(screenHeight);

    final titleHeight = widget.post.title.isNotEmpty
        ? titleFont * 1.4 + AppSizes.md
        : 0;

    final availableHeight = screenHeight - titleHeight - (AppSizes.xl * 2);

    final textStyle = TextStyle(fontSize: contentFont, height: 1.5);

    List<String> pages = [];
    int start = 0;

    while (start < content.length) {
      int end = (start + 80).clamp(0, content.length);
      String sub = content.substring(start, end);

      while (true) {
        final tp = TextPainter(
          text: TextSpan(text: sub, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: screenWidth - AppSizes.xl * 2);

        if (tp.height > availableHeight) {
          int lastSpace = sub.lastIndexOf(' ');
          if (lastSpace <= 0) break;
          sub = sub.substring(0, lastSpace);
          break;
        }

        if (end == content.length) break;
        end = (end + 40).clamp(0, content.length);
        sub = content.substring(start, end);
      }

      pages.add(sub.trim());
      start += sub.length;
    }

    setState(() {
      _fullScreenPages = pages;
      _currentPage = 0;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final titleFontSize = _getTitleFontSize(screenHeight);
    final contentFontSize = _getContentFontSize(screenHeight);

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,

          physics: widget.isUiHidden
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemCount: widget.isUiHidden
              ? _fullScreenPages.length
              : _contentChunks.length,
          itemBuilder: (_, index) {
            return widget.isUiHidden
                ? _buildFullScreenPage(index)
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        top: AppSizes.xl,
                        bottom: AppSizes.xl,
                      ),
                      child: _buildNormalPage(
                        index,
                        titleFontSize,
                        contentFontSize,
                      ),
                    ),
                  );
          },
        ),

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

  Widget _buildNormalPage(
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

  Widget _buildFullScreenPage(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xl,
        vertical: AppSizes.lg,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (index == 0 && widget.post.title.isNotEmpty) ...[
              Text(
                widget.post.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
            ],

            Text(
              _fullScreenPages[index],
              textAlign: TextAlign.justify,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                letterSpacing: 0.2,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getTitleFontSize(double h) => h > 700
      ? 18
      : h > 600
      ? 16
      : 14;

  double _getContentFontSize(double h) => h > 700
      ? 15
      : h > 600
      ? 14
      : 13;
}
