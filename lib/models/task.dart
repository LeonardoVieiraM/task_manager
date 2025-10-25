import 'package:uuid/uuid.dart';
import 'category.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final String priority;
  final DateTime createdAt;
  final DateTime? dueDate;
  final Category category; 

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.completed = false,
    this.priority = 'medium',
    DateTime? createdAt,
    this.dueDate,
    required this.category, // Obrigatório
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed ? 1 : 0,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'categoryId': category.id,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, List<Category> categories) {
    final categoryId = map['categoryId'];
    final category = categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => defaultCategories.last,
    );

    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      completed: map['completed'] == 1,
      priority: map['priority'] ?? 'medium',
      createdAt: DateTime.parse(map['createdAt']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      category: category,
    );
  }

  Task copyWith({
    String? title,
    String? description,
    bool? completed,
    String? priority,
    DateTime? dueDate,
    Category? category,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
    );
  }

  bool get isOverdue {
    if (dueDate == null || completed) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  int? get daysUntilDue {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final difference = dueDate!.difference(now);
    return difference.inDays;
  }
}