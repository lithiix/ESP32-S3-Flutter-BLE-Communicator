import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ble_esp32/ads/app_open_ad_manager.dart';
import 'package:flutter/foundation.dart';

/// Listens for app foreground events and shows app open ads.
class AppLifecycleReactor {
  void listenToAppStateChanges() {
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.listen((AppState appState) {
      debugPrint('App State Change: $appState');
      if (appState == AppState.foreground) {
        AppOpenAdManager.showAdIfAvailable();
      }
    });
  }
}
