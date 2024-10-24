import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/phoneBook.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'Dashboard.dart';

void main() {
  runApp(MaterialApp(
    home: AddStudent(),
  ));
}

class AddStudent extends StatefulWidget {
  const AddStudent({super.key});

  @override
  _AddStudentState createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClass;
  int ? selectedAmmount;
  String ? _classId;
  String? accountId;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  bool isloading = true;
  bool hasShownClassToast = false;
  List<ClassData> classes = [];
  var otherclasses = [];
  String? staffAccess;
  bool createStudentBool = false;

  @override
  void initState() {
    super.initState();
    getStaffAccess();
  }

  void getStaffAccess() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      staffAccess = prefs.getString('setAccess') ?? "";
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve accountId after the context is fully available
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    accountId = args?['account_id'] as String?;
    if (accountId != null) {
      getAllClasses();
    }
  }

  void getAllClasses() async {
    final String url =
        "${APIURL}/api/v3/class/getclasses/account_no=$accountId";

    try {
      var response = await http.get(Uri.parse(url));
      print("Student Classes response: ${response.statusCode}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        classes = List<ClassData>.from(
            data['data'].map((values) => ClassData.fromJson(values)));
        setState(() {
          otherclasses = data['data'];
        });
        if (classes.isEmpty && !hasShownClassToast) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: Text("Please Add Class"),
            autoCloseDuration: Duration(milliseconds: 5000),
          );
          hasShownClassToast = true;
        }
      } else {
        print("Failed to fetch classes. Status code: ${response.statusCode}");
      }

      setState(() {
        isloading = false; // Update loading state
      });
    } catch (err) {
      print("Error fetching classes: $err");
      setState(() {
        isloading = false; // Update loading state
      });
    }
  }

  Future<void> createStudent() async {

    setState(() {
      createStudentBool = true;
    });

    var studentData = {
      "account_id": accountId,
      "classes": _selectedClass,
      "classId":_classId,
      "student_name": _name.text,
      "phone": _phone.text,
      "total_fees": selectedAmmount??0,
      "paid_fees": 0,
      "image_path": ""
    };

    final String url =
        "${APIURL}/api/v3/student/createStudent";
    var response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(studentData),
    );

    if (response.statusCode == 200) {
      // Handle successful student creation
      setState(() {
        createStudentBool = false;
      });
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Dashboard(),
              settings: RouteSettings(arguments: {
                "accountId": accountId,
                "staffAccess": staffAccess
              })));
    } else {
      // Handle error
      setState(() {
        createStudentBool = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create student')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(staffAccess);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: Text(
          "Add Customer",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          padding: const EdgeInsets.symmetric(vertical: 15,horizontal: 5),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTextField(
                  controller: _name,
                  labelText: 'Name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a student name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                _buildPhoneNumberField(),
                SizedBox(height: 10),
                _buildDropdownField(),
                SizedBox(height: 10),
                _buildBottomSheet(context)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String labelText,
      required IconData icon,
      String? Function(String?)? validator}) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        child: TextFormField(
          textInputAction: TextInputAction.next,
          controller: controller,
          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          decoration: InputDecoration(
            hintStyle: TextStyle(color: Colors.green.shade900),
            hintText: labelText,
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
          style: TextStyle(
              fontWeight: FontWeight.w500
          ),
        ));
  }

  Widget _buildPhoneNumberField() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        keyboardType: TextInputType.phone,
        controller: _phone,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '+91',
              style: TextStyle(color: Colors.green.shade900, fontSize: 16),
            ),
          ),

          suffixIcon: IconButton(
            onPressed: ()async {
              final phoneNumber = await Navigator.push(context, MaterialPageRoute(builder: (context)=>PhoneBook())
              );
              if(phoneNumber!=null){
                setState(() {
                  _phone.text = phoneNumber;
                });
              }
            },
            icon: Icon(Icons.contact_page_rounded,color: Colors.green.shade900,),
          ),
          hintText: "Phone Number",
          hintStyle: TextStyle(color: Colors.green.shade900),
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
        style: TextStyle(
          fontWeight: FontWeight.w500
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a phone number';
          } else if (value.length != 10) {
            return 'Enter a valid 10-digit phone number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Select Class",
          hintStyle: TextStyle(color: Colors.green.shade900),
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
        items: classes.map((ClassData classData) {
          return DropdownMenuItem<String>(
            value: classData.className,
            child: Text(classData.className,style: TextStyle(color: Colors.green.shade900),),
            onTap: (){
              setState(() {
                selectedAmmount = classData.classAmount;
                _classId = classData.id;
              });
            },
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedClass = newValue;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a class';
          }
          return null;
        },
        style: TextStyle(
            fontWeight: FontWeight.w500
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(10),
      height: 60,
      decoration: BoxDecoration(
        color: (classes.isEmpty || staffAccess == 'low')
            ? Colors.grey
            : Colors.green[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: (classes.isEmpty || staffAccess == 'low'||createStudentBool)
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  createStudent();
                }
              },
        child: Text(
          "Add Customer",
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
