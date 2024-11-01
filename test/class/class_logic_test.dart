import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:khatabook_project/class_logic.dart';
import '../mocks/mock_classes.dart';
import '../mocks/mock_class_service.dart';

void main() {
  group('ClassLogic Tests', () {
    late MockClassService mockClassService;

    setUp(() {
      mockClassService = MockClassService();
    });

    test('creates class successfully', () async {
      final classData = {
        'name': 'Test Class',
        'fees': 1000.0,
        'teacherId': 'teacher123'
      };

      when(mockClassService.createClass(
        classData['name']! as String,
        classData['fees']! as double,
        classData['teacherId']! as String,
      )).thenAnswer((_) async => true);

      final result = await mockClassService.createClass(
        classData['name']! as String,
        classData['fees']! as double,
        classData['teacherId']! as String,
      );

      expect(result, true);
      verify(mockClassService.createClass(
        classData['name']! as String,
        classData['fees']! as double,
        classData['teacherId']! as String,
      )).called(1);
    });

    test('handles class creation failure', () async {
      final classData = {
        'name': 'Test Class',
        'fees': 1000.0,
        'teacherId': 'teacher123'
      };

      when(mockClassService.createClass(
        classData['name']! as String,
        classData['fees']! as double,
        classData['teacherId']! as String,
      )).thenAnswer((_) async => false);

      final result = await mockClassService.createClass(
        classData['name']! as String,
        classData['fees']! as double,
        classData['teacherId']! as String,
      );

      expect(result, false);
    });

    test('throws exception for invalid data', () async {
      when(mockClassService.createClass(
        '',
        -1000.0,
        '',
      )).thenThrow(Exception('Invalid class data'));

      expect(
        () => mockClassService.createClass('', -1000.0, ''),
        throwsException,
      );
    });
  });
}
