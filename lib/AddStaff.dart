import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/AllTeachers.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/phoneBook.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  Toastification();
  runApp(MaterialApp(
    home: StaffLogin(),
    debugShowCheckedModeBanner: false,
  ));
}

class StaffLogin extends StatefulWidget {
  const StaffLogin({super.key});

  @override
  _StaffLoginState createState() => _StaffLoginState();
}

class _StaffLoginState extends State<StaffLogin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();

  String? _selectedClass;
  String? staff_name, staff_number;
  Account? accountData;
  String? account_id;
  String? staffAccess;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getStaffAccess();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve accountId after the context is fully available
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    account_id = args?['account_id'] as String?;
    if (account_id != null) {
      loginAccount(account_id);
    }
  }

  void getStaffAccess() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      staffAccess = pref.getString('setAccess') ?? "";
    });
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

  void addStaff(String accountId) async {
    print("Staff $accountData");
    setState(() {
      isLoading = true;
    });
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
        setState(() {
          isLoading = false;
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('isStaffListModified', true);

        Navigator.push(
            context, MaterialPageRoute(builder: (context) => TeacherWidget()));
      } else {
        // Handle unsuccessful response
        print("Failed to add staff");
        setState(() {
          isLoading = false;
        });
      }
    } catch (err) {
      print("Error while adding staff $err");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: Text("Add Employee",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context,
                MaterialPageRoute(builder: (context) => TeacherWidget()));
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTextField(
                        labelText: "Enter Name",
                        icon: Icons.verified_user_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a staff name';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          staff_name = value;
                        },
                      ),
                      SizedBox(height: 10),
                      _buildPhoneNumberField(),
                      SizedBox(height: 10),
                      _buildDropdownField(),
                      SizedBox(height: 5),
                      _buildBottomSheet(context, account_id!),
                    ],
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
      // margin: EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        decoration: InputDecoration(
          hintText: labelText,
          hintStyle: TextStyle(color: Colors.green.shade900),
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
          border: OutlineInputBorder(),
        ),
        style: TextStyle(fontWeight: FontWeight.w500),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Container(
      // margin: EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '+91',
              style: TextStyle(color: Colors.green.shade900, fontSize: 16),
            ),
          ),
          suffixIcon: IconButton(
            onPressed: () async {
              final phoneNumber = await Navigator.push(context,
                  MaterialPageRoute(builder: (context) => PhoneBook()));
              if (phoneNumber != null) {
                setState(() {
                  _phoneNumberController.text = phoneNumber;
                });
              }
            },
            icon: Icon(
              Icons.contact_page_rounded,
              color: Colors.green.shade900,
            ),
          ),
          hintText: "Phone Number",
          hintStyle: TextStyle(color: Colors.green.shade900),
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
        style: TextStyle(fontWeight: FontWeight.w500),
        onSaved: (value) {
          staff_number = value;
        },
        controller: _phoneNumberController,
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      // margin: EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonFormField<String>(
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
            hintText: "Select privilege level",
            hintStyle: TextStyle(color: Colors.green.shade900)),
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
        style: TextStyle(
            fontWeight: FontWeight.w500, color: Colors.green.shade900),
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
      margin: EdgeInsets.symmetric(vertical: 10),
      height: 60,
      decoration: BoxDecoration(
        color: isLoading ? Colors.grey : Colors.green.shade900,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextButton(
        onPressed: isLoading
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  print("Account in Bottom $account_id");
                  addStaff(account_id);
                }
              },
        child: Text(
          "Add Employee",
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
