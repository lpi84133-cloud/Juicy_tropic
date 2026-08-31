/// Live legal URLs. Leave null until the pages are published.
/// When a non-empty URL is set, Settings shows the matching button
/// and LegalScreen tries the network first, then cached/local HTML.
class AppLinks {
  AppLinks._();

  /// Insert the Privacy Policy URL here when it is ready.
  static const String? privacyPolicyUrl = 'https://juicytrropic.online/privacy-policy.html';

  /// Insert the Support URL here when it is ready.
  static const String? supportUrl = 'https://juicytrropic.online/support.html';

  static bool get hasPrivacyPolicy => _has(privacyPolicyUrl);
  static bool get hasSupport => _has(supportUrl);

  static bool _has(String? value) =>
      value != null && value.trim().isNotEmpty;
}
