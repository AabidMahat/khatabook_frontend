import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(
    home: OrganisationSetting(),
  ));
}

class OrganisationSetting extends StatefulWidget {
  const OrganisationSetting({super.key});

  @override
  State<OrganisationSetting> createState() => _OrganisationSettingState();
}

class _OrganisationSettingState extends State<OrganisationSetting> {
  late String userId;
  List accounts = [];
  bool isLoading=true;

  @override
  void initState() {
    super.initState();
    getUserId();
  }

  void getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId') ?? '';
    });
    fetchAccounts(userId);
  }

  void fetchAccounts(String user_id) async {
    try {
      var url =
          "${APIURL}/api/v3/account/getAccounts/$user_id";
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        setState(() {
          accounts = responseBody['data']['account'].map((account) {
            account['access'] = ""; // Add access field to each account
            return account;
          }).toList();
          print(accounts);
        });
        setState(() {
          isLoading = false;
        });
      }
    } catch (err) {
      print("Error fetching accounts: $err");
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
          'Organization Settings',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green.shade900,
        elevation: 3,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: _buildBodyContent()
      ),
    );
  }
  Widget _buildBodyContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (accounts.isEmpty) {
      return Center(child: Text('No accounts found'));
    } else {
      return Container(
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            return OrganisationcCard(
              account: accounts[index],
            );
          },
        ),
      );
    }
  }
}



class OrganisationcCard extends StatelessWidget {
  final Map<String, dynamic> account;
  OrganisationcCard({super.key,required this.account});


  void showSubscribeDialog(BuildContext context) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5,sigmaY: 5),
          child: Dialog(
            elevation: 4,
            shadowColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12)
                ),
                constraints: BoxConstraints(
                    maxHeight: 280
                ),
                child: Subscribe()
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final String? subscriptionDateStr = account['suscribtionDate'];
    final String? paymentDateStr = account['paymentDate'];

    DateTime? subscriptionDate;
    DateTime? currentDate;

    if (subscriptionDateStr != null) {
      try {
        subscriptionDate = DateTime.parse(subscriptionDateStr);
      } catch (e) {
        print("Error parsing subscription date: $e");
      }
    }

    if (paymentDateStr != null) {
      try {
        currentDate = DateTime.parse(paymentDateStr);
      } catch (e) {
        print("Error parsing payment date: $e");
      }
    }

    final int remainingDays = subscriptionDate != null && currentDate != null
        ? subscriptionDate.difference(currentDate).inDays
        : 0;

    var activeMap ={
      true:"Active",
      false:"InActive"
    };


    return Container(
      padding: EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width,

          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 3,
                color: Color(0x35000000),
                offset: Offset(0.0, 1),
              )
            ],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(0xFFF1F4F8),
              width: 0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.only(top: 10, left: 12, right: 12),
                child: Text(
                  '${account['account_name']}',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.only(left: 12, right: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Id: ',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF57636C),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${account['accountId']}',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF57636C),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: AlignmentDirectional(1, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            activeMap[account['isActive']]!,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: Color(0xFF57636C),
                              fontSize: 12,
                              letterSpacing: 0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0),
                  child: Container(
                      padding: EdgeInsets.only(bottom: 10),
                      width: MediaQuery.sizeOf(context).width,
                      decoration: BoxDecoration(
                        color: ((remainingDays)>0 &&  account['isActive'])?Color(0xFF3F704D):Colors.red.shade900,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 3,
                            color: Color(0x35000000),
                            offset: Offset(
                              0.0,
                              1,
                            ),
                          )
                        ],
                        shape: BoxShape.rectangle,
                        border: Border.all(
                          color: Color(0xFF3F704D),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding:
                        EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: Column(children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Subscription',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'From: ',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        '${subscriptionDate?.toLocal()}'.split(' ')[0],
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    '$remainingDays Days',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Remaining',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          TextButton(
                            onPressed: () {
                              showSubscribeDialog(context);
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.card_membership,
                                  size: 20,
                                  color: Colors.green.shade900,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Subscribe',
                                  style: TextStyle(
                                    fontFamily: 'Readex Pro',
                                    color: Color(0xFF3F704D),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ]),
                      ))),
            ],
          ),
        ),
      ),
    );
  }
}
