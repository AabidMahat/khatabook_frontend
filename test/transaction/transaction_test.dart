import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:khatabook_project/transaction.dart';
import 'package:khatabook_project/transaction_logic.dart';

class MockTransactionService extends Mock implements TransactionService {
  @override
  Future<bool> createTransaction(
    String studentId,
    String accountId,
    double amount,
    String transactionType,
    String description,
    String paymentMode,
  ) async {
    return super.noSuchMethod(
      Invocation.method(#createTransaction, [
        studentId,
        accountId,
        amount,
        transactionType,
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
        'studentId': 'student_1',
        'accountId': 'account_1',
        'amount': 1000.0,
        'transactionType': 'payment',
        'description': 'Test payment',
        'paymentMode': 'cash',
      }),
    );
  }
}

@GenerateMocks([])
void main() {
  group('Transaction Logic Tests', () {
    late TransactionLogic transactionLogic;
    late MockTransactionService mockService;

    setUp(() {
      mockService = MockTransactionService();
      transactionLogic = TransactionLogic(service: mockService);
    });

    test('validates transaction amount', () {
      expect(transactionLogic.isValidAmount(1000.0), true);
      expect(transactionLogic.isValidAmount(0.0), false);
      expect(transactionLogic.isValidAmount(-100.0), false);
    });

    test('validates transaction type', () {
      expect(transactionLogic.isValidTransactionType('payment'), true);
      expect(transactionLogic.isValidTransactionType('refund'), true);
      expect(transactionLogic.isValidTransactionType(''), false);
      expect(transactionLogic.isValidTransactionType('invalid'), false);
    });

    test('validates payment mode', () {
      expect(transactionLogic.isValidPaymentMode('cash'), true);
      expect(transactionLogic.isValidPaymentMode('online'), true);
      expect(transactionLogic.isValidPaymentMode('upi'), true);
      expect(transactionLogic.isValidPaymentMode(''), false);
      expect(transactionLogic.isValidPaymentMode('invalid'), false);
    });

    test('validates transaction description', () {
      expect(transactionLogic.isValidDescription('Test payment'), true);
      // Description can be empty as it's optional
      expect(transactionLogic.isValidDescription(''), true);
      expect(transactionLogic.isValidDescription('   '), true);
    });

    test('validates complete transaction data', () {
      final validData = {
        'studentId': 'student_1',
        'accountId': 'account_1',
        'amount': 1000.0,
        'transactionType': 'payment',
        'description': 'Test payment',
        'paymentMode': 'cash',
      };

      expect(transactionLogic.isValidTransactionData(validData), true);

      final invalidData = {
        'studentId': 'student_1',
        'accountId': 'account_1',
        'amount': -100.0,  // invalid
        'transactionType': 'payment',
        'description': 'Test payment',
        'paymentMode': 'cash',
      };

      expect(transactionLogic.isValidTransactionData(invalidData), false);
    });

    test('creates transaction successfully with valid data', () async {
      when(mockService.createTransaction(
        'student_1',
        'account_1',
        1000.0,
        'payment',
        'Test payment',
        'cash',
      )).thenAnswer((_) async => true);

      final result = await transactionLogic.createTransaction(
        'student_1',
        'account_1',
        1000.0,
        'payment',
        'Test payment',
        'cash',
      );

      expect(result.success, true);
      expect(result.error, null);

      verify(mockService.createTransaction(
        'student_1',
        'account_1',
        1000.0,
        'payment',
        'Test payment',
        'cash',
      )).called(1);
    });

    test('handles transaction creation API errors gracefully', () async {
      when(mockService.createTransaction(
        'student_1',
        'account_1',
        1000.0,
        'payment',
        'Test payment',
        'cash',
      )).thenThrow(Exception('API Error'));

      final result = await transactionLogic.createTransaction(
        'student_1',
        'account_1',
        1000.0,
        'payment',
        'Test payment',
        'cash',
      );

      expect(result.success, false);
      expect(result.error, isNotNull);
    });

    test('prevents duplicate transaction submission while request is in progress', () async {
      when(mockService.createTransaction(
        'student_1',
        'account_1',
        1000.0,
        'payment',
        'Test payment',
        'cash',
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 1));
        return true;
      });

      final firstRequest = transactionLogic.createTransaction(
        'student_1',
        'account_1',
        1000.0,
        'payment',
        'Test payment',
        'cash',
      );

      expect(transactionLogic.isSubmitting, true);

      expect(
        () => transactionLogic.createTransaction(
          'student_1',
          'account_1',
          1000.0,
          'payment',
          'Test payment',
          'cash',
        ),
        throwsA(isA<Exception>()),
      );

      await firstRequest;
      expect(transactionLogic.isSubmitting, false);
    });

    test('loads transaction details successfully', () async {
      const testTransactionId = 'transaction_1';
      when(mockService.getTransactionDetails(testTransactionId))
          .thenAnswer((_) async => {
                'studentId': 'student_1',
                'accountId': 'account_1',
                'amount': 1000.0,
                'transactionType': 'payment',
                'description': 'Test payment',
                'paymentMode': 'cash',
              });

      final result = await transactionLogic.getTransactionDetails(testTransactionId);

      expect(result.success, true);
      expect(result.data?['amount'], 1000.0);
      expect(result.data?['transactionType'], 'payment');
      expect(result.data?['paymentMode'], 'cash');
    });

    test('handles transaction details loading error', () async {
      const testTransactionId = 'transaction_1';
      when(mockService.getTransactionDetails(testTransactionId))
          .thenThrow(Exception('Failed to load transaction details'));

      final result = await transactionLogic.getTransactionDetails(testTransactionId);

      expect(result.success, false);
      expect(result.error, isNotNull);
    });
  });
}
