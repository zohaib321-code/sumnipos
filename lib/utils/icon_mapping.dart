import 'package:flutter/material.dart';

class IconMapping {
  static IconData getIcon(String name) {
    switch (name) {
      case 'restaurant':
        return Icons.restaurant;
      case 'local_drink':
        return Icons.local_drink;
      case 'fastfood':
        return Icons.fastfood;
      case 'icecream':
        return Icons.icecream;
      case 'local_offer':
        return Icons.local_offer;
      case 'coffee':
        return Icons.coffee;
      case 'cake':
        return Icons.cake;
      case 'lunch_dining':
        return Icons.lunch_dining;
      default:
        return Icons.category;
    }
  }
}
