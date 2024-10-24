import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/LoginPage.dart';
import 'package:khatabook_project/Student.dart';
import 'package:khatabook_project/newLoginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main()async  {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('userId');
  String? staffAccess = prefs.getString('setAccess');
  runApp(MaterialApp(
    home: userId==null? Splash():Dashboard(),
    debugShowCheckedModeBanner: false,
  ));
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 3), () {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewLoginPage(),
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.green.shade900,
        child: Center(
          child: Container(
            height: 300,
            width: 300,
            child: Image.asset("android/assets/main_icon.png",width: 300,height: 300,),
          ),
        ),
      ),
    );
  }
}
