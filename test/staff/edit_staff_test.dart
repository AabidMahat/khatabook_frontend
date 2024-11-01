import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:khatabook_project/staff_edit_logic.dart';
import 'package:khatabook_project/EditStaff.dart';

class MockStaffEditService extends Mock implements StaffEditService {
  @override
  Future<bool> editStaff(
    String staffId,
    String name,
    String email,
    String phone,
    String role,
    String salary,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#editStaff, [staffId, name, email, phone, role, salary]),
      returnValue: Future.value(true),
    );
  }

  @override
  Future<Map<String, dynamic>> getStaffDetails(String staffId) async {
    return super.noSuchMethod(
      Invocation.method(#getStaffDetails, [staffId]),
      returnValue: Future.value({
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '1234567890',
        'role': 'Teacher',
        'salary': '5000'
      }),
    );
  }
}

@GenerateMocks([])
void main() {
  group('Staff Edit Logic Tests', () {
    late StaffEditLogic staffEditLogic;
    late MockStaffEditService mockService;
    const String testStaffId = 'test_staff_id';

    setUp(() {
      mockService = MockStaffEditService();
      staffEditLogic = StaffEditLogic(service: mockService);
    });

    test('loads existing staff details successfully', () async {
      when(mockService.getStaffDetails(testStaffId)).thenAnswer((_) async => {
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '1234567890',
        'role': 'Teacher',
        'salary': '5000'
      });

      final result = await staffEditLogic.loadStaffDetails(testStaffId);

      expect(result.success, true);
      expect(result.data?['name'], 'John Doe');
      expect(result.data?['email'], 'john@example.com');
      expect(result.data?['phone'], '1234567890');
      expect(result.data?['role'], 'Teacher');
      expect(result.data?['salary'], '5000');
    });

    test('handles staff details loading error', () async {
      when(mockService.getStaffDetails(testStaffId))
          .thenThrow(Exception('Failed to load staff details'));

      final result = await staffEditLogic.loadStaffDetails(testStaffId);

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('validates updated email format', () {
      expect(staffEditLogic.isValidEmail('updated@example.com'), true);
      expect(staffEditLogic.isValidEmail('invalid-email'), false);
      expect(staffEditLogic.isValidEmail(''), false);
    });

    test('validates updated phone number format', () {
      expect(staffEditLogic.isValidPhone('9876543210'), true);
      expect(staffEditLogic.isValidPhone('123'), false);
      expect(staffEditLogic.isValidPhone(''), false);
      expect(staffEditLogic.isValidPhone('abcdefghij'), false);
    });

    test('validates updated staff name', () {
      expect(staffEditLogic.isValidName('Jane Doe'), true);
      expect(staffEditLogic.isValidName(''), false);
      expect(staffEditLogic.isValidName('   '), false);
    });

    test('validates updated role', () {
      expect(staffEditLogic.isValidRole('Admin'), true);
      expect(staffEditLogic.isValidRole('Teacher'), true);
      expect(staffEditLogic.isValidRole(''), false);
      expect(staffEditLogic.isValidRole('   '), false);
    });

    test('validates updated salary format', () {
      expect(staffEditLogic.isValidSalary('6000'), true);
      expect(staffEditLogic.isValidSalary('1500.50'), true);
      expect(staffEditLogic.isValidSalary(''), false);
      expect(staffEditLogic.isValidSalary('abc'), false);
      expect(staffEditLogic.isValidSalary('-1000'), false);
    });

    test('validates complete updated staff data', () {
      final validData = {
        'staffId': testStaffId,
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'phone': '9876543210',
        'role': 'Admin',
        'salary': '6000'
      };

      expect(staffEditLogic.isValidStaffData(validData), true);

      final invalidData = {
        'staffId': testStaffId,
        'name': '',
        'email': 'jane@example.com',
        'phone': '9876543210',
        'role': 'Admin',
        'salary': '6000'
      };

      expect(staffEditLogic.isValidStaffData(invalidData), false);
    });

    test('updates staff successfully with valid data', () async {
      when(mockService.editStaff(
        testStaffId,
        'Jane Doe',
        'jane@example.com',
        '9876543210',
        'Admin',
        '6000',
      )).thenAnswer((_) async => true);

      final result = await staffEditLogic.editStaff(
        testStaffId,
        'Jane Doe',
        'jane@example.com',
        '9876543210',
        'Admin',
        '6000',
      );

      expect(result.success, true);
      expect(result.error, null);

      verify(mockService.editStaff(
        testStaffId,
        'Jane Doe',
        'jane@example.com',
        '9876543210',
        'Admin',
        '6000',
      )).called(1);
    });

    test('handles update API errors gracefully', () async {
      when(mockService.editStaff(
        testStaffId,
        'Jane Doe',
        'jane@example.com',
        '9876543210',
        'Admin',
        '6000',
      )).thenThrow(Exception('API Error'));

      final result = await staffEditLogic.editStaff(
        testStaffId,
        'Jane Doe',
        'jane@example.com',
        '9876543210',
        'Admin',
        '6000',
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('prevents duplicate update submission while request is in progress', () async {
      when(mockService.editStaff(
        testStaffId,
        'Jane Doe',
        'jane@example.com',
        '9876543210',
        'Admin',
        '6000',
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        return true;
      });

      final firstRequest = staffEditLogic.editStaff(
        testStaffId,
        'Jane Doe',
        'jane@example.com',
        '9876543210',
        'Admin',
        '6000',
      );

      expect(staffEditLogic.isSubmitting, true);

      expect(
        () => staffEditLogic.editStaff(
          testStaffId,
          'Jane Doe',
          'jane@example.com',
          '9876543210',
          'Admin',
          '6000',
        ),
        throwsA(isA<Exception>()),
      );

      await firstRequest; // Wait for first request to complete
      expect(staffEditLogic.isSubmitting, false);
    });

    test('detects if staff data has changed', () {
      final originalData = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '1234567890',
        'role': 'Teacher',
        'salary': '5000'
      };

      final sameData = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '1234567890',
        'role': 'Teacher',
        'salary': '5000'
      };

      final changedData = {
        'name': 'Jane Doe',
        'email': 'john@example.com',
        'phone': '1234567890',
        'role': 'Teacher',
        'salary': '5000'
      };

      expect(staffEditLogic.hasDataChanged(originalData, sameData), false);
      expect(staffEditLogic.hasDataChanged(originalData, changedData), true);
    });
  });
}
