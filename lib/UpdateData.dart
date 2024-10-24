import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/phoneBook.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'package:toastification/toastification.dart';

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MaterialApp(
    home: UpdateSetting(),
  ));
}

class UpdateSetting extends StatefulWidget {
  const UpdateSetting({super.key});

  @override
  State<UpdateSetting> createState() => _UpdateSettingState();
}

class _UpdateSettingState extends State<UpdateSetting> {
  File? _image;
  var name = TextEditingController();
  var phone = TextEditingController();
  var address = TextEditingController();
  late String selectedClass;
  String? staffAccess;
  String? accountId;
  late Map<String, dynamic> args;
  bool hasShownClassToast = false;
  List<ClassData> allClass = [];
  late String studentId;
  String? publicUrl;
  Student? student;
  bool isLoading = false;
  bool isUpdating = false;

  final supabaseClient = SupabaseClient(
    'https://qlbruwvurmckjguvvjmp.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYnJ1d3Z1cm1ja2pndXZ2am1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTc0Nzg5ODMsImV4cCI6MjAzMzA1NDk4M30.AJFS6eia23B5bAZsuSCB8KUsbr6uTVVrVsJARVCN-to',
  );

  @override
  void initState() {
    super.initState();
    getStaffAccess();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
      studentId = args['studentId'];
      student = args['student'];

      if (student != null) {
        name.text = student!.studentName;
        phone.text = student!.phone;
        // Set address with default value if empty
        address.text =
            student!.address.isNotEmpty ? student!.address : "";
        selectedClass = student!.classes;

        if (student!.imagePath != null) {
          publicUrl = student!.imagePath;
        }
      }
    });
  }

  void getStaffAccess() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      staffAccess = prefs.getString("setAccess");
      accountId = prefs.getString("selectedAccountId");
    });
    getAllClasses(accountId!);
  }

  void _pickImage() async {
    final pickFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickFile != null) {
      setState(() {
        _image = File(pickFile.path);
      });
      await uploadImageToSupabase(_image!);
    }
  }

  Future<void> uploadImageToSupabase(File imageFile) async {
    setState(() {
      isLoading = true;
    });
    final String formattedDate = DateFormat('yyyyMMdd').format(DateTime.now());
    final String randomString = Uuid().v4().split('-').first;
    final String fileName =
        '${student!.studentName}_$formattedDate$randomString.jpg';

    await supabaseClient.storage
        .from('khatabook')
        .upload('public/$fileName', imageFile);

    final url = supabaseClient.storage
        .from('khatabook')
        .getPublicUrl('public/$fileName');

    print(url);

    setState(() {
      publicUrl = url;
    });

    Future.delayed(Duration(milliseconds: 2000), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  void _updateData() async {
    setState(() {
      isUpdating = true;
    });
    print("Update Data $publicUrl");
    print(selectedClass);
    final String url =
        "${APIURL}/api/v3/student/updateme/$studentId";
    // final String url = "http://10.0.2.2:3500/api/v3/student/updateme/$studentId";
    var updateBody = {
      "name": name.text,
      "phone": phone.text,
      "address": address.text,
      "classes": selectedClass,
      "imagePath": publicUrl.toString(),
    };
    var response = await http.patch(Uri.parse(url),
        body: json.encode(updateBody),
        headers: {"Content-Type": "application/json"});

    if (response.statusCode == 200) {
      setState(() {
        isUpdating = false;
      });
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: Text("Student Profile Updated"),
        icon: Icon(Icons.check_circle),
        autoCloseDuration: Duration(milliseconds: 2000),
        showProgressBar: false
      );
      // Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(
      //         builder: (context) => Dashboard(),
      //         settings:
      //             RouteSettings(arguments: {"staffAccess": staffAccess})));
    } else {
      setState(() {
        isUpdating = false;
      });
      var errorMessage =
          json.decode(response.body)['message'] ?? 'LogIn failed';
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(errorMessage),
        icon: Icon(Icons.error),
        autoCloseDuration: Duration(milliseconds: 3000),
      );
    }
  }

  void getAllClasses(String accountId) async {
    final String url =
        "${APIURL}/api/v3/class/getclasses/account_no=$accountId";

    try {
      var response = await http.get(Uri.parse(url));
      print("AccountId $accountId");
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        setState(() {
          allClass = List<ClassData>.from(
              data['data'].map((values) => ClassData.fromJson(values)));
        });

        print(allClass);
      } else {
        print("Failed to fetch classes. Status code: ${response.statusCode}");
      }
    } catch (err) {
      print("Error fetching classes: $err");
    }
  }

  void deleteStudent() async {
    setState(() {
      isUpdating = true;
    });
    final String url =
        "${APIURL}/api/v3/student/deleteStudent/$studentId";

    var response = await http.delete(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        isUpdating = false;
      });
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Dashboard(),
              settings:
                  RouteSettings(arguments: {"staffAccess": staffAccess})));
    } else {
      toastification.show(
          context: context,
          type: ToastificationType.error,
          autoCloseDuration: Duration(milliseconds: 3000),
          title: Text("Error while Deleting"));
      setState(() {
        isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Dashboard(),
              settings: RouteSettings(arguments: {
                "staffAccess": staffAccess,
              })),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Update Settings",
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: Color(0xFF3F704D),
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Color(0xFF3F704D),
                  child: ClipOval(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: _image != null
                          ? Image.file(
                              _image!,
                              fit: BoxFit.cover,
                            )
                          : (publicUrl!
                                  .contains(student!.studentName.split(" ")[0])
                              ? Image.network(
                                  publicUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 50,
                                )),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              buildTextField(
                label: "Enter Name",
                icon: FontAwesomeIcons.user,
                controller: name,
              ),
              SizedBox(
                height: 3,
              ),
              buildTextField(
                label: "Enter Phone Number",
                icon: FontAwesomeIcons.phone,
                prefixIcon: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 13.0, horizontal: 10),
                  child: Text(
                    '+91',
                    style: TextStyle(
                        color: Colors.green.shade900,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                suffixIcon: IconButton(
                  onPressed: () async {
                    final phoneNumber = await Navigator.push(context,
                        MaterialPageRoute(builder: (context) => PhoneBook()));
                    if (phoneNumber != null) {
                      setState(() {
                        phone.text = phoneNumber;
                      });
                    }
                  },
                  icon: Icon(
                    Icons.contact_page_rounded,
                    color: Colors.green.shade900,
                  ),
                ),
                keyboardType: TextInputType.number,
                controller: phone,
              ),
              SizedBox(
                height: 3,
              ),
              buildClassDropdown(),
              SizedBox(
                height: 5,
              ),
              buildTextField(
                label: "Enter Address",
                icon: FontAwesomeIcons.addressCard,
                controller: address,
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  if (staffAccess == "high" ||
                      staffAccess == "medium" ||
                      staffAccess == "")
                    Container(
                      width: MediaQuery.of(context).size.width,
                      child: TextButton(
                        onPressed: (isLoading || isUpdating) ? null : _updateData,
                        style: TextButton.styleFrom(
                          padding:
                              EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                          backgroundColor:
                          (isLoading|| isUpdating) ?Colors.grey: Color(0xFF3F704D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              "Update",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 16,
                  ),
                  if (staffAccess == "high" || staffAccess == "")
                    Container(
                      width: MediaQuery.of(context).size.width,
                      child: TextButton(
                        onPressed: (isLoading|| isUpdating) ? null : deleteStudent,
                        style: TextButton.styleFrom(
                          padding:
                              EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                          backgroundColor:(isLoading|| isUpdating)?Colors.grey: Colors.red.shade800,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              "Delete",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildClassDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedClass,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        label: Text("Class"),
        labelStyle: TextStyle(color: Colors.green.shade900),
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
      items: allClass.map((classData) {
        print(classData.className);
        return DropdownMenuItem<String>(
          value: classData.className,
          child: Text(classData.className),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedClass = newValue!;
        });
      },
      style: TextStyle(
        color: Colors.green.shade900,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget buildTextField(
      {required String label,
      required IconData icon,
      Widget? prefixIcon,
      Widget? suffixIcon,
      TextInputType keyboardType = TextInputType.text,
      required TextEditingController controller}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          label: Text(label),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(color: Colors.green.shade900),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
      ),
    );
  }
}
