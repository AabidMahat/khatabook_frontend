import 'package:flutter/foundation.dart';
import 'package:khatabook_project/Database.dart';

class DashboardState with ChangeNotifier {
  String? _staffAccess;
  String? _selectedAccountId;
  List<Student> _students = [];
  bool _isLoading = true;
  String _searchQuery = "";
  List<Student> _filteredStudents = [];

  String? get staffAccess => _staffAccess;
  String? get selectedAccountId => _selectedAccountId;
  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  List<Student> get filteredStudents => _filteredStudents;

  void setStaffAccess(String access) {
    _staffAccess = access;
    notifyListeners();
  }

  void setSelectedAccountId(String? accountId) {
    _selectedAccountId = accountId;
    notifyListeners();
  }

  void setStudents(List<Student> students) {
    _students = students;
    notifyListeners();
  }

  void setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilteredStudents(List<Student> students) {
    _filteredStudents = students;
    notifyListeners();
  }
}
