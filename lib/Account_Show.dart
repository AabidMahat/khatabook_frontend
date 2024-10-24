import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/AddStaff.dart';
import 'package:khatabook_project/CreateAccount.dart';
import 'package:khatabook_project/CreateBusinessAccount.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/StaffLogin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AccountScreen extends StatefulWidget {
  final List accounts;
  final Map<String, bool> selectedAccounts;
  final Function(String accountId, String access) loginAccount;
  final String? userId;
  final String? userNum;
  final String?staffAccess;


  const AccountScreen({
    Key? key,
    required this.accounts,
    required this.selectedAccounts,
    required this.loginAccount,
    required this.userId,
    required this.userNum,
    required this.staffAccess,
  }) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int? studentCount;
  List accounts = [];
  List staffAccount = [];
  String? selectedAccountId;

  @override
  void initState() {
    super.initState();
    getUserIdFromSharedPreferences();
    fetchAccounts(widget.userId!);
  }

  void getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      studentCount = prefs.getInt('studentCount') ?? 0;
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
        setState(() {
          staffAccount = responseBody['data'].map((staff) {
            var account = staff['account_no'];
            account['access'] = staff['staff_access']; // Add access field to each account
            return account;
          }).toList();
        });
      } else {
        print("Failed to load accounts");
      }
    } catch (err) {
      print(err);
    }
  }
  Future<void> fetchAccounts(String user_id) async {
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
        await getAccountByStaff(widget.userNum!);
      }
    } catch (err) {
      print("Error fetching accounts: $err");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Account Show ${widget.userId}");
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Select Account",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          Container(
            height: 300.0, // Adjust height as needed
            child: ListView.builder(
              itemCount: widget.accounts.length,
              itemBuilder: (context, index) {
                String accountId = widget.accounts[index]['_id'];
                String accountName = widget.accounts[index]['account_name'];
                String accountAvatarUrl = widget.accounts[index]['avatar_url'] ?? '';
                String access = widget.accounts[index]['access'] ?? '';
                bool isActive = widget.selectedAccounts[accountId] ?? false;
                return GestureDetector(
                  onTap: () async {
                    setState(() {
                      widget.selectedAccounts.forEach((key, _) {
                        widget.selectedAccounts[key] = false;
                      });
                      widget.selectedAccounts[accountId] = true;
                      widget.loginAccount(accountId, access);
                    });

                    // Perform your login or any other action here

                    Navigator.of(context).pop(); // Close the bottom sheet after selection

                    // Save selected account ID to shared preferences
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setString('selectedAccountId', accountId);
                    // Save staffAccess if it's set
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: isActive
                          ? Border.all(color: Color(0xFF3F704D), width: 2.0)
                          : Border.all(color: Colors.transparent),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 3,
                          color: Color(0x35000000),
                          offset: Offset(
                            0.0,
                            1,
                          ),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF3F704D),
                        child: Text(
                          accountName[0],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            accountName,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                          ),
                          // Text(
                          //   "${studentCount} Students",
                          //   style: TextStyle(color: Colors.black, fontSize: 16),
                          // ),
                        ],
                      ),
                      trailing: Checkbox(
                        value: isActive,
                        onChanged: (bool? value) async {
                          setState(() {
                            widget.selectedAccounts.forEach((key, _) {
                              widget.selectedAccounts[key] = false;
                            });
                            widget.selectedAccounts[accountId] = value!;
                          });

                          // Perform your login or any other action here
                          widget.loginAccount(accountId, access);
                          Navigator.of(context).pop(); // Close the bottom sheet after selection

                          // Save selected account ID to shared preferences
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString('selectedAccountId', accountId);
                          await prefs.setBool('loginAccountModified', true);
                        },
                        shape: CircleBorder(),
                        visualDensity:
                            VisualDensity(horizontal: 0, vertical: -4),
                        activeColor: Color(0xFF3F704D),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        splashRadius: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFF3F704D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateOrganisation(),
                          settings: RouteSettings(
                              arguments: {"userId": widget.userId})),
                    );
                  },
                  child: Text(
                    "Create Khatabook",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
