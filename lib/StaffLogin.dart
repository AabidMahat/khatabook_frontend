import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/Dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(MaterialApp(
      home: LoginAsStaff(),
      debugShowCheckedModeBanner: false,
    ));
}

class LoginAsStaff extends StatefulWidget {
  const LoginAsStaff({super.key});

  @override
  _LoginAsStaffState createState() => _LoginAsStaffState();
}

class _LoginAsStaffState extends State<LoginAsStaff> {
  final _formKey = GlobalKey<FormState>();
  String? staff_number, staffPassword;

  void loginStaff() async {
    var staffData = {
      "staff_number": staff_number,
      "staffPassword": staffPassword,
    };

    try {
      var url = "https://aabid.up.railway.app/api/v3/staff/loginStaff";

      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(staffData),
      );

      if (response.statusCode == 201) {
        var staffResponse = json.decode(response.body);

        var staffId = staffResponse['data']['_id'];
        print(staffId);

        var accountUrl =
            'https://aabid.up.railway.app/api/v3/staff/staffAccount/staff_id=$staffId';

        var accountResponse = await http.get(Uri.parse(accountUrl));
        print(accountResponse.statusCode);

        if (accountResponse.statusCode == 200) {
          var accountResponseBody = json.decode(accountResponse.body);
          var accountId = accountResponseBody['data']['account']['_id'];

          // // Save userId to shared preferences
          // SharedPreferences prefs = await SharedPreferences.getInstance();
          // await prefs.setString('staffAccess',staffResponse['data']['staff_access'] );
          // Show toast notification
          toastification.show(
            context: context,
            title: Text("Login Successful",style: TextStyle(color: Colors.white,fontSize: 18),),
            icon: Icon(Icons.check_circle_outline,size: 30,color: Colors.green.shade800,),
            autoCloseDuration: Duration(milliseconds: 3000)
          );


          Future.delayed(Duration(seconds: 3), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Dashboard(),
                settings: RouteSettings(arguments: {'accountId': accountId}),
              ),
            );
          });
        }
      } else {
        // Handle unsuccessful response
        print("Failed to Login staff");
      }
    } catch (err) {
      print("Error while Login staff $err");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "LogIn Staff",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: CupertinoColors.activeBlue,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset("android/assets/staff.jpg"),
                SizedBox(height: 20),
                _buildPhoneNumberField(),
                SizedBox(height: 20),
                _buildPasswordField(),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: _buildBottomSheet(context),
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
              onSaved: (value) {
                staff_number = value;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        obscureText: true,
        decoration: InputDecoration(
          labelText: "Enter Password",
          prefixIcon: Icon(Icons.lock_outline, color: Colors.blueAccent),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a Password';
          }
          return null;
        },
        onSaved: (value) {
          staffPassword = value;
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
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            loginStaff();
          }
        },
        child: Text(
          "Login Staff",
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
