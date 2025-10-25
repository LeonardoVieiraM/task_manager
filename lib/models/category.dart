import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final Color color;

  Category({
    String? id,
    required this.name,
    required this.color,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      color: Color(map['color']),
    );
  }
}

// Categorias padrão
final List<Category> defaultCategories = [
  Category(name: 'Trabalho', color: Colors.blue),
  Category(name: 'Pessoal', color: Colors.green),
  Category(name: 'Estudos', color: Colors.orange),
  Category(name: 'Saúde', color: Colors.red),
  Category(name: 'Lazer', color: Colors.purple),
  Category(name: 'Outros', color: Colors.grey),
];