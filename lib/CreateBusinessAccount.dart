import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/newLoginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: CreateOrganisation(),
  ));
}

class CreateOrganisation extends StatefulWidget {
  const CreateOrganisation({super.key});

  @override
  State<CreateOrganisation> createState() => _CreateOrganisationState();
}

class _CreateOrganisationState extends State<CreateOrganisation> {
  var organisationName = TextEditingController();
  String? organisationType;
  final _formKey = GlobalKey<FormState>();
  String? account_name;
  bool isActive = true;
  late String userId;
  String? staffAccess;
  bool ?accountListModified;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getUserIdFromSharedPreferences();
  }

  void getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
      staffAccess = prefs.getString('setAccess') ?? "";
    });
    print("Dashboard User Id $userId");
  }

  void addAccount(String user_id) async {
    print(user_id);
    setState(() {
      isLoading =true;
    });
    final String url =
        "${TESTURL}/api/v3/account/createAccount";
    var createBody = {
      "account_name": account_name,
      "account_type":organisationType,
      "isActive": isActive,
      "user_id": user_id,
    };
    try {
      var response = await http.post(Uri.parse(url),
          body: json.encode(createBody),
          headers: {"Content-Type": "application/json"});

      if (response.statusCode == 201) {
        var data = json.decode(response.body);
        print(data['data']);
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: Text("Account created Successfully"),
          icon: Icon(Icons.verified),
          autoCloseDuration: Duration(milliseconds: 1000),
        );
        setState(() {
          isLoading =false;
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('selectedAccountId',data['data']['account']['_id']);

          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => Dashboard(),
                  settings: RouteSettings(
                      arguments: {
                        "userId": userId,
                        "staffAccess":staffAccess,
                        "isAccountModified":true,
                      })));

      } else {
        var errorMessage =
            json.decode(response.body)['message'] ?? 'Account Creation Failed';
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text(errorMessage),
          icon: Icon(Icons.error),
          autoCloseDuration: Duration(milliseconds: 2000),
        );
        setState(() {
          isLoading =false;
        });
      }
    } catch (err) {
      setState(() {
        isLoading =false;
      });
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
          "Add Organization",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green.shade900,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => NewLoginPage()));
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an account name';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      account_name = value;
                    },
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Organization Name',
                      labelStyle: TextStyle(color: Colors.green.shade900),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
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
                    ),
                    style: TextStyle(
                      color: Color(0xFF101213),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                child: DropdownButtonFormField<String>(
                  value: organisationType,
                  onChanged: (String? newValue) {
                    setState(() {
                      organisationType = newValue;
                    });
                  },
                  items: <String>['Maktab', 'Masjid']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    hintText: 'Organization Type',
                    hintStyle: TextStyle(color: Colors.green.shade900),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
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
                  ),
                  style: TextStyle(
                    color: Color(0xFF101213),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text("Create"),
                    style: ElevatedButton.styleFrom(
                      primary:isLoading?Colors.grey:  Colors.green.shade900,
                      onPrimary: Colors.white,
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 60, vertical: 12),
                    ),
                    onPressed:isLoading?null: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        addAccount(userId!);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
