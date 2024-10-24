import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'Student.dart';
import 'ClassData.dart';

// Function to get user ID from shared preferences
Future<Map<String, String>> getUserIdFromSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return {
    'userId': prefs.getString('userId') ?? '',
    'userNumber': prefs.getString('userNumber') ?? ''
  };
}

// Function to fetch accounts from the API
Future<List<dynamic>> fetchAccounts(String userId, String userNumber) async {
  List<dynamic> accounts = [];
  try {
    var url = "https://aabid.up.railway.app/api/v3/account/getAccounts/$userId";
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      accounts = responseBody['data']['account'].map((account) {
        account['access'] = "";
        return account;
      }).toList();
    }

    var staffAccounts = await getAccountByStaff(userNumber);
    accounts.addAll(staffAccounts);

  } catch (err) {
    print("Error fetching accounts: $err");
  }
  return accounts;
}

// Function to fetch classes from the API
Future<List<ClassData>> fetchClasses(String accountId) async {
  List<ClassData> classes = [];
  try {
    var url = "https://aabid.up.railway.app/api/v3/class/getclasses/account_no=$accountId";
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      var classesList = responseBody['data'] as List;
      classes = classesList.map((classJson) => ClassData.fromJson(classJson as Map<String, dynamic>)).toList();
    }
  } catch (err) {
    print("Error fetching classes: $err");
  }
  return classes;
}

// Function to fetch students from the API
Future<List<Student>> getStudents(String accountId) async {
  List<Student> students = [];
  try {
    var response = await http.get(Uri.parse("https://aabid.up.railway.app/api/v3/student/getStudnet/accountId=$accountId"));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      students = List<Student>.from(data['data'].map((values) => Student.fromJson(values)));
    }
  } catch (err) {
    print("Error fetching students: $err");
  }
  return students;
}

// Function to get accounts assigned to staff
Future<List<dynamic>> getAccountByStaff(String userNum) async {
  List<dynamic> staffAccounts = [];
  try {
    var url = "https://aabid.up.railway.app/api/v3/staff/loginStaff";
    var updateData = {"staff_number": userNum};
    var response = await http.post(Uri.parse(url), body: json.encode(updateData), headers: {"Content-Type": "application/json"});
    if (response.statusCode == 201) {
      var responseBody = json.decode(response.body);
      staffAccounts = responseBody['data'].map((staff) {
        var account = staff['account_no'];
        account['access'] = staff['staff_access'];
        return account;
      }).toList();
    }
  } catch (err) {
    print("Error fetching accounts: $err");
  }
  return staffAccounts;
}

// Function to login to an account
Future<void> loginAccount(String accountId, String access, ValueNotifier<String?> appBarTitle, TextEditingController accountName) async {
  try {
    var url = "https://aabid.up.railway.app/api/v3/account/getAccount";
    var response = await http.get(Uri.parse("$url/account_is=$accountId"));

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedAccountId', accountId);
      await prefs.setString('accessByStaff', access);

      appBarTitle.value = responseBody['data']['account']['account_name'];
      accountName.text = responseBody['data']['account']['account_name'];
    }
  } catch (err) {
    print("Error logging in account: $err");
  }
}


Future<void> getAccountByStaff(String userNum) async {
  try {
    print('Staff Modified $isStaffListModified');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedStaffAccounts = prefs.getString('cachedStaffAccounts_$userNum');

    // if (cachedStaffAccounts != null && !isStaffListModified) {
    // If cached data exists, use it
    if(isStaffListModified){
      print("Using cached staff accounts");
      var responseBody = json.decode(cachedStaffAccounts!);
      setState(() {
        staffAccount = List<Map<String, dynamic>>.from(responseBody
            .where((staff) => staff['account_no']['isActive'] == true)
            .map((staff) {
          var account = Map<String, dynamic>.from(staff['account_no']);
          account['access'] =
          staff['staff_access']; // Add access field to each account
          return account;
        }));
      });
      print(staffAccount);
    } else {
      // If no cached data, fetch from server
      var url = "${APIURL}/api/v3/staff/loginStaff";
      var updateData = {"staff_number": userNum};
      var response = await http.post(Uri.parse(url),
          body: json.encode(updateData),
          headers: {"Content-Type": "application/json"});

      if (response.statusCode == 201) {
        var responseBody = json.decode(response.body);
        print("Staff Account ${responseBody['data']}");
        prefs.setString('cachedStaffAccounts_$userNum',
            json.encode(responseBody['data']));
        setState(() {
          staffAccount = List<Map<String, dynamic>>.from(
              responseBody['data'].where((staff) => staff['account_no']['isActive'] == true).map((staff) {
                var account = Map<String, dynamic>.from(staff['account_no']);
                account['access'] = staff['staff_access']; // Add access field to each account
                return account;
              }));
        });
        print(staffAccount);
      } else {
        print("Failed to load Staff accounts");
      }
    }
  } catch (err) {
    print("Error fetching staff accounts: $err");
  }
}