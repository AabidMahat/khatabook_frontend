import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/Database.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';
import 'package:toastification/toastification.dart';

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MaterialApp(
    home: UpdateUserData(),
  ));
}

class UpdateUserData extends StatefulWidget {
  const UpdateUserData({super.key});

  @override
  State<UpdateUserData> createState() => _UpdateUserDataState();
}

class _UpdateUserDataState extends State<UpdateUserData> {
  File? _image;
  var name = TextEditingController();
  var phone = TextEditingController();
  var address = TextEditingController();
  var classes = TextEditingController();
  var confirmPassword = TextEditingController();
  bool loadImage = false;
  late String userId;
  String? staffAccess;
  late Map<String, dynamic> args;
  late String studentId;
  String? publicUrl;
  Student? student;
  UserData? user;
  bool isUserLoading = true;
  bool isLoading = false;

  final supabaseClient = SupabaseClient(
    'https://qlbruwvurmckjguvvjmp.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYnJ1d3Z1cm1ja2pndXZ2am1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTc0Nzg5ODMsImV4cCI6MjAzMzA1NDk4M30.AJFS6eia23B5bAZsuSCB8KUsbr6uTVVrVsJARVCN-to',
  );

  @override
  void initState() {
    super.initState();

    getStaffAccess();
  }

  void getStaffAccess() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      userId = pref.getString('userId') ?? '';
      staffAccess = pref.getString("setAccess");
    });
    getUser(userId);
  }

  void fillData() {
    if (user != null) {
      setState(() {
        name.text = user!.name;
        phone.text = user!.phone;
        classes.text = user!.email;
        address.text = user!.password;

        if (user!.imagePath.isNotEmpty) {
          publicUrl = user!.imagePath;
        }
      });
    }
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
    try {
      setState(() {
        loadImage = true;
      });

      final String formattedDate =
          DateFormat('yyyyMMdd').format(DateTime.now());
      final String randomString = Uuid().v4().split('-').first;
      final String fileName = '${user!.name}_$formattedDate$randomString.jpg';

      print("Filename $fileName");

      await supabaseClient.storage
          .from('khatabook')
          .upload('user/$fileName', imageFile);

      final url = await supabaseClient.storage
          .from('khatabook')
          .getPublicUrl('user/$fileName');

      setState(() {
        publicUrl = url;
      });

      Future.delayed(Duration(milliseconds: 2000), () {
        setState(() {
          loadImage = false;
        });
      });
    } catch (err) {
      print(err);
    }
  }

  void getUser(String userId) async {
    print("UserId $userId");
    final url = "${APIURL}/api/v3/user/getUser/${userId}";
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      print("Response Body for user: $responseBody");
      user = UserData.fromJson(responseBody['data']);

      setState(() {
        isUserLoading = false;
      });
      fillData();
    } else {
      print("Failed to load user: ${response.statusCode}");
      setState(() {
        isUserLoading = false;
      });
    }
  }

  void _updateData(String userId, {bool isPasswordUpdate = false}) async {

    if (isPasswordUpdate) if (address.text.length<=8) {
      toastification.show(
        context: context,
        title: Text("Password must be atleast 8 character long"),
        autoCloseDuration: Duration(milliseconds: 3000),
        type: ToastificationType.error,
      );
      return;
    }

    if (isPasswordUpdate) if (address.text != confirmPassword.text) {
      toastification.show(
        context: context,
        title: Text("Passwords do not match"),
        autoCloseDuration: Duration(milliseconds: 3000),
        type: ToastificationType.error,
      );
      return;
    }
    setState(() {
      isLoading = true;
    });
    print("Update Data $publicUrl");
    final String url =
        "${APIURL}/api/v3/user/updateUser/$userId";

    Map<String, dynamic> updateBody = {};
    if (isPasswordUpdate) {
      updateBody = {
        "password": address.text,
        "confirmPassword": confirmPassword.text,
      };
    } else {
      updateBody["name"] = name.text;
      updateBody["phone"] = phone.text;
      updateBody["email"] = classes.text;
      updateBody["imagePath"] = publicUrl;
    }

    var response = await http.patch(Uri.parse(url),
        body: json.encode(updateBody),
        headers: {"Content-Type": "application/json"});

    if (response.statusCode == 200) {
      toastification.show(
        context: context,
        title: Text("Data updated Successfully"),
        autoCloseDuration: Duration(milliseconds: 3000),
        showProgressBar: false,
        type: ToastificationType.success,
      );

      SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setBool("isUserModified", true);
      setState(() {
        isLoading = false;
      });
    } else {
      var errorMessage =
          json.decode(response.body)['message'] ?? 'LogIn failed';
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(errorMessage),
        icon: Icon(Icons.error),
        autoCloseDuration: Duration(milliseconds: 3000),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
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
                        : (publicUrl != null &&
                                user != null &&
                                publicUrl!.contains(user!.name.split(" ")[0])
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
            buildTextField(
              label: "Phone Number",
              icon: FontAwesomeIcons.phone,
              keyboardType: TextInputType.number,
              controller: phone,
            ),
            buildTextField(
              label: "Email",
              icon: Icons.mail,
              controller: classes,

            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: (loadImage || isLoading)
                  ?null: () {
                      _updateData(userId);
                    },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                primary:
                    (loadImage || isLoading) ? Colors.grey : Color(0xFF3F704D),
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
                    "Update Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
            ),
            buildTextField(
              label: "Enter password",
              icon: FontAwesomeIcons.lock,
              controller: address,
              obscureText:true,
            ),
            buildTextField(
              label: "Enter Confirm Password",
              icon: FontAwesomeIcons.lock,
              controller: confirmPassword,
              obscureText:true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: (loadImage || isLoading)
                  ? null
                  : () {
                      _updateData(userId, isPasswordUpdate: true);
                    },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                primary:
                    (loadImage || isLoading) ? Colors.grey : Color(0xFF3F704D),
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
                    "Update Password",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(
      {required String label,
      required IconData icon,
      TextInputType keyboardType = TextInputType.text,
        bool obscureText = false,
      required TextEditingController controller}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        obscureText: obscureText,
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Color(0xFF3F704D),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          label: Text(label),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintStyle: TextStyle(color: Colors.green.shade900),
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
      ),
    );
  }
}
