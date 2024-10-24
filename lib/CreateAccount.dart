import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(MaterialApp(
    home: AddAccount(),
    debugShowCheckedModeBanner: false,
  ));
}

class AddAccount extends StatefulWidget {
  const AddAccount({super.key});

  @override
  _AddAccountState createState() => _AddAccountState();
}

class _AddAccountState extends State<AddAccount> {
  final _formKey = GlobalKey<FormState>();
  String? account_name;
  bool isActive = true;
  late String userId;

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
    print("Dashboard User Id $userId");

  }

  void addAccount(String user_id) async {
    print(user_id);
    final String url = "${APIURL}/api/v3/account/createAccount";
    var createBody = {
      "account_name": account_name,
      "isActive": isActive,
      "user_id": user_id,
    };
    try {
      var response = await http.post(Uri.parse(url),
          body: json.encode(createBody),
          headers: {"Content-Type": "application/json"});

      if(response.statusCode==201){
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: Text("Account created Successfully"),
          icon: Icon(Icons.verified),
          autoCloseDuration: Duration(milliseconds: 3000),
        );

        Future.delayed(Duration(milliseconds: 3000), () {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => Dashboard(),
                  settings: RouteSettings(arguments: {
                    "userId":userId
                  })
              ));
        });
      }else {
        var errorMessage =
            json.decode(response.body)['message'] ?? 'Account Creation Failed';
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
    }
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Business Account",
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
                _buildTextField(
                  labelText: "Enter Account Name",
                  icon: Icons.verified_user_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an account name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    account_name = value;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: _buildBottomSheet(context),
    );
  }

  Widget _buildTextField({
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(),
        ),
        validator: validator,
        onSaved: onSaved,
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
            addAccount(userId!);
          }
        },
        child: Text(
          "Add Account",
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
