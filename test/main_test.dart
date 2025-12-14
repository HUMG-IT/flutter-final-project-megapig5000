import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); 
  setupFirebaseCoreMocks();
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('App displays Login Screen by default', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.text('Đăng nhập'), findsWidgets); 
    expect(find.text('Hello World!'), findsNothing);
  });
}