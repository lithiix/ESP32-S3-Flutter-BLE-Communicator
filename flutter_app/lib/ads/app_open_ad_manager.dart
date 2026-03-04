import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// App Open Ad manager to show ads on app launch.
/// Logic exactly matches the MedzophenApp pattern provided by user.
class AppOpenAdManager {
  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;
  static bool _requestedThisLaunch = false;

  // Dedicated App Open Ad unit ID for ESP32 BLE Communicator
  // Source: AdMob dashboard → ca-app-pub-7246605734713628~6861632529
  static String get _adUnitId => 'ca-app-pub-7246605734713628/6813531064';

  static void prepareAndScheduleShow() {
    if (_requestedThisLaunch || _isShowingAd) return;
    _requestedThisLaunch = true;

    debugPrint('AppOpenAdManager: Loading App Open Ad...');
    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (AppOpenAd ad) {
          debugPrint('AppOpenAdManager: App Open Ad loaded successfully');
          _appOpenAd = ad;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('AppOpenAdManager: App Open Ad showed full screen content');
              _isShowingAd = true;
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('AppOpenAdManager: App Open Ad dismissed');
              _isShowingAd = false;
              ad.dispose();
              _appOpenAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AppOpenAdManager: App Open Ad failed to show: $error');
              _isShowingAd = false;
              ad.dispose();
              _appOpenAd = null;
            },
          );

          // Show after first frame to avoid jank on startup UI
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isShowingAd && _appOpenAd != null) {
              _appOpenAd!.show();
            }
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AppOpenAdManager: App Open Ad failed to load: $error');
          _appOpenAd = null;
        },
      ),
    );
  }

  // Check if ad is available and not currently showing
  static bool get isAdAvailable => _appOpenAd != null && !_isShowingAd;

  // Show the ad if available
  static void showAdIfAvailable() {
    if (isAdAvailable) {
      _appOpenAd!.show();
    }
  }

  // Dispose of the ad
  static void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isShowingAd = false;
  }
}
