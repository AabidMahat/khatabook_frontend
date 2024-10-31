import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Mock HTTP Client
class MockHttpClient extends Mock implements http.Client {}
class MockClient extends Mock implements http.Client {}

// Mock SharedPreferences 
class MockSharedPreferences extends Mock implements SharedPreferences {}

// Add any other mock classes you need for testing here
