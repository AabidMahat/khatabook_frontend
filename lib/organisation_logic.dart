abstract class OrganisationService {
  Future<bool> updateOrganisation(
    String orgId,
    String name,
    String email,
    String phone,
    String address,
    String description,
  );
  Future<Map<String, dynamic>> getOrganisationDetails(String orgId);
}

class OrganisationLogic {
  final OrganisationService service;
  bool _isSubmitting = false;

  OrganisationLogic({required this.service});

  bool get isSubmitting => _isSubmitting;

  Future<OrganisationResult> loadOrganisationDetails(String orgId) async {
    try {
      final data = await service.getOrganisationDetails(orgId);
      return OrganisationResult(success: true, data: data);
    } catch (e) {
      return OrganisationResult(success: false, error: e.toString());
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

  bool isValidAddress(String address) {
    return address.trim().isNotEmpty;
  }

  bool isValidDescription(String description) {
    // Description is optional, so empty is valid
    return true;
  }

  bool isValidOrganisationData(Map<String, String> data) {
    return data['orgId']?.isNotEmpty == true &&
           isValidName(data['name'] ?? '') &&
           isValidEmail(data['email'] ?? '') &&
           isValidPhone(data['phone'] ?? '') &&
           isValidAddress(data['address'] ?? '') &&
           isValidDescription(data['description'] ?? '');
  }

  Future<OrganisationResult> updateOrganisation(
    String orgId,
    String name,
    String email,
    String phone,
    String address,
    String description,
  ) async {
    if (_isSubmitting) {
      throw Exception('An update is already in progress');
    }

    if (!isValidOrganisationData({
      'orgId': orgId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'description': description,
    })) {
      return OrganisationResult(
        success: false,
        error: 'Invalid organisation data',
      );
    }

    try {
      _isSubmitting = true;
      final success = await service.updateOrganisation(
        orgId,
        name,
        email,
        phone,
        address,
        description,
      );
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

  bool hasDataChanged(Map<String, dynamic> original, Map<String, dynamic> current) {
    return original['name'] != current['name'] ||
           original['email'] != current['email'] ||
           original['phone'] != current['phone'] ||
           original['address'] != current['address'] ||
           original['description'] != current['description'];
  }
}

class OrganisationResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  OrganisationResult({
    required this.success,
    this.error,
    this.data,
  });
}
