import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final String icon; // Icon name as string for DB storage
  final String? imagePath;

  Category({
    this.id,
    required this.name,
    required this.icon,
    this.imagePath,
  });

  static const Map<String, IconData> availableIcons = {
    'fastfood': Icons.fastfood,
    'local_drink': Icons.local_drink,
    'icecream': Icons.icecream,
    'cake': Icons.cake,
    'local_pizza': Icons.local_pizza,
    'dinner_dining': Icons.dinner_dining,
    'local_offer': Icons.local_offer,
    'restaurant': Icons.restaurant,
    'bakery_dining': Icons.bakery_dining,
    'coffee': Icons.coffee,
  };

  IconData get iconData => availableIcons[icon] ?? Icons.fastfood;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'image_path': imagePath,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      imagePath: map['image_path'],
    );
  }
}
