import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/ViewReport.dart';
import 'Student.dart';

void main() {
  runApp(
    customerPage(),
  );
}

class customerPage extends StatefulWidget {
  customerPage({super.key});

  @override
  State<customerPage> createState() => _customerPageState();
}

class _customerPageState extends State<customerPage> {
  @override
  void initState() {
    getStudents();
    super.initState();
  }

  List<Student> students = [];
  bool isLoading = true;

  Future<void> selectDate() async {
    await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  void getStudents() async {
    String url = "http://10.0.2.2:8000/api/v1/students";
    try {
      final res = await http.get(Uri.parse(url));
      print(res.body);
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body) as List;
        setState(() {
          students = data.map((value) => Student.fromJson(value)).toList();
          isLoading = false;
        });
      } else {
        print("Failed to load Data");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: Container(
          child: Row(
            children: [
              Icon(
                Icons.bookmarks_rounded,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 10),
              Text(
                "My Business",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(width: 10),
              Icon(
                Icons.edit,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
            width: MediaQuery.of(context).size.width,
            color: Colors.blue[900],
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "STUDENTS",
                          style: TextStyle(color: Colors.yellow),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_add_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              "ADD STAFF",
                              style: TextStyle(color: Colors.white),
                            ),
                            Icon(
                              Icons.navigate_next,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  child: Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text('₹ 0',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.green)),
                              Text('You will give',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('₹ 0',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.red)),
                              Text('You will get',
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
                                MaterialPageRoute(
                                  builder: (context) => Report(),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      "View",
                                      style: TextStyle(color: Colors.blue[900]),
                                    ),
                                    Text(
                                      "Report",
                                      style: TextStyle(color: Colors.blue[900]),
                                    )
                                  ],
                                ),
                                Icon(
                                  Icons.navigate_next,
                                  color: Colors.blue[900],
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 10),
                  height: 50,
                  width: 250,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search Student",
                      prefixIcon: Icon(CupertinoIcons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Container(
                  child: Column(
                    children: [
                      Container(
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.filter_alt_sharp,
                            size: 30,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      Container(
                        child: Text(
                          "Filters",
                          style: TextStyle(color: Colors.blue[900]),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Container(
                  child: Column(
                    children: [
                      Container(
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 30,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                      Container(
                        child: Text(
                          "PDF",
                          style: TextStyle(color: Colors.blue[900]),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                children: students.map((student) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.1,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.blueGrey[50],
                    child: Row(
                      children: [
                        Container(
                          child: CircleAvatar(
                            child: Text(
                              student.studentName, // Assuming the Student model has a 'name' field
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          margin: EdgeInsets.only(top: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                child: Text(
                                  student.studentName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                              Container(
                                child: Text("39 hours ago"),
                              )
                            ],
                          ),
                        ),
                        Spacer(),
                        Container(
                          child: Row(
                            children: [
                              Container(
                                child: Icon(
                                  Icons.currency_rupee,
                                  color: Colors.red,
                                ),
                              ),
                              Container(
                                child: Text(
                                  "300",
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            margin: EdgeInsets.only(left: 160, top: 10, bottom: 10),
            width: 200,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[700],
                elevation: 3.0,
                shadowColor: Colors.grey,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    color: Colors.white,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "ADD STUDENT",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
