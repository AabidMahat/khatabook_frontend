import 'package:flutter/foundation.dart';

// Service interface for class operations
abstract class ClassService {
  Future<bool> createClass(String name, double fees, String teacherId);
  Future<List<Map<String, dynamic>>> getClasses(String accountId);
  Future<bool> updateClass(String classId, Map<String, dynamic> data);
  Future<bool> deleteClass(String classId);
}

class ClassLogic {
  final ClassService _classService;
  bool _isProcessing = false;

  ClassLogic(this._classService);

  bool get isProcessing => _isProcessing;

  // Validation methods
  bool isValidClassName(String name) {
    return name.trim().isNotEmpty && name.length <= 50;
  }

  bool isValidFees(double fees) {
    return fees > 0 && fees <= 1000000; // Example maximum limit
  }

  bool isValidTeacherId(String teacherId) {
    return teacherId.trim().isNotEmpty;
  }

  // Create class with validation
  Future<ClassResult> createClass(String name, double fees, String teacherId) async {
    if (_isProcessing) {
      return ClassResult(
        success: false,
        error: 'Another operation is in progress',
      );
    }

    try {
      _isProcessing = true;

      // Validate input
      if (!isValidClassName(name)) {
        return ClassResult(
          success: false,
          error: 'Invalid class name',
        );
      }

      if (!isValidFees(fees)) {
        return ClassResult(
          success: false,
          error: 'Invalid fees amount',
        );
      }

      if (!isValidTeacherId(teacherId)) {
        return ClassResult(
          success: false,
          error: 'Invalid teacher ID',
        );
      }

      final success = await _classService.createClass(name, fees, teacherId);
      return ClassResult(success: success);
    } catch (e) {
      return ClassResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isProcessing = false;
    }
  }

  // Get classes for an account
  Future<ClassListResult> getClasses(String accountId) async {
    if (_isProcessing) {
      return ClassListResult(
        success: false,
        error: 'Another operation is in progress',
      );
    }

    try {
      _isProcessing = true;
      final classes = await _classService.getClasses(accountId);
      return ClassListResult(
        success: true,
        classes: classes,
      );
    } catch (e) {
      return ClassListResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isProcessing = false;
    }
  }

  // Update class
  Future<ClassResult> updateClass(String classId, Map<String, dynamic> data) async {
    if (_isProcessing) {
      return ClassResult(
        success: false,
        error: 'Another operation is in progress',
      );
    }

    try {
      _isProcessing = true;

      // Validate update data
      if (data.containsKey('name') && !isValidClassName(data['name'])) {
        return ClassResult(
          success: false,
          error: 'Invalid class name',
        );
      }

      if (data.containsKey('fees') && !isValidFees(data['fees'])) {
        return ClassResult(
          success: false,
          error: 'Invalid fees amount',
        );
      }

      final success = await _classService.updateClass(classId, data);
      return ClassResult(success: success);
    } catch (e) {
      return ClassResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isProcessing = false;
    }
  }

  // Delete class
  Future<ClassResult> deleteClass(String classId) async {
    if (_isProcessing) {
      return ClassResult(
        success: false,
        error: 'Another operation is in progress',
      );
    }

    try {
      _isProcessing = true;
      final success = await _classService.deleteClass(classId);
      return ClassResult(success: success);
    } catch (e) {
      return ClassResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      _isProcessing = false;
    }
  }
}

// Result classes for operations
class ClassResult {
  final bool success;
  final String? error;

  ClassResult({required this.success, this.error});
}

class ClassListResult {
  final bool success;
  final List<Map<String, dynamic>>? classes;
  final String? error;

  ClassListResult({
    required this.success,
    this.classes,
    this.error,
  });
}

// Class model
@immutable
class Class {
  final String id;
  final String name;
  final double fees;
  final String teacherId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Class({
    required this.id,
    required this.name,
    required this.fees,
    required this.teacherId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Class.fromJson(Map<String, dynamic> json) {
    return Class(
      id: json['id'] as String,
      name: json['name'] as String,
      fees: (json['fees'] as num).toDouble(),
      teacherId: json['teacherId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fees': fees,
      'teacherId': teacherId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Class copyWith({
    String? name,
    double? fees,
    String? teacherId,
    DateTime? updatedAt,
  }) {
    return Class(
      id: id,
      name: name ?? this.name,
      fees: fees ?? this.fees,
      teacherId: teacherId ?? this.teacherId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
