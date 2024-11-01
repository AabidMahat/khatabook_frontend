abstract class StudentUpdateService {
  Future<bool> updateStudent(
    String studentId,
    String name,
    String phone,
    String classId,
    int amount,
  );
  Future<Map<String, dynamic>> getStudentDetails(String studentId);
  Future<List<Map<String, dynamic>>> getClasses(String accountId);
}

class UpdateResult {
  final bool success;
  final String? error;
  final dynamic data;

  UpdateResult({
    required this.success,
    this.error,
    this.data,
  });
}

class StudentUpdateLogic {
  final StudentUpdateService service;
  bool _isSubmitting = false;

  StudentUpdateLogic({required this.service});

  bool get isSubmitting => _isSubmitting;

  bool isValidName(String name) {
    return name.trim().isNotEmpty;
  }

  bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    return phone.length == 10 && int.tryParse(phone) != null;
  }

  bool isValidClass(String? classId) {
    return classId != null && classId.isNotEmpty;
  }

  bool isValidAmount(int amount) {
    return amount > 0;
  }

  bool isValidUpdateData(Map<String, dynamic> data) {
    return isValidName(data['name'] ?? '') &&
           isValidPhone(data['phone'] ?? '') &&
           isValidClass(data['classId']) &&
           isValidAmount(data['amount'] ?? 0);
  }

  Future<UpdateResult> loadStudentDetails(String studentId) async {
    try {
      final details = await service.getStudentDetails(studentId);
      return UpdateResult(success: true, data: details);
    } catch (e) {
      return UpdateResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<UpdateResult> loadClasses(String accountId) async {
    try {
      final classes = await service.getClasses(accountId);
      return UpdateResult(success: true, data: classes);
    } catch (e) {
      return UpdateResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<UpdateResult> updateStudent(
    String studentId,
    String name,
    String phone,
    String classId,
    int amount,
  ) async {
    if (_isSubmitting) {
      throw Exception('An update is already in progress');
    }

    if (!isValidUpdateData({
      'name': name,
      'phone': phone,
      'classId': classId,
      'amount': amount,
    })) {
      return UpdateResult(
        success: false,
        error: 'Invalid student data',
      );
    }

    try {
      _isSubmitting = true;
      final success = await service.updateStudent(
        studentId,
        name,
        phone,
        classId,
        amount,
      );
      return UpdateResult(success: success);
    } catch (e) {
      return UpdateResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isSubmitting = false;
    }
  }

  bool hasDataChanged(Map<String, dynamic> original, Map<String, dynamic> updated) {
    return original['name'] != updated['name'] ||
           original['phone'] != updated['phone'] ||
           original['classId'] != updated['classId'] ||
           original['amount'] != updated['amount'];
  }
}
