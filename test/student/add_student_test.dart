import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:khatabook_project/AddStudent.dart';
import 'package:khatabook_project/student_logic.dart';

class MockStudentService extends Mock implements StudentService {
  @override
  Future<bool> addStudent(
    String name,
    String phone,
    String classId,
    String accountId,
    int amount,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#addStudent, [name, phone, classId, accountId, amount]),
      returnValue: Future.value(true),
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
  group('Student Addition Logic Tests', () {
    late StudentLogic studentLogic;
    late MockStudentService mockService;
    const String testAccountId = 'test_account_id';

    setUp(() {
      mockService = MockStudentService();
      studentLogic = StudentLogic(service: mockService);
    });

    test('validates student name', () {
      expect(studentLogic.isValidName('John Doe'), true);
      expect(studentLogic.isValidName(''), false);
      expect(studentLogic.isValidName('   '), false);
    });

    test('validates phone number format', () {
      expect(studentLogic.isValidPhone('1234567890'), true);
      expect(studentLogic.isValidPhone('123'), false);
      expect(studentLogic.isValidPhone(''), false);
      expect(studentLogic.isValidPhone('abcdefghij'), false);
    });

    test('validates class selection', () {
      expect(studentLogic.isValidClass('class_1'), true);
      expect(studentLogic.isValidClass(''), false);
      expect(studentLogic.isValidClass(null), false);
    });

    test('validates amount', () {
      expect(studentLogic.isValidAmount(1000), true);
      expect(studentLogic.isValidAmount(0), false);
      expect(studentLogic.isValidAmount(-100), false);
    });

    test('validates complete student data', () {
      final validData = {
        'name': 'John Doe',
        'phone': '1234567890',
        'classId': 'class_1',
        'accountId': testAccountId,
        'amount': 1000,
      };

      expect(studentLogic.isValidStudentData(validData), true);

      final invalidData = {
        'name': '',  // invalid
        'phone': '1234567890',
        'classId': 'class_1',
        'accountId': testAccountId,
        'amount': 1000,
      };

      expect(studentLogic.isValidStudentData(invalidData), false);
    });

    test('loads classes successfully', () async {
      when(mockService.getClasses(testAccountId)).thenAnswer((_) async => [
        {
          'id': 'class_1',
          'name': 'Class A',
          'amount': 1000,
        }
      ]);

      final result = await studentLogic.loadClasses(testAccountId);

      expect(result.success, true);
      expect(result.data?.length, 1);
      expect(result.data?[0]['name'], 'Class A');
    });

    test('handles class loading error', () async {
      when(mockService.getClasses(testAccountId))
          .thenThrow(Exception('Failed to load classes'));

      final result = await studentLogic.loadClasses(testAccountId);

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('adds student successfully with valid data', () async {
      when(mockService.addStudent(
        'John Doe',
        '1234567890',
        'class_1',
        testAccountId,
        1000,
      )).thenAnswer((_) async => true);

      final result = await studentLogic.addStudent(
        'John Doe',
        '1234567890',
        'class_1',
        testAccountId,
        1000,
      );

      expect(result.success, true);
      expect(result.error, null);

      verify(mockService.addStudent(
        'John Doe',
        '1234567890',
        'class_1',
        testAccountId,
        1000,
      )).called(1);
    });

    test('handles addition API errors gracefully', () async {
      when(mockService.addStudent(
        'John Doe',
        '1234567890',
        'class_1',
        testAccountId,
        1000,
      )).thenThrow(Exception('API Error'));

      final result = await studentLogic.addStudent(
        'John Doe',
        '1234567890',
        'class_1',
        testAccountId,
        1000,
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('prevents duplicate submission while request is in progress', () async {
      when(mockService.addStudent(
        'John Doe',
        '1234567890',
        'class_1',
        testAccountId,
        1000,
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        return true;
      });

      final firstRequest = studentLogic.addStudent(
        'John Doe',
        '1234567890',
        'class_1',
        testAccountId,
        1000,
      );

      expect(studentLogic.isSubmitting, true);

      expect(
        () => studentLogic.addStudent(
          'John Doe',
          '1234567890',
          'class_1',
          testAccountId,
          1000,
        ),
        throwsA(isA<Exception>()),
      );

      await firstRequest;
      expect(studentLogic.isSubmitting, false);
    });
  });
}
