import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/CreateAccount.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import 'Dashboard.dart';
import 'LoginPage.dart';

import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: Register(),
    debugShowCheckedModeBanner: false,
  ));
}

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  var usernameText = TextEditingController();
  var passText = TextEditingController();
  var emailText = TextEditingController();
  bool _isPasswordVisible = false;
  bool isLoading = true;
  var userId;
  void createAccount() async {
    try {
      final String url = "${APIURL}/api/v3/user/createUser";
      var userBody = {
        "name": usernameText.text,
        "email": emailText.text,
        "password": passText.text,
      };

      var response = await http.post(Uri.parse(url),
          body: json.encode(userBody),
          headers: {"Content-Type": "application/json"});

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        userId = data['data']['_id'];
        print(userId);

        // Save userId to shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: Text("User created Successfully"),
          icon: Icon(Icons.verified),
          autoCloseDuration: Duration(milliseconds: 2000),
        );
        Future.delayed(Duration(milliseconds: 2000), () {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => AddAccount(),
                  settings: RouteSettings(arguments: {
                    "userId":userId
                  })
              ));
        });
      } else {
        var errorMessage =
            json.decode(response.body)['message'] ?? 'Registration failed';
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text(errorMessage),
          icon: Icon(Icons.error),
          autoCloseDuration: Duration(milliseconds: 2000),
        );
      }
    } catch (err) {
      print(err);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(

        gradient: LinearGradient(
          colors: [Colors.green, Colors.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        ),
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Container(
              padding: EdgeInsets.only(left: 35, top: 30),
              child: Text(
                "Create Account",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 33,
                    fontWeight: FontWeight.bold),
              ),
            ),
            SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.3,
                    right: 35,
                    left: 35),
                child: Column(
                  children: [
                    TextField(
                      controller: usernameText,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          // Use white color for the text field background
                          labelText: "Name",
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                          // Adjust label text color
                          enabledBorder: UnderlineInputBorder(
                            // Underline border
                            borderSide: BorderSide(
                                color: Colors.grey.shade400), // Border color
                          ),
                          focusedBorder: UnderlineInputBorder(
                            // Focused underline border
                            borderSide: BorderSide(
                                color: Colors.blue), // Border color on focus
                          ),
                          prefixIcon: Icon(Icons.person),
                          suffixIcon: IconButton(
                            onPressed: () {
                              usernameText.clear();
                            },
                            icon: Icon(CupertinoIcons.clear_thick_circled),
                          )
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    TextField(
                      controller: emailText,
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          // Use white color for the text field background
                          labelText: "Email",
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                          // Adjust label text color
                          enabledBorder: UnderlineInputBorder(
                            // Underline border
                            borderSide: BorderSide(
                                color: Colors.grey.shade400), // Border color
                          ),
                          focusedBorder: UnderlineInputBorder(
                            // Focused underline border
                            borderSide: BorderSide(
                                color: Colors.blue), // Border color on focus
                          ),
                          prefixIcon: Icon(Icons.email)),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    TextField(
                      controller: passText,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        // Use white color for the text field background
                        labelText: "Password",
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        // Adjust label text color
                        enabledBorder: UnderlineInputBorder(
                          // Underline border
                          borderSide: BorderSide(
                              color: Colors.grey.shade400), // Border color
                        ),
                        focusedBorder: UnderlineInputBorder(
                          // Focused underline border
                          borderSide: BorderSide(
                              color: Colors.blue), // Border color on focus
                        ),
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Sign Up",
                          style: TextStyle(
                              color: Color(0xff4c505b),
                              fontSize: 27,
                              fontWeight: FontWeight.w700),
                        ),
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(0xff4c505b),
                          child: IconButton(
                            onPressed: () {
                              createAccount();
                            },
                            icon: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyLogin(),
                                  ));
                            },
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontSize: 18,
                                  color: Color(0xff4c505b)),
                            )),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
