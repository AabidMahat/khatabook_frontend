import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:khatabook_project/staff_logic.dart';
import 'package:khatabook_project/AddStaff.dart';

class MockStaffService extends Mock implements StaffService {
  @override
  Future<bool> addStaff(
    String name,
    String email,
    String phone,
    String role,
    String salary,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#addStaff, [name, email, phone, role, salary]),
      returnValue: Future.value(true),
    );
  }
}

@GenerateMocks([])
void main() {
  group('Staff Addition Logic Tests', () {
    late StaffLogic staffLogic;
    late MockStaffService mockService;

    setUp(() {
      mockService = MockStaffService();
      staffLogic = StaffLogic(service: mockService);
    });

    test('validates staff email format', () {
      expect(staffLogic.isValidEmail('staff@example.com'), true);
      expect(staffLogic.isValidEmail('invalid-email'), false);
      expect(staffLogic.isValidEmail(''), false);
    });

    test('validates staff phone number format', () {
      expect(staffLogic.isValidPhone('1234567890'), true);
      expect(staffLogic.isValidPhone('123'), false);
      expect(staffLogic.isValidPhone(''), false);
      expect(staffLogic.isValidPhone('abcdefghij'), false);
    });

    test('validates staff name', () {
      expect(staffLogic.isValidName('John Doe'), true);
      expect(staffLogic.isValidName(''), false);
      expect(staffLogic.isValidName('   '), false);
    });

    test('validates staff role', () {
      expect(staffLogic.isValidRole('Teacher'), true);
      expect(staffLogic.isValidRole('Admin'), true);
      expect(staffLogic.isValidRole(''), false);
      expect(staffLogic.isValidRole('   '), false);
    });

    test('validates salary format', () {
      expect(staffLogic.isValidSalary('5000'), true);
      expect(staffLogic.isValidSalary('1000.50'), true);
      expect(staffLogic.isValidSalary(''), false);
      expect(staffLogic.isValidSalary('abc'), false);
      expect(staffLogic.isValidSalary('-1000'), false);
    });

    test('validates complete staff data', () {
      final validData = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '1234567890',
        'role': 'Teacher',
        'salary': '5000'
      };

      expect(staffLogic.isValidStaffData(validData), true);

      final invalidData = {
        'name': '',
        'email': 'john@example.com',
        'phone': '1234567890',
        'role': 'Teacher',
        'salary': '5000'
      };

      expect(staffLogic.isValidStaffData(invalidData), false);
    });

    test('adds staff successfully with valid data', () async {
      when(mockService.addStaff(
        'John Doe',
        'john@example.com',
        '1234567890',
        'Teacher',
        '5000',
      )).thenAnswer((_) async => true);

      final result = await staffLogic.addStaff(
        'John Doe',
        'john@example.com',
        '1234567890',
        'Teacher',
        '5000',
      );

      expect(result.success, true);
      expect(result.error, null);

      verify(mockService.addStaff(
        'John Doe',
        'john@example.com',
        '1234567890',
        'Teacher',
        '5000',
      )).called(1);
    });

    test('handles API errors gracefully', () async {
      when(mockService.addStaff(
        'John Doe',
        'john@example.com',
        '1234567890',
        'Teacher',
        '5000',
      )).thenThrow(Exception('API Error'));

      final result = await staffLogic.addStaff(
        'John Doe',
        'john@example.com',
        '1234567890',
        'Teacher',
        '5000',
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('prevents duplicate submission while request is in progress', () async {
      when(mockService.addStaff(
        'John Doe',
        'john@example.com',
        '1234567890',
        'Teacher',
        '5000',
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        return true;
      });

      final firstRequest = staffLogic.addStaff(
        'John Doe',
        'john@example.com',
        '1234567890',
        'Teacher',
        '5000',
      );

      expect(staffLogic.isSubmitting, true);

      expect(
        () => staffLogic.addStaff(
          'John Doe',
          'john@example.com',
          '1234567890',
          'Teacher',
          '5000',
        ),
        throwsA(isA<Exception>()),
      );

      await firstRequest; // Wait for first request to complete
      expect(staffLogic.isSubmitting, false);
    });
  });
}
