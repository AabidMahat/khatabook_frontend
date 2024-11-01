import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:khatabook_project/Register.dart';
import 'package:khatabook_project/registration_logic.dart';

class MockRegistrationService extends Mock implements RegistrationService {
  @override
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String password,
    String confirmPassword,
    Map<String, dynamic> additionalInfo,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#register, [name, email, phone, password, confirmPassword, additionalInfo]),
      returnValue: Future.value({
        'success': true,
        'userId': 'new_user_id',
        'token': 'registration_token',
      }),
    );
  }

  @override
  Future<bool> checkEmailAvailability(String email) async {
    return super.noSuchMethod(
      Invocation.method(#checkEmailAvailability, [email]),
      returnValue: Future.value(true),
    );
  }
}

@GenerateMocks([])
void main() {
  group('Registration Logic Tests', () {
    late RegistrationLogic registrationLogic;
    late MockRegistrationService mockService;

    setUp(() {
      mockService = MockRegistrationService();
      registrationLogic = RegistrationLogic(service: mockService);
    });

    test('validates name format', () {
      expect(registrationLogic.isValidName('John Doe'), true);
      expect(registrationLogic.isValidName('J'), false); // too short
      expect(registrationLogic.isValidName(''), false);
      expect(registrationLogic.isValidName('   '), false);
      expect(registrationLogic.isValidName('123'), false); // numbers only
    });

    test('validates email format', () {
      expect(registrationLogic.isValidEmail('user@example.com'), true);
      expect(registrationLogic.isValidEmail('invalid-email'), false);
      expect(registrationLogic.isValidEmail(''), false);
      expect(registrationLogic.isValidEmail('user@.com'), false);
      expect(registrationLogic.isValidEmail('@example.com'), false);
    });

    test('validates phone number format', () {
      expect(registrationLogic.isValidPhone('1234567890'), true);
      expect(registrationLogic.isValidPhone('123-456-7890'), false);
      expect(registrationLogic.isValidPhone('123'), false);
      expect(registrationLogic.isValidPhone(''), false);
      expect(registrationLogic.isValidPhone('abcdefghij'), false);
    });

    test('validates password strength', () {
      expect(registrationLogic.isValidPassword('StrongPass123!'), true);
      expect(registrationLogic.isValidPassword('weak'), false);
      expect(registrationLogic.isValidPassword('12345678'), false);
      expect(registrationLogic.isValidPassword(''), false);
      expect(registrationLogic.isValidPassword('NoSpecialChar1'), false);
    });

    test('validates password confirmation', () {
      expect(registrationLogic.doPasswordsMatch('Pass123!', 'Pass123!'), true);
      expect(registrationLogic.doPasswordsMatch('Pass123!', 'Pass123'), false);
      expect(registrationLogic.doPasswordsMatch('Pass123!', ''), false);
    });

    test('validates additional info', () {
      final validInfo = {
        'address': 'Test Address',
        'termsAccepted': true,
      };

      final invalidInfo = {
        'address': '',
        'termsAccepted': false,
      };

      expect(registrationLogic.isValidAdditionalInfo(validInfo), true);
      expect(registrationLogic.isValidAdditionalInfo(invalidInfo), false);
    });

    test('validates complete registration data', () {
      final validData = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '1234567890',
        'password': 'StrongPass123!',
        'confirmPassword': 'StrongPass123!',
        'additionalInfo': {
          'address': 'Test Address',
          'termsAccepted': true,
        }
      };

      expect(registrationLogic.isValidRegistrationData(validData), true);

      final invalidData = {
        'name': '', // invalid
        'email': 'john@example.com',
        'phone': '1234567890',
        'password': 'StrongPass123!',
        'confirmPassword': 'StrongPass123!',
        'additionalInfo': {
          'address': 'Test Address',
          'termsAccepted': true,
        }
      };

      expect(registrationLogic.isValidRegistrationData(invalidData), false);
    });

    test('checks email availability', () async {
      when(mockService.checkEmailAvailability('available@example.com'))
          .thenAnswer((_) async => true);
      when(mockService.checkEmailAvailability('taken@example.com'))
          .thenAnswer((_) async => false);

      final availableResult = await registrationLogic.checkEmailAvailability('available@example.com');
      expect(availableResult.success, true);

      final takenResult = await registrationLogic.checkEmailAvailability('taken@example.com');
      expect(takenResult.success, false);
      expect(takenResult.error, 'Email is already taken');
    });

    test('successful registration with valid data', () async {
      final additionalInfo = {
        'address': 'Test Address',
        'termsAccepted': true,
      };

      when(mockService.register(
        'John Doe',
        'john@example.com',
        '1234567890',
        'StrongPass123!',
        'StrongPass123!',
        additionalInfo,
      )).thenAnswer((_) async => {
        'success': true,
        'userId': 'new_user_id',
        'token': 'registration_token',
      });

      final result = await registrationLogic.register(
        'John Doe',
        'john@example.com',
        '1234567890',
        'StrongPass123!',
        'StrongPass123!',
        additionalInfo,
      );

      expect(result.success, true);
      expect(result.data?['userId'], 'new_user_id');
      expect(result.data?['token'], 'registration_token');
      expect(result.error, null);
    });

    test('handles registration API errors gracefully', () async {
      final additionalInfo = {
        'address': 'Test Address',
        'termsAccepted': true,
      };

      when(mockService.register(
        'John Doe',
        'john@example.com',
        '1234567890',
        'StrongPass123!',
        'StrongPass123!',
        additionalInfo,
      )).thenThrow(Exception('Network error'));

      final result = await registrationLogic.register(
        'John Doe',
        'john@example.com',
        '1234567890',
        'StrongPass123!',
        'StrongPass123!',
        additionalInfo,
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('prevents duplicate registration attempts while request is in progress', () async {
      final additionalInfo = {
        'address': 'Test Address',
        'termsAccepted': true,
      };

      when(mockService.register(
        'John Doe',
        'john@example.com',
        '1234567890',
        'StrongPass123!',
        'StrongPass123!',
        additionalInfo,
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        return {
          'success': true,
          'userId': 'new_user_id',
          'token': 'registration_token',
        };
      });

      final firstRequest = registrationLogic.register(
        'John Doe',
        'john@example.com',
        '1234567890',
        'StrongPass123!',
        'StrongPass123!',
        additionalInfo,
      );

      expect(registrationLogic.isRegistering, true);

      expect(
        () => registrationLogic.register(
          'John Doe',
          'john@example.com',
          '1234567890',
          'StrongPass123!',
          'StrongPass123!',
          additionalInfo,
        ),
        throwsA(isA<Exception>()),
      );

      await firstRequest;
      expect(registrationLogic.isRegistering, false);
    });
  });
}
