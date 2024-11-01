import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:khatabook_project/ModifyTransaction.dart';
import 'package:khatabook_project/transaction_modify_logic.dart';

class MockTransactionModifyService extends Mock implements TransactionModifyService {
  @override
  Future<bool> updateTransaction(
    String transactionId,
    String studentId,
    double amount,
    String description,
    String paymentMode,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#updateTransaction, [
        transactionId,
        studentId,
        amount,
        description,
        paymentMode,
      ]),
      returnValue: Future.value(true),
    );
  }

  @override
  Future<Map<String, dynamic>> getTransactionDetails(String transactionId) async {
    return super.noSuchMethod(
      Invocation.method(#getTransactionDetails, [transactionId]),
      returnValue: Future.value({
        'id': 'transaction_1',
        'studentId': 'student_1',
        'amount': 1000.0,
        'description': 'Initial payment',
        'paymentMode': 'cash',
      }),
    );
  }
}

@GenerateMocks([])
void main() {
  group('Transaction Modification Logic Tests', () {
    late TransactionModifyLogic modifyLogic;
    late MockTransactionModifyService mockService;
    const String testTransactionId = 'transaction_1';

    setUp(() {
      mockService = MockTransactionModifyService();
      modifyLogic = TransactionModifyLogic(service: mockService);
    });

    test('loads existing transaction details successfully', () async {
      when(mockService.getTransactionDetails(testTransactionId))
          .thenAnswer((_) async => {
                'id': testTransactionId,
                'studentId': 'student_1',
                'amount': 1000.0,
                'description': 'Initial payment',
                'paymentMode': 'cash',
              });

      final result = await modifyLogic.loadTransactionDetails(testTransactionId);

      expect(result.success, true);
      expect(result.data?['amount'], 1000.0);
      expect(result.data?['paymentMode'], 'cash');
      expect(result.data?['description'], 'Initial payment');
    });

    test('handles transaction details loading error', () async {
      when(mockService.getTransactionDetails(testTransactionId))
          .thenThrow(Exception('Failed to load transaction details'));

      final result = await modifyLogic.loadTransactionDetails(testTransactionId);

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('validates modified amount', () {
      expect(modifyLogic.isValidAmount(2000.0), true);
      expect(modifyLogic.isValidAmount(0.0), false);
      expect(modifyLogic.isValidAmount(-100.0), false);
    });

    test('validates modified payment mode', () {
      expect(modifyLogic.isValidPaymentMode('cash'), true);
      expect(modifyLogic.isValidPaymentMode('online'), true);
      expect(modifyLogic.isValidPaymentMode('upi'), true);
      expect(modifyLogic.isValidPaymentMode(''), false);
      expect(modifyLogic.isValidPaymentMode('invalid'), false);
    });

    test('validates modified description', () {
      expect(modifyLogic.isValidDescription('Updated payment'), true);
      // Description can be empty
      expect(modifyLogic.isValidDescription(''), true);
      expect(modifyLogic.isValidDescription('   '), true);
    });

    test('validates complete modified transaction data', () {
      final validData = {
        'transactionId': testTransactionId,
        'studentId': 'student_1',
        'amount': 2000.0,
        'description': 'Updated payment',
        'paymentMode': 'online',
      };

      expect(modifyLogic.isValidModificationData(validData), true);

      final invalidData = {
        'transactionId': testTransactionId,
        'studentId': 'student_1',
        'amount': -100.0,  // invalid
        'description': 'Updated payment',
        'paymentMode': 'online',
      };

      expect(modifyLogic.isValidModificationData(invalidData), false);
    });

    test('updates transaction successfully with valid data', () async {
      when(mockService.updateTransaction(
        testTransactionId,
        'student_1',
        2000.0,
        'Updated payment',
        'online',
      )).thenAnswer((_) async => true);

      final result = await modifyLogic.updateTransaction(
        testTransactionId,
        'student_1',
        2000.0,
        'Updated payment',
        'online',
      );

      expect(result.success, true);
      expect(result.error, null);

      verify(mockService.updateTransaction(
        testTransactionId,
        'student_1',
        2000.0,
        'Updated payment',
        'online',
      )).called(1);
    });

    test('handles update API errors gracefully', () async {
      when(mockService.updateTransaction(
        testTransactionId,
        'student_1',
        2000.0,
        'Updated payment',
        'online',
      )).thenThrow(Exception('API Error'));

      final result = await modifyLogic.updateTransaction(
        testTransactionId,
        'student_1',
        2000.0,
        'Updated payment',
        'online',
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('prevents duplicate modification while request is in progress', () async {
      when(mockService.updateTransaction(
        testTransactionId,
        'student_1',
        2000.0,
        'Updated payment',
        'online',
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        return true;
      });

      final firstRequest = modifyLogic.updateTransaction(
        testTransactionId,
        'student_1',
        2000.0,
        'Updated payment',
        'online',
      );

      expect(modifyLogic.isSubmitting, true);

      expect(
        () => modifyLogic.updateTransaction(
          testTransactionId,
          'student_1',
          2000.0,
          'Updated payment',
          'online',
        ),
        throwsA(isA<Exception>()),
      );

      await firstRequest;
      expect(modifyLogic.isSubmitting, false);
    });

    test('detects if transaction data has changed', () {
      final originalData = {
        'amount': 1000.0,
        'description': 'Initial payment',
        'paymentMode': 'cash',
      };

      final sameData = Map<String, dynamic>.from(originalData);

      final changedData = {
        'amount': 2000.0,  // changed
        'description': 'Initial payment',
        'paymentMode': 'cash',
      };

      expect(modifyLogic.hasDataChanged(originalData, sameData), false);
      expect(modifyLogic.hasDataChanged(originalData, changedData), true);
    });
  });
}
