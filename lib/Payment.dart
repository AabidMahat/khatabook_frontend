import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/ModifyOrganisation.dart';
import 'package:khatabook_project/Subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

class Payment extends StatefulWidget {
  final String accountName;
  final String accountId;

  Payment(
      {super.key, required this.accountName, required this.accountId});

  @override
  State<Payment> createState() => _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState extends State<Payment> {
  List accounts = [];
  String? _selectedAccount;
  String? accountName;
  String? staffAccess;
  var accountData;
  bool isLoading = false;

  // Controllers to handle text input
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController smsController = TextEditingController();
  final TextEditingController urlController = TextEditingController();

  String whatsappHintText = 'Fetching template...';
  String smsHintText = 'Fetching template...';
  String urlHintText = "Fetching url...";

  DateTime? subscriptionDate;

  @override
  void initState() {
    super.initState();
    getStaffAccess();// Fetch account details on initialization
    fetchAccountDetails();
  }

  void getStaffAccess() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    staffAccess = prefs.getString('setAccess');
  }

  Future<void> fetchAccountDetails() async {
    final url =
        '${APIURL}/api/v3/account/getAccount/account_id=${widget.accountId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        accountData = responseBody['data']['account'];
        print('Account Data: $accountData'); // Debug statement

        setState(() {
          whatsappHintText =
              accountData['whatsapp_template'] ?? "";
          smsHintText = accountData['sms_template'] ?? "";
          urlHintText = accountData['url_template'] ?? "";
          subscriptionDate = DateTime.parse(accountData['suscribtionDate']);
        });

        if (whatsappHintText.isNotEmpty) {
          setState(() {
            whatsappController.text = whatsappHintText;
          });
        }
        if (smsHintText.isNotEmpty) {
          setState(() {
            smsController.text = smsHintText;
          });
        }
        if (urlHintText.isNotEmpty) {
          setState(() {
            urlController.text = urlHintText;
          });
        }
      } else {
        print(
            'Failed to load account details, Status code: ${response.statusCode}'); // Debug statement
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load account details')));
      }
    } catch (e) {
      print('Error: $e'); // Debug statement
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void showSubscribeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            elevation: 4,
            shadowColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Container(
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(12)),
                constraints: BoxConstraints(maxHeight: 280),
                child: Subscribe()),
          ),
        );
      },
    );
  }

  Future<void> updateTemplates() async {
    setState(() {
      isLoading=true;
    });
    final url =
        '${APIURL}/api/v3/account/updateAccount/${widget.accountId}';
    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      'whatsapp_template': whatsappController.text,
      'sms_template': smsController.text,
      'url_template':urlController.text,
    });

    try {
      final response =
          await http.patch(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        // Successfully updated
        final responseBody = jsonDecode(response.body);
        toastification.show(
          context: context,
          title: Text("Account Updated"),
          autoCloseDuration: Duration(milliseconds: 2000),
          type: ToastificationType.success,
          showProgressBar: false
        );
        setState(() {
          isLoading=false;
        });
      } else {
        // Error while updating
        final errorBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorBody['message'])));
        setState(() {
          isLoading=false;
        });
      }
    } catch (e) {
      // Error during request
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update templates')));
      setState(() {
        isLoading=false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Account $accountData");
    final DateTime currentDate = DateTime.now();

    final remainingDays = subscriptionDate?.difference(currentDate).inDays;

    var activeMap ={
      true:"Active",
      false:"InActive"
    };
    return Scaffold(
      appBar: AppBar(
        title: Text('Organization Settings',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        leading: IconButton(
          onPressed: (){
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade900,
      ),
      body: accountData == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding:  EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.accountName,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 100),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Id:" + (accountData['accountId'] ?? 'N/A'),
                                style: TextStyle(color: Colors.grey)),
                            SizedBox(height: 4),
                            Container(
                                child: Text(activeMap[accountData['isActive']]!,
                                    style: TextStyle(color: Colors.green))),
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  buildCombinedTemplateCard(),
                  SizedBox(height: 16),
                  Container(
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
                        child: Container(
                            padding: EdgeInsets.only(bottom: 10),
                            width: MediaQuery.sizeOf(context).width,
                            decoration: BoxDecoration(
                              color: ((remainingDays)!>0 && accountData['isActive'])?Color(0xFF3F704D):Colors.red.shade900,
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
                              padding: EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 10),
                              child: Column(children: [
                                 Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
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
                                    // Navigator.push(
                                    //     context,
                                    //     MaterialPageRoute(
                                    //         builder: (context) => Subscribe()));
                                    showSubscribeDialog(context);
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                            )),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget buildCombinedTemplateCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'WhatsApp Template',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: Color(0xFF14181B),
              fontSize: 18,
              letterSpacing: 0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: whatsappController,
            maxLines: 4,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: whatsappHintText,
              alignLabelWithHint: true,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFC5C8CE),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF4B39EF),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFE0E3E7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFE0E3E7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 16), // Added spacing between the fields
          Text(
            'SMS Template',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: Color(0xFF14181B),
              fontSize: 18,
              letterSpacing: 0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: smsController,
            maxLines: 4,
            maxLength: 200,
            decoration: InputDecoration(
              alignLabelWithHint: true,
              hintText: smsHintText,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFC5C8CE),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF4B39EF),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFE0E3E7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFE0E3E7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Upi Id',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: Color(0xFF14181B),
              fontSize: 18,
              letterSpacing: 0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: urlController,
            maxLines: 1,
            maxLength: 100,
            decoration: InputDecoration(
              alignLabelWithHint: true,
              hintText: urlHintText,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFC5C8CE),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFF4B39EF),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFE0E3E7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xFFE0E3E7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          SizedBox(height: 8),

          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed:isLoading?null: updateTemplates,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit,
                    size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Update',
                    style: TextStyle(
                      fontFamily: 'Readex Pro',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              style: TextButton.styleFrom(
                backgroundColor:isLoading?Colors.grey: Colors.green.shade900,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
