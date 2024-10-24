import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/Database.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  Toastification();
  runApp(MaterialApp(
    home: NewStaffLogin(),
    debugShowCheckedModeBanner: false,
  ));
}

class NewStaffLogin extends StatefulWidget {
  const NewStaffLogin({super.key});

  @override
  _NewStaffLoginState createState() => _NewStaffLoginState();
}

class _NewStaffLoginState extends State<NewStaffLogin> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClass;
  String? staff_name, staff_number;
  Account? accountData;
  String ? account_id;

  @override
  void initState() {
    super.initState();

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve accountId after the context is fully available
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    account_id = args?['account_id'] as String?;
    if (account_id != null) {
      loginAccount(account_id);
    }
  }

  void loginAccount(String? accountId) async {
    try {
      var url = "${APIURL}/api/v3/account/getAccount";
      var response = await http.get(Uri.parse("$url/account_id=$accountId"));


      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);

        setState(() {
          accountData = responseBody['data'];
        });
      } else {
        print("Failed to load account");
      }
    } catch (err) {
      print("Error logging in account: $err");
    }
  }

  Future<void> sendWhatsApp(String staffPass) async {
    var phone = staff_number;
    var text =
        "You have been assigned to handle khatabook . Your username $staff_number and password $staffPass ";
    var url = "https://wa.me/$phone?text=$text";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Could not launch $url")));
    }
  }
  void addStaff(String accountId) async {
    print("Staff $accountData");
    var staffData = {
      "staff_name": staff_name,
      "staff_number": staff_number,
      "staff_access": _selectedClass,
    };

    print("Account Id in staff $accountId");


    try {
      var url = "${APIURL}/api/v3/staff/addStaff/accountId=$accountId";
      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(staffData),
      );
      print(response.body);

      if (response.statusCode == 201) {
        var data = json.decode(response.body);
        toastification.show(
            context: context,
            title: Text("Staff Created Successfully"),
            type: ToastificationType.success,
            autoCloseDuration: Duration(milliseconds: 4000)
        );
        Future.delayed(Duration(milliseconds: 4000),(){
          Navigator.push(context, MaterialPageRoute(builder: (context)=>Dashboard()));
        });
      } else {
        // Handle unsuccessful response
        print("Failed to add staff");
      }
    } catch (err) {
      print("Error while adding staff $err");
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40, bottom: 32),
                  child: Container(
                    width: 360,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Add Staff',
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
                      maxWidth: 570, // Adjust this value as necessary
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
                      padding: const EdgeInsets.symmetric( vertical: 20 ,horizontal: 15),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildTextField(
                              labelText: 'Enter Staff name',
                              icon: Icons.verified_user_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a staff name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            _buildPhoneNumberField(),
                            SizedBox(height: 16),
                            _buildDropdownField(),
                            SizedBox(height: 16),
                            _buildBottomSheet(context, account_id!)
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
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      child: TextFormField(
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.green.shade900),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xFFF1F4F8),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.green.shade900,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Color(0xFFF1F4F8),
          prefixIcon: Icon(icon, color: Colors.green[900]),
          border: OutlineInputBorder(),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 65,
            decoration: BoxDecoration(
              border: Border.all(
                color: Color(0xFFF1F4F8),
                width: 2,
              ),
              color: Color(0xFFF1F4F8),
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
          SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Enter Phone Number",
                labelStyle: TextStyle(color: Colors.green.shade900),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFFF1F4F8),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.green.shade900,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Color(0xFFF1F4F8),
                prefixIcon: Icon(Icons.mobile_screen_share_outlined,
                    color: Colors.green[900]),
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

  Widget _buildDropdownField() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        // Ensures the dropdown button expands to fit its container width
        decoration: InputDecoration(
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFFF1F4F8),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.green.shade900,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Color(0xFFF1F4F8),
            prefixIcon: Icon(Icons.class_, color: Colors.green[900]),
            labelText: "Select privilege level",
            labelStyle: TextStyle(color: Colors.green.shade900)),
        items: [
          DropdownMenuItem(
            value: "low",
            child: Text("View and Send Alert"),
          ),
          DropdownMenuItem(
            value: "medium",
            child: Text("View and Add Entries"),
          ),
          DropdownMenuItem(
            value: "high",
            child: Text("View, Add and Edit Entries"),
          ),
        ],
        onChanged: (newValue) {
          setState(() {
            _selectedClass = newValue;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a privilege level';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, String account_id) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(5),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.green[900],
      ),
      child: TextButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            print("Account in Bottom $account_id");
            addStaff(account_id);
          }
        },
        child: Text(
          "Add Staff",
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
