import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:khatabook_project/API_URL.dart';
import 'package:khatabook_project/AmmountGave.dart';
import 'package:khatabook_project/AmmountGot.dart';
import 'package:khatabook_project/Dashboard.dart';
import 'package:khatabook_project/Database.dart';
import 'package:khatabook_project/UpdateData.dart';
import 'package:khatabook_project/api/Class.dart';
import 'package:khatabook_project/sideBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:upi_india/upi_india.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'card.dart';
import 'package:upi_india/upi_india.dart';

void main() {
  AwesomeNotifications().initialize(
    'resource://drawable/res_app_icon',
    [
      NotificationChannel(
        channelKey: 'aabid',
        channelName: 'Basic Notification',
        channelDescription: 'Notification channel for basic test',
      ),
    ],
    debug: true,
  );
}

class Transaction extends StatefulWidget {
  final String studentId;
  final String accountId;

  const Transaction(
      {super.key, required this.studentId, required this.accountId});

  @override
  State<Transaction> createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<TransactionData> transaction = [];
  Student? student;
  bool isLoading = true;
  String? staffAccess;
  var accountData;

  int? requiredAmount;
  String? studentName;
  int? studentTotalFees;
  int? studentPaidFees;

  final UpiIndia _upiIndia = UpiIndia();
  ClassApi classApi = ClassApi();


