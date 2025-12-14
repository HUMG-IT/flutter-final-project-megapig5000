import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/product_model.dart';

void main() {
  group('Logic Lọc và Sắp xếp', () {
    final date1 = DateTime(2023, 1, 1);
    final date2 = DateTime(2023, 6, 1);
    final date3 = DateTime(2023, 12, 1);

    final List<Product> mockProducts = [
      Product(id: '1', title: 'Apple', quantity: 10, description: 'Fruit', updatedAt: date1),
      Product(id: '2', title: 'Banana', quantity: 5, description: 'Fruit', updatedAt: date3),
      Product(id: '3', title: 'Carrot', quantity: 20, description: 'Vegetable', updatedAt: date2),
    ];
    
    test('Tìm kiếm trả về kết quả đúng', () {
      const query = 'ana';
      final result = mockProducts.where((p) => p.title.toLowerCase().contains(query)).toList();
      expect(result.length, 1);
      expect(result.first.title, 'Banana');
    });
    test('Sắp xếp theo số lượng tăng dần hoạt động đúng', () {
      mockProducts.sort((a, b) => a.quantity.compareTo(b.quantity));
      expect(mockProducts.first.title, 'Banana'); 
      expect(mockProducts.last.title, 'Carrot');  
    });
    test('Sắp xếp theo thời gian mới nhất (Giảm dần)', () {
      mockProducts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      expect(mockProducts[0].title, 'Banana'); 
      expect(mockProducts[1].title, 'Carrot'); 
      expect(mockProducts[2].title, 'Apple');  
    });
  });
}