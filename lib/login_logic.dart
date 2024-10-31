abstract class AuthService {
  Future<Map<String, dynamic>> login(
    String email,
    String password,
    bool rememberMe,
  );
  Future<bool> verifyToken(String token);
}

class LoginResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  LoginResult({
    required this.success,
    this.error,
    this.data,
  });
}

class LoginLogic {
  final AuthService service;
  bool _isLoggingIn = false;

  LoginLogic({required this.service});

  bool get isLoggingIn => _isLoggingIn;

  bool isValidEmail(String email) {
    if (email.trim().isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    if (password.trim().isEmpty) return false;
    // Password should be at least 8 characters long and contain at least one number and one special character
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$');
    return passwordRegex.hasMatch(password);
  }

  bool isValidLoginData(Map<String, dynamic> data) {
    return isValidEmail(data['email'] ?? '') &&
           isValidPassword(data['password'] ?? '') &&
           data['rememberMe'] is bool;
  }

  Future<LoginResult> login(
    String email,
    String password,
    bool rememberMe,
  ) async {
    if (_isLoggingIn) {
      throw Exception('A login attempt is already in progress');
    }

    final loginData = {
      'email': email,
      'password': password,
      'rememberMe': rememberMe,
    };

    if (!isValidLoginData(loginData)) {
      return LoginResult(
        success: false,
        error: 'Invalid login data',
      );
    }

    try {
      _isLoggingIn = true;
      final response = await service.login(
        email,
        password,
        rememberMe,
      );

      if (response['success'] == true) {
        return LoginResult(
          success: true,
          data: response,
        );
      } else {
        return LoginResult(
          success: false,
          error: response['error'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return LoginResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isLoggingIn = false;
    }
  }

  Future<LoginResult> verifyToken(String token) async {
    try {
      final isValid = await service.verifyToken(token);
      
      if (isValid) {
        return LoginResult(success: true);
      } else {
        return LoginResult(
          success: false,
          error: 'Invalid token',
        );
      }
    } catch (e) {
      return LoginResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}
