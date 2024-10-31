abstract class BusinessService {
  Future<bool> createOrganisation(
    String name,
    String email,
    String phone,
    String address,
  );
}

class BusinessLogic {
  final BusinessService service;
  bool _isSubmitting = false;

  BusinessLogic({required this.service});

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

  bool isValidFormData(Map<String, String> data) {
    return isValidName(data['name'] ?? '') &&
           isValidEmail(data['email'] ?? '') &&
           isValidPhone(data['phone'] ?? '') &&
           data['address']?.isNotEmpty == true;
  }

  Future<OrganisationResult> createOrganisation(
    String name,
    String email,
    String phone,
    String address,
  ) async {
    if (_isSubmitting) {
      throw Exception('A submission is already in progress');
    }

    if (!isValidFormData({
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
    })) {
      return OrganisationResult(
        success: false,
        error: 'Invalid form data',
      );
    }

    try {
      _isSubmitting = true;
      final success = await service.createOrganisation(name, email, phone, address);
      return OrganisationResult(success: success);
    } catch (e) {
      return OrganisationResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isSubmitting = false;
    }
  }
}

class OrganisationResult {
  final bool success;
  final String? error;

  OrganisationResult({required this.success, this.error});
}
