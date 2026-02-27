import 'launch_service_stub.dart' if (dart.library.js_util) 'launch_service_web.dart';

abstract class LaunchService {
  /// Open the Gemini AI tool.
  /// On iOS (web context): tries the Gemini app deeplink first, falls back to
  /// gemini.google.com in a new tab if the app is not installed.
  /// On desktop: opens gemini.google.com in a new tab.
  Future<void> openGemini();

  /// Open any URL in a new tab/window.
  /// [url]: The URL to open (must include scheme, e.g., https://)
  Future<void> launchUrl(String url);

  factory LaunchService() => getLaunchService();
}

class DefaultLaunchService implements LaunchService {
  @override
  Future<void> openGemini() async {
    // Stub for non-web environments — no-op.
  }

  @override
  Future<void> launchUrl(String url) async {
    // Stub for non-web environments — no-op.
  }
}
