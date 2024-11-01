abstract class StudentService {
  Future<bool> addStudent(
    String name,
    String phone,
    String classId,
    String accountId,
    int amount,
  );
  Future<List<Map<String, dynamic>>> getClasses(String accountId);
}

class StudentResult {
  final bool success;
  final String? error;
  final dynamic data;

  StudentResult({
    required this.success,
    this.error,
    this.data,
  });
}

class StudentLogic {
  final StudentService service;
  bool _isSubmitting = false;

  StudentLogic({required this.service});

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

  bool isValidStudentData(Map<String, dynamic> data) {
    return isValidName(data['name'] ?? '') &&
           isValidPhone(data['phone'] ?? '') &&
           isValidClass(data['classId']) &&
           isValidAmount(data['amount'] ?? 0);
  }

  Future<StudentResult> loadClasses(String accountId) async {
    try {
      final classes = await service.getClasses(accountId);
      return StudentResult(success: true, data: classes);
    } catch (e) {
      return StudentResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<StudentResult> addStudent(
    String name,
    String phone,
    String classId,
    String accountId,
    int amount,
  ) async {
    if (_isSubmitting) {
      throw Exception('A submission is already in progress');
    }

    if (!isValidStudentData({
      'name': name,
      'phone': phone,
      'classId': classId,
      'accountId': accountId,
      'amount': amount,
    })) {
      return StudentResult(
        success: false,
        error: 'Invalid student data',
      );
    }

    try {
      _isSubmitting = true;
      final success = await service.addStudent(
        name,
        phone,
        classId,
        accountId,
        amount,
      );
      return StudentResult(success: success);
    } catch (e) {
      return StudentResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isSubmitting = false;
    }
  }
}
