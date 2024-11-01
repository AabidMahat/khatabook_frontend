abstract class TransactionService {
  Future<bool> createTransaction(
    String studentId,
    String accountId,
    double amount,
    String transactionType,
    String description,
    String paymentMode,
  );
  Future<Map<String, dynamic>> getTransactionDetails(String transactionId);
}

class TransactionResult {
  final bool success;
  final String? error;
  final dynamic data;

  TransactionResult({
    required this.success,
    this.error,
    this.data,
  });
}

class TransactionLogic {
  final TransactionService service;
  bool _isSubmitting = false;

  TransactionLogic({required this.service});

  bool get isSubmitting => _isSubmitting;

  final List<String> validTransactionTypes = ['payment', 'refund'];
  final List<String> validPaymentModes = ['cash', 'online', 'upi'];

  bool isValidAmount(double amount) {
    return amount > 0;
  }

  bool isValidTransactionType(String type) {
    return validTransactionTypes.contains(type.toLowerCase());
  }

  bool isValidPaymentMode(String mode) {
    return validPaymentModes.contains(mode.toLowerCase());
  }

  bool isValidDescription(String description) {
    return true; // Description is optional
  }

  bool isValidTransactionData(Map<String, dynamic> data) {
    return data['studentId'] != null &&
           data['accountId'] != null &&
           isValidAmount(data['amount'] ?? 0.0) &&
           isValidTransactionType(data['transactionType'] ?? '') &&
           isValidPaymentMode(data['paymentMode'] ?? '');
  }

  Future<TransactionResult> createTransaction(
    String studentId,
    String accountId,
    double amount,
    String transactionType,
    String description,
    String paymentMode,
  ) async {
    if (_isSubmitting) {
      throw Exception('A transaction is already in progress');
    }

    if (!isValidTransactionData({
      'studentId': studentId,
      'accountId': accountId,
      'amount': amount,
      'transactionType': transactionType,
      'paymentMode': paymentMode,
    })) {
      return TransactionResult(
        success: false,
        error: 'Invalid transaction data',
      );
    }

    try {
      _isSubmitting = true;
      final success = await service.createTransaction(
        studentId,
        accountId,
        amount,
        transactionType,
        description,
        paymentMode,
      );
      return TransactionResult(success: success);
    } catch (e) {
      return TransactionResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isSubmitting = false;
    }
  }

  Future<TransactionResult> getTransactionDetails(String transactionId) async {
    try {
      final details = await service.getTransactionDetails(transactionId);
      return TransactionResult(success: true, data: details);
    } catch (e) {
      return TransactionResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}
