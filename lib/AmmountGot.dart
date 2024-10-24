import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/AnimatedScreen.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(MaterialApp(
    home: AmmountGotPage(),
  ));
}

class AmmountGotPage extends StatefulWidget {
  const AmmountGotPage({super.key});

  @override
  State<AmmountGotPage> createState() => _AmmountPageState();
}

class _AmmountPageState extends State<AmmountGotPage> {
  var _totalFess = TextEditingController();
  var _description = TextEditingController();
  var transactionDescription = TextEditingController();
  String? _selectedPaymentMode;

  bool isLoading = false;
  double paid_fees = 0.0;
  late Map<String, dynamic> args;
  late String studentId;
  late String accountId;
  late double pendingAmount;
  late Student student;
  String? staffAccess;
  String? transactionMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
      studentId = args['student_id'];
      accountId = args['account_id'];
      pendingAmount = (args['pendingAmount'] as num).toDouble();
      student = args['student'];
    });
  }

  void updateYouGet(String studentId) async {
    try {
      final String url =
          "${APIURL}/api/v3/student/updateAmount/studentId=$studentId";
      var updateBody = {
        "paid_fees": student.paidFees + paid_fees,
      };
      await http.patch(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateBody),
      );
    } catch (err) {
      print("Error $err");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating student fees')),
      );
    }
  }

  void addAmount() async {
    if (_selectedPaymentMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a payment mode')),
      );
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      var url = "${APIURL}/api/v3/transaction/addAmount";
      var amount = double.parse(_totalFess.text); // Convert text to double
      pendingAmount = pendingAmount - amount;

      paid_fees = amount;
      var tranData = {
        "student_id": studentId,
        "account_id": accountId,
        "pendingAmount": pendingAmount,
        "transactionType": "payment",
        "transaction_description": transactionDescription.text,
        "transaction_mode": _selectedPaymentMode,
        "amount": amount,
      };

      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(tranData),
      );

      if (response.statusCode == 201) {
        updateYouGet(studentId);

        toastification.show(
            context: context,
            type: ToastificationType.success,
            autoCloseDuration: Duration(milliseconds: 1000),
            title: Text("Transaction Complete"),
            showProgressBar: false);

        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                Transaction(studentId: studentId, accountId: accountId)));

        setState(() {
          isLoading = false;
        });
      } else {
        // Handle other status codes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transaction')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      print(err.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save transaction')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: Text(
          "Collect Pay",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Transaction(
                          studentId: studentId, accountId: accountId)));
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.symmetric(vertical: 0),
              child: TextFormField(
                keyboardType: TextInputType.number,
                controller: _totalFess,
                onChanged: (value) {
                  setState(() {
                    _totalFess.text = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: 'Amount',
                  hintStyle: TextStyle(color: Colors.green.shade900),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.green.shade900,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Color(0xFFF1F4F8),
                ),
                style: TextStyle(
                  color: Color(0xFF101213),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.symmetric(vertical: 0),
              child: TextFormField(
                keyboardType: TextInputType.text,
                controller: transactionDescription,
                onChanged: (value) {
                  setState(() {
                    transactionDescription.text = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: 'Description',
                  hintStyle: TextStyle(color: Colors.green.shade900),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.green.shade900,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Color(0xFFF1F4F8),
                ),
                style: TextStyle(
                  color: Color(0xFF101213),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLength: 50,
                validator: (value) {
                  if (value != null && value.split(' ').length > 50) {
                    return 'Description cannot be more than 50 words';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(vertical: 0),
              child: DropdownButtonFormField<String>(
                value: _selectedPaymentMode,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMode = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: 'Payment Mode',
                  hintStyle: TextStyle(color: Colors.green.shade900),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.green.shade900,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Color(0xFFF1F4F8),
                ),
                style: TextStyle(
                  color: Color(0xFF101213),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                items: <String>['Online', 'Cash']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 65,
        child: Container(
          padding: EdgeInsets.all(10),
          child: TextButton(
            onPressed: isLoading
                ? null
                : () {
                    addAmount();
                  },
            child: Text(
              isLoading ? "Saving..." : "Save",
              style: TextStyle(
                  color: Colors.white, fontSize: 18, letterSpacing: 1),
            ),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
              backgroundColor: Colors.green[900],
            ),
          ),
        ),
      ),
    );
  }
}
