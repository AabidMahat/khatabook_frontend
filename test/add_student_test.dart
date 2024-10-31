import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:khatabook_project/AddStudent.dart';

// Mock classes for http.Client and SharedPreferences
class MockClient extends Mock implements http.Client {}
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('AddStudent Widget Tests', () {
    late MockClient mockClient;
    late MockSharedPreferences mockSharedPreferences;

    setUp(() {
      mockClient = MockClient();
      mockSharedPreferences = MockSharedPreferences();
    });

    testWidgets('AddStudent form renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AddStudent(client: mockClient, sharedPreferences: mockSharedPreferences),
      ));

      // Verify if all form fields are present
      expect(find.text('Add Student'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Name, Phone Number
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget); // Class dropdown
      expect(find.byKey(Key('add_button')), findsOneWidget); // Add button
    });

    testWidgets('Form validation fails if fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AddStudent(client: mockClient, sharedPreferences: mockSharedPreferences),
      ));

      // Tap on the Add button without filling the form
      await tester.tap(find.byKey(Key('add_button')));
      await tester.pump();

      // Check if validation errors are shown
      expect(find.text('Please enter student name'), findsOneWidget); // Make sure error message text matches
      expect(find.text('Please enter a phone number'), findsOneWidget);
      expect(find.text('Please select a class'), findsOneWidget);
    });

    testWidgets('Form submission works with valid inputs', (WidgetTester tester) async {
      // Mock successful response for class fetching
      when(mockClient.get(Uri.parse("https://aabid.up.railway.app/api/v3/class/getclasses/account_no=66b7825bce5f7cabfb38a597")))
          .thenAnswer((_) async => http.Response(jsonEncode({
        "status": "success",
        "data": [
          {
            "_id": "6714aec17095155f86f2006d",
            "class_name": "A",
            "teacher_name": "Rafik Shaikh",
            "class_amount": 120,
            "amount_by_time": 10,
            "duration": 12,
            "teacherId": "6714aea57095155f86f20066",
            "account_no": "6714ae497095155f86f20050"
          },
        ]
      }), 200));

      // Mock response for student creation
      when(mockClient.post(
        Uri.parse("https://aabid.up.railway.app/api/v3/student/createStudent"),
        body: anyNamed('body'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async {
        // You can print the body of the request here if needed
        // print("API Call Body: ${_.body}");
        return http.Response(jsonEncode({"status": "success", "message": "Student created successfully!"}), 200);
      });

      when(mockSharedPreferences.getString("setAccess")).thenReturn('high'); // Mock staff access

      // Render the AddStudent widget
      await tester.pumpWidget(MaterialApp(
        home: AddStudent(client: mockClient, sharedPreferences: mockSharedPreferences),
      ));

      // Enter valid data in the form
      await tester.enterText(find.byType(TextFormField).first, 'John Doe'); // Name field
      await tester.enterText(find.byType(TextFormField).last, '9876543210'); // Phone number field
      await tester.pump(); // Wait for UI to update

      // Select a class from the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle(); // Wait for dropdown to open
      await tester.tap(find.text('Maths').last); // Select 'Maths'
      await tester.pump(); // Wait for dropdown to close

      // Tap on Add button
      await tester.tap(find.byKey(Key('add_button')));
      await tester.pump(); // Wait for form submission

      // Wait for the form submission to complete
      await tester.pumpAndSettle(); // Ensure all animations are complete

      // Verify that student creation API was called
      verify(mockClient.post(
        Uri.parse("https://aabid.up.railway.app/api/v3/student/createStudent"),
        body: anyNamed('body'),
        headers: anyNamed('headers'),
      )).called(1);

      // Optionally, you can also check the output of the mocked API call:
      // Check the mocked response
      when(mockClient.post(
        Uri.parse("https://aabid.up.railway.app/api/v3/student/createStudent"),
        body: anyNamed('body'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async {
        final response = http.Response(jsonEncode({"status": "success", "message": "Student created successfully!"}), 200);
        print("Response from API: ${response.body}");
        return response;
      });
    });


    testWidgets('Error toast shows when no classes are available', (WidgetTester tester) async {
      // Mock no classes response
      when(mockClient.get(Uri.parse("https://aabid.up.railway.app/api/v3/class/getclasses/account_no=66b7825bce5f7cabfb38a597"))).thenAnswer((_) async => http.Response(jsonEncode({"data": []}), 200));
      when(mockSharedPreferences.getString("setAccess")).thenReturn('high'); // Mock staff access

      await tester.pumpWidget(MaterialApp(
        home: AddStudent(client: mockClient, sharedPreferences: mockSharedPreferences),
      ));

      // Verify if the toast is shown after loading no classes
      await tester.pump(Duration(milliseconds: 5000)); // Wait for toast to show
      expect(find.text("Please Add Class"), findsOneWidget); // Toast message
    });
  });
}
