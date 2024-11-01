abstract class TransactionModifyService {
  Future<bool> updateTransaction(
    String transactionId,
    String studentId,
    double amount,
    String description,
    String paymentMode,
  );
  Future<Map<String, dynamic>> getTransactionDetails(String transactionId);
}

class ModifyResult {
  final bool success;
  final String? error;
  final dynamic data;

  ModifyResult({
    required this.success,
    this.error,
    this.data,
  });
}

class TransactionModifyLogic {
  final TransactionModifyService service;
  bool _isSubmitting = false;

  TransactionModifyLogic({required this.service});

  bool get isSubmitting => _isSubmitting;

  final List<String> validPaymentModes = ['cash', 'online', 'upi'];

  bool isValidAmount(double amount) {
    return amount > 0;
  }

  bool isValidPaymentMode(String mode) {
    return validPaymentModes.contains(mode.toLowerCase());
  }

  bool isValidDescription(String description) {
    return true; // Description is optional
  }

  bool isValidModificationData(Map<String, dynamic> data) {
    return data['transactionId'] != null &&
           data['studentId'] != null &&
           isValidAmount(data['amount'] ?? 0.0) &&
           isValidPaymentMode(data['paymentMode'] ?? '');
  }

  Future<ModifyResult> loadTransactionDetails(String transactionId) async {
    try {
      final details = await service.getTransactionDetails(transactionId);
      return ModifyResult(success: true, data: details);
    } catch (e) {
      return ModifyResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<ModifyResult> updateTransaction(
    String transactionId,
    String studentId,
    double amount,
    String description,
    String paymentMode,
  ) async {
    if (_isSubmitting) {
      throw Exception('A modification is already in progress');
    }

    if (!isValidModificationData({
      'transactionId': transactionId,
      'studentId': studentId,
      'amount': amount,
      'paymentMode': paymentMode,
    })) {
      return ModifyResult(
        success: false,
        error: 'Invalid modification data',
      );
    }

    try {
      _isSubmitting = true;
      final success = await service.updateTransaction(
        transactionId,
        studentId,
        amount,
        description,
        paymentMode,
      );
      return ModifyResult(success: success);
    } catch (e) {
      return ModifyResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isSubmitting = false;
    }
  }

  bool hasDataChanged(Map<String, dynamic> original, Map<String, dynamic> updated) {
    return original['amount'] != updated['amount'] ||
           original['description'] != updated['description'] ||
           original['paymentMode'] != updated['paymentMode'];
  }
}
