import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main(){
  runApp(MaterialApp(
    home: WatsAppWidget(),
  ));
}

class WatsAppWidget extends StatefulWidget {
  const WatsAppWidget({super.key});

  @override
  State<WatsAppWidget> createState() => _WatsAppWidgetState();
}

class _WatsAppWidgetState extends State<WatsAppWidget> {

  void sendWatsApp(){
    String url = "whatsapp://send?+8275117683";
    launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
