import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentCard extends StatefulWidget {
  final Student student;
  final String accountId;


  const StudentCard({super.key, required this.student,required this.accountId});

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  String getFormattedDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd MMM yy - hh:mm a');
    return formatter.format(date);
  }

  void provideStudentDetail()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("studentName", widget.student.studentName);
    prefs.setInt("totalFees", widget.student.totalFees);
    prefs.setInt("paidFees", widget.student.paidFees);
    prefs.setString("classId", widget.student.classId!);
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(10, 0, 10, 8),
      child: InkWell(
        onTap: (){
          provideStudentDetail();
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context)=>Transaction(
                studentId:widget.student.id,
                accountId:widget.accountId,
              )));
        },
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.92,
          height: 85,
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
            padding: EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(12, 0, 0, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.student.studentName,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF14181B),
                            fontSize: 17,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(0, 4, 0, 0),
                              child: Text(
                                'Class - ${widget.student.classes}',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: Color(0xFF57636C),
                                  fontSize: 14,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹ ${widget.student.totalFees - widget.student.paidFees >= 0 ? widget.student.totalFees - widget.student.paidFees : '-' + (widget.student.totalFees - widget.student.paidFees).abs().toString()}'
                        ,
                        textAlign: TextAlign.end,
                        style:TextStyle(
                          fontFamily: 'Outfit',
                          color: Color(0xFF090F13),
                          fontSize: 22,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 4, 0, 0),
                        child: Text(
                          'Total: ₹ ${widget.student.totalFees}',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF57636C),
                            fontSize: 14,
                            letterSpacing: 0,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
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
