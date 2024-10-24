import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/AllClasses.dart';

import 'package:khatabook_project/AllTeachers.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: ModifyClass(),
  ));
}

class ModifyClass extends StatefulWidget {
  const ModifyClass({super.key});

  @override
  State<ModifyClass> createState() => _ModifyClassState();
}

class _ModifyClassState extends State<ModifyClass> {
  var organisationName = TextEditingController();
  var staffName = TextEditingController();
  var class_ammount = TextEditingController();
  var _requiredAmount = TextEditingController();
  int? duration;
  String? organisationType;
  final _formKey = GlobalKey<FormState>();
  String? account_name;
  String? accountId;
  bool isActive = true;
  late String userId;
  late Map<String, dynamic> args;
  late String classId;
  late String className;
  bool isLoading = false;
  String? staffAccess;
  String? staffId;
  var staff;
  var allStaffs;
  String? _selectionDuration;

  @override
  void initState() {
    super.initState();
    getUserIdFromSharedPreferences();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null) {
        args = arguments as Map<String, dynamic>;
        print('Duration type: $args');
        classId = args['classId'];
        className = args['className'];
        staffId = args['staffId'];
        // Ensure duration is properly converted to int
        duration = int.tryParse(args['duration'].toString());

        // Initialize text fields with appropriate type conversion
        class_ammount.text = args['classAmount']?.toString() ?? '';
        _requiredAmount.text = args['requiredAmount']?.toString() ?? '';


        // Initialize _selectionDuration based on the passed duration value
        _selectionDuration = durationToLabel[duration] ?? _durationOptions.first;
        print(duration);
        print(_selectionDuration);
        setState(() {
          organisationName.text = className;
        });

        getStaff(staffId!);
      } else {
        // Handle case where arguments are not passed correctly
        print('Arguments not passed correctly');
      }
    });
  }

  final List<String> _durationOptions = [
    'Monthly',
    'Quarterly',
    'Half yearly',
    'Yearly'
  ];
  final Map<int, String> durationToLabel = {
    12: 'Monthly',
    4: 'Quarterly',
    2: 'Half yearly',
    1: 'Yearly'
  };

  void calculateRequiredAmount() {
    double amount = double.tryParse(class_ammount.text) ?? 0.0;
    int months = 1;

    switch (_selectionDuration) {
      case 'Monthly':
        months = 12;
        setState(() {
          duration = 12;
        });
        break;
      case 'Quarterly':
        months = 4;
        setState(() {
          duration = 4;
        });
        break;
      case 'Half yearly':
        months = 2;
        setState(() {
          duration = 2;
        });
        break;
      case 'Yearly':
        months = 1;
        setState(() {
          duration = 1;
        });
        break;
    }

    double requiredAmount = amount / months;
    int roundedRequiredAmount = requiredAmount.ceil();
    setState(() {
      _requiredAmount.text = roundedRequiredAmount.toString();
    });
  }

  void getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
      staffAccess = prefs.getString("setAccess");
      accountId = prefs.getString("selectedAccountId");
    });
    getAllStaff(accountId!);
  }

  void getStaff(String staffId) async {
    final String url =
        "${APIURL}/api/v3/staff/getStaff/$staffId";

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        staff = data['data'];
        staffName.text = staff['staff_name'];
      });
    } else {
      print("Failed to load Staff");
    }
  }

  void getAllStaff(String accountId) async {
    final String url =
        "${APIURL}/api/v3/staff/getAllStaff/$accountId";

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      setState(() {
        allStaffs = data['data'];
      });
      print(allStaffs);
    } else {
      print("Failed to load Staff");
    }
  }

  void updateClass(String classId, String newClassName) async {
    setState(() {
      isLoading = true;
    });
    final String url =
        "${APIURL}/api/v3/class/updateClass/$classId";
    var updateBody = {
      "class_name": newClassName,
      "class_ammount": class_ammount.text,
      "amount_by_time": _requiredAmount.text,
      "duration": duration,
      "teacherId": staffId,
      "teacher_name": staffName.text,
    };

    var response = await http.patch(Uri.parse(url),
        body: json.encode(updateBody),
        headers: {"Content-Type": "application/json"});

    print("Class ${response.body}");
    if (response.statusCode == 200) {
      toastification.show(
          context: context,
          type: ToastificationType.success,
          autoCloseDuration: Duration(milliseconds: 1000),
          title: Text("Data Updated Successfully"),
        showProgressBar: false
      );

      setState(() {
        isLoading = false;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("requestedAmount", _requiredAmount.text);

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ClassesWidget()));
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

  void deleteClass(String classId) async {
    setState(() {
      isLoading = true;
    });

    final String url =
        "${APIURL}/api/v3/class/deleteClass/$classId";
    var response = await http.delete(Uri.parse(url));
    print(response.body);
    if (response.statusCode == 204) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ClassesWidget()));
    } else {
      toastification.show(
          context: context,
          type: ToastificationType.error,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Failed to Update Data"));
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
          "Edit Class",
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
                context, MaterialPageRoute(builder: (context) => ClassesWidget()));
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
                  padding: const EdgeInsets.symmetric( vertical: 6 ,horizontal: 5),
                  child: TextFormField(
                    controller: organisationName,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      label: Text("Class"),
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
                  child: DropdownButtonFormField<String>(
                    value: staffId,
                    onChanged: (newValue) {
                      setState(() {
                        staffId = newValue;
                        getStaff(staffId!);
                      });
                    },
                    items: allStaffs?.map<DropdownMenuItem<String>>((staff) {
                      return DropdownMenuItem<String>(
                        value: staff['_id'],
                        child: Text(staff['staff_name']),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      label: Text("Employee Name"),
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
                        return 'Please select a Employee';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric( vertical: 6 ,horizontal: 5),
                  child: TextFormField(
                    controller: class_ammount,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      label: Text("Amount"),
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
                    onChanged: (value) {
                      calculateRequiredAmount();
                    },
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Amount';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric( vertical: 6 ,horizontal: 5),
                  child: DropdownButtonFormField<String>(
                    value: _selectionDuration,
                    decoration: InputDecoration(
                      label: Text("Duration"),
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
                    items: _durationOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectionDuration = newValue;
                        calculateRequiredAmount();
                        // Handle duration change logic here if needed
                      });
                    },
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric( vertical: 6 ,horizontal: 5),
                  child: TextFormField(
                    controller: _requiredAmount,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      label: Text("Required Amount"),
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
                        return 'Please fill Required Amount';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.edit),
                      label: Text("Update"),
                      style: ElevatedButton.styleFrom(
                        primary:isLoading? Colors.grey: Colors.green.shade900,
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
                          updateClass(classId, organisationName.text);
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
                        primary:isLoading?Colors.grey: Colors.red.shade900,
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
                        deleteClass(classId);
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
