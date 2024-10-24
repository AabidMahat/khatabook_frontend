// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:freelancing/StudentsScreen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class Accounts extends StatefulWidget {
//   const Accounts({Key? key, required String userId}) : super(key: key);
//
//   @override
//   State<Accounts> createState() => _AccountsState();
// }
//
// class _AccountsState extends State<Accounts> {
//   String appBarTitle = "My Business";
//   List accounts = [];
//   Map<String, bool> selectedAccounts = {};
//   bool isLoading = true;
//   String? selectedAccountId;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchAccounts();
//   }
//
//
//
//   void fetchAccounts() async {
//     try {
//       var url = "https://aabid.up.railway.app/api/v3/account/getAdminAccounts";
//       var response = await http.get(Uri.parse(url));
//       print(response.body);
//       if (response.statusCode == 200) {
//         var responseBody = json.decode(response.body);
//         setState(() {
//           accounts = responseBody['data']['account'];
//           selectedAccounts = {
//             for (var account in accounts) account['_id']: false
//           };
//           isLoading = false;
//         });
//
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         selectedAccountId = prefs.getString('selectedAccountId');
//
//         if (accounts.isNotEmpty) {
//           if (selectedAccountId != null) {
//             selectedAccounts[selectedAccountId!] = true;
//           } else {
//             selectedAccounts[accounts[0]['_id']] = true;
//           }
//         }
//       } else {
//         print("Failed to load accounts");
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (err) {
//       print("Error fetching accounts: $err");
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//
//
//   void loginAccount(String accountId, String accountName) async {
//     try {
//       var url = "https://aabid.up.railway.app/api/v3/account/getAccount/account_is=$accountId";
//       print("Making request to: $url");
//       var response = await http.get(Uri.parse(url));
//
//       if (response.statusCode == 200) {
//         var responseBody = json.decode(response.body);
//
//         if (responseBody['data'] != null &&
//             responseBody['data']['account'] != null) {
//           var accountName =
//           responseBody['data']['account']['account_name'];
//
//           setState(() {
//             appBarTitle = accountName;
//           });
//
//           SharedPreferences prefs = await SharedPreferences.getInstance();
//           await prefs.setString('selectedAccountId', accountId);
//
//           print("Logged in with account: $accountName");
//           _showSnackBar("Logged in with account: $accountName");
//
//           // Navigate to Dashboard with arguments
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => StudentsScreen(accountId: accountId, accountName: accountName),
//             ),
//           );
//         } else {
//           print("Unexpected response structure");
//         }
//       } else {
//         print("Failed to load account");
//         print("Response status: ${response.statusCode}");
//         print("Response body: ${response.body}");
//       }
//     } catch (err) {
//       print("Error logging in account: $err");
//     }
//   }
//
//   void _showSnackBar(String message) {
//     final snackBar = SnackBar(content: Text(message));
//     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(appBarTitle,style: TextStyle(
//           color: Colors.white
//         ),),
//         backgroundColor: Colors.blue[900],
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: ListView.builder(
//           itemCount: accounts.length,
//           itemBuilder: (context, index) {
//             var account = accounts[index];
//             return Card(
//               margin: EdgeInsets.symmetric(vertical: 8),
//               child: ListTile(
//                 title: Text(
//                   account['account_name'],
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                 ),
//                 selected: selectedAccounts[account['_id']] ?? false,
//                 onTap: () {
//                   setState(() {
//                     selectedAccountId = account['_id'];
//                     selectedAccounts.updateAll((key, value) => false);
//                     selectedAccounts[account['_id']] = true;
//                   });
//                   loginAccount(account['_id'], account['account_name']);
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
