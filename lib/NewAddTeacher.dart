import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import 'Dashboard.dart';
import 'Database.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: NewAddTeacher(),
  ));
}

class NewAddTeacher extends StatefulWidget {
  const NewAddTeacher({super.key});

  @override
  _addclassState createState() => _addclassState();
}

class _addclassState extends State<NewAddTeacher> {
  final TextEditingController _teacherName = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedAccount;
  List accounts = [];
  late String userId;
  bool isSubmit = false;

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
      var url = "${APIURL}/api/v3/account/getAccounts/$userId";
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

  Future<void> createClass() async {
    if (_formKey.currentState!.validate()) {
      var classData = {
        "teacher_name": _teacherName.text,
        "account_no": _selectedAccount,
      };

      setState(() {
        isSubmit = true;
      });

      final String url = "${APIURL}/api/v3/teacher/addTeacher";
      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(classData),
      );

      if (response.statusCode == 201) {
        toastification.show(
            context: context,
            title: Text("Teacher Created Successfully"),
            type: ToastificationType.success,
            autoCloseDuration: Duration(milliseconds: 4000)
        );
        Future.delayed(Duration(milliseconds: 4000),(){
          Navigator.push(context, MaterialPageRoute(builder: (context)=>Dashboard()));
        });
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create Teacher')),
        );

        setState(() {
          isSubmit = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Teacher $accounts");
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade900, Colors.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 32),
                  child: Container(
                    width: 350,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Add Teacher',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: 570,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4,
                          color: Color(0x33000000),
                          offset: Offset(0, 2),
                        )
                      ],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildTextField(
                              controller: _teacherName,
                              labelText: 'Enter Teacher name',
                              icon: Icons.verified_user_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a teacher name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 32),
                            _buildAccountDropdown(),

                            SizedBox(height: 32),
                            _buildSubmitButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.green[900]),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildAccountDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedAccount,
      decoration: InputDecoration(
        labelText: "Select Account",
        prefixIcon: Icon(Icons.account_circle, color: Colors.green[900]),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
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
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.green[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: createClass,
        child: isSubmit?CircularProgressIndicator(color: Colors.white,): Text(
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
