import 'dart:io';

/// Service for handling deep links and share URLs
/// Creates links that open the app if installed, otherwise redirect to stores
class DeepLinkService {
  static const String appScheme = 'literature';
  static const String domain = 'thekaiverse.com';
  static const String appStoreId = 'YOUR_APP_STORE_ID'; // Replace with actual App Store ID
  static const String playStoreId = 'com.thekaiverse.literature'; // Replace with actual package name

  /// Generate a deep link for a post
  /// Format: literature://post/{postId}
  static String generatePostDeepLink(String postId) {
    return '$appScheme://post/$postId';
  }

  /// Generate a universal link (web URL that redirects to app or store)
  /// Format: https://thekaiverse.com/post/{postId}
  static String generatePostUniversalLink(String postId) {
    return 'https://$domain/post/$postId';
  }

  /// Generate share text with app link
  static String generateShareText({
    required String postId,
    required String postTitle,
    required String authorUsername,
  }) {
    final link = generatePostUniversalLink(postId);
    return '"$postTitle" by @$authorUsername\n\nRead on Literature\n$link';
  }

  /// Get store URL based on platform
  static String getStoreUrl() {
    if (Platform.isIOS) {
      return 'https://apps.apple.com/app/id$appStoreId';
    } else if (Platform.isAndroid) {
      return 'https://play.google.com/store/apps/details?id=$playStoreId';
    }
    return 'https://$domain';
  }

  /// Generate store redirect HTML for web
  /// This can be hosted at thekaiverse.com/post/{postId}
  static String generateRedirectHtml(String postId) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Literature - Where words come alive</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body {
      font-family: system-ui, -apple-system, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      background: #000;
      color: #fff;
      text-align: center;
      padding: 20px;
    }
    .container {
      max-width: 400px;
    }
    h1 { margin-bottom: 16px; }
    p { color: #7A7A7A; margin-bottom: 24px; }
    .btn {
      display: inline-block;
      background: #fff;
      color: #000;
      padding: 12px 24px;
      border-radius: 4px;
      text-decoration: none;
      font-weight: 500;
    }
  </style>
  <script>
    // Try to open the app
    window.location.replace('$appScheme://post/$postId');

    // If still here after 2 seconds, redirect to store
    setTimeout(function() {
      var userAgent = navigator.userAgent || navigator.vendor || window.opera;

      if (/iPad|iPhone|iPod/.test(userAgent) && !window.MSStream) {
        window.location.replace('https://apps.apple.com/app/id$appStoreId');
      } else if (/android/i.test(userAgent)) {
        window.location.replace('https://play.google.com/store/apps/details?id=$playStoreId');
      } else {
        window.location.replace('https://$domain');
      }
    }, 2000);
  </script>
</head>
<body>
  <div class="container">
    <h1>Literature</h1>
    <p>Opening in app...</p>
    <a href="#" class="btn" onclick="location.reload()">Open App</a>
  </div>
</body>
</html>
''';
  }
}
