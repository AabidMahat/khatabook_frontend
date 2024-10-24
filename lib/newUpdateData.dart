import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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
    home: NewUpdateSettings(),
  ));
}

class NewUpdateSettings extends StatefulWidget {
  const NewUpdateSettings({super.key});

  @override
  State<NewUpdateSettings> createState() => _NewUpdateSettingsState();
}

class _NewUpdateSettingsState extends State<NewUpdateSettings> {
  File? _image;
  var name = TextEditingController();
  var phone = TextEditingController();
  var address = TextEditingController();
  var classes = TextEditingController();
  String? staffAccess;
  late Map<String, dynamic> args;
  late String studentId;
  String? publicUrl;
  Student? student;
  bool isLoading = true;

  final supabaseClient = SupabaseClient(
    'https://qlbruwvurmckjguvvjmp.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsYnJ1d3Z1cm1ja2pndXZ2am1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTc0Nzg5ODMsImV4cCI6MjAzMzA1NDk4M30.AJFS6eia23B5bAZsuSCB8KUsbr6uTVVrVsJARVCN-to',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
      studentId = args['studentId'];
      student = args['student'];

      if (student != null) {
        name.text = student!.studentName;
        phone.text = student!.phone;
        // Set address with default value if empty
        address.text =
        student!.address.isNotEmpty ? student!.address : "A/p Rankala";
        classes.text = student!.classes;

        if (student!.imagePath != null) {
          publicUrl = student!.imagePath;
        }
      }
    });
    getStaffAccess();
  }


  void getStaffAccess() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    staffAccess = prefs.getString("setAccess");
    print(staffAccess);
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
      isLoading = false;
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

    Future.delayed(Duration(milliseconds: 2000),(){
      setState(() {
        isLoading=true;
      });
    });

  }

  void _updateData() async {
    print("Update Data $publicUrl");

    final String url =
        "${APIURL}/api/v3/student/updateme/$studentId";
    // final String url = "http://10.0.2.2:3500/api/v3/student/updateme/$studentId";
    var updateBody = {
      "name": name.text,
      "phone": phone.text,
      "address": address.text,
      "classes": classes.text,
      "imagePath": publicUrl.toString(),
    };
    var response = await http.patch(Uri.parse(url),
        body: json.encode(updateBody),
        headers: {"Content-Type": "application/json"});

    if (response.statusCode == 200) {
      toastification.show(
        context: context,
        title: Text("Data updated Successfully"),
        autoCloseDuration: Duration(milliseconds: 1000),
        type: ToastificationType.success,
      );
      Future.delayed(Duration(milliseconds: 1000), () {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => Dashboard(),
                settings:
                RouteSettings(arguments: {"staffAccess": staffAccess})));
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Update Settings",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
        ),
        backgroundColor: Color(0xFF3F704D),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 80,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : (publicUrl != null ? NetworkImage(publicUrl!) : null)
                as ImageProvider<Object>?,
                child: _image == null && publicUrl == null
                    ? Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 70,
                )
                    : null,
                backgroundColor: Color(0xFF3F704D),
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
              label: "Enter Phone Number",
              icon: FontAwesomeIcons.phone,
              keyboardType: TextInputType.number,
              controller: phone,
            ),
            buildTextField(
              label: "Enter Class",
              icon: Icons.grain,
              controller: classes,
            ),
            buildTextField(
              label: "Enter Address",
              icon: FontAwesomeIcons.addressCard,
              controller: address,
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed:isLoading? _updateData:null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  primary: Color(0xFF3F704D),
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
                      "Submit Data",
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
      ),
    );
  }

  Widget buildTextField(
      {required String label,
        required IconData icon,
        TextInputType keyboardType = TextInputType.text,
        required TextEditingController controller}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
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
          labelText: label,
          labelStyle: TextStyle(color: Colors.green.shade900),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.green.shade900,
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
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
