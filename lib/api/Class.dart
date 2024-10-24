import 'dart:convert';

import 'package:khatabook_project/API_URL.dart';
import 'package:http/http.dart' as http;

class ClassApi {
  Future<int> getRequiredAmount(String classId) async {
    final String url = "${APIURL}/api/v3/class/fetchClasses/${classId}";

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var body = json.decode(response.body);

      int amount = body['data']['amount_by_time'];

      print(body['data']);

      return amount;
    } else {
      return 0;
    }
  }
}
