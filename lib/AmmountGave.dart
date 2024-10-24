import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/transaction.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(MaterialApp(
    home: AmmountGivePage(),
  ));
}

class AmmountGivePage extends StatefulWidget {
  const AmmountGivePage({Key? key}) : super(key: key);

  @override
  State<AmmountGivePage> createState() => _AmmountPageState();
}

class _AmmountPageState extends State<AmmountGivePage> {
  var _totalFess = TextEditingController();
  var _description = TextEditingController();
  var transactionDescription = TextEditingController();
  bool isLoading = false;
  double? total_fees;
  late Map<String, dynamic> args;
  late String studentId;
  late String accountId;
  late double pendingAmount;
  late Student student;
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
      var updateBody = {"total_fees": total_fees};
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
    setState(() {
      isLoading = true;
    });
    try {
      var url = "${APIURL}/api/v3/transaction/addAmount";
      var amount = double.parse(_totalFess.text);
      pendingAmount = pendingAmount + amount;
      print(student);

      total_fees = student.totalFees + amount;

      var tranData = {
        "student_id": studentId,
        "account_id": accountId,
        "pendingAmount": pendingAmount,
        "transactionType": "charge",
        "transaction_description": _description.text,
        "amount": amount,
      };

      print(tranData);

      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(tranData),
      );

      if (response.statusCode == 201) {
        updateYouGet(studentId);
        setState(() {
          isLoading = false;
        });
        toastification.show(
            context: context,
            type: ToastificationType.success,
            autoCloseDuration: Duration(milliseconds: 1000),
            title: Text("Transaction Complete"),
            showProgressBar: false);
        // Handle success
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                Transaction(studentId: studentId, accountId: accountId)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transaction')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (err) {
      print(err.toString());
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save transaction')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: Text(
          "Request Pay ",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
            Container(
              margin: EdgeInsets.symmetric(vertical: 30),
              child: TextFormField(
                keyboardType: TextInputType.number,
                controller: _totalFess,
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
            SizedBox(
              height: 10,
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 0),
              child: TextFormField(
                keyboardType: TextInputType.text,
                controller: _description,
                onChanged: (value) {
                  setState(() {
                    _description.text = value;
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
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(10),
        height: 65,
        child: TextButton(
          onPressed: isLoading
              ? null
              : () {
            setState(() {
              isLoading = true;
            });
            addAmount();
          },
          child: Text(
            isLoading ? "Saving..." : "Save",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            backgroundColor: Colors.red[900],
          ),
        ),
      ),
    );
  }
}
