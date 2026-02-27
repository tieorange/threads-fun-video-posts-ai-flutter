import 'package:web/web.dart' as web;
import 'launch_service.dart';

class WebLaunchService implements LaunchService {
  @override
  Future<void> openGemini() async {
    // Simulate a link click to the iOS app deeplink — most compatible approach
    // on iPhone Safari. Does not navigate the current page if the scheme fails.
    final body = web.document.body;
    if (body == null) return;

    final link = web.document.createElement('a') as web.HTMLAnchorElement;
    link.href = 'googlegemini://';
    link.style.display = 'none';
    body.appendChild(link);
    link.click();
    body.removeChild(link);
  }

  @override
  Future<void> launchUrl(String url) async {
    // Open URL in a new tab
    web.window.open(url, '_blank');
  }
}

LaunchService getLaunchService() => WebLaunchService();
