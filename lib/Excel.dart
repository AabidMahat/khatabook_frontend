import 'dart:io';
import 'package:excel/excel.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> exportDataToExcel({
  required List<Map<String, dynamic>> transactions,
  required List<Map<String, dynamic>> students,
}) async {
  // Request permission to manage external storage
  if (Platform.isAndroid) {
    if (!await _requestPermission(Permission.manageExternalStorage)) {
      print('Permission denied to access external storage.');
      return;
    }
  }

  var excel = Excel.createExcel();

  // Create Transactions sheet
  var transactionsSheet = excel['Transactions'];

  // Add column headers for Transactions sheet
  transactionsSheet.appendRow([
    '_id',
    'transactionType',
    'amount',
    'pendingAmount',
    'transaction_description',
    'transaction_mode',
    'student_id',
    'account_id',
    'createdAt',
    'updatedAt',
  ]);

  // Add data to Transactions sheet
  for (var transaction in transactions) {
    transactionsSheet.appendRow([
      transaction['_id'],
      transaction['transactionType'],
      transaction['amount'],
      transaction['pendingAmount'],
      transaction['transaction_description'],
      transaction['transaction_mode'],
      transaction['student_id'],
      transaction['account_id'],
      transaction['createdAt'],
      transaction['updatedAt'],
    ]);
  }

  // Create Students sheet
  var studentsSheet = excel['Students'];

  // Add column headers for Students sheet
  studentsSheet.appendRow([
    '_id',
    'student_name',
    'phone',
    'classes',
    'address',
    'total_fees',
    'paid_fees',
    'imagePath',
    'account_id',
  ]);

  // Add data to Students sheet
  for (var student in students) {
    studentsSheet.appendRow([
      student['_id'],
      student['student_name'],
      student['phone'],
      student['classes'],
      student['address'],
      student['total_fees'],
      student['paid_fees'],
      student['imagePath'],
      student['account_id'],
    ]);
  }

  // Save the file to the Downloads directory
  var directory = Directory('/storage/emulated/0/Download'); // Adjust path if needed
  String filePath = '${directory.path}/Data.xlsx';

  // Write the file to the directory
  var fileBytes = excel.encode();
  File(filePath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(fileBytes!);

  print('Excel file saved to $filePath');

  // Open the file
  final result = await OpenFile.open(filePath);
  print(result.message);
}

// Function to request storage permission
Future<bool> _requestPermission(Permission permission) async {
  if (await permission.isGranted) {
    return true;
  } else {
    var result = await permission.request();
    return result == PermissionStatus.granted;
  }
}
