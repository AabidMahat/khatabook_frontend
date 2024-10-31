import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatabook_project/AddClass.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks/mock_classes.dart';

void main() {
  group('AddClass Tests', () {
    late MockClient mockClient;
    late MockSharedPreferences mockPrefs;
    late Widget testWidget;

    setUp(() {
      mockClient = MockClient();
      mockPrefs = MockSharedPreferences();
      
      // Initialize test widget
      testWidget = MaterialApp(home: addclass());

      // Setup SharedPreferences mock
      when(mockPrefs.getString('userId')).thenReturn('test_user_id');
      when(mockPrefs.getString('selectedAccountId')).thenReturn('test_account_id');
      when(mockPrefs.getString('setAccess')).thenReturn('high');
    });

    testWidgets('Add Class form displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Verify all form fields are present
      expect(find.text('Add Class'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3)); // Class name, amount, required amount
      expect(find.byType(DropdownButtonFormField), findsNWidgets(2)); // Teacher and Duration dropdowns
    });

    testWidgets('Form validation shows error messages', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Try to submit empty form
      final submitButton = find.text('Add Class');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify error messages
      expect(find.text('Please enter a class name'), findsOneWidget);
    });

    testWidgets('Successfully creates a class', (WidgetTester tester) async {
      // Mock HTTP response for fetchAccounts
      when(mockClient.get(Uri.parse('${APIURL}/api/v3/account/getAccount/account_no=test_account_id')))
          .thenAnswer((_) async => http.Response(json.encode({
                'data': {
                  'account': {
                    '_id': 'test_account_id',
                    'account_name': 'Test Account'
                  }
                }
              }), 200));

      // Mock HTTP response for fetchTeachers
      when(mockClient.get(Uri.parse('${APIURL}/api/v3/staff/getAllStaff/test_account_id')))
          .thenAnswer((_) async => http.Response(json.encode({
                'data': [
                  {
                    'id': 'teacher_1',
                    'staffName': 'Test Teacher',
                    'staffNumber': '1234567890',
                    'staffAccess': 'high'
                  }
                ]
              }), 200));

      // Mock HTTP response for createClass
      when(mockClient.post(
        Uri.parse('${APIURL}/api/v3/class/addClass'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"message": "Class created successfully"}', 200));

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Fill the form
      await tester.enterText(find.byKey(Key('class_name')), 'Test Class');
      await tester.enterText(find.byKey(Key('class_amount')), '1000');
      
      // Select teacher from dropdown
      await tester.tap(find.byType(DropdownButtonFormField).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Teacher').last);
      await tester.pumpAndSettle();

      // Select duration from dropdown
      await tester.tap(find.byType(DropdownButtonFormField).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly').last);
      await tester.pumpAndSettle();

      // Submit form
      await tester.tap(find.text('Add Class'));
      await tester.pumpAndSettle();

      // Verify HTTP request was made with correct data
      verify(mockClient.post(
        Uri.parse('${APIURL}/api/v3/class/addClass'),
        headers: {'Content-Type': 'application/json'},
        body: anything,
      )).called(1);
    });

    testWidgets('Handles API error gracefully', (WidgetTester tester) async {
      // Mock failed HTTP response
      when(mockClient.post(
        Uri.parse('${APIURL}/api/v3/class/addClass'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"error": "Failed to create class"}', 400));

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Fill form with valid data
      await tester.enterText(find.byKey(Key('class_name')), 'Test Class');
      await tester.enterText(find.byKey(Key('class_amount')), '1000');
      
      // Submit form
      await tester.tap(find.text('Add Class'));
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(find.text('Failed to create class'), findsOneWidget);
    });

    testWidgets('Required amount calculates correctly', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Enter class amount
      await tester.enterText(find.byKey(Key('class_amount')), '1200');
      
      // Select Monthly duration
      await tester.tap(find.byType(DropdownButtonFormField).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monthly').last);
      await tester.pumpAndSettle();

      // Verify required amount is calculated correctly (1200/12 = 100)
      expect(find.text('100'), findsOneWidget);
    });
  });
}
