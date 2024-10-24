import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'Dashboard.dart';

void main() {
  runApp(MaterialApp(
    routes: {
      "/": (context) => Dashboard(),
    },
    debugShowCheckedModeBanner: false,
  ));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClass;
  String? accountId;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  bool isloading = true;
  bool hasShownClassToast = false;
  List<ClassData> classes = [];
  String? staffAccess;

  @override
  void initState() {
    super.initState();
    getStaffAccess();
  }

  void getStaffAccess() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      staffAccess = pref.getString('setAccess') ?? "";
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve accountId after the context is fully available
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    accountId = args?['account_id'] as String?;
    if (accountId != null) {
      getAllClasses();
    }
  }

  void getAllClasses() async {
    final String url =
        "${APIURL}/api/v3/class/getclasses/account_no=$accountId";

    try {
      var response = await http.get(Uri.parse(url));
      print("Student Classes response: ${response.statusCode}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        classes = List<ClassData>.from(
            data['data'].map((values) => ClassData.fromJson(values)));

        if (classes.isEmpty && !hasShownClassToast) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: Text("Please Add Class"),
            autoCloseDuration: Duration(milliseconds: 5000),
          );
          hasShownClassToast = true;
        }
      } else {
        print("Failed to fetch classes. Status code: ${response.statusCode}");
      }

      setState(() {
        isloading = false; // Update loading state
      });
    } catch (err) {
      print("Error fetching classes: $err");
      setState(() {
        isloading = false; // Update loading state
      });
    }
  }

  Future<void> createStudent() async {
    var studentData = {
      "account_id": accountId,
      "classes": _selectedClass,
      "student_name": _name.text,
      "phone": _phone.text,
      "total_fees": 0,
      "paid_fees": 0,
      "image_path": ""
    };

    final String url =
        "${APIURL}/api/v3/student/createStudent";
    var response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(studentData),
    );

    if (response.statusCode == 200) {
      // Handle successful student creation
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Dashboard(),
              settings: RouteSettings(arguments: {
                accountId: accountId,
                "staffAccess": staffAccess,
              })));
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create student')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(accountId);
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage(
                "android/assets/loginPage.png",
              ),
              fit: BoxFit.cover)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            Container(
              padding: EdgeInsets.only(left: 20, top: 60),
              child: Text(
                "Add Student",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                ),
              ),
            ),
            SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image.asset("android/assets/login1.png"),
                      SizedBox(height: 5),
                      Container(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.4),
                        child: _buildTextField(
                          controller: _name,
                          labelText: "Enter Student Name",
                          icon: Icons.verified_user_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a student name';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 30),
                      _buildPhoneNumberField(),
                      SizedBox(height: 20),
                      _buildDropdownField(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomSheet: _buildBottomSheet(context),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String labelText,
      required IconData icon,
      String? Function(String?)? validator}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        textInputAction: TextInputAction.next,
        controller: controller,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 65,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Center(
              child: Text(
                "+91",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: TextFormField(
              keyboardType: TextInputType.phone,
              controller: _phone,
              decoration: InputDecoration(
                labelText: "Enter Phone Number",
                prefixIcon: Icon(Icons.mobile_screen_share_outlined,
                    color: Colors.blueAccent),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                } else if (value.length != 10) {
                  return 'Enter a valid 10-digit phone number';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.class_, color: Colors.blueAccent),
          labelText: "Select Class",
        ),
        items: classes.map((ClassData classData) {
          return DropdownMenuItem<String>(
            value: classData.className,
            child: Text(classData.className),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedClass = newValue;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a class';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(10),
      height: 60,
      decoration: BoxDecoration(
        color: (classes.isEmpty||staffAccess=='low') ? Colors.grey : CupertinoColors.activeBlue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextButton(
        onPressed: (classes.isEmpty || staffAccess=='low')
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  createStudent();
                }
              },
        child: Text(
          "Add Student",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
