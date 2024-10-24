import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/AddStaff.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/EditStaff.dart';
import 'package:khatabook_project/NewAddTeacher.dart';
import 'package:khatabook_project/addTeacher.dart';
import 'package:khatabook_project/sideBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(MaterialApp(
    home: TeacherWidget(),
  ));
}

class TeacherWidget extends StatefulWidget {
  const TeacherWidget({super.key});

  @override
  State<TeacherWidget> createState() => _TeacherWidgetState();
}

class _TeacherWidgetState extends State<TeacherWidget> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<Staff> staffs = [];
  List<Staff> filteredStaffs = [];
  late String accountId;
  var searchQuery = TextEditingController();
  var teacherNameController = TextEditingController();
  String? staffAccess;
  String ?access;
  bool isLoading = false;
  bool sortAscending = true;

  @override
  void initState() {
    super.initState();
    getUserIdFromSharedPreferences();
  }

  void getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      accountId = prefs.getString('selectedAccountId') ?? '';
      access = prefs.getString("setAccess");
    });
    await getAllTeacher(accountId);
  }

  Future<void> getAllTeacher(String accountId) async {
    final String url =
        "${APIURL}/api/v3/staff/getAllStaff/$accountId";

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        staffs = List<Staff>.from(
            data['data'].map((value) => Staff.fromJson(value)));
        filteredStaffs = staffs;
      });
    } else {
      print("Not able to fetch teachers");
    }
  }

  void filterTransaction() {
    setState(() {
      if (searchQuery.text.isEmpty) {
        filteredStaffs = staffs;
      } else {
        filteredStaffs = staffs
            .where((staff) => staff.staffName
            .toLowerCase()
            .contains(searchQuery.text.toLowerCase()))
            .toList();
      }
    });
  }
  void sortStaffByName() {
    setState(() {
      sortAscending = !sortAscending;
      if (sortAscending) {
        filteredStaffs.sort((a, b) => a.staffName.compareTo(b.staffName));
      } else {
        filteredStaffs.sort((a, b) => b.staffName.compareTo(a.staffName));
      }
    });
  }

  Widget buildLoader() {
    return isLoading
        ? BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    )
        : SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => Dashboard(),
                settings: RouteSettings(arguments: {
                  "staffAccess": access,
                })),
          );
          return false;
        },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.green.shade900,
          title: Text(
            'Employees',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Readex Pro',
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.menu,
              color: Colors.white,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ),
        drawer: SideBarWidget(accountId: accountId),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (isLoading)
                Center(
                  child: CircularProgressIndicator(),
                )
              else
                Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.75,
                            child: TextFormField(
                              controller: searchQuery,
                              onChanged: (value) => filterTransaction(),
                              textInputAction: TextInputAction.search,
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
                          IconButton(
                            onPressed: () {
                              setState(() {
                                sortStaffByName();
                              });
                            },
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.green.shade900,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5))),
                            icon: Icon(
                              Icons.sort_by_alpha,
                              color: Colors.white,
                              size: 30,
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(10, 20, 10, 8),
                      child: ListView.builder(
                        shrinkWrap: true, // Add this line
                        physics: NeverScrollableScrollPhysics(), // Add this line
                        itemCount: filteredStaffs.length,
                        itemBuilder: (context, index) {
                          final staff = filteredStaffs[index];
                          return TeacherCard(
                            staff: staff,
                          );
                        },
                      ),
                    ),
                    buildLoader(),
                  ],
                ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(20, 0, 20, 10),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => StaffLogin(),
                      settings: RouteSettings(arguments: {
                        "account_id": accountId,
                      })),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: Colors.white,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Create',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              style: TextButton.styleFrom(
                elevation: 3,
                backgroundColor: Colors.green.shade900,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TeacherCard extends StatelessWidget {
  final Staff staff;
  const TeacherCard({
    required this.staff,
  });

  String getAccessLevel(String access) {
    switch (access.toLowerCase()) {
      case 'low':
        return 'View Only';
      case 'medium':
        return 'View & Edit';
      case 'high':
        return 'Full Access';
      default:
        return 'Unknown Access';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditStaff(),
            settings: RouteSettings(arguments: {
              "staffId": staff.id,
              "staffName": staff.staffName,
              "staffNumber":staff.staffNumber,
              "staffAccess":staff.staffAccess,
            }),
          ),
        );
      },
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.92,
        height: 80,
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 3,
              color: Color(0x35000000),
              offset: Offset(0, 1),
            ),
          ],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(0xFFF1F4F8),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  staff.staffName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Access: ${getAccessLevel(staff.staffAccess)}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
