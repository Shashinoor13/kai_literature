import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/features/feed/bloc/feed_bloc.dart';
import 'package:literature/features/feed/bloc/feed_event.dart';
import 'package:literature/features/feed/bloc/feed_state.dart';

/// Extension to get display name for FeedType
extension FeedTypeExtension on FeedType {
  String get displayName {
    switch (this) {
      case FeedType.following:
        return 'Following';
      case FeedType.recommended:
        return 'Recommended';
    }
  }
}

/// Extension to get display name for ContentFilter
extension ContentFilterExtension on ContentFilter {
  String get displayName {
    switch (this) {
      case ContentFilter.all:
        return 'All';
      case ContentFilter.poem:
        return 'Poems';
      case ContentFilter.story:
        return 'Stories';
      case ContentFilter.joke:
        return 'Jokes';
    }
  }
}

/// Hierarchical filter chips for feed filtering
class FeedFilterChips extends StatefulWidget {
  final FeedBloc feedBloc;

  const FeedFilterChips({
    super.key,
    required this.feedBloc,
  });

  @override
  State<FeedFilterChips> createState() => _FeedFilterChipsState();
}

class _FeedFilterChipsState extends State<FeedFilterChips> {
  late FeedType _selectedFeedType;
  late ContentFilter _selectedContentFilter;
  late Stream<FeedState> _blocStream;

  @override
  void initState() {
    super.initState();
    _selectedFeedType = widget.feedBloc.currentFeedType;
    _selectedContentFilter = widget.feedBloc.currentContentFilter;
    _blocStream = widget.feedBloc.stream;
    _blocStream.listen((state) {
      if (mounted) {
        setState(() {
          _selectedFeedType = widget.feedBloc.currentFeedType;
          _selectedContentFilter = widget.feedBloc.currentContentFilter;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top level filter: Following / Recommended
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFeedTypeChip(context, FeedType.following),
                const SizedBox(width: AppSizes.xs),
                _buildFeedTypeChip(context, FeedType.recommended),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Second level filter: All / Poems / Stories / Jokes
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildContentFilterChip(context, ContentFilter.all),
                const SizedBox(width: AppSizes.xs),
                _buildContentFilterChip(context, ContentFilter.poem),
                const SizedBox(width: AppSizes.xs),
                _buildContentFilterChip(context, ContentFilter.story),
                const SizedBox(width: AppSizes.xs),
                _buildContentFilterChip(context, ContentFilter.joke),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTypeChip(BuildContext context, FeedType feedType) {
    final isSelected = _selectedFeedType == feedType;

    return GestureDetector(
      onTap: () {
        if (_selectedFeedType != feedType) {
          widget.feedBloc.add(ChangeFeedType(feedType));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            feedType.displayName,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentFilterChip(BuildContext context, ContentFilter filter) {
    final isSelected = _selectedContentFilter == filter;

    // Heroicons and color for each filter type
    Widget iconWidget;
    Color chipColor;
    switch (filter) {
      case ContentFilter.all:
        iconWidget = HeroIcon(
          HeroIcons.squares2x2,
          style: HeroIconStyle.outline,
          size: 18,
          color: isSelected ? Colors.black : Colors.white,
        );
        chipColor = isSelected ? Colors.white : Colors.white12;
        break;
      case ContentFilter.poem:
        iconWidget = HeroIcon(
          HeroIcons.bookOpen,
          style: HeroIconStyle.outline,
          size: 18,
          color: isSelected ? Colors.black : const Color(0xFF90EE90),
        );
        chipColor = isSelected ? const Color(0xFF90EE90) : Colors.white12;
        break;
      case ContentFilter.story:
        iconWidget = HeroIcon(
          HeroIcons.documentText,
          style: HeroIconStyle.outline,
          size: 18,
          color: isSelected ? Colors.black : const Color(0xFFADD8E6),
        );
        chipColor = isSelected ? const Color(0xFFADD8E6) : Colors.white12;
        break;
      case ContentFilter.joke:
        iconWidget = HeroIcon(
          HeroIcons.faceSmile,
          style: HeroIconStyle.outline,
          size: 18,
          color: isSelected ? Colors.black : const Color(0xFFFFD700),
        );
        chipColor = isSelected ? const Color(0xFFFFD700) : Colors.white12;
        break;
    }

    return GestureDetector(
      onTap: () {
        if (_selectedContentFilter != filter) {
          widget.feedBloc.add(ChangeContentFilter(filter));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs - 2,
        ),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 6),
            Text(
              filter.displayName,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
