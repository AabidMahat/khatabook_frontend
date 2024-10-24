import 'package:flutter/material.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Payment.dart';
import 'package:khatabook_project/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/Database.dart';

class ModifyTransaction extends StatefulWidget {
  final TransactionData transaction;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;
  final Student student;

  const ModifyTransaction({
    required this.transaction,
    required this.onDelete,
    required this.onUpdate,
    required this.student,
    super.key,
  });

  @override
  State<ModifyTransaction> createState() => _ModifyTransactionState();
}

class _ModifyTransactionState extends State<ModifyTransaction> {
  final _formKey = GlobalKey<FormState>();
  var updateAmmount = TextEditingController();
  var transactionDescription = TextEditingController();
  String? _selectedPaymentMode;
  bool isLoading = false;
  String? staffAccess;
  String? accountId;

  @override
  void initState() {
    super.initState();
    getUserIdFromSharedPreferences();
    setAmmount();
  }

  void setAmmount(){
    setState(() {
      updateAmmount.text = widget.transaction.amount.toString();
      transactionDescription.text = widget.transaction.transactionDescription??"";
      _selectedPaymentMode = widget.transaction.transactionMode??"Online";
    });
  }

  void getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      staffAccess = prefs.getString('setAccess') ?? "";
      accountId = prefs.getString("selectedAccountId");
    });
  }

  Future<void> updateTransaction(int amount) async {
    final String url =
        "${APIURL}/api/v3/transaction/updateTransaction/transactionId=${widget.transaction.id}";
    try {
      setState(() {
        isLoading = true;
      });

      var amountDiff = amount - widget.transaction.amount;
      var pendingAmount = widget.transaction.transactionType == 'charge'
          ? widget.transaction.pendingAmount + amountDiff
          : widget.transaction.pendingAmount - amountDiff;

      final response = await http.patch(
        Uri.parse(url),
        body: {
          'amount': amount.toString(),
          'pendingAmount': pendingAmount.toString(),
          "transaction_description": transactionDescription.text,
          "transaction_mode": _selectedPaymentMode??"-",
        },
      );

      final String url2 =
          "${APIURL}/api/v3/student/updateAmount/studentId=${widget.transaction.studentId}";

      var total_fees = widget.transaction.transactionType == "charge"
          ? widget.student.totalFees + amountDiff
          : widget.student.totalFees;
      var paid_fees = widget.transaction.transactionType == "payment"
          ? widget.student.paidFees + amountDiff
          : widget.student.paidFees;

      final studentResponse = await http.patch(
        Uri.parse(url2),
        body: {
          'total_fees': total_fees.toString(),
          'paid_fees': paid_fees.toString(),
        },
      );

      if (response.statusCode == 200) {
        print("Updated Transaction");
        widget.onUpdate();
        
        setState(() {
          isLoading = false;
        });
        
        Navigator.push(context, MaterialPageRoute(builder: (context)=>Transaction(studentId: widget.student.id, accountId: accountId!)));
      } else {
        print("Failed to update transaction: ${response.statusCode}");
        // You can show a toast or dialog here to inform the user of the failure
      }
    } catch (e) {
      print("Error updating transaction: $e");
      // Handle the error properly, e.g., by showing a toast or dialog
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteTransaction() async {
    setState(() {
      isLoading = true;
    });

    final String url =
        "${APIURL}/api/v3/transaction/deleteTransaction/transactionId=${widget.transaction.id}";
    try {
      final String url2 =
          "${APIURL}/api/v3/student/updateAmount/studentId=${widget.transaction.studentId}";

      var total_fees = widget.transaction.transactionType == "charge"
          ? widget.student.totalFees - widget.transaction.amount
          : widget.student.totalFees;

      var paid_fees = widget.transaction.transactionType == "payment"
          ? widget.student.paidFees - widget.transaction.amount
          : widget.student.paidFees;

      final studentResponse = await http.patch(
        Uri.parse(url2),
        body: {
          'total_fees': total_fees.toString(),
          'paid_fees': paid_fees.toString(),
        },
      );

      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
        print("Deleted Transaction");
        widget.onDelete();

        Navigator.push(context, MaterialPageRoute(builder: (context)=>Transaction(studentId: widget.student.id, accountId: accountId!)));

      } else {
        print("Failed to delete transaction: ${response.statusCode}");
        // You can show a toast or dialog here to inform the user of the failure
      }
    } catch (e) {
      print("Error deleting transaction: $e");
      // Handle the error properly, e.g., by showing a toast or dialog
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
        title: Text(
          "Edit Transaction",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green.shade900,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, // Make sure form key is linked
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: TextFormField(
                    controller: updateAmmount,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      label: Text('Amount'),
                      labelStyle: TextStyle(color: Colors.green.shade900),
                      floatingLabelBehavior: FloatingLabelBehavior.always,

                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      return null;
                    },
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
                      label: Text('Description'),
                      labelStyle: TextStyle(color: Colors.green.shade900),
                      floatingLabelBehavior: FloatingLabelBehavior.always,

                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
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
                SizedBox(height: 20),
                if(widget.transaction.transactionType=='payment')
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
                      label: Text('Payment Mode'),
                      floatingLabelBehavior: FloatingLabelBehavior.always,

                      labelStyle: TextStyle(color: Colors.green.shade900),
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
                SizedBox(height: 30),
                if (staffAccess == "high" ||
                    staffAccess == "" ||
                    staffAccess == "medium")
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.edit),
                        label: Text("Update"),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green.shade900,
                          onPrimary: Colors.white,
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 60, vertical: 12),
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  int amount = int.parse(updateAmmount.text);
                                  updateTransaction(amount);
                                }
                              },
                      ),
                    ),
                  ),
                if (staffAccess == "high" || staffAccess == "")
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.delete),
                        label: Text("Delete"),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red.shade900,
                          onPrimary: Colors.white,
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 60, vertical: 12),
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                deleteTransaction();
                              },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
