/// Spacing system based on 8pt grid (See CLAUDE.md Design System)
class AppSizes {
  AppSizes._();

  // Spacing (8-pt grid)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Screen padding
  static const double screenPadding = md;

  // Card padding
  static const double cardPadding = md;

  // Section gap
  static const double sectionGap = lg;

  // Feed item gap
  static const double feedItemGap = xl;

  // Border radius
  static const double radiusNone = 0.0;
  static const double radiusSm = 4.0; // Buttons
  static const double radiusMd = 8.0; // Posts/cards, Images/videos
  static const double radiusLg = 12.0;
  static const double radiusFull = 999.0; // Story avatars only

  // Border width
  static const double borderWidth = 1.0;

  // Button height
  static const double buttonHeight = 48.0;

  // Tap target (accessibility)
  static const double minTapTarget = 44.0;

  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  // Story ring width
  static const double storyRingWidth = 2.0;
}
