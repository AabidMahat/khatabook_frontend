import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/AllClassCopy.dart';
import 'package:khatabook_project/AllClasses.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'Dashboard.dart';
import 'Database.dart';

void main() {
  runApp(addclass());
}

class addclass extends StatefulWidget {
  const addclass({super.key});

  @override
  _addclassState createState() => _addclassState();
}

class _addclassState extends State<addclass> {
  final TextEditingController _name = TextEditingController();
  var class_ammount = TextEditingController();
  var accountName = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedAccount;
  String? _selectedTeacher;
  String? _selectionDuration;
  int? duration;
  var _requiredAmount = TextEditingController();
  String? staffAccess;
  var accounts;
  List<TeacherData> teachers = [];
  List<Staff> staffs = [];
  bool isLoading = true;
  late String userId;
  String? accountId;
  bool isSubmit = false;
  bool createClassBool = false;

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
      accountId = prefs.getString('selectedAccountId') ?? '';
    });
    print("Dashboard Account Id $accountId");
    fetchAccounts(accountId!);
  }

  final List<String> _durationOptions = [
    'Monthly',
    'Quarterly',
    'Half yearly',
    'Yearly'
  ];

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

  Future<void> fetchAccounts(String accountId) async {
    try {
      var url =
          "${APIURL}/api/v3/account/getAccount/account_no=$accountId";
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        print(
            "Response Body: ${responseBody['data']['account']}"); // Debug line
        setState(() {
          accounts = responseBody['data']['account'];
          if (accounts.isNotEmpty) {
            _selectedAccount = accounts['_id'];

            fetchTeachers(_selectedAccount!);
            accountName.text = accounts['account_name'];
          }
        });
        print("Accounts fetched successfully: $accounts"); // Debug line
      } else {
        print("Failed to load accounts: ${response.statusCode}");
      }
    } catch (err) {
      print("Error fetching accounts: $err");
    }
  }

  Future<void> fetchTeachers(String accountId) async {
    setState(() {
      isLoading = true;
    });

    try {
      var url =
          "${APIURL}/api/v3/staff/getAllStaff/$accountId";
      var response = await http.get(Uri.parse(url));
      print(response);
      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);

        var teacherList = responseBody['data'] as List;
        setState(() {
          staffs = teacherList
              .map((classJson) =>
                  Staff.fromJson(classJson as Map<String, dynamic>))
              .toList();
          isLoading = false;
        });
        print("Teachers fetched successfully: $staffs");

        if (staffs.isEmpty) {
          toastification.show(
            context: context,
            title: Text("No Teacher Found"),
            type: ToastificationType.error,
            autoCloseDuration: Duration(milliseconds: 5000),
          );
        }
      } else {
        print("Failed to load Teachers: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (err) {
      print("Error fetching teacher: $err");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> createClass() async {
    setState(() {
      createClassBool = true;
    });
    if (_formKey.currentState!.validate()) {
      Staff? selectedTeacher = staffs.firstWhere(
        (teacher) => teacher.id == _selectedTeacher,
        orElse: () => Staff(
            id: "",
            staffName: "",
            staffNumber: "",
            staffPassword: "staffPassword",
            staffAccess: "",
            accountId: ""),
      );

      setState(() {
        isSubmit = true;
      });

      var classData = {
        "class_name": _name.text,
        "class_ammount": class_ammount.text,
        "teacher_name": selectedTeacher?.staffName,
        "amount_by_time": _requiredAmount.text,
        "duration": duration,
        "account_no": accountId,
        "teacherId": selectedTeacher.id
      };

      final String url = "${APIURL}/api/v3/class/addClass";
      var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(classData),
      );

      if (response.statusCode == 200) {
        print(response.body);
        // Handle successful class creation
        setState(() {
          createClassBool = false;
        });
        print(_requiredAmount.text);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString("requestedAmount", _requiredAmount.text);
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => ClassesWidget()));
      } else {
        // Handle error
        setState(() {
          createClassBool = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create class')),
        );
        setState(() {
          isSubmit = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: Text(
          "Add Class",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context,
                MaterialPageRoute(builder: (context) => ClassesWidget()));
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Container(
                    width: MediaQuery.of(context).size.width*0.36,
                    child: Text("Organization :",
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        )),
                  ),
                  Expanded(
                    child: _buildAccountDropdown(),
                  ),
                ]),
                SizedBox(height: 10),
                _buildTextField(
                  controller: _name,
                  labelText: 'Class name',
                  keyborad: TextInputType.text,
                  icon: Icons.verified_user_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a class name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                _buildTeacherDropdown(),
                SizedBox(height: 16),
                _buildTextField(
                  controller: class_ammount,
                  labelText: 'Amount',
                  keyborad: TextInputType.number,
                  icon: Icons.verified_user_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a class name';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    calculateRequiredAmount();
                  },
                ),
                SizedBox(height: 16),
                _buildDurationDropdown(),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _requiredAmount,
                  labelText: 'Required Amount',
                  keyborad: TextInputType.number,
                  icon: Icons.verified_user_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a class name';
                    }
                    return null;
                  },
                  readOnly: true,
                ),
                SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required TextInputType keyborad,
    bool? readOnly,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyborad,
      readOnly: readOnly ?? false,
      decoration: InputDecoration(
        hintText: labelText,
        hintStyle: TextStyle(
          color: Colors.green.shade900,
        ),
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
      ),
      validator: validator,
      style: TextStyle(
        color: Colors.green.shade900,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectionDuration,
      decoration: InputDecoration(
        hintText: "Duration",
        hintStyle: TextStyle(
          color: Colors.green.shade900,
        ),
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
      ),
      items: _durationOptions.map<DropdownMenuItem<String>>((String value) {
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
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildAccountDropdown() {
    return TextFormField(
      readOnly: true,
      controller: accountName,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.transparent,
      ),
      style: TextStyle(
        color: Colors.green.shade900,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTeacherDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTeacher,
      decoration: InputDecoration(
        hintText: "Select Teacher",
        hintStyle: TextStyle(
          color: Colors.green.shade900,
        ),
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
      ),
      items: staffs.map<DropdownMenuItem<String>>((teacher) {
        return DropdownMenuItem<String>(
          value: teacher.id,
          child: Text(teacher.staffName),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedTeacher = newValue;
        });
      },
      style: TextStyle(
        color: Colors.green.shade900,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isSubmit ? null : createClass,
        style: ElevatedButton.styleFrom(
          primary: Colors.green[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSubmit
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                'Add Class',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }
}
