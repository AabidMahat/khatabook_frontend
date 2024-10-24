import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'Database.dart';
import 'StudentCard.dart';
import 'ViewReport.dart';

class StudentsScreen extends StatefulWidget {
  final String accountId;
  final String accountName;

  StudentsScreen({required this.accountId, required this.accountName});

  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Student> students = [];
  List<Student> filteredStudent = [];
  bool isLoading = true;
  String searchQuery = "";
  String classSelected = "";
  String selectedSortedOption = "";

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  void fetchStudents() async {
    try {
      var response = await http.get(Uri.parse(
          "${APIURL}/api/v3/student/getStudnet/accountId=${widget.accountId}"));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        setState(() {
          students = List<Student>.from(
            data['data'].map((values) => Student.fromJson(values)),
          );
          filteredStudent = students;
          isLoading = false;
        });
        filterStudentData();
      } else {
        print("Failed to load students: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching students: $err");
    }
  }

  void filterStudentData() {
    setState(() {
      filteredStudent = students
          .where((student) => student.studentName
          .toLowerCase()
          .contains(searchQuery.toLowerCase()))
          .toList();

      if (classSelected.isNotEmpty) {
        filteredStudent = filteredStudent
            .where((student) => student.classes == classSelected)
            .toList();
      }
    });
  }

  void handleClassSelected(String className) {
    setState(() {
      classSelected = className;
      filterStudentData();
    });
  }

  void sortStudent(String sortBy) {
    if (sortBy == 'name') {
      filteredStudent.sort((a, b) => a.studentName.compareTo(b.studentName));
    } else if (sortBy == 'price_low') {
      filteredStudent.sort((a, b) => a.totalFees.compareTo(b.totalFees));
    } else if (sortBy == 'price_high') {
      filteredStudent.sort((a, b) => -a.totalFees.compareTo(b.totalFees));
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalFees =
    filteredStudent.fold(0, (sum, student) => sum + student.totalFees);

    int paidFees =
    filteredStudent.fold(0, (sum, student) => sum + student.paidFees);

    int pendingFees = totalFees - paidFees;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountName,style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue[900],
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.131,
            width: MediaQuery.of(context).size.width,
            color: Colors.blue[900],
            child: Column(
              children: [
                SizedBox(height: 10),
                Card(
                  margin: EdgeInsets.all(5),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder(
                              tween: IntTween(begin: 0, end: totalFees),
                              duration: Duration(seconds: 2),
                              builder: (context, int value, child) {
                                return Text('₹ ${value}',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold));
                              },
                            ),
                            Text('Total Fees',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        Column(
                          children: [
                            TweenAnimationBuilder(
                              tween: IntTween(begin: 0, end: pendingFees),
                              duration: Duration(seconds: 2),
                              builder: (context, int value, child) {
                                return Text('₹ ${value}',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold));
                              },
                            ),
                            Text('Pending Fees',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        TextButton(
                          style: ElevatedButton.styleFrom(
                            shape: BeveledRectangleBorder(),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Report()),
                            );
                          },
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  Text("View",
                                      style: TextStyle(color: Colors.blue[900])),
                                  Text("Report",
                                      style: TextStyle(color: Colors.blue[900])),
                                ],
                              ),
                              Icon(Icons.navigate_next,
                                  color: Colors.blue[900]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 80,
            decoration: BoxDecoration(color: Colors.grey.shade100),
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  padding: EdgeInsets.all(10),
                  child: TextFormField(
                    keyboardType: TextInputType.name,
                    onChanged: (value) {
                      searchQuery = value;
                      filterStudentData();
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.blue.shade900,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: "Search here",
                      labelStyle: TextStyle(
                        color: Colors.blue.shade900,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue.shade900,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.28,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                        EdgeInsets.symmetric(vertical: 18, horizontal: 5)),
                    items: [
                      DropdownMenuItem(
                        value: "price_low",
                        child: Row(
                          children: [
                            Icon(Icons.currency_rupee),
                            SizedBox(width: 5),
                            Icon(Icons.arrow_upward)
                            // Text("Price(Low->high)")
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "price_high",
                        child: Row(
                          children: [
                            Icon(Icons.currency_rupee),
                            SizedBox(width: 5),
                            Icon(Icons.arrow_downward)
                            // Text("Price(High->Low)")
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: "name",
                        child: Row(
                          children: [
                            Icon(Icons.sort),
                            SizedBox(width: 10),
                            Icon(Icons.person)
                            // Text("Name")
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedSortedOption = value ?? "";
                        sortStudent(selectedSortedOption);
                      });
                    },
                    hint: Icon(Icons.sort),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Container(
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, "/studentLogin", arguments: {
                          "account_id": widget.accountId
                        }).then((_) {
                          // Refresh the state after returning from student login
                          fetchStudents();
                        });
                      },
                      icon: Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      iconSize: 20,
                    ))
              ],
            ),
          ),
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else if (students.isEmpty)
            Center(child: Text('No students found'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredStudent.length,
                itemBuilder: (context, index) {
                  return StudentCard(
                    student: filteredStudent[index],
                    accountId: widget.accountId,
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}
