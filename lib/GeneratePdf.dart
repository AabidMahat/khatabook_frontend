import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:khatabook_project/Database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> generatePdf(List<TransactionData> transactions, List<Student> students) async {
  final pdf = pw.Document();

  // Load the app logo
  final ByteData logoData = await rootBundle.load('android/assets/pdf.png');
  final Uint8List logoBytes = logoData.buffer.asUint8List();

  // Calculating Total Credit, Paid Fees, and Pending Fees
  double totalCredit = transactions
      .where((txn) => txn.transactionType == 'payment')
      .fold(0, (sum, txn) => sum + txn.amount);
  double totalDebit = transactions
      .where((txn) => txn.transactionType == 'charge')
      .fold(0, (sum, txn) => sum + txn.amount);
  double pendingFees = totalDebit - totalCredit;

  // Function to build a page
  pw.Widget buildPage(List<TransactionData> transactions) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Image(
            pw.MemoryImage(logoBytes),
            height: 100,
            width: 100,
          ),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Header(
              level: 0,
              child: pw.Text('Transaction Report'),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Amount: $totalDebit'),
              pw.Text('Received Amount: $totalCredit'),
              pw.Text('Pending Amount: $pendingFees'),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: pw.FixedColumnWidth(65),  // Date
              1: pw.FlexColumnWidth(),     // Student Name
              2: pw.FlexColumnWidth(),     // Transaction Type
              3: pw.FixedColumnWidth(60),  // Amount
              4: pw.FlexColumnWidth(),     // Description
              5: pw.FixedColumnWidth(60),  // Mode
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Student Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Transaction Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Mode', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...transactions.map((txn) {
                final student = students.firstWhere(
                      (student) => student.id == txn.studentId,
                  orElse: () => Student(
                    id: "",
                    studentName: "Unknown",
                    phone: "phone",
                    classes: "classes",
                    totalFees: 0,
                    paidFees: 0,
                    accountId: "accountId",
                  ),
                );
                final date = DateFormat('dd/MM/yy').format(txn.createdAt);
                final transactionType = txn.transactionType == 'payment' ? 'Received' : 'Requested';
                final amount = txn.amount.toString();
                final description = txn.transactionDescription ?? "-";
                final mode = txn.transactionMode ?? "-";
                final rowColor = transactionType == 'Received'
                    ? PdfColors.green50
                    : transactionType == 'Requested'
                    ? PdfColors.red50
                    : PdfColors.white;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowColor),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(date),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(student.studentName),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(transactionType),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(amount),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(description),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(mode),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  // Determine the number of transactions per page
  const int transactionsPerPage = 10; // Adjust this value as needed
  int totalPages = (transactions.length / transactionsPerPage).ceil();

  for (int page = 0; page < totalPages; page++) {
    final start = page * transactionsPerPage;
    final end = start + transactionsPerPage;
    final pageTransactions = transactions.sublist(start, end > transactions.length ? transactions.length : end);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => buildPage(pageTransactions),
      ),
    );
  }

  // Get the document directory using path_provider
  final directory = await getExternalStorageDirectory();
  final path = directory!.path;

  print('PDF Path: $path');

  try {
    // Save the PDF file
    final file = File('$path/transaction_report.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the generated PDF using open_file package
    OpenFile.open('$path/transaction_report.pdf');
  } catch (e) {
    print('Error generating or opening PDF: $e');
  }
}
