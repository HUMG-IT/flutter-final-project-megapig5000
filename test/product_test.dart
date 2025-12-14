import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/product_model.dart';

void main() {
  group('Product Model', () {
    test('Nên khởi tạo Product đúng cách từ Map', () {
      final now = DateTime.now();
      final timestamp = Timestamp.fromDate(now);
      final data = {'title': 'Laptop', 'quantity': 10, 'description': 'New', 'updatedAt': timestamp};
      final product = Product.fromMap(data, 'abc_123');

      expect(product.id, 'abc_123');
      expect(product.title, 'Laptop');
      expect(product.quantity, 10);
      expect(product.description, 'New');
      expect(product.updatedAt.toString(), now.toString());
    });

    test('Nên chuyển Product sang Map đúng cách', () {
      final now = DateTime.now();
      final product = Product(id: '1', title: 'Mouse', quantity: 5, description: 'Gaming', updatedAt: now);
      final map = product.toMap();

      expect(map['title'], 'Mouse');
      expect(map['quantity'], 5);
      expect(map['description'], 'Gaming');
      expect(map['updatedAt'], isA<Timestamp>());
    });
  });
}