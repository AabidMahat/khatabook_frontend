import 'dart:ffi';

import 'package:supabase/supabase.dart';

class TransactionData {
  final String id;
  final String transactionType;
  final int amount;
  final int pendingAmount;
  final String studentId;
  final Account account;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? transactionDescription;
  final String? transactionMode;

  TransactionData({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.pendingAmount,
    required this.studentId,
    required this.account,
    required this.createdAt,
    required this.updatedAt,
    this.transactionDescription,
    this.transactionMode,
  });

  factory TransactionData.fromJson(Map<String, dynamic> json) {
    return TransactionData(
      id: json['_id'],
      transactionType: json['transactionType'],
      amount: json['amount'],
      pendingAmount: json['pendingAmount'],
      studentId: json['student_id'],
      account: Account.fromJson(json['account_id']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      transactionDescription: json['transaction_description'],
      transactionMode: json['transaction_mode'] ?? "-",
    );
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'transactionType': transactionType,
      'amount': amount,
      'pendingAmount': pendingAmount,
      'student_id': studentId,
      'account_id': account.id, // Assuming Account has an 'id' field
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'transaction_description': transactionDescription ?? "",
      'transaction_mode': transactionMode ?? "-",
    };
  }
}


class Account {
  final String id;
  final String accountName;

  Account({required this.id, required this.accountName});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['_id'],
      accountName: json['account_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'account_name': accountName,
    };
  }
}

class Student {
  final String id;
  final String studentName;
  final String phone;
  final String classes;
  final String? classId;
  final String address;
  final int totalFees;
  final int paidFees;
  final String? imagePath;
  final String accountId;

  Student({
    required this.id,
    required this.studentName,
    required this.phone,
    required this.classes,
    this.classId = "",
    this.address = "",
    required this.totalFees,
    required this.paidFees,
    this.imagePath,
    required this.accountId,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'],
      studentName: json['student_name'],
      phone: json['phone'],
      classes: json['classes'],
      classId: json['classId'],
      address: json['address'] ?? "",
      totalFees: json['total_fees'],
      paidFees: json['paid_fees'],
      imagePath: json['imagePath'],
      accountId: json['account_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'student_name': studentName,
      'phone': phone,
      'classes': classes,
      'classId':classId,
      'address': address,
      'total_fees': totalFees,
      'paid_fees': paidFees,
      'imagePath': imagePath,
      'account_id': accountId,
    };
  }
}

class ClassData {
  final String id;
  final String className;
  final String teacherName;
  final String accountId;
  final String teacherId;
  final int? classAmount;
  final int? duration;
  final int? requiredAmount; // Nullable field

  ClassData({
    required this.id,
    required this.className,
    required this.teacherName,
    required this.accountId,
    required this.teacherId,
    this.classAmount,
    this.duration,
    this.requiredAmount, // Nullable field
  });

  factory ClassData.fromJson(Map<String, dynamic> json) {
    return ClassData(
      id: json['_id'],
      className: json['class_name'],
      teacherName: json['teacher_name'],
      accountId: json['account_no'],
      teacherId: json['teacherId'],
      classAmount: json['class_ammount'] != null ? json['class_ammount'] as int : null,
      duration: json['duration'] != null ? json['duration'] as int : null,
      requiredAmount: json['amount_by_time'] != null ? json['amount_by_time'] as int : null, // Handle nullable field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'class_name': className,
      'teacher_name': teacherName,
      'account_no': accountId,
      'teacherId': teacherId,
      'class_ammount': classAmount, // Nullable field
      'duration': duration,
      'required_amount': requiredAmount, // Nullable field
    };
  }
}



class TeacherData {
  final String id;
  final String teacherName;
  final String accountId;

  TeacherData({
    required this.id,
    required this.teacherName,
    required this.accountId,
  });
  factory TeacherData.fromJson(Map<String, dynamic>json){
    return TeacherData(
        id: json['_id'],
        teacherName: json['teacher_name'],
        accountId: json['account_no']
    );
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'teacher_name': teacherName,
      'account_no': accountId,
    };
  }
}


class Staff {
  final String id;
  final String staffName;
  final String staffNumber;
  final String staffPassword;
  final String staffAccess;
  final String accountId;

  Staff({
    required this.id,
    required this.staffName,
    required this.staffNumber,
    required this.staffPassword,
    required this.staffAccess,
    required this.accountId,
  });
  factory Staff.fromJson(Map<String, dynamic>json){
    return Staff(
        id: json['_id'],
        staffName: json['staff_name'],
        staffNumber: json['staff_number'],
        staffPassword: json['staffPassword'],
        staffAccess: json['staff_access'],
        accountId: json['account_no']
    );
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'staff_name': staffName,
      'staff_number':staffNumber,
      'staffPassword':staffPassword,
      'staff_access':staffAccess,
      'account_no': accountId,
    };
  }
}

class UserData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final String imagePath;
  final bool isActive;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.imagePath,
    required this.isActive,
  });
  factory UserData.fromJson(dynamic json) {
    return UserData(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      password: json['password'],
      confirmPassword: json['confirmPassword'],
      imagePath: json['imagePath'],
      isActive: json['isActive'],
    );
  }
}
