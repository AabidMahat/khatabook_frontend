import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatabook_project/ViewReport.dart';
import 'package:khatabook_project/Database.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import '../mocks/mock_classes.dart';

void main() {
  group('ViewReport Widget Tests', () {
    late MockClient mockClient;
    late Widget testWidget;

    // Sample test data
    final List<Student> testStudents = [
      Student(
        id: "1",
        studentName: "Test Student",
        phone: "1234567890",
        classes: "Test Class",
        totalFees: 1000,
        paidFees: 500,
        accountId: "test_account",
      )
    ];

    final List<TransactionData> testTransactions = [
      TransactionData(
        id: "1",
        studentId: "1",
        accountId: "test_account",
        pendingAmount: 500,
        transactionType: "payment",
        transactionDescription: "Test payment",
        transactionMode: "cash",
        amount: 500,
        createdAt: DateTime.now(),
      )
    ];

    setUp(() {
      mockClient = MockClient();
      
      // Setup the test widget with required arguments
      testWidget = MaterialApp(
        home: Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Report(),
              settings: RouteSettings(
                arguments: {
                  'students': testStudents,
                  'accountId': 'test_account'
                },
              ),
            );
          },
        ),
      );

      // Mock the HTTP responses
      when(mockClient.get(any)).thenAnswer((_) async =>
          http.Response(json.encode({'data': testTransactions}), 200));
    });

    testWidgets('Renders initial UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Verify basic UI elements
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Total Fees'), findsOneWidget);
      expect(find.text('Pending Fees'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search field
    });

    testWidgets('Search functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Test Student');
      await tester.pump();

      // Verify filtered results
      expect(find.text('Test Student'), findsOneWidget);
    });

    testWidgets('Date range picker opens', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      // Tap the date range button
      await tester.tap(find.byIcon(Icons.date_range));
      await tester.pumpAndSettle();

      // Verify date picker is shown
      expect(find.byType(DateRangePicker), findsOneWidget);
    });

    testWidgets('Download PDF button works', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      expect(find.text('Download PDF'), findsOneWidget);
      await tester.tap(find.text('Download PDF'));
      await tester.pump();
    });

    testWidgets('Export Excel button works', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();

      expect(find.text('Export Excel'), findsOneWidget);
      await tester.tap(find.text('Export Excel'));
      await tester.pump();
    });

    test('filterTransaction filters by date range', () {
      final report = _ReportState();
      report.filterTrans = testTransactions;
      report.filterDate.text = '2024-01-01 - 2024-12-31';
      
      report.filterTransaction();
      
      expect(report.filterTransactionData.length, equals(1));
    });

    test('filterBySearch filters transactions by student name', () {
      final report = _ReportState();
      report.filterTrans = testTransactions;
      report.students = testStudents;
      report.searchQuery.text = 'Test Student';
      
      report.filterBySearch();
      
      expect(report.filterTransactionData.length, equals(1));
    });
  });
}
