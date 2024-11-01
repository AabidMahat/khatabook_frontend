abstract class StaffEditService {
  Future<bool> editStaff(
    String staffId,
    String name,
    String email,
    String phone,
    String role,
    String salary,
  );
  Future<Map<String, dynamic>> getStaffDetails(String staffId);
}

class StaffEditLogic {
  final StaffEditService service;
  bool _isSubmitting = false;

  StaffEditLogic({required this.service});

  bool get isSubmitting => _isSubmitting;

  Future<StaffResult> loadStaffDetails(String staffId) async {
    try {
      final data = await service.getStaffDetails(staffId);
      return StaffResult(success: true, data: data);
    } catch (e) {
      return StaffResult(success: false, error: e.toString());
    }
  }

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
    return data['staffId']?.isNotEmpty == true &&
           isValidName(data['name'] ?? '') &&
           isValidEmail(data['email'] ?? '') &&
           isValidPhone(data['phone'] ?? '') &&
           isValidRole(data['role'] ?? '') &&
           isValidSalary(data['salary'] ?? '');
  }

  Future<StaffResult> editStaff(
    String staffId,
    String name,
    String email,
    String phone,
    String role,
    String salary,
  ) async {
    if (_isSubmitting) {
      throw Exception('An update is already in progress');
    }

    if (!isValidStaffData({
      'staffId': staffId,
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
      final success = await service.editStaff(staffId, name, email, phone, role, salary);
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

  bool hasDataChanged(Map<String, dynamic> original, Map<String, dynamic> current) {
    return original['name'] != current['name'] ||
           original['email'] != current['email'] ||
           original['phone'] != current['phone'] ||
           original['role'] != current['role'] ||
           original['salary'] != current['salary'];
  }
}

class StaffResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  StaffResult({
    required this.success,
    this.error,
    this.data,
  });
}
