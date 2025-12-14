import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hiển thị tiêu đề ứng dụng', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Quản lý Kho'))));

    expect(find.text('Quản lý Kho'), findsOneWidget);
  });
}