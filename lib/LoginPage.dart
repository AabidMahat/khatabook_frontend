import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/CreateBusinessAccount.dart';
import 'package:khatabook_project/ResetPassword.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'Dashboard.dart';
import 'CreateAccount.dart';
import 'Register.dart';

void main() {
  runApp(MaterialApp(
    home: HomeLogin(),
  ));
}

class HomeLogin extends StatefulWidget {
  const HomeLogin({Key? key}) : super(key: key);

  @override
  State<HomeLogin> createState() => _HomeLoginState();
}

class _HomeLoginState extends State<HomeLogin> {
  var emailText = TextEditingController();
  var passText = TextEditingController();
  bool _isPasswordVisible = false;
  var userId;
  bool isLoading = false;
  List staffAccount = [];

  @override
  void initState() {
    super.initState();
    removePrefs();
  }

  void removePrefs() async {
    // Clear Shared Preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> getAccountByStaff(String userNum) async {
    try {
      var url = "${APIURL}/api/v3/staff/loginStaff";
      var updateData = {"staff_number": userNum};
      var response = await http.post(Uri.parse(url),
          body: json.encode(updateData),
          headers: {"Content-Type": "application/json"});
      if (response.statusCode == 201) {
        var responseBody = json.decode(response.body);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'accessByStaff', responseBody['data'][0]['staff_access']);

        setState(() {
          staffAccount = responseBody['data'].map((staff) {
            var account = staff['account_no'];
            account['access'] =
            staff['staff_access']; // Add access field to each account
            return account;
          }).toList();
        });
        // Save userId to shared preferences
      } else {
        print("Failed to load accounts");
      }
    } catch (err) {
      print(err);
    }
  }

  void loginAccount() async {
    try {
      setState(() {
        isLoading = true;
      });
      final String url = "${APIURL}/api/v3/user/login";

      var loginBody = {"phone": emailText.text, "password": passText.text};
      var response = await http.post(Uri.parse(url),
          body: json.encode(loginBody),
          headers: {"Content-Type": "application/json"});
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        userId = data['data']['_id'];

        // Save userId to shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        await prefs.setString("userNumber", data['data']['phone']);
        await getAccountByStaff(data['data']['phone']);
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                (data['data']['account_id'].isEmpty && staffAccount.isEmpty)
                    ? CreateOrganisation()
                    : Dashboard(),
                settings: RouteSettings(arguments: {"userId": userId})));
      } else {
        var errorMessage = "Invalid phone number or password";
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text(errorMessage),
          icon: Icon(Icons.error),
          autoCloseDuration: Duration(milliseconds: 3000),
        );
      }
    } catch (err) {
      print(err);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade900, Colors.lightGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 32),
                      child: Align(
                        alignment: AlignmentDirectional(0, 0),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              "android/assets/main_icon.png",
                              width: 241,
                              height: 169,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )),
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF101213),
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 12,),
                            // Padding(
                            //   padding: const EdgeInsets.symmetric(vertical: 12),
                            //   child: Text(
                            //     'Assalamu alaikum',
                            //     textAlign: TextAlign.center,
                            //     style: TextStyle(
                            //       color: Color(0xFF57636C),
                            //       fontSize: 16,
                            //       fontWeight: FontWeight.w500,
                            //     ),
                            //   ),
                            // ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextFormField(
                                controller: emailText,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Phone',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFF1F4F8),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF4B39EF),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFFF1F4F8),
                                ),
                                style: TextStyle(
                                  color: Color(0xFF101213),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TextFormField(
                                controller: passText,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFFF1F4F8),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0xFF4B39EF),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFFF1F4F8),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Color(0xFF57636C),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                        !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                style: TextStyle(
                                  color: Color(0xFF101213),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width,
                              child: Padding(
                                padding:
                                EdgeInsetsDirectional.fromSTEB(0, 0, 0, 16),
                                child: TextButton(
                                  onPressed: isLoading ? null : loginAccount,
                                  child: isLoading
                                      ? CircularProgressIndicator(
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  )
                                      : Text(
                                    'Login',
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
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ResetPassword()));
                                },
                                child: Text(
                                  'Forget password',
                                  style: TextStyle(
                                    color: Color(0xFF57636C),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Register()),
                                  );
                                },
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Don't have an account?  ",
                                        style: TextStyle(
                                          color: Color(0xFF101213),
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Sign Up here',
                                        style: TextStyle(
                                          color: Color(0xFF4B39EF),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
