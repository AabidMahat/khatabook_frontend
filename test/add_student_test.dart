import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatabook_project/AddStudent.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // If you are using a state management solution like provider.

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

    testWidgets('Initial UI elements are displayed correctly',
            (WidgetTester tester) async {
          await tester.pumpWidget(MaterialApp(home: AddStudent()));

          // Verify the UI elements
          expect(find.text('Add Customer'), findsOneWidget);
          expect(find.byType(TextFormField), findsNWidgets(2)); // Name and phone
          expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
        });

    testWidgets('Error shows if form is submitted without entering data',
            (WidgetTester tester) async {
          await tester.pumpWidget(MaterialApp(home: AddStudent()));

          // Tap the add button without entering data
          await tester.tap(find.text('Add Customer'));
          await tester.pump();

          // Verify that error messages are displayed
          expect(find.text('Please enter a student name'), findsOneWidget);
          expect(find.text('Please enter a phone number'), findsOneWidget);
          expect(find.text('Please select a class'), findsOneWidget);
        });

    testWidgets('Data submission on form validation', (WidgetTester tester) async {
      // Set up mock SharedPreferences and stub method calls
      when(mockSharedPreferences.getString(any)).thenReturn('medium');

      await tester.pumpWidget(MaterialApp(
        home: AddStudent(),
      ));

      // Fill the form with valid data
      await tester.enterText(find.byKey(Key('student_name')), 'John Doe');
      await tester.enterText(find.byKey(Key('phone')), '9999999999');

      // Simulate class dropdown selection
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Class 1').last);
      await tester.pumpAndSettle();

      // Submit the form
      await tester.tap(find.text('Add Customer'));
      await tester.pump();

      // Ensure no error messages
      expect(find.text('Please enter a student name'), findsNothing);
      expect(find.text('Please enter a phone number'), findsNothing);

      // Verify that the HTTP request is made (mock HTTP response)
      verify(mockClient.post(
        Uri.parse('${APIURL}/api/v3/student/createStudent'),
        headers: {'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).called(1);
    });
  });
}