  @override
  void initState() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    super.initState();
    getStaffAccess();
    getTransaction();
    getStudentAccunt();
    fetchAccountDetails();
    getAmount();
  }

  DateTime? _dateController;

  void getStaffAccess() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    setState(() {
      staffAccess = pref.getString('setAccess');
      studentName = pref.getString('studentName');
      studentTotalFees = pref.getInt('totalFees');
      studentPaidFees = pref.getInt('paidFees');

    });
    print("Transaction ${pref.getString("requestedAmount")}");
  }

  void getAmount()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String ? classId = preferences.getString("classId");
    int amount =await classApi.getRequiredAmount(classId!);

    setState(() {
      requiredAmount = amount;
    });
  }

  void getTransaction() async {
    try {
      var response = await http.get(Uri.parse(
          "${APIURL}/api/v3/transaction/seeTransaction/studentId=${widget.studentId}"));
      if (response.statusCode == 202) {
        var data = jsonDecode(response.body);
        setState(() {
          transaction = List<TransactionData>.from(
            data['data'].map((values) => TransactionData.fromJson(values)),
          );

          isLoading = false; // Set loading to false when data is loaded
        });
        getStudentAccunt();
      } else {
        print("Failed to load transactions: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      print("No data: $err");
    }
  }

  Future<void> fetchAccountDetails() async {
    final url =
        '${APIURL}/api/v3/account/getAccount/account_id=${widget.accountId}';
    try {
      final response = await http.get(Uri.parse(url));
      print(response);
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        accountData = responseBody['data']['account'];
      } else {
        // Debug statement
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load account details')));
      }
    } catch (e) {
      print('Error: $e'); // Debug statement
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void getStudentAccunt() async {
    final String url =
        "${APIURL}/api/v3/student/fetchStudent/studentId=${widget.studentId}";
    try {
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        setState(() {
          student = Student.fromJson(data['data'][0]);
          isLoading = false;
        });
      } else {
        print("Failed to load Student: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (err) {
      setState(() {
        isLoading = false;
      });
      print("No data : $err");
    }
  }

  void triggerNotification() {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'aabid',
            title: 'Reminder Set',
            body:
                'Reminder has been set for ${_dateController!.day}/${_dateController!.month}/${_dateController!.year}',
            notificationLayout: NotificationLayout.Default));
  }

  void scheduleNotification(DateTime scheduledDate) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 20,
        channelKey: 'aabid',
        title: 'Reminder',
        body: 'This is your reminder for today',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        year: scheduledDate.year,
        month: scheduledDate.month,
        day: scheduledDate.day,
        hour: 9,
        // Set the desired time for the reminder
        minute: 0,
        second: 0,
        millisecond: 0,
        repeats: false,
      ),
    );
  }



  Future<void> _selectDate() async {
    DateTime now = DateTime.now();
    DateTime initialDate = DateTime(now.year, now.month, 1);
    DateTime? _picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2024),
        lastDate: DateTime(2027));

    if (_picked != null) {
      setState(() {
        _dateController = _picked;
      });
      triggerNotification();
      scheduleNotification(_picked);
    }
  }

  Future<UpiResponse> initiateTransaction(UpiApp app) async {
    return _upiIndia.startTransaction(
      app: app,
      receiverUpiId: accountData['url_template'],
      receiverName: 'Rafik Shaikh',
      transactionRefId: 'TestingUpiIndiaPlugin',
      transactionNote: 'Not actual. Just an example.',
      amount: 99,
    );
  }

  Future<void> sendWhatsApp() async {
    var phone = student?.phone;
    int pendingFees = student!.totalFees - student!.paidFees;
    int requiredAmt = int.tryParse(requiredAmount.toString()) ?? 0;
    num feesToDisplay = pendingFees < requiredAmt ? pendingFees : requiredAmt;
    String upi = accountData['url_template']; // Ensure this is a valid UPI link

    // Create the UPI payment link
    String upiLink = "upi://pay?pa=$upi";

    // Construct the message text
    var text =
        "${accountData['whatsapp_template']}\n Pending fees : ₹$feesToDisplay \n UPI Payment Link : $upiLink";

    // Encode the text for the WhatsApp URL
    var url = "https://wa.me/$phone?text=${Uri.encodeComponent(text)}";

    // Launch WhatsApp with the constructed URL
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Could not launch $url")));
    }
  }



  Future<void> sendSMS() async {
    var phone = student?.phone;
    int pendingFees = student!.totalFees - student!.paidFees;
    print("Pending Fees $pendingFees");
    print("RequiredAmount $requiredAmount");
    int requiredAmt = int.tryParse(requiredAmount.toString()) ?? 0;
    num feesToDisplay = pendingFees < requiredAmt ? pendingFees : requiredAmt;
    String upi = accountData['url_template'];
    String upiLink = "upi://pay?pa=${upi}";

    String smsText =
        "${accountData['sms_template']}.\nPending fees: ₹$feesToDisplay\nPay via UPI: $upiLink\n\n(If the link above is not clickable, copy and paste it into your UPI app.)";


    // Encode the SMS text to be used in a URL
    String encodedText = Uri.encodeComponent(smsText);

    // Create the SMS URL
    String url = 'sms:$phone?body=$encodedText';

    // Launch the URL
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not send SMS to $phone")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
        key: _scaffoldKey,
        appBar: _buildAppBar(),
        drawer: SideBarWidget(accountId: widget.accountId),
        body: Column(
          children: [
            // _buildReminderCard(),
            _buildRemainderNewCard(),
            _buildURLContainer(),
            _buildEntriesHeader(),
            SizedBox(
              height: 10,
            ),
            _buildEntriesList(),
          ],
        ),
        bottomNavigationBar: (staffAccess == "medium" ||
                staffAccess == "high" ||
                staffAccess == "")
            ? _buildBottomNavigationBar()
            : null,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF3F704D),
      actions: (staffAccess == "low")
          ? []
          : [
              IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UpdateSetting(),
                          settings: RouteSettings(arguments: {
                            "studentId": widget.studentId,
                            "student": student,
                          })));
                },
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
      leading: IconButton(
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        icon: Icon(
          Icons.menu,
          color: Colors.white,
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: NetworkImage("${student?.imagePath}"),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                student?.studentName != null
                    ? Text(
                        student!.studentName,
                        key: ValueKey('studentName'),
                        style: TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        studentName!,
                        style: TextStyle(color: Colors.white),
                      )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainderNewCard() {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 12),
      child: Material(
        color: Colors.transparent,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        child: Container(
          width: MediaQuery.sizeOf(context).width,
          decoration: BoxDecoration(
            color: Color(0xFF3F704D),
            // borderRadius: BorderRadius.only(
            //     bottomLeft: Radius.circular(24),
            //     bottomRight: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                blurRadius: 5,
                color: Color(0x32171717),
                offset: Offset(0, 2),
              )
            ],
            border: Border.all(
              color: Color(0xFF3F704D),
            ),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(20, 8, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "₹ ${student != null ? (student!.totalFees) : studentTotalFees}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Total Amount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Color(0xB3FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "₹ ${student != null ? (student!.totalFees - student!.paidFees) : (studentTotalFees! - studentPaidFees!)}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Pending Amount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Color(0xB3FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildURLContainer() {
    return Container(
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 10,
          ),
          InkWell(
            onTap:  _selectDate,
            child: Container(
              width: MediaQuery.of(context).size.width*0.37,
              decoration: BoxDecoration(
                color: Colors.white,
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
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFFF1F4F8),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                    icon: Icon(
                      Icons.calendar_month,
                      color: Color(0xFF3F704D),
                      size: 30,
                    ),
                    onPressed: _selectDate,
                  ),
                  // SizedBox(width: 7), // Add space between icon and text
                  Text(
                    _dateController == null
                        ? "Set Date"
                        : "${_dateController!.day}/${_dateController!.month}/${_dateController!.year}",
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Readex Pro',
                      fontSize: 18,
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal,
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                  SizedBox(width: 3), // Add space between icon and text
                ],
              ),
            ),
          ),


          Container(
            width: MediaQuery.of(context).size.width*0.2,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
              icon: FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Color(0xFF3F704D),
                size: 36,
              ),
              onPressed: () {
                print("Whatsapp ${accountData['whatsapp_template']}");
                if (accountData['whatsapp_template'] != "" &&
                    accountData['whatsapp_template'] != null) {
                  sendWhatsApp();
                } else {
                  toastification.show(
                    context: context,
                    title: Text("Please select the template"),
                    autoCloseDuration: Duration(seconds: 3),
                  );
                }
              },
            ),
          ),

          Container(
            width: MediaQuery.of(context).size.width*0.2,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
              icon: Icon(
                Icons.message,
                color: Color(0xFF3F704D),
                size: 36,
              ),
              onPressed: () {
                if (accountData['sms_template'] != "" &&
                    accountData['sms_template'] != null) {
                  sendSMS();
                } else {
                  toastification.show(
                    context: context,
                    title: Text("Please select the template"),
                    autoCloseDuration: Duration(seconds: 3),
                  );
                }
              },
            ),
          ),

          Container(
            width: MediaQuery.of(context).size.width*0.2,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
              icon: Icon(
                Icons.phone_in_talk,
                color: Color(0xFF3F704D),
                size: 36,
              ),
              onPressed: () {
                launchUrl(Uri.parse("tel:${student!.phone}"));
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEntriesHeader() {
    return Container(
      padding: EdgeInsets.all(5),
      child: Text(
        'Transactions',
        textAlign: TextAlign.start,
        style: TextStyle(
          fontFamily: 'Readex Pro',
          fontSize: 16,
          letterSpacing: 0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEntriesList() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else if (transaction.isEmpty) {
      return Center(child: Text('No transactions found'));
    } else {
      return Expanded(
        child: ListView.builder(
          itemCount: transaction.length,
          itemBuilder: (context, index) {
            // Checking if 'student' is null
            if (student == null) {
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.green.shade900,
                ),
              );
            } else {
              return CardWidget(
                transaction: transaction[index],
                onDelete: () {
                  getTransaction();
                  getStudentAccunt();
                },
                onUpdate: () {
                  getTransaction();
                  getStudentAccunt();
                },
                student: student!,
              ).animate().fadeIn(duration: Duration(milliseconds: 1000));
            }
          },
        ),
      );

    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 60,
      margin: EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                var student_id = widget.studentId;
                var account_id = widget.accountId;
                var pendingAmount = transaction.isNotEmpty
                    ? transaction[transaction.length - 1].pendingAmount
                    : 0;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AmmountGivePage(),
                        settings: RouteSettings(arguments: {
                          'student_id': student_id,
                          'account_id': account_id,
                          "pendingAmount": pendingAmount,
                          "student": student,
                        })));
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                primary: Colors.white,
              ),
              child: Text('Request Pay ₹', style: TextStyle(fontSize: 16)),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: TextButton(
              onPressed: () {
                var student_id = widget.studentId;
                var account_id = widget.accountId;
                var pendingAmount =
                    transaction[transaction.length - 1].pendingAmount;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AmmountGotPage(),
                        settings: RouteSettings(arguments: {
                          'student_id': student_id,
                          'account_id': account_id,
                          "pendingAmount": pendingAmount,
                          "student": student,
                        })));
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                primary: Colors.white,
              ),
              child: Text('Collect Pay ₹', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
