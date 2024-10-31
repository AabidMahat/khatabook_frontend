import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:khatabook_project/business_logic.dart';

class MockBusinessService extends Mock implements BusinessService {
  @override
  Future<bool> createOrganisation(
    String name,
    String email,
    String phone,
    String address,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#createOrganisation, [name, email, phone, address]),
      returnValue: Future.value(true),
    );
  }
}

@GenerateMocks([])
void main() {
  group('Business Account Creation Logic Tests', () {
    late BusinessLogic businessLogic;
    late MockBusinessService mockService;

    setUp(() {
      mockService = MockBusinessService();
      businessLogic = BusinessLogic(service: mockService);
    });

    test('validates email format', () {
      expect(businessLogic.isValidEmail('test@example.com'), true);
      expect(businessLogic.isValidEmail('invalid-email'), false);
      expect(businessLogic.isValidEmail(''), false);
    });

    test('validates phone number format', () {
      expect(businessLogic.isValidPhone('1234567890'), true);
      expect(businessLogic.isValidPhone('123'), false);
      expect(businessLogic.isValidPhone(''), false);
    });

    test('validates organisation name', () {
      expect(businessLogic.isValidName('Test Organisation'), true);
      expect(businessLogic.isValidName(''), false);
      expect(businessLogic.isValidName('   '), false);
    });

    test('validates form data completeness', () {
      final validData = {
        'name': 'Test Org',
        'email': 'test@example.com',
        'phone': '1234567890',
        'address': 'Test Address'
      };

      expect(businessLogic.isValidFormData(validData), true);

      final invalidData = {
        'name': '',
        'email': 'test@example.com',
        'phone': '1234567890',
        'address': 'Test Address'
      };

      expect(businessLogic.isValidFormData(invalidData), false);
    });

    test('creates organisation successfully with valid data', () async {
      when(mockService.createOrganisation(
        'Test Org',
        'test@example.com',
        '1234567890',
        'Test Address',
      )).thenAnswer((_) async => true);

      final result = await businessLogic.createOrganisation(
        'Test Org',
        'test@example.com',
        '1234567890',
        'Test Address',
      );

      expect(result.success, true);
      expect(result.error, null);

      verify(mockService.createOrganisation(
        'Test Org',
        'test@example.com',
        '1234567890',
        'Test Address',
      )).called(1);
    });

    test('handles API errors gracefully', () async {
      when(mockService.createOrganisation(
        'Test Org',
        'test@example.com',
        '1234567890',
        'Test Address',
      )).thenThrow(Exception('API Error'));

      final result = await businessLogic.createOrganisation(
        'Test Org',
        'test@example.com',
        '1234567890',
        'Test Address',
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('prevents duplicate submission while request is in progress', () async {
      when(mockService.createOrganisation(
        'Test Org',
        'test@example.com',
        '1234567890',
        'Test Address',
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        return true;
      });

      final firstRequest = businessLogic.createOrganisation(
        'Test Org',
        'test@example.com',
        '1234567890',
        'Test Address',
      );

      expect(businessLogic.isSubmitting, true);

      // Second request should throw an exception
      expect(
        () => businessLogic.createOrganisation(
          'Test Org',
          'test@example.com',
          '1234567890',
          'Test Address',
        ),
        throwsA(isA<Exception>()),
      );

      await firstRequest; // Wait for first request to complete
      expect(businessLogic.isSubmitting, false);
    });
  });
}
