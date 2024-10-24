import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/ModifyTransaction.dart';
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
  bool hasBeenShown = false;
  TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getStaffAccess();
  }

  void getStaffAccess() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      staffAccess = pref.getString('setAccess') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transaction == null || widget.student == null) {
      return Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 8),
          child: InkWell(
            onTap:(staffAccess=='low')?null: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ModifyTransaction(
                          transaction: widget.transaction,
                          onDelete: widget.onDelete,
                          onUpdate: widget.onUpdate,
                          student: widget.student)));
            },
            child: Container(
              height: 70,
              margin: EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 3,
                    color: Color(0x35000000),
                    offset: Offset(
                      0.0,
                      1,
                    ),
                  )
                ],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFFF1F4F8),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
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
                        Text(
                          "Academic Fees",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            "₹${widget.transaction.amount}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color:
                                  widget.transaction.transactionType == 'charge'
                                      ? Colors.red
                                      : Colors.green,
                            ),
                          ),
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
}
