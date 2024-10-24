import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Dashboard.dart';
import 'Database.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: addTeacher(),
  ));
}

class addTeacher extends StatefulWidget {
  const addTeacher({super.key});

  @override
  _addclassState createState() => _addclassState();
}

class _addclassState extends State<addTeacher> {
  final TextEditingController _teacherName = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedAccount;
  List accounts = [];
  late String userId;
  bool isSubmit = false;

  Future<void> createClass() async {
    if (_formKey.currentState!.validate()) {
      var classData = {
        "teacher_name": _teacherName.text,
        "account_no": _selectedAccount,
      };
      setState(() {
        isSubmit = true;
      });

      final String url =
          "${APIURL}/api/v3/teacher/addTeacher";
      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(classData),
      );

      if (response.statusCode == 201) {
        // Handle successful class creation
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      } else {
        // Handle error
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to create Teacher')));

        setState(() {
          isSubmit = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getUserIdFromSharedPreferences();
  }

  void getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
    });
    print("Teacher User Id $userId");
    fetchAccounts(userId);
  }

  Future<void> fetchAccounts(String userId) async {
    try {
      var url =
          "${APIURL}/api/v3/account/getAccounts/$userId";
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        print("Response Body: $responseBody"); // Debug line
        setState(() {
          accounts = responseBody['data']['account'];
          if (accounts.isNotEmpty) {
            _selectedAccount = accounts[0]['_id'];
          }
        });
        print("Accounts fetched successfully: $accounts"); // Debug line
      } else {
        print("Failed to load accounts: ${response.statusCode}");
      }
    } catch (err) {
      print("Error fetching accounts: $err");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Teacher $accounts");
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
                    "Add Teacher",
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
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height * 0.4),
                            child: _buildTextField(
                              controller: _teacherName,
                              labelText: "Enter Teacher Name",
                              icon: Icons.verified_user_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a Teacher name';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: 40),
                          _buildAccountDropdown(),
                          SizedBox(height: 40),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
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

  Widget _buildAccountDropdown() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonFormField<String>(
        value: _selectedAccount,
        decoration: InputDecoration(
          labelText: "Select Account",
          prefixIcon: Icon(Icons.account_circle, color: Colors.blueAccent),
          border: OutlineInputBorder(),
        ),
        items: accounts.map<DropdownMenuItem<String>>((account) {
          return DropdownMenuItem<String>(
            value: account['_id'],
            child: Text(account['account_name']),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedAccount = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select an account';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(10),
      height: 60,
      decoration: BoxDecoration(
        color: CupertinoColors.activeBlue,
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
        onPressed: isSubmit ? null : createClass,
        child: isSubmit
            ? CircularProgressIndicator(
                color: Colors.white,
              )
            : Text(
                "Add Teacher",
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
