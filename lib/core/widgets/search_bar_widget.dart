import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:literature/core/constants/sizes.dart';

/// Reusable platform-adaptive search bar widget
/// Used throughout the app for consistent search UI
class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final Widget? suffixIcon;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.autofocus = false,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(isIOS ? 10 : 20),
      ),
      child: Row(
        children: [
          HeroIcon(
            HeroIcons.magnifyingGlass,
            style: HeroIconStyle.outline,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              enabled: enabled,
              onChanged: onChanged,
              onTap: onTap,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
                filled: true,
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon!,
        ],
      ),
    );
  }
}
