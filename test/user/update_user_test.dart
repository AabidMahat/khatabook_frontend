import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:khatabook_project/updateUser.dart';
import 'package:khatabook_project/user_update_logic.dart';

class MockUserService extends Mock implements UserService {
  @override
  Future<bool> updateUser(
    String userId,
    String name,
    String email,
    String phone,
    String password,
    Map<String, dynamic> preferences,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#updateUser, [userId, name, email, phone, password, preferences]),
      returnValue: Future.value(true),
    );
  }

  @override
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    return super.noSuchMethod(
      Invocation.method(#getUserDetails, [userId]),
      returnValue: Future.value({
        'name': 'Test User',
        'email': 'user@example.com',
        'phone': '1234567890',
        'preferences': {
          'darkMode': false,
          'notifications': true,
          'language': 'English'
        }
      }),
    );
  }
}

@GenerateMocks([])
void main() {
  group('User Update Logic Tests', () {
    late UserUpdateLogic userLogic;
    late MockUserService mockService;
    const String testUserId = 'test_user_id';

    setUp(() {
      mockService = MockUserService();
      userLogic = UserUpdateLogic(service: mockService);
    });

    test('loads existing user details successfully', () async {
      when(mockService.getUserDetails(testUserId)).thenAnswer((_) async => {
        'name': 'Test User',
        'email': 'user@example.com',
        'phone': '1234567890',
        'preferences': {
          'darkMode': false,
          'notifications': true,
          'language': 'English'
        }
      });

      final result = await userLogic.loadUserDetails(testUserId);

      expect(result.success, true);
      expect(result.data?['name'], 'Test User');
      expect(result.data?['email'], 'user@example.com');
      expect(result.data?['phone'], '1234567890');
      expect(result.data?['preferences']['darkMode'], false);
    });

    test('handles user details loading error', () async {
      when(mockService.getUserDetails(testUserId))
          .thenThrow(Exception('Failed to load user details'));

      final result = await userLogic.loadUserDetails(testUserId);

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('validates email format', () {
      expect(userLogic.isValidEmail('user@example.com'), true);
      expect(userLogic.isValidEmail('invalid-email'), false);
      expect(userLogic.isValidEmail(''), false);
    });

    test('validates phone number format', () {
      expect(userLogic.isValidPhone('1234567890'), true);
      expect(userLogic.isValidPhone('123'), false);
      expect(userLogic.isValidPhone(''), false);
      expect(userLogic.isValidPhone('abcdefghij'), false);
    });

    test('validates user name', () {
      expect(userLogic.isValidName('John Doe'), true);
      expect(userLogic.isValidName(''), false);
      expect(userLogic.isValidName('   '), false);
    });

    test('validates password format', () {
      expect(userLogic.isValidPassword('Password123!'), true);
      expect(userLogic.isValidPassword('weak'), false);
      expect(userLogic.isValidPassword(''), false);
      expect(userLogic.isValidPassword('   '), false);
    });

    test('validates user preferences', () {
      final validPreferences = {
        'darkMode': false,
        'notifications': true,
        'language': 'English'
      };

      final invalidPreferences = {
        'darkMode': 'invalid', // should be boolean
        'notifications': true,
        'language': 'English'
      };

      expect(userLogic.isValidPreferences(validPreferences), true);
      expect(userLogic.isValidPreferences(invalidPreferences), false);
    });

    test('validates complete user data', () {
      final validData = {
        'userId': testUserId,
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '1234567890',
        'password': 'Password123!',
        'preferences': {
          'darkMode': false,
          'notifications': true,
          'language': 'English'
        }
      };

      expect(userLogic.isValidUserData(validData), true);

      final invalidData = {
        'userId': testUserId,
        'name': '',  // invalid
        'email': 'john@example.com',
        'phone': '1234567890',
        'password': 'Password123!',
        'preferences': {
          'darkMode': false,
          'notifications': true,
          'language': 'English'
        }
      };

      expect(userLogic.isValidUserData(invalidData), false);
    });

    test('updates user successfully with valid data', () async {
      final preferences = {
        'darkMode': true,
        'notifications': false,
        'language': 'Spanish'
      };

      when(mockService.updateUser(
        testUserId,
        'John Doe',
        'john@example.com',
        '1234567890',
        'Password123!',
        preferences,
      )).thenAnswer((_) async => true);

      final result = await userLogic.updateUser(
        testUserId,
        'John Doe',
        'john@example.com',
        '1234567890',
        'Password123!',
        preferences,
      );

      expect(result.success, true);
      expect(result.error, null);

      verify(mockService.updateUser(
        testUserId,
        'John Doe',
        'john@example.com',
        '1234567890',
        'Password123!',
        preferences,
      )).called(1);
    });

    test('handles update API errors gracefully', () async {
      final preferences = {
        'darkMode': true,
        'notifications': false,
        'language': 'Spanish'
      };

      when(mockService.updateUser(
        testUserId,
        'John Doe',
        'john@example.com',
        '1234567890',
        'Password123!',
        preferences,
      )).thenThrow(Exception('API Error'));

      final result = await userLogic.updateUser(
        testUserId,
        'John Doe',
        'john@example.com',
        '1234567890',
        'Password123!',
        preferences,
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('prevents duplicate submission while request is in progress', () async {
      final preferences = {
        'darkMode': true,
        'notifications': false,
        'language': 'Spanish'
      };

      when(mockService.updateUser(
        testUserId,
        'John Doe',
        'john@example.com',
        '1234567890',
        'Password123!',
        preferences,
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        return true;
      });

      final firstRequest = userLogic.updateUser(
        testUserId,
        'John Doe',
        'john@example.com',
        '1234567890',
        'Password123!',
        preferences,
      );

      expect(userLogic.isSubmitting, true);

      expect(
        () => userLogic.updateUser(
          testUserId,
          'John Doe',
          'john@example.com',
          '1234567890',
          'Password123!',
          preferences,
        ),
        throwsA(isA<Exception>()),
      );

      await firstRequest;
      expect(userLogic.isSubmitting, false);
    });

    test('detects if user data has changed', () {
      final originalData = {
        'name': 'Test User',
        'email': 'user@example.com',
        'phone': '1234567890',
        'preferences': {
          'darkMode': false,
          'notifications': true,
          'language': 'English'
        }
      };

      final sameData = Map<String, dynamic>.from(originalData);

      final changedData = {
        'name': 'Updated User',  // changed
        'email': 'user@example.com',
        'phone': '1234567890',
        'preferences': {
          'darkMode': false,
          'notifications': true,
          'language': 'English'
        }
      };

      expect(userLogic.hasDataChanged(originalData, sameData), false);
      expect(userLogic.hasDataChanged(originalData, changedData), true);
    });
  });
}
