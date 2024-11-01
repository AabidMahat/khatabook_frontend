abstract class UserService {
  Future<bool> updateUser(
    String userId,
    String name,
    String email,
    String phone,
    String password,
    Map<String, dynamic> preferences,
  );
  Future<Map<String, dynamic>> getUserDetails(String userId);
}

class UserResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  UserResult({
    required this.success,
    this.error,
    this.data,
  });
}

class UserUpdateLogic {
  final UserService service;
  bool _isSubmitting = false;

  UserUpdateLogic({required this.service});

  bool get isSubmitting => _isSubmitting;

  Future<UserResult> loadUserDetails(String userId) async {
    try {
      final data = await service.getUserDetails(userId);
      return UserResult(success: true, data: data);
    } catch (e) {
      return UserResult(success: false, error: e.toString());
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

  bool isValidPassword(String password) {
    if (password.isEmpty) return false;
    // Password should be at least 8 characters long and contain at least one number and one special character
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  bool isValidPreferences(Map<String, dynamic> preferences) {
    return preferences.containsKey('darkMode') &&
           preferences.containsKey('notifications') &&
           preferences.containsKey('language') &&
           preferences['darkMode'] is bool &&
           preferences['notifications'] is bool &&
           preferences['language'] is String;
  }

  bool isValidUserData(Map<String, dynamic> data) {
    return data['userId']?.isNotEmpty == true &&
           isValidName(data['name'] ?? '') &&
           isValidEmail(data['email'] ?? '') &&
           isValidPhone(data['phone'] ?? '') &&
           isValidPassword(data['password'] ?? '') &&
           isValidPreferences(data['preferences'] ?? {});
  }

  Future<UserResult> updateUser(
    String userId,
    String name,
    String email,
    String phone,
    String password,
    Map<String, dynamic> preferences,
  ) async {
    if (_isSubmitting) {
      throw Exception('An update is already in progress');
    }

    final userData = {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'preferences': preferences,
    };

    if (!isValidUserData(userData)) {
      return UserResult(
        success: false,
        error: 'Invalid user data',
      );
    }

    try {
      _isSubmitting = true;
      final success = await service.updateUser(
        userId,
        name,
        email,
        phone,
        password,
        preferences,
      );
      return UserResult(success: success);
    } catch (e) {
      return UserResult(
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
           _hasPreferencesChanged(original['preferences'], current['preferences']);
  }

  bool _hasPreferencesChanged(Map<String, dynamic>? original, Map<String, dynamic>? current) {
    if (original == null || current == null) return false;
    return original['darkMode'] != current['darkMode'] ||
           original['notifications'] != current['notifications'] ||
           original['language'] != current['language'];
  }
}
