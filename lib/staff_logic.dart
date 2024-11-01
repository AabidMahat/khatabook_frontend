abstract class StaffService {
  Future<bool> addStaff(
    String name,
    String email,
    String phone,
    String role,
    String salary,
  );
}

class StaffLogic {
  final StaffService service;
  bool _isSubmitting = false;

  StaffLogic({required this.service});

  bool get isSubmitting => _isSubmitting;

  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    return phone.length == 10 && int.tryParse(phone) != null;
  }

  bool isValidName(String name) {
    return name.trim().isNotEmpty;
  }

  bool isValidRole(String role) {
    return role.trim().isNotEmpty;
  }

  bool isValidSalary(String salary) {
    if (salary.isEmpty) return false;
    final amount = double.tryParse(salary);
    return amount != null && amount > 0;
  }

  bool isValidStaffData(Map<String, String> data) {
    return isValidName(data['name'] ?? '') &&
           isValidEmail(data['email'] ?? '') &&
           isValidPhone(data['phone'] ?? '') &&
           isValidRole(data['role'] ?? '') &&
           isValidSalary(data['salary'] ?? '');
  }

  Future<StaffResult> addStaff(
    String name,
    String email,
    String phone,
    String role,
    String salary,
  ) async {
    if (_isSubmitting) {
      throw Exception('A submission is already in progress');
    }

    if (!isValidStaffData({
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'salary': salary,
    })) {
      return StaffResult(
        success: false,
        error: 'Invalid staff data',
      );
    }

    try {
      _isSubmitting = true;
      final success = await service.addStaff(name, email, phone, role, salary);
      return StaffResult(success: success);
    } catch (e) {
      return StaffResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isSubmitting = false;
    }
  }
}

class StaffResult {
  final bool success;
  final String? error;

  StaffResult({required this.success, this.error});
}
