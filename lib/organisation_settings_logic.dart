abstract class OrgSettingsService {
  Future<bool> updateSettings(
    String orgId,
    String currency,
    String language,
    String timeZone,
    Map<String, dynamic> notifications,
    Map<String, dynamic> security,
  );
  Future<Map<String, dynamic>> getSettings(String orgId);
}

class SettingsResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  SettingsResult({
    required this.success,
    this.error,
    this.data,
  });
}

class OrgSettingsLogic {
  final OrgSettingsService service;
  bool _isSubmitting = false;

  // Valid currencies list (example)
  final List<String> validCurrencies = ['USD', 'EUR', 'GBP', 'INR'];
  
  // Valid languages list (example)
  final List<String> validLanguages = ['English', 'Spanish', 'French', 'German'];

  OrgSettingsLogic({required this.service});

  bool get isSubmitting => _isSubmitting;

  Future<SettingsResult> loadSettings(String orgId) async {
    try {
      final data = await service.getSettings(orgId);
      return SettingsResult(success: true, data: data);
    } catch (e) {
      return SettingsResult(success: false, error: e.toString());
    }
  }

  bool isValidCurrency(String currency) {
    return validCurrencies.contains(currency);
  }

  bool isValidLanguage(String language) {
    return validLanguages.contains(language);
  }

  bool isValidTimeZone(String timeZone) {
    if (timeZone.isEmpty) return false;
    // Simple regex for UTC±HH:MM format
    final regex = RegExp(r'^UTC[+-]\d{2}:\d{2}$');
    return regex.hasMatch(timeZone);
  }

  bool isValidNotificationSettings(Map<String, dynamic> notifications) {
    return notifications.containsKey('email') &&
           notifications.containsKey('sms') &&
           notifications.containsKey('push') &&
           notifications.values.every((v) => v is bool);
  }

  bool isValidSecuritySettings(Map<String, dynamic> security) {
    return security.containsKey('twoFactorAuth') &&
           security.containsKey('passwordExpiry') &&
           security.containsKey('ipRestriction') &&
           security['twoFactorAuth'] is bool &&
           security['ipRestriction'] is bool &&
           security['passwordExpiry'] is int &&
           security['passwordExpiry'] >= 0;
  }

  bool isValidSettings(Map<String, dynamic> settings) {
    return settings['orgId']?.isNotEmpty == true &&
           isValidCurrency(settings['currency'] ?? '') &&
           isValidLanguage(settings['language'] ?? '') &&
           isValidTimeZone(settings['timeZone'] ?? '') &&
           isValidNotificationSettings(settings['notifications'] ?? {}) &&
           isValidSecuritySettings(settings['security'] ?? {});
  }

  Future<SettingsResult> updateSettings(
    String orgId,
    String currency,
    String language,
    String timeZone,
    Map<String, dynamic> notifications,
    Map<String, dynamic> security,
  ) async {
    if (_isSubmitting) {
      throw Exception('An update is already in progress');
    }

    final settings = {
      'orgId': orgId,
      'currency': currency,
      'language': language,
      'timeZone': timeZone,
      'notifications': notifications,
      'security': security,
    };

    if (!isValidSettings(settings)) {
      return SettingsResult(
        success: false,
        error: 'Invalid settings data',
      );
    }

    try {
      _isSubmitting = true;
      final success = await service.updateSettings(
        orgId,
        currency,
        language,
        timeZone,
        notifications,
        security,
      );
      return SettingsResult(success: success);
    } catch (e) {
      return SettingsResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isSubmitting = false;
    }
  }

  bool hasSettingsChanged(Map<String, dynamic> original, Map<String, dynamic> current) {
    return original['currency'] != current['currency'] ||
           original['language'] != current['language'] ||
           original['timeZone'] != current['timeZone'] ||
           _hasNotificationsChanged(original['notifications'], current['notifications']) ||
           _hasSecurityChanged(original['security'], current['security']);
  }

  bool _hasNotificationsChanged(Map<String, dynamic>? original, Map<String, dynamic>? current) {
    if (original == null || current == null) return false;
    return original['email'] != current['email'] ||
           original['sms'] != current['sms'] ||
           original['push'] != current['push'];
  }

  bool _hasSecurityChanged(Map<String, dynamic>? original, Map<String, dynamic>? current) {
    if (original == null || current == null) return false;
    return original['twoFactorAuth'] != current['twoFactorAuth'] ||
           original['passwordExpiry'] != current['passwordExpiry'] ||
           original['ipRestriction'] != current['ipRestriction'];
  }
}
