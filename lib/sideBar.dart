import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/AllClasses.dart';

// import 'package:khatabook_project/AllClasses.dart';
import 'package:khatabook_project/AllTeachers.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/NewAddStaff.dart';
import 'package:khatabook_project/OranisationSetting.dart';
import 'package:khatabook_project/Subscription.dart';
import 'package:khatabook_project/addTeacher.dart';
import 'package:khatabook_project/newLoginPage.dart';
import 'package:khatabook_project/updateUser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import 'AddClass.dart';
import 'AddStaff.dart';
import 'Database.dart';

class SideBarWidget extends StatefulWidget {
  final String accountId;

  const SideBarWidget({super.key, required this.accountId});

  @override
  State<SideBarWidget> createState() => _SideBarWidgetState();
}

class _SideBarWidgetState extends State<SideBarWidget> {
  bool isLoading = true;
  bool isUserLoading = true;
  String? staffAccess;
  late String userId;
  UserData? user;
  bool isLogOut = false;
  bool isUserModified = false;

  @override
  void initState() {
    super.initState();
    getStaffAccess();
  }

  void getStaffAccess() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      staffAccess = pref.getString('setAccess') ?? "";
      userId = pref.getString('userId') ?? '';
      isUserModified = pref.getBool('isUserModified')??false;
    });
    print("Sidebar Access Level $staffAccess");
    getUser(userId);
  }

  void getUser(String userId) async {
    print("User Modified $isUserModified");

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedUser = prefs.getString('cachedUser_$userId');

      if (cachedUser != null && !isUserModified) {
        // If cached data exists, use it
        print("Using cached user data");
        var responseBody = json.decode(cachedUser);
        user = UserData.fromJson(responseBody);

        setState(() {
          isUserLoading = false;
        });
      } else {
        // If no cached data, fetch from server
        print("Making Api call");
        final url = "${APIURL}/api/v3/user/getUser/$userId";
        var response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          var responseBody = json.decode(response.body);
          print("Response Body for user: $responseBody");
          user = UserData.fromJson(responseBody['data']);

          // Save user data to shared preferences
          await prefs.setString('cachedUser_$userId', json.encode(responseBody['data']));

          setState(() {
            isUserLoading = false;
          });
          // Reset isUserModified flag
          await prefs.setBool('isUserModified', false);
          print("User Modified $isUserModified");
        } else {
          print("Failed to load user: ${response.statusCode}");
          setState(() {
            isUserLoading = false;
          });
        }
      }
    } catch (err) {
      print("Error fetching user data: $err");
      setState(() {
        isUserLoading = false;
      });
    }
  }

  void logOut() async {
    final url = "${APIURL}/api/v3/user/logOut/${userId}";

    try {
      var response = await http.post(Uri.parse(url));
      print(response.statusCode);
      if (response.statusCode == 200) {
        if (!isLogOut)
          toastification.show(
            context: context,
            title: Text("User logged out successfully"),
            type: ToastificationType.success,
            autoCloseDuration: Duration(milliseconds: 1000),
            showProgressBar: false
          );
        setState(() {
          isLogOut = true;
        });
        // Clear Shared Preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => NewLoginPage()),
          (Route<dynamic> route) => false,
        );
      } else {
        toastification.show(
          context: context,
          title: Text("Error while logging out"),
          type: ToastificationType.error,
          autoCloseDuration: Duration(milliseconds: 4000),
        );
      }
    } catch (err) {
      print(err);
    }
  }





  @override
  Widget build(BuildContext context) {
    print("Sidebar $staffAccess");
    return isUserLoading
        ? CircularProgressIndicator(
            color: Colors.transparent,
          )
        : Scaffold(
            body: Container(
                width: MediaQuery.sizeOf(context).width,
                child: Drawer(
                    elevation: 16,
                    child: Align(
                      alignment: AlignmentDirectional(-1, -1),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 0,
                              color: Color(0xFFE5E7EB),
                              offset: Offset(1, 0),
                            )
                          ],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xFFF1F4F8),
                            width: 1,
                          ),
                          shape: BoxShape.rectangle,
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0, 59, 0, 24),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF3F704D),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x4D9489F5),
                                        offset: Offset(0, 1),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            16, 20, 16, 16),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Container(
                                              width: 95,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                color: Color(0x4D9489F5),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.green.shade900,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(2),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    user != null &&
                                                            user!.imagePath
                                                                .contains(
                                                                    "default")
                                                        ? 'https://images.unsplash.com/photo-1624561172888-ac93c696e10c?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8NjJ8fHVzZXJzfGVufDB8fDB8fA%3D%3D&auto=format&fit=crop&w=900&q=60'
                                                        : user!.imagePath,
                                                    width: 74,
                                                    height: 44,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(12, 0, 0, 0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${(user!.name)}',
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Plus Jakarta Sans',
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0, 4, 0, 0),
                                                      child: Text(
                                                        '${user!.phone}',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Plus Jakarta Sans',
                                                          color:
                                                              Color(0x9AFFFFFF),
                                                          fontSize: 14,
                                                          letterSpacing: 0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              -1, 0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(0, 29,
                                                                    0, 0),
                                                        child: InkWell(
                                                          onTap:
                                                              () {
                                                                      Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => UpdateUserData()));
                                                                    }
                                                                  ,
                                                          child: Text(
                                                            'Edit Profile',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Plus Jakarta Sans',
                                                              color: Color(
                                                                  0x9AFFFFFF),
                                                              fontSize: 16,
                                                              letterSpacing: 0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  ],
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
                              SizedBox(
                                height: 20,
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Dashboard(),
                                        settings: RouteSettings(arguments: {
                                          "staffAccess": staffAccess,
                                        })),
                                  );
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(0),
                                    shape: BoxShape.rectangle,
                                    border: Border.all(
                                      color: Color(0x84BDBDBD),
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        22, 0, 12, 0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Icon(
                                          Icons.dashboard_outlined,
                                          color: Colors.green.shade900,
                                          size: 28,
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  12, 0, 0, 0),
                                          child: Text(
                                            'Dashboard',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              color: Colors.green.shade900,
                                              fontSize: 17,
                                              letterSpacing: 0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (staffAccess == "high" ||
                                  staffAccess == 'medium' ||
                                  staffAccess == "")
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ClassesWidget(),
                                          settings: RouteSettings(arguments: {
                                            "staffAccess": staffAccess,
                                          })),
                                    );
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: Color(0x84BDBDBD),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          22, 0, 12, 0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Icon(
                                            Icons.grain,
                                            color: Colors.green.shade900,
                                            size: 28,
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    12, 0, 0, 0),
                                            child: Text(
                                              'Classes',
                                              style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                color: Colors.green.shade900,
                                                fontSize: 17,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (staffAccess == "high" ||
                                  staffAccess == 'medium' ||
                                  staffAccess == "")
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => TeacherWidget(),
                                          settings: RouteSettings(arguments: {
                                            "staffAccess": staffAccess,
                                          })),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: Color(0x84BDBDBD),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          22, 0, 12, 0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Icon(
                                            Icons.person_2_outlined,
                                            color: Colors.green.shade900,
                                            size: 26,
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    12, 0, 0, 0),
                                            child: Text(
                                              'Employee(s)',
                                              style: TextStyle(
                                                fontFamily: 'Plus Jakarta Sans',
                                                color: Colors.green.shade900,
                                                fontSize: 17,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              if (staffAccess == "high" || staffAccess == "")
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              OrganisationSetting(),
                                          settings: RouteSettings(arguments: {
                                            "staffAccess": staffAccess,
                                          })),
                                    );
                                  },
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 0, 0, 12),
                                    child: Container(
                                      width: double.infinity,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(0),
                                        shape: BoxShape.rectangle,
                                        border: Border.all(
                                          color: Color(0x84BDBDBD),
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            22, 0, 12, 0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Icon(
                                              Icons.settings,
                                              color: Colors.green.shade900,
                                              size: 26,
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(12, 0, 0, 0),
                                              child: Text(
                                                'Settings',
                                                style: TextStyle(
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                  color: Colors.green.shade900,
                                                  fontSize: 17,
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16, 0, 16, 16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            12, 0, 12, 0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.6,
                                              child: Align(
                                                alignment:
                                                    AlignmentDirectional(0, 0),
                                                child: ElevatedButton(
                                                  onPressed:isLogOut?null: logOut,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              24),
                                                    ),
                                                    primary:
                                                        Colors.green.shade900,
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(
                                                                24, 0, 24, 0),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        FaIcon(
                                                          Icons.logout_sharp,
                                                          color: Colors.white,
                                                          size: 26,
                                                        ),
                                                        SizedBox(width: 12),
                                                        Text(
                                                          'Log Out',
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Plus Jakarta Sans',
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Align(
                                        alignment: AlignmentDirectional(0, 0),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  12, 12, 0, 0),
                                          child: Text(
                                            "DeenConnect",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              color: Color(0xFF3F704D),
                                              fontSize: 24,
                                              letterSpacing: 0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: AlignmentDirectional(0, 0),
                                        child: Text(
                                          'App version 1.0.0',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Readex Pro',
                                            color: Color(0xFF3F704D),
                                            letterSpacing: 0,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ))),
          );
  }
}
