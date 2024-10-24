import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/CreateBusinessAccount.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/Payment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;

class ModifyOrganisation extends StatefulWidget {
  final Function(String accountId, String access) loginAccount;
  final String userNum;

  const ModifyOrganisation(
      {required this.loginAccount, required this.userNum, super.key});

  @override
  State<ModifyOrganisation> createState() => _ModifyOrganisationState();
}

class _ModifyOrganisationState extends State<ModifyOrganisation> {
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
  List accounts = [];
  var account;
  bool isLoading = false;

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
        getAccount(accountId);
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
    fetchAccounts(userId);
    getAccountByStaff(widget.userNum);
  }

  void fetchAccounts(String user_id) async {
    try {
      var url =
          "${APIURL}/api/v3/account/getAccounts/$user_id";
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        setState(() {
          accounts = responseBody['data']['account'].map((account) {
            account['access'] = ""; // Add access field to each account
            return account;
          }).toList();
        });
        print(accounts);
      }
    } catch (err) {
      print("Error fetching accounts: $err");
    }
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
            'staffAccess', responseBody['data'][0]['staff_access']);

        setState(() {
          staffAccount = responseBody['data'].map((staff) {
            var account = staff['account_no'];
            account['access'] =
                staff['staff_access']; // Add access field to each account
            return account;
          }).toList();
        });
        print(staffAccount);
        print(staffAccount[0]['_id']);
        // Save userId to shared preferences
      } else {
        print("Failed to load accounts");
      }
    } catch (err) {
      print(err);
    }
  }

  void getAccount(String accountId) async {
    try {
      var url = "${APIURL}/api/v3/account/getAccount";
      var response = await http.get(Uri.parse("$url/account_is=$accountId"));

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        setState(() {
          account = responseBody['data'];
          organisationType = account['account']['account_type'];
        });
      } else {
        print("Failed to load account");
      }
    } catch (err) {
      print("Error logging in account: $err");
    }
  }

  void deleteAccount(String accountId) async {
    setState(() {
      isLoading = true;
    });
    final String url =
        "${APIURL}/api/v3/account/deleteAccount/$accountId";
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
      setState(() {
        isLoading = false;
      });
      if (accountLength > 0) {
        widget.loginAccount(accounts[0]['_id'], accounts[0]['access']);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Dashboard(),
                settings: RouteSettings(arguments: {
                  "staffAccess": accounts[0]['access'],
                  "isAccountModified": true,
                  "loginAccountModified": true,
                })));
      } else if (staffAccount.isNotEmpty) {
        widget.loginAccount(staffAccount[0]['_id'], staffAccount[0]['access']);
        setState(() {
          isLoading = false;
        });
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Dashboard(),
                settings: RouteSettings(arguments: {
                  "staffAccess": staffAccount[0]['access'],
                  "isAccountModified": true,
                  "loginAccountModified": true,
                })));
      } else {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => CreateOrganisation()));
      }
    } else {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text("Error while deleting Account"),
        autoCloseDuration: Duration(milliseconds: 3000),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateAccount(String account_id, String accountName) async {
    print("Update Account $account_id");
    setState(() {
      isLoading = true;
    });
    var updateBody = {
      "account_name": accountName,
      "account_type": organisationType
    };

    var response = await http.patch(
        Uri.parse(
            "${APIURL}/api/v3/account/updateAccount/$account_id"),
        body: json.encode(updateBody),
        headers: {"Content-Type": "application/json"});

    print(response.statusCode);
    if (response.statusCode == 200) {
      toastification.show(
          context: context,
          type: ToastificationType.success,
          autoCloseDuration: Duration(milliseconds: 1000),
          title: Text("Data Updated Successfully"));
      setState(() {
        isLoading = false;
      });
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Dashboard(),
              settings: RouteSettings(arguments: {
                "staffAccess": staffAccess,
                "loginAccountModified": true,
                "isAccountModified": true,
              })));
    } else {
      toastification.show(
          context: context,
          type: ToastificationType.error,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Failed to Update Data"));
      setState(() {
        isLoading = false;
      });
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Dashboard(),
                    settings: RouteSettings(
                        arguments: {"staffAccess": staffAccess})));
          },
        ),
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
                      label: Text('Organization Name'),
                      labelStyle: TextStyle(color: Colors.green.shade900),
                      floatingLabelBehavior: FloatingLabelBehavior.always,

                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
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
                    onChanged: (newValue) {
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
                      label:Text('Organization Type') ,
                      labelStyle: TextStyle(color: Colors.green.shade900),
                      floatingLabelBehavior: FloatingLabelBehavior.always,

                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
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
                          primary:
                              isLoading ? Colors.grey : Colors.green.shade900,
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
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  updateAccount(
                                      accountId, organisationName.text);
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
                          primary:
                              isLoading ? Colors.grey : Colors.red.shade900,
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
                        onPressed: isLoading
                            ? null
                            : () {
                                deleteAccount(accountId);
                              },
                      ),
                    ),
                  ),
                if (staffAccess == "high" ||
                    staffAccess == 'medium' ||
                    staffAccess == "")
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
                          padding: EdgeInsets.symmetric(
                              horizontal: 60, vertical: 12),
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
