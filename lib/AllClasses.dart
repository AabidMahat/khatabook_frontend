import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/AddClass.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/ModifyClass.dart';
import 'package:khatabook_project/sideBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(MaterialApp(
    home: ClassesWidget(),
  ));
}

class ClassesWidget extends StatefulWidget {
  const ClassesWidget({super.key});

  @override
  State<ClassesWidget> createState() => _ClassesWidgetState();
}

class _ClassesWidgetState extends State<ClassesWidget> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Account> accounts = [];
  List<ClassData> classes = [];
  List<ClassData> filteredClass = [];
  var searchQuery = TextEditingController();
  String accountId = '';
  bool isLoading = true;
  var classController = TextEditingController();
  bool sortAscending = true;
  String ?staffAccess;


  @override
  void initState() {
    super.initState();
    getUserIdFromSharedPreferences();
  }

  Future<void> getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      accountId = prefs.getString('selectedAccountId') ?? '';
      staffAccess = prefs.getString("setAccess");
    });

    if (accountId.isNotEmpty) {
      await getClasses(accountId);
    } else {
      print("Account ID is empty");
    }
  }

  Future<void> getClasses(String accountId) async {
    final String url =
        "${APIURL}/api/v3/class/getclasses/account_no=$accountId";

    var response = await http.get(Uri.parse(url));
    print("object $accountId");
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print("Classes $data");
      setState(() {
        classes = List<ClassData>.from(
            data['data'].map((value) => ClassData.fromJson(value)));
        isLoading = false;
        filteredClass = classes;
      });
    } else {
      print("Not able to fetch classes");
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateClass(String classId, String newClassName) async {
    final String url =
        "${APIURL}/api/v3/class/updateClass/$classId";
    // final String url = "http://10.0.2.2:3500/api/v3/class/updateClass/$classId";

    var updateBody = {
      "class_name": newClassName,
    };

    var response = await http.patch(Uri.parse(url),
        body: json.encode(updateBody),
        headers: {"Content-Type": "application/json"});

    print("Class ${response.body}");
    if (response.statusCode == 200) {
      toastification.show(
          context: context,
          type: ToastificationType.success,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Data Updated Successfully"));
      await getClasses(accountId);
    } else {
      toastification.show(
          context: context,
          type: ToastificationType.error,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Failed to Update Data"));
    }
  }

  void deleteClass(String classId) async {
    setState(() {
      isLoading = true;
    });

    final String url =
        "${APIURL}/api/v3/class/deleteClass/$classId";

    var response = await http.delete(Uri.parse(url));
    print(response.body);
    if (response.statusCode == 204) {
      toastification.show(
          context: context,
          type: ToastificationType.success,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Data Deleted Successfully"));
      await getClasses(accountId);
    } else {
      toastification.show(
          context: context,
          type: ToastificationType.error,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Failed to Update Data"));
    }

    setState(() {
      isLoading = false;
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
  void filterTransaction() {
    setState(() {
      if (searchQuery.text.isEmpty) {
        filteredClass = classes;
      } else {
        filteredClass = classes
            .where((staff) => staff.className
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
        filteredClass.sort((a, b) => a.className.compareTo(b.className));
      } else {
        filteredClass.sort((a, b) => b.className.compareTo(a.className));
        }
    }
      );
  }

  @override
  Widget build(BuildContext context) {
    print("Classes $classes");

    return WillPopScope(
        onWillPop: () async {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => Dashboard(),
            settings: RouteSettings(arguments: {
              "staffAccess": staffAccess,
            })),
      );
      return false;
    },
      child: Scaffold(
        key: _scaffoldKey,
        appBar:AppBar(
          backgroundColor: Colors.green.shade900,
          title: Text(
            'Classes',
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
        body:Column(
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
            Expanded(
              child: isLoading
                  ? Center(
                child: CircularProgressIndicator(),
              )
                  : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: filteredClass.length,
                  itemBuilder: (context, index) {
                    final classData = filteredClass[index];
                    return ClassCard(
                      classData: classData,
                      teacherName: classData.className,
                      deleteClass: deleteClass,
                    );
                  },
                ),
              ),
            ),
          ],
        ),

        bottomNavigationBar: Container(
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(10, 0, 10, 10),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => addclass()),
                );
              },
              child: Text(
                'Create',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w500,
                ),
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

class ClassCard extends StatelessWidget {
  final String teacherName;
  final Function(String) deleteClass;
  final ClassData classData;

  const ClassCard({
    required this.teacherName,
    required this.deleteClass,
    required this.classData,
  });

  @override
  Widget build(BuildContext context) {
    print(classData.requiredAmount);
    return InkWell(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=>ModifyClass(),settings: RouteSettings(
            arguments: {
              "classId":classData.id,
              "className":classData.className,
              "classAmount":classData.classAmount,
              "duration":classData.duration,
              "requiredAmount":classData.requiredAmount,
              "staffId":classData.teacherId,
            }
        )));
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.symmetric(vertical: 2),
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
        child: ListTile(
          title: Text(" Class $teacherName"),
        ),
      ),
    );
  }
}
