import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:khatabook_project/UpdateData.dart';
import 'package:khatabook_project/student_update_logic.dart';

class MockStudentUpdateService extends Mock implements StudentUpdateService {
  @override
  Future<bool> updateStudent(
    String studentId,
    String name,
    String phone,
    String classId,
    int amount,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#updateStudent, [studentId, name, phone, classId, amount]),
      returnValue: Future.value(true),
    );
  }

  @override
  Future<Map<String, dynamic>> getStudentDetails(String studentId) async {
    return super.noSuchMethod(
      Invocation.method(#getStudentDetails, [studentId]),
      returnValue: Future.value({
        'name': 'Test Student',
        'phone': '1234567890',
        'classId': 'class_1',
        'amount': 1000,
      }),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getClasses(String accountId) async {
    return super.noSuchMethod(
      Invocation.method(#getClasses, [accountId]),
      returnValue: Future.value([
        {
          'id': 'class_1',
          'name': 'Class A',
          'amount': 1000,
        }
      ]),
    );
  }
}

@GenerateMocks([])
void main() {
  group('Student Update Logic Tests', () {
    late StudentUpdateLogic updateLogic;
    late MockStudentUpdateService mockService;
    const String testStudentId = 'test_student_id';
    const String testAccountId = 'test_account_id';

    setUp(() {
      mockService = MockStudentUpdateService();
      updateLogic = StudentUpdateLogic(service: mockService);
    });

    test('loads existing student details successfully', () async {
      when(mockService.getStudentDetails(testStudentId)).thenAnswer((_) async => {
        'name': 'Test Student',
        'phone': '1234567890',
        'classId': 'class_1',
        'amount': 1000,
      });

      final result = await updateLogic.loadStudentDetails(testStudentId);

      expect(result.success, true);
      expect(result.data?['name'], 'Test Student');
      expect(result.data?['phone'], '1234567890');
      expect(result.data?['classId'], 'class_1');
      expect(result.data?['amount'], 1000);
    });

    test('handles student details loading error', () async {
      when(mockService.getStudentDetails(testStudentId))
          .thenThrow(Exception('Failed to load student details'));

      final result = await updateLogic.loadStudentDetails(testStudentId);

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('loads available classes successfully', () async {
      when(mockService.getClasses(testAccountId)).thenAnswer((_) async => [
        {
          'id': 'class_1',
          'name': 'Class A',
          'amount': 1000,
        }
      ]);

      final result = await updateLogic.loadClasses(testAccountId);

      expect(result.success, true);
      expect(result.data?.length, 1);
      expect(result.data?[0]['name'], 'Class A');
    });

    test('validates updated name format', () {
      expect(updateLogic.isValidName('Updated Name'), true);
      expect(updateLogic.isValidName(''), false);
      expect(updateLogic.isValidName('   '), false);
    });

    test('validates updated phone number format', () {
      expect(updateLogic.isValidPhone('9876543210'), true);
      expect(updateLogic.isValidPhone('123'), false);
      expect(updateLogic.isValidPhone(''), false);
      expect(updateLogic.isValidPhone('abcdefghij'), false);
    });

    test('validates updated class selection', () {
      expect(updateLogic.isValidClass('class_1'), true);
      expect(updateLogic.isValidClass(''), false);
      expect(updateLogic.isValidClass(null), false);
    });

    test('validates updated amount', () {
      expect(updateLogic.isValidAmount(2000), true);
      expect(updateLogic.isValidAmount(0), false);
      expect(updateLogic.isValidAmount(-100), false);
    });

    test('validates complete updated student data', () {
      final validData = {
        'studentId': testStudentId,
        'name': 'Updated Name',
        'phone': '9876543210',
        'classId': 'class_1',
        'amount': 2000,
      };

      expect(updateLogic.isValidUpdateData(validData), true);

      final invalidData = {
        'studentId': testStudentId,
        'name': '',  // invalid
        'phone': '9876543210',
        'classId': 'class_1',
        'amount': 2000,
      };

      expect(updateLogic.isValidUpdateData(invalidData), false);
    });

    test('updates student successfully with valid data', () async {
      when(mockService.updateStudent(
        testStudentId,
        'Updated Name',
        '9876543210',
        'class_1',
        2000,
      )).thenAnswer((_) async => true);

      final result = await updateLogic.updateStudent(
        testStudentId,
        'Updated Name',
        '9876543210',
        'class_1',
        2000,
      );

      expect(result.success, true);
      expect(result.error, null);

      verify(mockService.updateStudent(
        testStudentId,
        'Updated Name',
        '9876543210',
        'class_1',
        2000,
      )).called(1);
    });

    test('handles update API errors gracefully', () async {
      when(mockService.updateStudent(
        testStudentId,
        'Updated Name',
        '9876543210',
        'class_1',
        2000,
      )).thenThrow(Exception('API Error'));

      final result = await updateLogic.updateStudent(
        testStudentId,
        'Updated Name',
        '9876543210',
        'class_1',
        2000,
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('prevents duplicate update submission while request is in progress', () async {
      when(mockService.updateStudent(
        testStudentId,
        'Updated Name',
        '9876543210',
        'class_1',
        2000,
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        return true;
      });

      final firstRequest = updateLogic.updateStudent(
        testStudentId,
        'Updated Name',
        '9876543210',
        'class_1',
        2000,
      );

      expect(updateLogic.isSubmitting, true);

      expect(
        () => updateLogic.updateStudent(
          testStudentId,
          'Updated Name',
          '9876543210',
          'class_1',
          2000,
        ),
        throwsA(isA<Exception>()),
      );

      await firstRequest;
      expect(updateLogic.isSubmitting, false);
    });

    test('detects if student data has changed', () {
      final originalData = {
        'name': 'Test Student',
        'phone': '1234567890',
        'classId': 'class_1',
        'amount': 1000,
      };

      final sameData = Map<String, dynamic>.from(originalData);

      final changedData = {
        'name': 'Updated Name', // changed
        'phone': '1234567890',
        'classId': 'class_1',
        'amount': 1000,
      };

      expect(updateLogic.hasDataChanged(originalData, sameData), false);
      expect(updateLogic.hasDataChanged(originalData, changedData), true);
    });
  });
}
