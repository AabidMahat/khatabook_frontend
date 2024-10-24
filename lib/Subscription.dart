import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upi_india/upi_india.dart';
import "package:http/http.dart" as http;

class Subscribe extends StatefulWidget {
  const Subscribe({super.key});

  @override
  State<Subscribe> createState() => _SubscribeState();
}

class _SubscribeState extends State<Subscribe> {
  Future<UpiResponse>? _transaction;
  final UpiIndia _upiIndia = UpiIndia();
  List<UpiApp>? apps;
  String ? staffAccess;
  var admin;

  @override
  void initState() {
    super.initState();
    getStaffAccess();
    adminData();
    _upiIndia.getAllUpiApps(mandatoryTransactionId: false).then((value) {
      setState(() {
        apps = value;
      });
    }).catchError((e) {
      print(e);
      apps = [];
    });
  }

  void adminData()async{
    final String url = "${TESTURL}/api/v3/admin/getAdmin";

    var response = await http.get(Uri.parse(url));

    if(response.statusCode==200){
      var responseBody = json.decode(response.body);
      setState(() {
        admin = responseBody['data'];
      });
      print(admin);
    }


  }

  void getStaffAccess() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    staffAccess = prefs.getString("setAccess");
  }

  Future<UpiResponse> initiateTransaction(UpiApp app) async {
    return _upiIndia.startTransaction(
      app: app,
      receiverUpiId: "${admin[0]['upiId']}",
      receiverName: 'Rafik Shaikh',
      transactionRefId: 'TestingUpiIndiaPlugin',
      transactionNote: 'Not actual. Just an example.',
      amount: admin[0]['amount'].toDouble(),
    );
  }

  Widget displayUpiApps() {
    if (apps == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (apps!.isEmpty) {
      return const Center(
        child: Text("No apps found to handle transaction"),
      );
    } else {
      return Wrap(
        children: apps!.map<Widget>((UpiApp app) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _transaction = initiateTransaction(app);
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 20,horizontal: 20),
              height: 50,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.green.shade900
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.memory(
                    app.icon,
                    height: 30,
                  ),
                  const SizedBox(width: 10,),
                  Text(app.name,style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.only(top: 10),
          height: 300, // Increased the height to accommodate UPI apps
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                blurRadius: 3,
                color: Color(0x35000000),
                offset: Offset(0, 1),
              ),
            ],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.green.shade900,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(top: 10),
                child: const Align(
                  alignment: AlignmentDirectional(0, -1),
                  child: Text(
                    'Subscribe now',
                    style: TextStyle(
                      fontFamily: 'Readex Pro',
                      fontSize: 24,
                      letterSpacing: 0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Container(
                child:  Align(
                  alignment: AlignmentDirectional(0, 0),
                  child: Text(
                    '₹${admin!=null?admin[0]['amount']:"..."}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Readex Pro',
                      fontSize: 60,
                      letterSpacing: 0,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.grey,
                          offset: Offset(2.0, 2.0),
                          blurRadius: 2.0,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                child: const Align(
                  alignment: AlignmentDirectional(0, -1),
                  child: Text(
                    'Per Year',
                    style: TextStyle(
                      fontFamily: 'Readex Pro',
                      fontSize: 20,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              displayUpiApps(), // Display UPI apps
            ],
          ),
        ),
      ),
    );
  }
}
