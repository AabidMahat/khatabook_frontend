import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Account_Show.dart';
import 'package:khatabook_project/AddStudent.dart';
import 'package:khatabook_project/CreateBusinessAccount.dart';
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/ModifyOrganisation.dart';
import 'package:khatabook_project/Student.dart';
import 'package:khatabook_project/StudentCard.dart';
import 'package:khatabook_project/newLoginPage.dart';
import 'package:khatabook_project/sideBar.dart';
import 'package:toastification/toastification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ViewReport.dart';
import 'package:flutter/widgets.dart';

void main() async {
  runApp(
    MaterialApp(
      home: Dashboard(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  final GlobalKey iconKey = GlobalKey();
  late Map<String, dynamic> args;
  String? staffAccess;
  String selectedButton = '';
  List accounts = [];
  List staffAccount = [];
  Map<String, bool> selectedAccounts = {};
  String? appBarTitle;
  var accountName = TextEditingController();

  List<Student> students = [];
  bool isLoading = true;
  String selectedSortedOption = "";
  String searchQuery = "";
  List<Student> filteredStudent = [];
  String? selectedAccountId;
  String selectedClassOption = '';
  String classSelected = "";
  late String userId;
  late String userNumber;
  int studentCount = 0;
  List<ClassData> classes = [];
  String? appTitle;
  bool accountListModified = false;
  bool loginAccountModified = false;
  bool isStaffListModified = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getUserIdFromSharedPreferences();
  }

  @override
  void didChangeDependencies() {
    getStaffAccess();
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // App is in the background (recent apps)
      clearCacheOnBackground();
    }
  }

  Future<void> clearCacheOnBackground() async {
    if (userId.isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('cachedAccounts_$userId');
      prefs.remove('account_$selectedAccountId');
      print(
          "Cache cleared for cachedAccounts_$userId when app went to background");
    }
  }

  void getStaffAccess() {
    final arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments.containsKey('staffAccess')) {
      staffAccess = arguments['staffAccess'] ?? '';
      accountListModified = arguments['isAccountModified'] ?? false;
      loginAccountModified = arguments['loginAccountModified'] ?? false;
    }
  }

  void findUserById(String user_id)async{
    var url = "${APIURL}/api/v3/user//getUser/$user_id";
    var response = await http.get(Uri.parse(url));

    if(response.statusCode==404){
      toastification.show(
        context: context,
        title: Text("User has been removed"),
        autoCloseDuration: Duration(milliseconds: 3000),
        showProgressBar: false
      );

      Navigator.push(context, MaterialPageRoute(builder: (context)=>NewLoginPage()));
    }

  }


  void getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';

      userNumber = prefs.getString('userNumber') ?? '';
      isStaffListModified = prefs.getBool('isStaffListModified') ?? false;
    });

    findUserById(userId);
    await getAccountByStaff(userNumber);
    fetchAccounts(userId);
  }

  Future<void> fetchAccounts(String user_id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedAccounts = prefs.getString('cachedAccounts_$user_id');

      if (!accountListModified &&
          cachedAccounts != null &&
          json.decode(cachedAccounts)['data']['account'].length > 0) {
        print("Cached");
        var accountData = json.decode(cachedAccounts);
        setState(() {
          accounts = accountData['data']['account']
              .where((account) => account['isActive'] == true)
              .map((account) {
            account['access'] = ""; // Add access field to each account
            return account;
          }).toList();
          print("Account Empty ${accounts.isEmpty}");

          if (accounts.isEmpty && staffAccount.isEmpty) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => CreateOrganisation()));
          }
          selectedAccounts = {
            for (var account in accounts) account['_id']: false
          };
        });
      } else {
        var url = "${APIURL}/api/v3/account/getAccounts/$user_id";
        var response = await http.get(Uri.parse(url));
        print("New Api Call Fro Fetch Account");
        if (response.statusCode == 200) {
          var responseBody = json.decode(response.body);
          prefs.setString('cachedAccounts_$user_id', response.body);
          setState(() {
            accounts = responseBody['data']['account']
                .where((account) => account['isActive'] == true)
                .map((account) {
              account['access'] = ""; // Add access field to each account
              return account;
            }).toList();
            print("Account Empty ${accounts.isEmpty}");

            if (accounts.isEmpty && staffAccount.isEmpty) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateOrganisation()));
            }
            selectedAccounts = {
              for (var account in accounts) account['_id']: false
            };
          });
          accountListModified =
              false; // Reset the flag after fetching the accounts
        }
      }
      if (accounts.isNotEmpty) {
        print("Account not empty");
        selectedAccountId = prefs.getString('selectedAccountId');
        if (selectedAccountId != null && selectedAccounts[selectedAccountId]!=null ) {
          selectedAccounts[selectedAccountId!] = true;
          loginAccount(selectedAccountId!, staffAccess ?? "");
          return;
        } else {
          selectedAccounts[accounts[0]['_id']] = true;
          loginAccount(accounts[0]['_id'], staffAccess ?? "");
          return;
        }
      }

      if (staffAccount.isNotEmpty) {
        print("Staff not empty");

        SharedPreferences pref = await SharedPreferences.getInstance();
        String? access = pref.getString('accessByStaff');

        selectedAccountId = prefs.getString('selectedAccountId');

        if (selectedAccountId != null) {
          selectedAccounts[selectedAccountId!] = true;
          loginAccount(selectedAccountId!, access ?? "");
          return;
        } else {
          selectedAccounts[staffAccount[0]['_id']] = true;
          loginAccount(staffAccount[0]['_id'], access ?? "");
          return;
        }
      }
    } catch (err) {
      print("Error fetching accounts: $err");
    }
  }

  Future<void> getAccountByStaff(String userNum) async {
    try {
      // If no cached data, fetch from server
      var url = "${APIURL}/api/v3/staff/loginStaff";
      var updateData = {"staff_number": userNum};
      var response = await http.post(Uri.parse(url),
          body: json.encode(updateData),
          headers: {"Content-Type": "application/json"});

      if (response.statusCode == 201) {
        var responseBody = json.decode(response.body);
        setState(() {
          staffAccount = List<Map<String, dynamic>>.from(responseBody['data']
              .where((staff) => staff['account_no']['isActive'] == true)
              .map((staff) {
            var account = Map<String, dynamic>.from(staff['account_no']);
            account['access'] =
                staff['staff_access']; // Add access field to each account
            return account;
          }));
        });
      } else {
        print("Failed to load Staff accounts");
      }
    } catch (err) {
      print("Error fetching staff accounts: $err");
    }
  }

  Future<void> loginAccount(String accountId, String access) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedAccountData = prefs.getString('account_$accountId');
      if (cachedAccountData != null && !loginAccountModified) {
        // Data is cached, use it
        print("Using cached account data");
        var accountData = json.decode(cachedAccountData);
        setState(() {
          // Clear the student list when logging into a new account
          students = [];
          filteredStudent = [];
          isLoading = true;
          appBarTitle = accountData['data']['account']['account_name'];
          accountName.text = accountData['data']['account']['account_name'];
        });
        print("Login $access");

        await prefs.setString('selectedAccountId', accountId);
        await prefs.setString("setAccess", access);
        await prefs.setInt('studentCount', students.length);
        fetchClasses();

        // Get students based on the cached data
        await getStudents(accountId);
      } else {
        // Data is not cached, make an API call
        print("New Api Call");
        var url = "${APIURL}/api/v3/account/getAccount";
        var response = await http.get(Uri.parse("$url/account_is=$accountId"));
        print(json.decode(response.body));
        print(accountId);
        if (response.statusCode == 200) {
          var responseBody = json.decode(response.body);

          // Cache the new data
          await prefs.setString('account_$accountId', response.body);

          setState(() {
            // Clear the student list when logging into a new account
            students = [];
            filteredStudent = [];
            isLoading = true;
            appBarTitle = responseBody['data']['account']['account_name'];
            accountName.text = responseBody['data']['account']['account_name'];
            loginAccountModified = false;
          });
          print("Login $access");

          await prefs.setString('selectedAccountId', accountId);
          await prefs.setBool('loginAccountModified', false);
          await prefs.setString("setAccess", access);
          await prefs.setInt('studentCount', students.length);
          fetchClasses();

          // Get students based on the new data
          await getStudents(accountId);
        } else {
          print("Failed to load account");
        }
      }
    } catch (err) {
      print("Error logging in account: $err");
    }
  }

  Future<void> showClassFilterPopup(BuildContext context) async {
    final selectedClass = await showMenu<String>(
      context: context,
      position:
          RelativeRect.fromLTRB(MediaQuery.of(context).size.width, 280, 0, 0),
      // Adjust position as needed
      items: [
        PopupMenuItem(
          value: "", // or any value you want to assign
          child: ListTile(
            leading: Icon(Icons.clear, color: Colors.blue.shade900),
            title: Text("No Filter"),
          ),
        ),
        ...classes.map((classItem) {
          return PopupMenuItem(
            value: classItem.className,
            child: ListTile(
              leading: Icon(Icons.grain, color: Colors.blue.shade900),
              title: Text("Class :- ${classItem.className}"),
            ),
          );
        }).toList(),
      ],
    );

    if (selectedClass != null) {
      handleClassSelected(selectedClass);
    }
  }

  void selectButton(String button) {
    setState(() {
      selectedButton = button;
    });
  }

  // void _showSnackBar(String message) {
  //   final snackBar = SnackBar(content: Text(message));
  //   ScaffoldMessenger.of(context).showSnackBar(snackBar);
  // }

  Future<void> fetchClasses() async {
    try {
      String accountId = selectedAccounts.keys.firstWhere(
        (accountId) => selectedAccounts[accountId] == true,
        orElse: () => "",
      );
      var url = "${APIURL}/api/v3/class/getclasses/account_no=${accountId}";
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);

        if (responseBody['data'] != null && responseBody['data'] is List) {
          var classesList = responseBody['data'] as List;
          setState(() {
            classes = classesList
                .map((classJson) =>
                    ClassData.fromJson(classJson as Map<String, dynamic>))
                .toList();
            isLoading = false;
          });
        } else {
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

  Future<void> getAllAccount() async {
    try {
      var url = "${APIURL}/api/v3/account/getAdminAccounts";
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        setState(() {});
      } else {
        print("Failed to load accounts");
      }
    } catch (err) {
      print("Error fetching accounts: $err");
    }
  }

  Future<void> getStudents(String accountId) async {
    try {
      var response = await http.get(Uri.parse(
          "${APIURL}/api/v3/student/getStudnet/accountId=${accountId}"));
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
        print("Failed to load student: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      print("No data: $err");
    }
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

  void _openBottomSheet() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => AccountScreen(
              accounts: [...accounts, ...staffAccount],
              selectedAccounts: selectedAccounts,
              loginAccount: loginAccount,
              userId: userId,
              userNum: userNumber,
              staffAccess: staffAccess,
            ));
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

  @override
  Widget build(BuildContext context) {
    int totalFees =
        filteredStudent.fold(0, (sum, student) => sum + student.totalFees);

    int paidFees =
        filteredStudent.fold(0, (sum, student) => sum + student.paidFees);

    int pendingFees = totalFees - paidFees;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      selectedAccountId = args['accountId'] as String?;
    } else {
      // Handle the case when arguments are not as expected
      selectedAccountId = null;
    }

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0xFF3F704D),
            iconTheme: IconThemeData(color: Colors.white),
            automaticallyImplyLeading: true,
            title: Align(
              alignment: AlignmentDirectional(-1, 0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _openBottomSheet,
                        child: Align(
                          alignment: AlignmentDirectional(-1, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                appBarTitle != null
                                    ? appBarTitle!
                                    : "Loading...",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: 'Readex Pro',
                                  color: Colors.white,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Icon(
                                FontAwesomeIcons.chevronDown,
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ModifyOrganisation(
                          loginAccount: loginAccount, userNum: userNumber),
                      settings: RouteSettings(arguments: {
                        "accountId": selectedAccounts.keys.firstWhere(
                          (accountId) => selectedAccounts[accountId] == true,
                          orElse: () => "",
                        ),
                        "accountName": accountName.text,
                        "accountLength": accounts.length,
                      }),
                    ),
                  );
                },
              ),
            ],
            centerTitle: false,
            elevation: 0,
          ),
          drawer: SideBarWidget(
            accountId: selectedAccounts.keys.firstWhere(
              (accountId) => selectedAccounts[accountId] == true,
              orElse: () => "",
            ),
          ),
          body: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.1,
                width: MediaQuery.of(context).size.width,
                color: Color(0xFF3F704D),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
                      child: Column(
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Align(
                                            alignment:
                                                AlignmentDirectional(0, 0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                TweenAnimationBuilder(
                                                  tween: IntTween(
                                                      begin: 0, end: totalFees),
                                                  duration:
                                                      Duration(seconds: 2),
                                                  builder: (context, int value,
                                                      child) {
                                                    return Text(
                                                      '₹ $value',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        color: Colors.white,
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    );
                                                  },
                                                ),
                                                Text(
                                                  'Total Fees',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
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
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      20, 8, 20, 0),
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
                                                builder: (context, int value,
                                                    child) {
                                                  return Text(
                                                    '₹ $value',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      color: Colors.white,
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  );
                                                },
                                              ),
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(0, 0, 4, 0),
                                                child: Text(
                                                  'Pending Fees',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'Plus Jakarta Sans',
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
                    ),
                  ],
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.06,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Color(0xFF3F704D),
                ),
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: BeveledRectangleBorder(),
                  ),
                  onPressed: (students.isEmpty)
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Report(),
                              settings: RouteSettings(arguments: {
                                "students": students,
                                "accountId": selectedAccounts.keys.firstWhere(
                                  (accountId) =>
                                      selectedAccounts[accountId] == true,
                                  orElse: () => "",
                                ),
                              }),
                            ),
                          );
                        },
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "View Report",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                        Icon(Icons.navigate_next, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                height: 70,
                decoration: BoxDecoration(color: Colors.grey.shade100),
                child: Row(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      padding: EdgeInsets.all(10),
                      child: TextFormField(
                        keyboardType: TextInputType.name,
                        onChanged: (value) {
                          searchQuery = value;
                          filterStudentData();
                        },
                        decoration: InputDecoration(
                          contentPadding:
                              EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
                          suffixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF080000),
                            size: 20,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xFF3F704D),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          isDense: false,
                          labelText: 'Search...',
                          labelStyle: TextStyle(
                            fontFamily: 'Readex Pro',
                            color: Color(0xFF3F704D),
                            letterSpacing: 0,
                            fontWeight: FontWeight.w500,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xFF3F704D),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 45,
                      width: 45,
                      child: IconButton(
                        style: IconButton.styleFrom(
                            backgroundColor: Color(0xFF3F704D),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5))),
                        icon: Icon(
                          Icons.sort_by_alpha,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Sort By"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.currency_rupee),
                                      title: Text("Price (Low -> High)"),
                                      onTap: () {
                                        setState(() {
                                          selectedSortedOption = "price_low";
                                          sortStudent(selectedSortedOption);
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.currency_rupee),
                                      title: Text("Price (High -> Low)"),
                                      onTap: () {
                                        setState(() {
                                          selectedSortedOption = "price_high";
                                          sortStudent(selectedSortedOption);
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.sort),
                                      title: Text("Name"),
                                      onTap: () {
                                        setState(() {
                                          selectedSortedOption = "name";
                                          sortStudent(selectedSortedOption);
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Container(
                      height: 45,
                      width: 45,
                      child: IconButton(
                        style: IconButton.styleFrom(
                            backgroundColor: Color(0xFF3F704D),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5))),
                        icon: Icon(
                          Icons.filter_alt,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          showClassFilterPopup(context);
                        },
                      ),
                    ),
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
                        accountId: selectedAccounts.keys.firstWhere(
                          (accountId) => selectedAccounts[accountId] == true,
                          orElse: () => "",
                        ),
                      );
                    },
                  ),
                )
            ],
          ),
          floatingActionButton: Container(
            height: 55,
            width: 55,
            child: IconButton(
              style: IconButton.styleFrom(backgroundColor: Color(0xFF3F704D)),
              icon: Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddStudent(),
                    settings: RouteSettings(arguments: {
                      "account_id": selectedAccounts.keys.firstWhere(
                        (accountId) => selectedAccounts[accountId] == true,
                        orElse: () => "",
                      ),
                    }),
                  ),
                );
              },
            ),
          )),
    );
  }
}
