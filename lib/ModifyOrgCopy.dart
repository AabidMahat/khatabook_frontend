import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:khatabook_project/CreateBusinessAccount.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/Payment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;

class ModifyOrganisationCopy extends StatefulWidget {
  const ModifyOrganisationCopy({super.key, required Future<void> Function(String accountId, String access) loginAccount});

  @override
  State<ModifyOrganisationCopy> createState() => _ModifyOrganisationCopyState();
}

class _ModifyOrganisationCopyState extends State<ModifyOrganisationCopy> {
  var organisationName = TextEditingController();
  String? organisationType;
  final _formKey = GlobalKey<FormState>();
  String? account_name;
  bool isActive = true;
  late String userId;
  late Map<String, dynamic> args;
  late String accountId;
  late String accountName;
  late int accountLength;
  String? staffAccess;
  List staffAccount = [];

  @override
  void initState() {
    super.initState();
    getUserIdFromSharedPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null) {
        args = arguments as Map<String, dynamic>;
        accountId = args['accountId'];
        accountName = args['accountName'];
        accountLength = args['accountLength'];
        organisationName.text = accountName;
      } else {
        // Handle case where arguments are not passed correctly
        print('Arguments not passed correctly');
      }
    });
  }

  void getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
      staffAccess = prefs.getString('setAccess') ?? "";
    });
  }

  Future<void> getAccountByStaff(String userNum) async {
    try {
      var url = "https://aabid.up.railway.app/api/v3/staff/loginStaff";
      var updateData = {"staff_number": userNum};
      var response = await http.post(Uri.parse(url),
          body: json.encode(updateData),
          headers: {"Content-Type": "application/json"});
      if (response.statusCode == 201) {
        var responseBody = json.decode(response.body);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('staffAccess', responseBody['data'][0]['staff_access']);

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

  void deleteAccount(String accountId) async {
    final String url =
        "https://aabid.up.railway.app/api/v3/account/deleteAccount/$accountId";
    var response = await http.delete(Uri.parse(url));

    if (response.statusCode == 200) {
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: Text("Data deleted successfully"),
        autoCloseDuration: Duration(milliseconds: 3000),
      );

      setState(() {
        accountLength = accountLength - 1;
      });
      if (accountLength > 0)
        Future.delayed(Duration(milliseconds: 1000), () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Dashboard(),
                  settings:
                  RouteSettings(arguments: {"staffAccess": staffAccess})));
        });
      else if(staffAccount.isNotEmpty){
        Future.delayed(Duration(milliseconds: 1000), () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Dashboard(),
                  settings:
                  RouteSettings(arguments: {"staffAccess": staffAccess})));
        });
      }
      else {
        Future.delayed(Duration(milliseconds: 1000), () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => CreateOrganisation()));
        });
      }
    } else {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text("Error while deleting Account"),
        autoCloseDuration: Duration(milliseconds: 3000),
      );
    }
  }

  Future<void> updateAccount(String account_id, String accountName) async {
    print("Update Account $account_id");

    var updateBody = {
      "account_name": accountName,
    };

    var response = await http.patch(
        Uri.parse(
            "https://aabid.up.railway.app/api/v3/account/updateAccount/$account_id"),
        body: json.encode(updateBody),
        headers: {"Content-Type": "application/json"});

    print(response.statusCode);
    if (response.statusCode == 200) {
      toastification.show(
          context: context,
          type: ToastificationType.success,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Data Updated Successfully"));
      Future.delayed(Duration(milliseconds: 3000), () {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => Dashboard(),
                settings:
                RouteSettings(arguments: {"staffAccess": staffAccess})));
      });
    } else {
      toastification.show(
          context: context,
          type: ToastificationType.error,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Failed to Update Data"));
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
            "Edit Organization",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.green.shade900,
          centerTitle: true,
          leading: Icon(Icons.arrow_back,color: Colors.white,)
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, // Make sure form key is linked
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: TextFormField(
                    controller: organisationName,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Organization Name',
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an organization name';
                      }
                      return null;
                    },
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
                    validator: (value) {
                      if (value == null) {
                        return 'Please select an organization type';
                      }
                      return null;
                    },
                  ),
                ),
                if (staffAccess == "high" || staffAccess == "")
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.edit),
                        label: Text("Update"),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green.shade900,
                          onPrimary: Colors.white,
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 60, vertical: 12),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            updateAccount(accountId, organisationName.text);
                          }
                        },
                      ),
                    ),
                  ),
                if (staffAccess == "high" || staffAccess == "")
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.delete),
                        label: Text("Delete"),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red.shade900,
                          onPrimary: Colors.white,
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 60, vertical: 12),
                        ),
                        onPressed: () {
                          deleteAccount(accountId);
                        },
                      ),
                    ),
                  ),
                if (staffAccess == "high" ||staffAccess=='medium'|| staffAccess == "")
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.settings),
                        label: Text("Settings"),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green.shade900,
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
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Payment(
                                    accountName: accountName,
                                    accountId: accountId,
                                  )));
                        },
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
}
