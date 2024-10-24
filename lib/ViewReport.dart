import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/Excel.dart';
import 'package:khatabook_project/GeneratePdf.dart';
import 'package:khatabook_project/ViewReportCard.dart';

void main() {
  runApp(MaterialApp(
    home: Report(),
  ));
}

class Report extends StatefulWidget {
  const Report({Key? key}) : super(key: key);

  @override
  _ReportState createState() => _ReportState();
}

class _ReportState extends State<Report> {
  TextEditingController filterDate = TextEditingController();
  var searchQuery = TextEditingController();
  List<TransactionData> filterTrans = [];
  late Map<String, dynamic> args;
  List<Student> students = [];
  List<TransactionData> filterTransactionData = [];
  String? accountId;
  bool isLoading = true;

  @override
  void initState() {

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
      students = args['students'];
      accountId = args['accountId'];
    });
    Future.delayed(Duration(seconds: 1), () {
      getAllTransactions();
    });

  }


  Future<void> selectDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        filterTransaction();
      });
    }
  }

  Future<void> selectDateRange(TextEditingController controller) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(Duration(days: 7)),
        end: DateTime.now(),
      ),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            '${DateFormat('yyyy-MM-dd').format(picked.start)} - ${DateFormat('yyyy-MM-dd').format(picked.end)}';
        filterTransaction();
      });
    }
  }

  void getAllTransactions() async {
    final String url =
        "${APIURL}/api/v3/transaction/getAllTransaction/accountId=${accountId}";
    try {
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          filterTrans = List<TransactionData>.from(
              data['data'].map((values) => TransactionData.fromJson(values)));

          filterTrans.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          filterTransactionData = filterTrans;
          isLoading = false;
        });
        print(filterTrans);
      } else {
        print("Failed to load filterTrans: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      print(err);
    }
  }

  void filterTransaction() {
    List<String> dateRange = filterDate.text.split(' - ');
    DateTime? startDate = dateRange.isNotEmpty
        ? DateFormat('yyyy-MM-dd').parse(dateRange[0])
        : null;
    DateTime? endDate = dateRange.length > 1
        ? DateFormat('yyyy-MM-dd').parse(dateRange[1])
        : null;

    setState(() {
      filterTransactionData = filterTrans.where((transaction) {
        bool isWithinDateRange = true;
        if (startDate != null && endDate != null) {
          isWithinDateRange = transaction.createdAt.isAfter(startDate.subtract(Duration(days: 1))) &&
              transaction.createdAt.isBefore(endDate.add(Duration(days: 1)));
        }
        return isWithinDateRange;
      }).toList();
    });
  }

  void filterBySearch() {
    String searchTerm = searchQuery.text.toLowerCase();
    print(students);
    setState(() {
      filterTransactionData = filterTrans.where((transaction) {
        // Step 2: Filter by search query in student name
        if (searchTerm.isNotEmpty) {
          final student = students.firstWhere(
                (student) => student.id == transaction.studentId,
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
          return student.studentName.toLowerCase().contains(searchTerm);
        }
        return true;
      }).toList();
    });
  }


  @override
  Widget build(BuildContext context) {
    int totalFees = filterTransactionData.fold(0, (sum, transaction) {
      if (transaction.transactionType == 'charge')
        return sum + transaction.amount;
      return sum;
    });

    int paidFees = filterTransactionData.fold(0, (sum, transaction) {
      if (transaction.transactionType == 'payment')
        return sum + transaction.amount;
      return sum;
    });

    int pendingFees = totalFees - paidFees;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Report",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green.shade900,
        elevation: 3,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => Dashboard()));
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Material(
            elevation: 5,
            child: Container(
              // height: MediaQuery.of(context).size.height * 0.1,
              padding: EdgeInsets.only(bottom: 20),
              width: MediaQuery.of(context).size.width,
              color: Colors.green.shade900,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Flexible(
                            child: Align(
                              alignment: AlignmentDirectional(0, 0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    20, 8, 20, 0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Align(
                                        alignment: AlignmentDirectional(0, 0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            TweenAnimationBuilder(
                                              tween: IntTween(
                                                  begin: 0, end: totalFees),
                                              duration: Duration(seconds: 2),
                                              builder:
                                                  (context, int value, child) {
                                                return Text(
                                                  '₹ $value',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                );
                                              },
                                            ),
                                            Text(
                                              'Total Fees',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                color: Color(0xB3FFFFFF),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Flexible(
                            child: Padding(
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(20, 8, 20, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Align(
                                      alignment: AlignmentDirectional(0, 0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          TweenAnimationBuilder(
                                            tween: IntTween(
                                                begin: 0, end: pendingFees),
                                            duration: Duration(seconds: 2),
                                            builder:
                                                (context, int value, child) {
                                              return Text(
                                                '₹ $value',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              );
                                            },
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0, 0, 4, 0),
                                            child: Text(
                                              'Pending Fees',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                color: Color(0xB3FFFFFF),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: TextFormField(
                    controller: searchQuery,
                    onChanged: (value) {
                      filterBySearch();
                    },
                    obscureText: false,
                    decoration: InputDecoration(
                      isDense: false,
                      labelText: 'Search...',
                      labelStyle: TextStyle(
                        color: Colors.green.shade900,
                        fontFamily: 'Readex Pro',
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF3F704D),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.green.shade900,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      contentPadding:
                          EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
                      suffixIcon: Icon(
                        Icons.search,
                        color: Color(0xFF080000),
                        size: 20,
                      ),
                    ),
                    style: TextStyle(
                      fontFamily: 'Readex Pro',
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.start,
                    cursorColor: Color(0xFF040000),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 0, 4, 0),
                  child: IconButton(
                    icon: Icon(
                      Icons.date_range,
                      color: Colors.white,
                      size: 30,
                    ),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.green.shade900,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5))),
                    onPressed: () {
                      (selectDateRange(filterDate));
                    },
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filterTransactionData.length,
                    itemBuilder: (context, index) {
                      final transaction = filterTransactionData[index];
                      final student = students.firstWhere(
                          (student) => student.id == transaction.studentId,
                          orElse: () => Student(
                              id: "",
                              studentName: "Unkown",
                              phone: "phone",
                              classes: "classes",
                              totalFees: 0,
                              paidFees: 0,
                              accountId: "accountId"));

                      return ReportCard(
                        transaction: transaction,
                        student: student,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(10, 0,0, 8),
            child: ElevatedButton(
              onPressed: () {
                generatePdf(filterTransactionData, students);
              },
              style: ElevatedButton.styleFrom(
                  primary: Colors.green.shade900,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)) // Background color
                  ),
              child: Text(
                "Download PDF",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Text color
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(10, 0, 10, 8),
            child: ElevatedButton(
              onPressed: ()async {
                List<Map<String, dynamic>> transactions = filterTrans.map((transaction) => transaction.toJson()).toList();
                List<Map<String, dynamic>> student = students.map((stu) => stu.toJson()).toList();
                 await exportDataToExcel(transactions: transactions,students: student);
              },
              style: ElevatedButton.styleFrom(
                  primary: Colors.green.shade900,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)) // Background color
              ),
              child: Text(
                "Export Excel",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Text color
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDateTextField(
      String labelText, TextEditingController controller) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4, // Adjust width as needed
      child: GestureDetector(
        onTap: () => selectDate(controller),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.black),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.black,
              ),
              Expanded(
                child: Text(
                  controller.text.isEmpty
                      ? labelText
                      : DateFormat('dd/MM/yy').format(
                          DateFormat('yyyy-MM-dd').parse(controller.text)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: controller.text.isEmpty
                        ? Colors.grey.shade600
                        : Colors.black,
                    fontSize: 15,
                    fontWeight: controller.text.isEmpty
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
