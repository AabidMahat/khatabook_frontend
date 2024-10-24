import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:khatabook_project/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(
    onGenerateRoute: (settings) {
      if (settings.name == "/transaction") {
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) {
            return Transaction(
              studentId: args['studentId'],
              accountId: args['accountId'],
            );
          },
        );
      }
      return null; // Return null if no matching route found
    },
  ));
}



class AnimatedScreenPage extends StatefulWidget {
  final String account_id;
  final String student_id;
  const AnimatedScreenPage({super.key, required this.student_id,required this.account_id});

  @override
  State<AnimatedScreenPage> createState() => _AnimatedScreenPageState();
}

class _AnimatedScreenPageState extends State<AnimatedScreenPage> {

  String ? staffAccess;

  void getStaffAccess()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    staffAccess = prefs.getString('setAccess');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSplashScreen(
        splash: Icon(
          FontAwesomeIcons.circleCheck,
          color: Colors.white,
          size: 100,
        ),
        nextScreen: Transaction(
          studentId: widget.student_id,
          accountId: widget.account_id,
        ),
        duration: 3000,
        backgroundColor: Colors.green.shade900,
        splashTransition: SplashTransition.fadeTransition,
      ),
    );
  }
}
