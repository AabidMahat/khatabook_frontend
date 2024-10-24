import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: SettingFields(
      icon: Icons.person_2_outlined,
      title: "Name",
      subtitle: "Aabid",
    ),
  ));
}

class SettingFields extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SettingFields({super.key,
    required this.icon,
    required this.title,
    required this.subtitle,});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 5,horizontal: 15), // Adds gap between containers
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, size: 26),
                SizedBox(width: 10), // Adds gap between icon and text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 5), // Adds gap between title and subtitle
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Repeat the container for additional items
        ],
      ),


    );
  }
}
