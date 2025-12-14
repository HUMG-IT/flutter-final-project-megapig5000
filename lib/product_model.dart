import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final int quantity;
  final String description;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.quantity,
    required this.description,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime date = DateTime.now();
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        date = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is String) {
        date = DateTime.parse(data['updatedAt']);
      }
    }

    return Product(
      id: documentId,
      title: data['title'] ?? '',
      quantity: data['quantity'] ?? 0,
      description: data['description'] ?? '',
      updatedAt: date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'quantity': quantity,
      'description': description,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  Product copyWith({
    String? id, 
    String? title, 
    int? quantity, 
    String? description, 
    DateTime? updatedAt
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}