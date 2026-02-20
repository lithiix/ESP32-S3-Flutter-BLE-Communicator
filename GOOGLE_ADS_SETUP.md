# Google Mobile Ads SDK Setup

## Configuration Completed ✅

### 1. SDK Prerequisites
- ✅ Minimum SDK version: **23**
- ✅ Compile SDK version: **35**
- ✅ Target SDK version: **35**

### 2. Gradle Configuration
- ✅ Added Google's Maven repository and Maven Central repository to `settings.gradle.kts`
- ✅ Added Google Mobile Ads SDK dependency (v24.9.0) to `app/build.gradle.kts`
- ✅ Configured `dependencyResolutionManagement` in `settings.gradle.kts`

### 3. AndroidManifest Configuration
- ✅ Added AdMob App ID meta-data to `AndroidManifest.xml`

## AdMob IDs

### App ID
```
ca-app-pub-7246605734713628~6861632529
```

### Ad Unit IDs

#### App Open Ad
```
ca-app-pub-7246605734713628/6813531064
```

#### Banner Ad
```
ca-app-pub-7246605734713628/9985547361
```

## Next Steps for Flutter Implementation

### 1. Add Google Mobile Ads Flutter Package

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  google_mobile_ads: ^5.2.0
```

Then run:
```bash
flutter pub get
```

### 2. Initialize the SDK

In your `main.dart`, initialize the Mobile Ads SDK before running the app:

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(MyApp());
}
```

### 3. Implement App Open Ad

Create a new file `lib/ads/app_open_ad_manager.dart`:

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  static const String adUnitId = 'ca-app-pub-7246605734713628/6813531064';
  
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  void loadAd() {
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  void showAdIfAvailable() {
    if (!_isShowingAd && _appOpenAd != null) {
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAd = true;
        },
        onAdDismissedFullScreenContent: (ad) {
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
          loadAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
          loadAd();
        },
      );
      _appOpenAd!.show();
    }
  }
}
```

### 4. Implement Banner Ad

Example widget for displaying banner ads:

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  static const String adUnitId = 'ca-app-pub-7246605734713628/9985547361';
  
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd != null && _isLoaded) {
      return SizedBox(
        height: _bannerAd!.size.height.toDouble(),
        width: _bannerAd!.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }
}
```


## Troubleshooting: Ads Not Displaying

If your ads are not displaying, check the following:

1. **Real IDs**: Ensure you are using your real production IDs. Production ads often have "No Fill" (Code 3) initially on emulators or newly created accounts.
   - **Production App ID**: `ca-app-pub-7246605734713628~6861632529`
   - **Production App Open ID**: `ca-app-pub-7246605734713628/6813531064`
   - **Production Banner ID**: `ca-app-pub-7246605734713628/9985547361`

2. **Account Approval**: Ensure your AdMob account is fully approved and your payment information is verified.
3. **App ID Verification**: Verify that the `com.google.android.gms.ads.APPLICATION_ID` in `AndroidManifest.xml` matches your AdMob App ID exactly.
4. **Initialization**: The SDK must be initialized using `MobileAds.instance.initialize()` before loading any ads.
5. **Load Time**: Ads take time to load over the network. Using a delay or checking `isAdAvailable` is necessary.

## Implementation Details

I have already:
1. Added the `google_mobile_ads` package to `pubspec.yaml`.
2. Created `lib/ads/app_open_ad_manager.dart` to handle ad logic.
3. Created `lib/ads/app_lifecycle_reactor.dart` to show ads when the app is foregrounded.
4. Updated `lib/main.dart` to initialize the SDK and load the App Open Ad on startup.

## Files Modified

1. `android/settings.gradle.kts` - Added dependency resolution management
2. `android/app/build.gradle.kts` - Added Google Mobile Ads SDK dependency and updated SDK versions
3. `android/app/src/main/AndroidManifest.xml` - Added AdMob App ID meta-data

## Build and Test

To verify the setup:

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

or run on a connected device:

```bash
flutter run
```
