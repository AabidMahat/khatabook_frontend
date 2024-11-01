abstract class RegistrationService {
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String password,
    String confirmPassword,
    Map<String, dynamic> additionalInfo,
  );
  Future<bool> checkEmailAvailability(String email);
}

class RegistrationResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  RegistrationResult({
    required this.success,
    this.error,
    this.data,
  });
}

class RegistrationLogic {
  final RegistrationService service;
  bool _isRegistering = false;

  RegistrationLogic({required this.service});

  bool get isRegistering => _isRegistering;

  bool isValidName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.trim().length < 2) return false;
    return RegExp(r'^[a-zA-Z\s]+$').hasMatch(name.trim());
  }

  bool isValidEmail(String email) {
    if (email.trim().isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    return phone.length == 10 && int.tryParse(phone) != null;
  }

  bool isValidPassword(String password) {
    if (password.isEmpty) return false;
    // Password should be at least 8 characters long and contain at least one number, 
    // one uppercase letter, and one special character
    final passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$'
    );
    return passwordRegex.hasMatch(password);
  }

  bool doPasswordsMatch(String password, String confirmPassword) {
    return password.isNotEmpty && password == confirmPassword;
  }

  bool isValidAdditionalInfo(Map<String, dynamic> additionalInfo) {
    return additionalInfo['address']?.toString().trim().isNotEmpty == true &&
           additionalInfo['termsAccepted'] == true;
  }

  bool isValidRegistrationData(Map<String, dynamic> data) {
    return isValidName(data['name'] ?? '') &&
           isValidEmail(data['email'] ?? '') &&
           isValidPhone(data['phone'] ?? '') &&
           isValidPassword(data['password'] ?? '') &&
           doPasswordsMatch(
             data['password'] ?? '',
             data['confirmPassword'] ?? ''
           ) &&
           isValidAdditionalInfo(data['additionalInfo'] ?? {});
  }

  Future<RegistrationResult> checkEmailAvailability(String email) async {
    try {
      final isAvailable = await service.checkEmailAvailability(email);
      if (isAvailable) {
        return RegistrationResult(success: true);
      } else {
        return RegistrationResult(
          success: false,
          error: 'Email is already taken',
        );
      }
    } catch (e) {
      return RegistrationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<RegistrationResult> register(
    String name,
    String email,
    String phone,
    String password,
    String confirmPassword,
    Map<String, dynamic> additionalInfo,
  ) async {
    if (_isRegistering) {
      throw Exception('A registration attempt is already in progress');
    }

    final registrationData = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'confirmPassword': confirmPassword,
      'additionalInfo': additionalInfo,
    };

    if (!isValidRegistrationData(registrationData)) {
      return RegistrationResult(
        success: false,
        error: 'Invalid registration data',
      );
    }

    try {
      _isRegistering = true;
      final response = await service.register(
        name,
        email,
        phone,
        password,
        confirmPassword,
        additionalInfo,
      );

      if (response['success'] == true) {
        return RegistrationResult(
          success: true,
          data: response,
        );
      } else {
        return RegistrationResult(
          success: false,
          error: response['error'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return RegistrationResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isRegistering = false;
    }
  }
}
