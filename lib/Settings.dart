import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/SeetingFields.dart';
import 'package:khatabook_project/UpdateData.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(MaterialApp(
    home: SettingWidget(),
    debugShowCheckedModeBanner: false,
  ));
}

class SettingWidget extends StatefulWidget {
  const SettingWidget({super.key});

  @override
  State<SettingWidget> createState() => _SettingWidgetState();
}

class _SettingWidgetState extends State<SettingWidget> {
  late Map<String, dynamic> args;
  String? studentId;
  Student? student;
  String? staffAccess;

  @override
  void initState() {
    super.initState();
    getStaffAccess();
  }

  void getStaffAccess() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      staffAccess = pref.getString('setAccess') ;
    });
  }

  void deleteStudent() async {
    final String url =
        "${APIURL}/api/v3/student/deleteStudent/$studentId";

    var response = await http.delete(Uri.parse(url));

    if (response.statusCode == 200) {
      toastification.show(
          context: context,
          type: ToastificationType.success,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Student Deleted Successfully"));

      Future.delayed(Duration(milliseconds: 3000), () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Dashboard(),
                settings:
                    RouteSettings(arguments: {"staffAccess": staffAccess})));
      });
    } else {
      toastification.show(
          context: context,
          type: ToastificationType.error,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Error while Deleting"));
    }
  }

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    studentId = args['studentId'];
    student = args['student'];

    print(student!.imagePath);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3F704D),
        iconTheme: IconThemeData(color: Colors.white),
        automaticallyImplyLeading: true,
        title: Text(
          "Student Profile",
          style: TextStyle(
            fontFamily: 'Readex Pro',
            color: Colors.white,
            letterSpacing: 0,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                height: 200,
                width: MediaQuery.of(context).size.width,
                // decoration: BoxDecoration(color: Colors.grey[200]),
                child: Center(
                  child: CircleAvatar(
                    radius: 100,
                    backgroundColor: Colors.white,
                    child: student?.imagePath == null
                        ? Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 100,
                          )
                        : ClipOval(
                            child: student!.imagePath!.contains("supabase")
                                ? Image.network(
                                    "${student!.imagePath}",
                                    fit: BoxFit.cover,
                                    width: 150,
                                    height: 150,
                                  )
                                : Image.asset(
                                    "android/assets/default.jpg",
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  ),
                          ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Manage Settings",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              SizedBox(height: 20),
              Container(
                height: 90,
                child: SettingFields(
                    icon: Icons.person_2_outlined,
                    title: "Full Name",
                    subtitle: "${student?.studentName}"),
              ),
              Container(
                height: 90,
                child: SettingFields(
                    icon: Icons.call,
                    title: "Mobile Number",
                    subtitle: "${student?.phone}"),
              ),
              Container(
                height: 90,
                child: SettingFields(
                    icon: Icons.grain,
                    title: "Class",
                    subtitle: "${student?.classes}"),
              ),
              Container(
                height: 90,
                child: SettingFields(
                    icon: Icons.location_on,
                    title: "Address",
                    subtitle: "${student?.address}"),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (staffAccess == "high" ||
              staffAccess == "medium" ||
              staffAccess == "")
          ? Container(
              width: MediaQuery.of(context).size.width / 2.5,
              height: 60,
              margin: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (staffAccess == "high" ||
                      staffAccess == "medium" ||
                      staffAccess == "")
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.green,
                          side: BorderSide(color: Colors.green, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UpdateSetting(),
                              settings: RouteSettings(arguments: {
                                'studentId': studentId,
                                'student': student
                              }),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.edit,
                                color: Colors.white, size: 18),
                            SizedBox(width: 5), // Space between icon and text
                            Text(
                              "Update",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 10,
                  ),
                  if (staffAccess == "high" || staffAccess == "")
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          side: BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          deleteStudent();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.remove,
                                color: Colors.white, size: 18),
                            SizedBox(width: 5), // Space between icon and text
                            Text(
                              "Remove",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
    );
  }
}
