import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:khatabook_project/newLoginPage.dart';
import 'package:khatabook_project/login_logic.dart';

class MockAuthService extends Mock implements AuthService {
  @override
  Future<Map<String, dynamic>> login(
    String email,
    String password,
    bool rememberMe,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#login, [email, password, rememberMe]),
      returnValue: Future.value({
        'success': true,
        'userId': 'test_user_id',
        'token': 'test_token',
        'role': 'admin'
      }),
    );
  }

  @override
  Future<bool> verifyToken(String token) async {
    return super.noSuchMethod(
      Invocation.method(#verifyToken, [token]),
      returnValue: Future.value(true),
    );
  }
}

@GenerateMocks([])
void main() {
  group('Login Logic Tests', () {
    late LoginLogic loginLogic;
    late MockAuthService mockService;

    setUp(() {
      mockService = MockAuthService();
      loginLogic = LoginLogic(service: mockService);
    });

    test('validates email format', () {
      expect(loginLogic.isValidEmail('user@example.com'), true);
      expect(loginLogic.isValidEmail('invalid-email'), false);
      expect(loginLogic.isValidEmail(''), false);
      expect(loginLogic.isValidEmail('   '), false);
    });

    test('validates password format', () {
      expect(loginLogic.isValidPassword('Password123!'), true);
      expect(loginLogic.isValidPassword('weak'), false);
      expect(loginLogic.isValidPassword(''), false);
      expect(loginLogic.isValidPassword('   '), false);
    });

    test('validates complete login data', () {
      final validData = {
        'email': 'user@example.com',
        'password': 'Password123!',
        'rememberMe': true,
      };

      expect(loginLogic.isValidLoginData(validData), true);

      final invalidData = {
        'email': '',  // invalid
        'password': 'Password123!',
        'rememberMe': true,
      };

      expect(loginLogic.isValidLoginData(invalidData), false);
    });

    test('successful login with valid credentials', () async {
      when(mockService.login(
        'user@example.com',
        'Password123!',
        true,
      )).thenAnswer((_) async => {
        'success': true,
        'userId': 'test_user_id',
        'token': 'test_token',
        'role': 'admin'
      });

      final result = await loginLogic.login(
        'user@example.com',
        'Password123!',
        true,
      );

      expect(result.success, true);
      expect(result.data?['userId'], 'test_user_id');
      expect(result.data?['token'], 'test_token');
      expect(result.data?['role'], 'admin');
      expect(result.error, null);

      verify(mockService.login(
        'user@example.com',
        'Password123!',
        true,
      )).called(1);
    });

    test('handles invalid credentials', () async {
      when(mockService.login(
        'user@example.com',
        'WrongPassword123!',
        false,
      )).thenAnswer((_) async => {
        'success': false,
        'error': 'Invalid credentials'
      });

      final result = await loginLogic.login(
        'user@example.com',
        'WrongPassword123!',
        false,
      );

      expect(result.success, false);
      expect(result.error, 'Invalid credentials');
    });

    test('handles API errors gracefully', () async {
      when(mockService.login(
        'user@example.com',
        'Password123!',
        true,
      )).thenThrow(Exception('Network error'));

      final result = await loginLogic.login(
        'user@example.com',
        'Password123!',
        true,
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('prevents duplicate login attempts while request is in progress', () async {
      when(mockService.login(
        'user@example.com',
        'Password123!',
        true,
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        return {
          'success': true,
          'userId': 'test_user_id',
          'token': 'test_token',
          'role': 'admin'
        };
      });

      final firstRequest = loginLogic.login(
        'user@example.com',
        'Password123!',
        true,
      );

      expect(loginLogic.isLoggingIn, true);

      expect(
        () => loginLogic.login(
          'user@example.com',
          'Password123!',
          true,
        ),
        throwsA(isA<Exception>()),
      );

      await firstRequest;
      expect(loginLogic.isLoggingIn, false);
    });

    test('verifies token successfully', () async {
      when(mockService.verifyToken('valid_token'))
          .thenAnswer((_) async => true);

      final result = await loginLogic.verifyToken('valid_token');

      expect(result.success, true);
      expect(result.error, null);
    });

    test('handles invalid token', () async {
      when(mockService.verifyToken('invalid_token'))
          .thenAnswer((_) async => false);

      final result = await loginLogic.verifyToken('invalid_token');

      expect(result.success, false);
      expect(result.error, 'Invalid token');
    });

    test('handles token verification errors', () async {
      when(mockService.verifyToken('valid_token'))
          .thenThrow(Exception('Network error'));

      final result = await loginLogic.verifyToken('valid_token');

      expect(result.success, false);
      expect(result.error, isNotNull);
    });
  });
}
