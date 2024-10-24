import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:khatabook_project/AllClasses.dart';

// import 'package:khatabook_project/AllClasses.dart';
import 'package:khatabook_project/AllTeachers.dart';
import 'package:khatabook_project/Subscription.dart';
import 'package:khatabook_project/addTeacher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AddClass.dart';
import 'AddStaff.dart';
import 'Database.dart';

class NewSideBar extends StatefulWidget {
  final Function(String) onClassSelected;
  final String accountId;

  const NewSideBar(
      {super.key, required this.onClassSelected, required this.accountId});

  @override
  State<NewSideBar> createState() => _NewSideBarState();
}

class _NewSideBarState extends State<NewSideBar> {
  List<ClassData> classes = [];
  bool isLoading = true;
  String? staffAccess;

  @override
  void initState() {
    super.initState();
    fetchClasses();
    getStaffAccess();
  }

  void getStaffAccess() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      staffAccess = pref.getString('staffAccess') ?? "";
    });
  }

  Future<void> fetchClasses() async {
    try {
      var url =
          "https://aabid.up.railway.app/api/v3/class/getclasses/account_no=${widget.accountId}";
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        print("Response Body for Classes: $responseBody");

        if (responseBody['data'] != null && responseBody['data'] is List) {
          var classesList = responseBody['data'] as List;
          setState(() {
            classes = classesList
                .map((classJson) =>
                ClassData.fromJson(classJson as Map<String, dynamic>))
                .toList();
            isLoading = false;
          });
          print("Classes fetched successfully: $classes");
        } else {
          print("Classes data is null or not in expected format");
          print("Actual data: ${responseBody['data']}");
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print("Failed to load classes: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (err) {
      print("Error fetching classes: $err");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(widget.accountId);
    return Drawer(
      elevation: 16,
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blue.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(
                      'android/assets/default.jpg'), // Replace with your asset
                ),
                SizedBox(height: 10),
                Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (staffAccess == "high"||staffAccess=="")
            ListTile(
              leading: Icon(Icons.person_add, color: Colors.blueAccent),
              title: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StaffLogin(),
                        settings: RouteSettings(arguments: {
                          "account_id": widget.accountId,
                        })),
                  );
                },
                child: Row(
                  children: [
                    Text("ADD STAFF",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    Icon(Icons.navigate_next, color: Colors.white),
                  ],
                ),
              ),
              onTap: () {
                // Add your onTap code here
              },
            ),
          ListTile(
            leading: Icon(Icons.person_add, color: Colors.blueAccent),
            title: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ClassesWidget()),
                );
              },
              child: Row(
                children: [
                  Text("SEE CLASSES",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      )),
                  Icon(Icons.navigate_next, color: Colors.white),
                ],
              ),
            ),
            onTap: () {
              // Add your onTap code here
            },
          ),
          ListTile(
            leading: Icon(Icons.person_add, color: Colors.blueAccent),
            title: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeacherWidget()),
                );
              },
              child: Row(
                children: [
                  Text("SEE TEACHERS",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      )),
                  Icon(Icons.navigate_next, color: Colors.white),
                ],
              ),
            ),
            onTap: () {
              // Add your onTap code here
            },
          ),
          ListTile(
            leading: Icon(Icons.currency_rupee, color: Colors.blueAccent),
            title: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Subscribe()),
                );
              },
              child: Row(
                children: [

                  Text("SUBSCRIPTION",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      )),
                  Icon(Icons.navigate_next, color: Colors.white),
                ],
              ),
            ),
            onTap: () {
              // Add your onTap code here
            },
          ),
          Divider(),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : classes.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 50.0,
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    "No Class Found!",
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    "Please Add Class",
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          )
              : ExpansionTile(
            leading:
            Icon(Icons.filter_list, color: Colors.blueAccent),
            title: Text(
              "Filter by Class",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            children: [
              ListTile(
                leading:
                Icon(Icons.clear, color: Colors.blue.shade900),
                title: Text("No Filter"),
                onTap: () {
                  widget.onClassSelected("");
                  Navigator.pop(context);
                },
              ),
              ...classes.map<Widget>((classItem) {
                return ListTile(
                  leading:
                  Icon(Icons.class_, color: Colors.blue.shade900),
                  title: Text(classItem.className),
                  onTap: () {
                    widget.onClassSelected(classItem.className);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}
