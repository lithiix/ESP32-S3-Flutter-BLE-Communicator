import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles ad consent for GDPR compliance and global ad request config.
/// This follows AdMob/AdSense policies: request consent before personalized ads,
/// set `tagForChildDirectedTreatment`/`tagForUnderAgeOfConsent` as needed, and
/// use `MaxAdContentRating` to avoid mature content by default.
class AdConsentService {
  AdConsentService._();
  static final AdConsentService instance = AdConsentService._();

  bool _initialized = false;
  bool _tagForChildDirected = false;
  bool _tagForUnderAge = false;
  bool _consentGiven = false;
  bool _canShowAds = false;
  bool _personalizedAds = false;

  // Keys for SharedPreferences
  static const String _consentGivenKey = 'consent_given';
  static const String _canShowAdsKey = 'can_show_ads';
  static const String _personalizedAdsKey = 'personalized_ads';

  /// Call once during app startup before loading any ads.
  Future<void> initialize({
    bool tagForChildDirectedTreatment = false,
    bool tagForUnderAgeOfConsent = false,
    String? maxAdContentRating,
    List<String> testDeviceIds = const [],
  }) async {
    if (_initialized) return;

    debugPrint('AdConsentService: Initializing...');

    // Persist current flags
    _tagForChildDirected = tagForChildDirectedTreatment;
    _tagForUnderAge = tagForUnderAgeOfConsent;

    try {
      // Load saved consent status
      await _loadConsentStatus();

      // Update ad request configuration based on consent
      await _updateAdRequestConfiguration(
        maxAdContentRating: maxAdContentRating,
        testDeviceIds: testDeviceIds,
      );

      _initialized = true;
      debugPrint('AdConsentService: Initialization complete. Can show ads: $_canShowAds');
    } catch (e) {
      debugPrint('AdConsentService: Initialization failed: $e');
      // Fallback to non-personalized ads
      _canShowAds = false;
      _consentGiven = false;
      await _updateAdRequestConfiguration(
        maxAdContentRating: maxAdContentRating,
        testDeviceIds: testDeviceIds,
      );
      _initialized = true;
    }
  }

  /// Set consent status manually (for GDPR compliance)
  Future<void> setConsent(bool hasConsent, {bool personalizedAds = false}) async {
    _consentGiven = hasConsent;
    _canShowAds = hasConsent && !_tagForChildDirected && !_tagForUnderAge;
    _personalizedAds = personalizedAds && _canShowAds;
    await _saveConsentStatus();
    debugPrint('AdConsentService: Consent set to: $hasConsent, Can show ads: $_canShowAds, Personalized: $_personalizedAds');
  }

  /// Set personalized ads preference
  Future<void> setPersonalizedAds(bool personalized) async {
    _personalizedAds = personalized && _canShowAds;
    await _saveConsentStatus();
    debugPrint('AdConsentService: Personalized ads set to: $_personalizedAds');
  }

  /// Update ad request configuration based on consent and age flags
  Future<void> _updateAdRequestConfiguration({
    String? maxAdContentRating,
    List<String> testDeviceIds = const [],
  }) async {
    final config = RequestConfiguration(
      maxAdContentRating: maxAdContentRating,
      tagForChildDirectedTreatment: _tagForChildDirected
          ? TagForChildDirectedTreatment.yes
          : TagForChildDirectedTreatment.no,
      tagForUnderAgeOfConsent: _tagForUnderAge
          ? TagForUnderAgeOfConsent.yes
          : TagForUnderAgeOfConsent.no,
      testDeviceIds: testDeviceIds,
    );

    await MobileAds.instance.updateRequestConfiguration(config);
    debugPrint('AdConsentService: Ad request configuration updated');
  }

  /// Allow user to update consent from Settings.
  Future<void> presentConsentFormIfAvailable() async {
    debugPrint('AdConsentService: Presenting consent form');
    // This will be handled by the UI dialog in settings_page.dart
    // The actual consent form logic is implemented there
  }

  /// Update request configuration based on a user's age.
  /// For users under 16 in GDPR regions, set TFUA; for under 13 (COPPA), TFCd.
  Future<void> updateAgeFlags({required int ageYears}) async {
    final isUnder13 = ageYears < 13;
    final isUnder16 = ageYears < 16;
    _tagForChildDirected = isUnder13;
    _tagForUnderAge = isUnder16;

    debugPrint('AdConsentService: Updated age flags - Under 13: $isUnder13, Under 16: $isUnder16');

    await _updateAdRequestConfiguration();
  }

  /// Get current consent status
  bool get consentGiven => _consentGiven;

  /// Check if ads can be shown
  bool get canShowAds => _canShowAds;

  /// Check if personalized ads are allowed
  bool get canShowPersonalizedAds {
    return _personalizedAds && _canShowAds;
  }

  /// Get personalized ads preference
  bool get personalizedAds => _personalizedAds;

  /// Save consent status to SharedPreferences
  Future<void> _saveConsentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentGivenKey, _consentGiven);
    await prefs.setBool(_canShowAdsKey, _canShowAds);
    await prefs.setBool(_personalizedAdsKey, _personalizedAds);
    debugPrint('AdConsentService: Saved consent status: $_consentGiven, can show ads: $_canShowAds, personalized: $_personalizedAds');
  }

  /// Load consent status from SharedPreferences
  Future<void> _loadConsentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _consentGiven = prefs.getBool(_consentGivenKey) ?? false;
    _canShowAds = prefs.getBool(_canShowAdsKey) ?? false;
    _personalizedAds = prefs.getBool(_personalizedAdsKey) ?? false;
    
    debugPrint('AdConsentService: Loaded consent status: $_consentGiven, can show ads: $_canShowAds, personalized: $_personalizedAds');
  }

  /// Reset consent (for testing or user request)
  Future<void> resetConsent() async {
    debugPrint('AdConsentService: Resetting consent...');
    _consentGiven = false;
    _canShowAds = false;
    _personalizedAds = false;
    await _saveConsentStatus();
  }

  /// Get debug information about consent status
  Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': _initialized,
      'consentGiven': _consentGiven,
      'canShowAds': _canShowAds,
      'canShowPersonalizedAds': canShowPersonalizedAds,
      'personalizedAds': _personalizedAds,
      'tagForChildDirected': _tagForChildDirected,
      'tagForUnderAge': _tagForUnderAge,
    };
  }
}
