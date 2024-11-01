import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:khatabook_project/organisation_settings_logic.dart';

class MockOrgSettingsService extends Mock implements OrgSettingsService {
  @override
  Future<bool> updateSettings(
    String orgId,
    String currency,
    String language,
    String timeZone,
    Map<String, dynamic> notifications,
    Map<String, dynamic> security,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#updateSettings, [orgId, currency, language, timeZone, notifications, security]),
      returnValue: Future.value(true),
    );
  }

  @override
  Future<Map<String, dynamic>> getSettings(String orgId) async {
    return super.noSuchMethod(
      Invocation.method(#getSettings, [orgId]),
      returnValue: Future.value({
        'currency': 'USD',
        'language': 'English',
        'timeZone': 'UTC+00:00',
        'notifications': {
          'email': true,
          'sms': false,
          'push': true,
        },
        'security': {
          'twoFactorAuth': false,
          'passwordExpiry': 90,
          'ipRestriction': false,
        }
      }),
    );
  }
}

@GenerateMocks([])
void main() {
  group('Organisation Settings Logic Tests', () {
    late OrgSettingsLogic settingsLogic;
    late MockOrgSettingsService mockService;
    const String testOrgId = 'test_org_id';

    setUp(() {
      mockService = MockOrgSettingsService();
      settingsLogic = OrgSettingsLogic(service: mockService);
    });

    test('loads existing settings successfully', () async {
      when(mockService.getSettings(testOrgId)).thenAnswer((_) async => {
        'currency': 'USD',
        'language': 'English',
        'timeZone': 'UTC+00:00',
        'notifications': {
          'email': true,
          'sms': false,
          'push': true,
        },
        'security': {
          'twoFactorAuth': false,
          'passwordExpiry': 90,
          'ipRestriction': false,
        }
      });

      final result = await settingsLogic.loadSettings(testOrgId);

      expect(result.success, true);
      expect(result.data?['currency'], 'USD');
      expect(result.data?['language'], 'English');
      expect(result.data?['timeZone'], 'UTC+00:00');
      expect(result.data?['notifications']['email'], true);
      expect(result.data?['security']['passwordExpiry'], 90);
    });

    test('handles settings loading error', () async {
      when(mockService.getSettings(testOrgId))
          .thenThrow(Exception('Failed to load settings'));

      final result = await settingsLogic.loadSettings(testOrgId);

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('validates currency format', () {
      expect(settingsLogic.isValidCurrency('USD'), true);
      expect(settingsLogic.isValidCurrency('EUR'), true);
      expect(settingsLogic.isValidCurrency(''), false);
      expect(settingsLogic.isValidCurrency('INVALID'), false);
    });

    test('validates language selection', () {
      expect(settingsLogic.isValidLanguage('English'), true);
      expect(settingsLogic.isValidLanguage('Spanish'), true);
      expect(settingsLogic.isValidLanguage(''), false);
      expect(settingsLogic.isValidLanguage('InvalidLanguage'), false);
    });

    test('validates timezone format', () {
      expect(settingsLogic.isValidTimeZone('UTC+00:00'), true);
      expect(settingsLogic.isValidTimeZone('UTC-05:00'), true);
      expect(settingsLogic.isValidTimeZone(''), false);
      expect(settingsLogic.isValidTimeZone('InvalidZone'), false);
    });

    test('validates notification settings', () {
      final validNotifications = {
        'email': true,
        'sms': false,
        'push': true,
      };

      final invalidNotifications = {
        'email': true,
        'push': true,
        // missing 'sms'
      };

      expect(settingsLogic.isValidNotificationSettings(validNotifications), true);
      expect(settingsLogic.isValidNotificationSettings(invalidNotifications), false);
    });

    test('validates security settings', () {
      final validSecurity = {
        'twoFactorAuth': false,
        'passwordExpiry': 90,
        'ipRestriction': false,
      };

      final invalidSecurity = {
        'twoFactorAuth': false,
        'passwordExpiry': -1, // invalid value
        'ipRestriction': false,
      };

      expect(settingsLogic.isValidSecuritySettings(validSecurity), true);
      expect(settingsLogic.isValidSecuritySettings(invalidSecurity), false);
    });

    test('updates settings successfully with valid data', () async {
      final notifications = {
        'email': true,
        'sms': true,
        'push': false,
      };

      final security = {
        'twoFactorAuth': true,
        'passwordExpiry': 60,
        'ipRestriction': true,
      };

      when(mockService.updateSettings(
        testOrgId,
        'EUR',
        'Spanish',
        'UTC+01:00',
        notifications,
        security,
      )).thenAnswer((_) async => true);

      final result = await settingsLogic.updateSettings(
        testOrgId,
        'EUR',
        'Spanish',
        'UTC+01:00',
        notifications,
        security,
      );

      expect(result.success, true);
      expect(result.error, null);

      verify(mockService.updateSettings(
        testOrgId,
        'EUR',
        'Spanish',
        'UTC+01:00',
        notifications,
        security,
      )).called(1);
    });

    test('handles update API errors gracefully', () async {
      final notifications = {
        'email': true,
        'sms': true,
        'push': false,
      };

      final security = {
        'twoFactorAuth': true,
        'passwordExpiry': 60,
        'ipRestriction': true,
      };

      when(mockService.updateSettings(
        testOrgId,
        'EUR',
        'Spanish',
        'UTC+01:00',
        notifications,
        security,
      )).thenThrow(Exception('API Error'));

      final result = await settingsLogic.updateSettings(
        testOrgId,
        'EUR',
        'Spanish',
        'UTC+01:00',
        notifications,
        security,
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('prevents duplicate submission while request is in progress', () async {
      final notifications = {
        'email': true,
        'sms': true,
        'push': false,
      };

      final security = {
        'twoFactorAuth': true,
        'passwordExpiry': 60,
        'ipRestriction': true,
      };

      when(mockService.updateSettings(
        testOrgId,
        'EUR',
        'Spanish',
        'UTC+01:00',
        notifications,
        security,
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        return true;
      });

      final firstRequest = settingsLogic.updateSettings(
        testOrgId,
        'EUR',
        'Spanish',
        'UTC+01:00',
        notifications,
        security,
      );

      expect(settingsLogic.isSubmitting, true);

      expect(
        () => settingsLogic.updateSettings(
          testOrgId,
          'EUR',
          'Spanish',
          'UTC+01:00',
          notifications,
          security,
        ),
        throwsA(isA<Exception>()),
      );

      await firstRequest;
      expect(settingsLogic.isSubmitting, false);
    });

    test('detects if settings have changed', () {
      final originalSettings = {
        'currency': 'USD',
        'language': 'English',
        'timeZone': 'UTC+00:00',
        'notifications': {
          'email': true,
          'sms': false,
          'push': true,
        },
        'security': {
          'twoFactorAuth': false,
          'passwordExpiry': 90,
          'ipRestriction': false,
        }
      };

      final sameSettings = Map<String, dynamic>.from(originalSettings);

      final changedSettings = {
        'currency': 'EUR',  // changed
        'language': 'English',
        'timeZone': 'UTC+00:00',
        'notifications': {
          'email': true,
          'sms': false,
          'push': true,
        },
        'security': {
          'twoFactorAuth': false,
          'passwordExpiry': 90,
          'ipRestriction': false,
        }
      };

      expect(settingsLogic.hasSettingsChanged(originalSettings, sameSettings), false);
      expect(settingsLogic.hasSettingsChanged(originalSettings, changedSettings), true);
    });
  });
}
