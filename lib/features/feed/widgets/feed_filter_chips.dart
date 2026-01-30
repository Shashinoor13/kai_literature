import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:heroicons/heroicons.dart';
import 'package:literature/core/constants/sizes.dart';
import 'package:literature/core/storages/gloabl/value.dart';
import 'package:literature/core/theme/theme_model.dart';
import 'package:literature/features/feed/bloc/feed_bloc.dart';
import 'package:literature/features/feed/bloc/feed_event.dart';
import 'package:literature/features/feed/bloc/feed_state.dart';
import 'package:literature/features/theme/bloc/theme_bloc.dart';
import 'package:literature/features/theme/bloc/theme_event.dart';

/// Extension to get display name for FeedType
extension FeedTypeExtension on FeedType {
  String get displayName {
    switch (this) {
      case FeedType.following:
        return 'Following';
      case FeedType.recommended:
        return 'Writers';
    }
  }
}

/// Extension to get display name for ContentFilter
extension ContentFilterExtension on ContentFilter {
  String get displayName {
    switch (this) {
      case ContentFilter.all:
        return 'Library';
      case ContentFilter.poem:
        return 'Poems';
      case ContentFilter.story:
        return 'Stories';
      case ContentFilter.book:
        return 'Books';
      case ContentFilter.joke:
        return 'Jokes';
      case ContentFilter.reflection:
        return 'Reflections';
      case ContentFilter.research:
        return 'Research';
      case ContentFilter.novel:
        return 'Novels';
      case ContentFilter.other:
        return 'Other';
    }
  }
}

/// Hierarchical filter chips for feed filtering
class FeedFilterChips extends StatefulWidget {
  final FeedBloc feedBloc;

  const FeedFilterChips({super.key, required this.feedBloc});

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

          // Second level filter: All categories
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
                _buildContentFilterChip(context, ContentFilter.book),
                const SizedBox(width: AppSizes.xs),
                _buildContentFilterChip(context, ContentFilter.joke),
                const SizedBox(width: AppSizes.xs),
                _buildContentFilterChip(context, ContentFilter.reflection),
                const SizedBox(width: AppSizes.xs),
                _buildContentFilterChip(context, ContentFilter.research),
                const SizedBox(width: AppSizes.xs),
                _buildContentFilterChip(context, ContentFilter.novel),
                const SizedBox(width: AppSizes.xs),
                _buildContentFilterChip(context, ContentFilter.other),
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
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            feedType.displayName,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
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

    final iconColor = isSelected
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;

    // Heroicons for each filter type (monochrome design)
    Widget iconWidget;
    switch (filter) {
      case ContentFilter.all:
        iconWidget = HeroIcon(
          HeroIcons.buildingLibrary,
          style: HeroIconStyle.outline,
          size: 18,
          color: iconColor,
        );
        break;
      case ContentFilter.poem:
        iconWidget = HeroIcon(
          HeroIcons.bookOpen,
          style: HeroIconStyle.outline,
          size: 18,
          color: iconColor,
        );
        break;
      case ContentFilter.story:
        iconWidget = HeroIcon(
          HeroIcons.documentText,
          style: HeroIconStyle.outline,
          size: 18,
          color: iconColor,
        );
        break;
      case ContentFilter.book:
        iconWidget = HeroIcon(
          HeroIcons.bookmarkSquare,
          style: HeroIconStyle.outline,
          size: 18,
          color: iconColor,
        );
        break;
      case ContentFilter.joke:
        iconWidget = HeroIcon(
          HeroIcons.faceSmile,
          style: HeroIconStyle.outline,
          size: 18,
          color: iconColor,
        );
        break;
      case ContentFilter.reflection:
        iconWidget = HeroIcon(
          HeroIcons.lightBulb,
          style: HeroIconStyle.outline,
          size: 18,
          color: iconColor,
        );
        break;
      case ContentFilter.research:
        iconWidget = HeroIcon(
          HeroIcons.academicCap,
          style: HeroIconStyle.outline,
          size: 18,
          color: iconColor,
        );
        break;
      case ContentFilter.novel:
        iconWidget = HeroIcon(
          HeroIcons.newspaper,
          style: HeroIconStyle.outline,
          size: 18,
          color: iconColor,
        );
        break;
      case ContentFilter.other:
        iconWidget = HeroIcon(
          HeroIcons.ellipsisHorizontalCircle,
          style: HeroIconStyle.outline,
          size: 18,
          color: iconColor,
        );
        break;
    }

    // Monochrome design using theme colors
    final chipColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () {
        if (_selectedContentFilter != filter) {
          GlobalState.instance.selectedContentFilter = filter;
          context.read<ThemeBloc>().add(
            ChangeThemeMode(
              AppThemeMode.custom,
            ), // using custom mode to apply our colors
          );
          widget.feedBloc.add(ChangeContentFilter(filter));
          setState(() {});
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
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
                color: iconColor,
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
