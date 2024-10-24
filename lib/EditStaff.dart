import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/AllTeachers.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/phoneBook.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: EditStaff(),
  ));
}

class EditStaff extends StatefulWidget {
  const EditStaff({super.key});

  @override
  State<EditStaff> createState() => _EditStaffState();
}

class _EditStaffState extends State<EditStaff> {
  var organisationName = TextEditingController();
  var organisationNumber = TextEditingController();
  String? organisationType;
  final _formKey = GlobalKey<FormState>();
  String? account_name;
  bool isActive = true;
  late String userId;
  late Map<String, dynamic> args;
  late String staffId;
  late String staffName;
  late String staffNumber;
  late String staffAccess;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getUserIdFromSharedPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null) {
        args = arguments as Map<String, dynamic>;
        staffId = args['staffId'];
        staffName = args['staffName'];
        staffNumber = args['staffNumber'];
        staffAccess = args['staffAccess'];
        organisationName.text = staffName;
        organisationNumber.text = staffNumber;
        organisationType = accessMap.entries
            .firstWhere((entry) => entry.value == staffAccess,
                orElse: () => const MapEntry('View and Send Alert', 'low'))
            .key;
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
    });
  }

  final Map<String, String> accessMap = {
    'View and Send Alert': 'low',
    'View and Edit': 'medium',
    'Full Access': 'high',
  };

  void updateStaff(String staffId, String staffName, String access) async {
    setState(() {
      isLoading = true;
    });
    final String url =
        "${APIURL}/api/v3/staff/updateStaff/$staffId";

    var updateBody = {
      "staff_name": staffName,
      "staff_access": access,
      'staff_number': staffNumber,
    };

    var response = await http.patch(Uri.parse(url),
        body: json.encode(updateBody),
        headers: {"Content-Type": "application/json"});

    print("Staff ${response.body}");
    if (response.statusCode == 200) {
      setState(() {
        isLoading = false;
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('isStaffListModified', true);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => TeacherWidget()));
    } else {
      setState(() {
        isLoading = false;
      });
      toastification.show(
          context: context,
          type: ToastificationType.error,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Failed to Update Data"));
    }
  }

  void deleteStaff(String staffId) async {
    setState(() {
      isLoading = true;
    });

    final String url =
        "${APIURL}/api/v3/staff/deleteStaff/$staffId";

    var response = await http.delete(Uri.parse(url));
    print(response.body);
    if (response.statusCode == 200) {
      setState(() {
        isLoading = false;
      });
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => TeacherWidget()));
    } else {
      toastification.show(
          context: context,
          type: ToastificationType.error,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Failed to Delete Data"));
    }

    setState(() {
      isLoading = false;
    });
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
          "Edit Employee",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green.shade900,
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
                      label: Text("Name"),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelStyle: TextStyle(color: Colors.green.shade900),
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
                      color: Colors.green.shade900,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an Staff name';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric( vertical: 6 ,horizontal: 5),
                  child: TextFormField(
                    controller: organisationNumber,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          '+91',
                          style: TextStyle(
                              color: Colors.green.shade900, fontSize: 16),
                        ),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () async {
                          final phoneNumber = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PhoneBook()));
                          if (phoneNumber != null) {
                            setState(() {
                              organisationNumber.text = phoneNumber;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.contact_page_rounded,
                          color: Colors.green.shade900,
                        ),
                      ),
                      label: Text("Number"),
                      floatingLabelBehavior: FloatingLabelBehavior.always,

                      labelStyle: TextStyle(color: Colors.green.shade900),
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
                      color: Colors.green.shade900,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an Staff number';
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
                        staffAccess = accessMap[newValue]!;
                      });
                    },
                    items: accessMap.keys
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      label: Text("Type"),
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
                      color: Colors.green.shade900,
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 60, vertical: 12),
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                updateStaff(staffId, organisationName.text,
                                    staffAccess);
                              }
                            },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.delete),
                      label: Text("Delete"),
                      style: ElevatedButton.styleFrom(
                        primary: isLoading ? Colors.grey : Colors.red.shade900,
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
                      onPressed: isLoading
                          ? null
                          : () {
                              deleteStaff(staffId);
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
