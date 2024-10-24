import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardWidget extends StatefulWidget {
  final TransactionData transaction;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;
  final Student student;

  const CardWidget({
    Key? key,
    required this.transaction,
    required this.onDelete,
    required this.onUpdate,
    required this.student,
  }) : super(key: key);

  @override
  _CardWidgetState createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  bool isLoading = false;
  String? staffAccess;

  @override
  void initState() {
    super.initState();
    getStaffAccess();
  }

  void getStaffAccess() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      staffAccess = pref.getString('staffAccess') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 8),
          child: SizedBox(
            height: 95,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: widget.transaction.transactionType == 'charge'
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          getFormattedDate(widget.transaction.createdAt),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "₹${widget.transaction.amount}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: widget.transaction.transactionType == 'charge'
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        if(staffAccess=="high"||staffAccess=="")
                          PopupMenuButton<int>(
                            onSelected: (int result) {
                              switch (result) {
                                case 0:
                                // Handle update
                                  showUpdateDialog(context);
                                  break;
                                case 1:
                                // Handle delete
                                  deleteTransaction();
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                              PopupMenuItem<int>(
                                value: 0,
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue),
                                    SizedBox(width: 10),
                                    Text('Update'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<int>(
                                value: 1,
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 10),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                            icon: Icon(Icons.more_vert),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  String getFormattedDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd MMM yyyy');
    return formatter.format(date);
  }

  Future<void> deleteTransaction() async {
    setState(() {
      isLoading = true;
    });

    final String url = "${APIURL}/api/v3/transaction/deleteTransaction/transactionId=${widget.transaction.id}";
    try {

      final String url2 =  "${APIURL}/api/v3/student/updateAmount/studentId=${widget.transaction.studentId}";

      var total_fees = widget.transaction.transactionType=="charge" ? widget.student.totalFees - widget.transaction.amount:widget.student.totalFees;

      var paid_fees = widget.transaction.transactionType=="payment" ? widget.student.paidFees -widget.transaction.amount:widget.student.paidFees;


      final studentResponse = await http.patch(
          Uri.parse(url2),
          body: {
            'total_fees':total_fees.toString(),
            'paid_fees':paid_fees.toString(),
          }
      );

      final response = await http.delete(Uri.parse(url));




      if (response.statusCode == 200) {
        print("Deleted Transaction");
        widget.onDelete();
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

  void showUpdateDialog(BuildContext context) {
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final int amount = int.tryParse(amountController.text) ?? 0;
                updateTransaction(amount);
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateTransaction(int amount) async {
    final String url = "${APIURL}/api/v3/transaction/updateTransaction/transactionId=${widget.transaction.id}";
    try {
      var amountDiff = amount - widget.transaction.amount;
      var pendingAmount = widget.transaction.transactionType == 'charge'
          ? widget.transaction.pendingAmount + amountDiff
          : widget.transaction.pendingAmount - amountDiff;

      final response = await http.patch(
        Uri.parse(url),
        body: {
          'amount': amount.toString(),
          'pendingAmount': pendingAmount.toString(),
        },
      );

      final String url2 =  "${APIURL}/api/v3/student/updateAmount/studentId=${widget.transaction.studentId}";

      var total_fees = widget.transaction.transactionType=="charge" ? widget.student.totalFees + amountDiff:widget.student.totalFees;
      var paid_fees = widget.transaction.transactionType=="payment" ? widget.student.paidFees + amountDiff:widget.student.paidFees;


      final studentResponse = await http.patch(
          Uri.parse(url2),
          body: {
            'total_fees':total_fees.toString(),
            'paid_fees':paid_fees.toString(),
          }
      );
      if (response.statusCode == 200) {
        print("Updated Transaction");
        widget.onUpdate();


        setState(() {
          isLoading =false;
        });
      } else {
        print("Failed to update transaction: ${response.statusCode}");
        // You can show a toast or dialog here to inform the user of the failure
      }
    } catch (e) {
      print("Error updating transaction: $e");
      setState(() {
        isLoading = false;
      });
      // Handle the error properly, e.g., by showing a toast or dialog
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
