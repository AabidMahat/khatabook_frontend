import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PhoneBook extends StatefulWidget {
  const PhoneBook({super.key});

  @override
  State<PhoneBook> createState() => _PhoneBookState();
}

class _PhoneBookState extends State<PhoneBook> {
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getContactPermission();
    searchController.addListener(() {
      filterContacts();
    });
  }

  Future<File> getContactsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    return File('$path/contacts.json');
  }

  Future<void> saveContactsToJson(List<Contact> contacts) async {
    final file = await getContactsFile();
    List<Map<String, dynamic>> contactsJson = contacts.map((contact) {
      return {
        'givenName': contact.givenName,
        'familyName': contact.familyName,
        'phones': contact.phones?.map((item) => item.value).toList(),
      };
    }).toList();
    await file.writeAsString(jsonEncode(contactsJson));
  }

  Future<List<Contact>> loadContactsFromJson() async {
    try {
      final file = await getContactsFile();
      if (await file.exists()) {
        final data = await file.readAsString();
        List<dynamic> contactsJson = jsonDecode(data);
        print(contactsJson);
        return contactsJson.map((json) {
          return Contact(
            givenName: json['givenName'],
            familyName: json['familyName'],
            phones: (json['phones'] as List?)
                ?.map((phone) => Item(label: 'mobile', value: phone))
                .toList(),
          );
        }).toList();
      }
    } catch (e) {
      // Handle the error
      print("Error loading contacts from JSON: $e");
    }
    return [];
  }

  void getContactPermission() async {
    if (await Permission.contacts.isGranted) {
      loadContacts();
    } else {
      var status = await Permission.contacts.request();
      if (status.isGranted) {
        loadContacts();
      }
    }
  }

  String formatPhoneNumber(String phone) {
    // Remove any country code prefix
    if (phone.startsWith('+91')) {
      phone = phone.substring(3).trim();
    }
    // Remove any spaces or dashes
    phone = phone.replaceAll(RegExp(r'\s+|-'), '');
    return phone;
  }

  void loadContacts() async {
    // First, try to load contacts from the local JSON file
    contacts = await loadContactsFromJson();
    if (contacts.isEmpty) {
      // If no contacts were found in the local file, fetch from the phonebook
      contacts = await ContactsService.getContacts();
      print(contacts);
      saveContactsToJson(contacts); // Save fetched contacts to the JSON file
    }

    // Filter out contacts with "No name" or "No phone"
    contacts = contacts.where((contact) {
      var name = contact.givenName ?? 'No name';
      var phone = contact.phones?.isNotEmpty == true
          ? formatPhoneNumber(contact.phones![0].value ?? 'No phone')
          : 'No phone';
      return name != 'No name' && phone != 'No phone';
    }).toList();

    setState(() {
      filteredContacts = contacts;
      isLoading = false;
    });
  }

  void filterContacts() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredContacts = contacts.where((contact) {
        return (contact.givenName ?? '').toLowerCase().contains(query) ||
            (contact.familyName ?? '').toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: const Text(
          "Contacts",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Icon(
          Icons.arrow_back,
          color: Colors.green.shade900,
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                contentPadding:
                EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
                suffixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF080000),
                  size: 20,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFF3F704D),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                isDense: false,
                labelText: 'Search...',
                labelStyle: TextStyle(
                  fontFamily: 'Readex Pro',
                  color: Color(0xFF3F704D),
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFF3F704D),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredContacts.length,
              itemBuilder: (context, index) {
                var contact = filteredContacts[index];
                var initial = contact.givenName?.isNotEmpty == true
                    ? contact.givenName![0]
                    : '';

                var name = contact.givenName ?? 'No name';
                var familyName = contact.familyName ?? '';
                var fullName = '$name $familyName';
                var phone = contact.phones?.isNotEmpty == true
                    ? formatPhoneNumber(contact.phones![0].value ?? 'No phone')
                    : 'No phone';

                return ListTile(
                  leading: Container(
                    height: 30.h,
                    width: 30.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
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
                      borderRadius: BorderRadius.circular(6.r),
                      color: Colors.white,
                    ),
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 23.sp,
                        color: Colors.primaries[
                        Random().nextInt(Colors.primaries.length)],
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  title: Text(
                    fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.black,
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    phone,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.black,
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  horizontalTitleGap: 12.w,
                  onTap: () {
                    Navigator.pop(context, phone);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
